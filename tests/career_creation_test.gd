extends SceneTree
const Main = preload("res://scenes/app/main.tscn")
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
const Career = preload("res://scripts/career/career_data.gd")
const Appearance = preload("res://scripts/data/appearance_data.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
const PATH := "user://tests/career.json"
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value:
		failures += 1

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://tests")
	var repo = Repository.new(PATH)
	if "--reload-career" in OS.get_cmdline_user_args():
		var saved: Dictionary = repo.load_snapshot()
		check(saved.get("kind") == "career", "career survives separate Godot process")
		check(saved.get("career", {}).get("athlete", {}).get("first_name") == "Nadia", "saved identity survives separate process")
		quit(failures)
		return
	DirAccess.remove_absolute(PATH)
	var app = Main.instantiate()
	root.add_child(app)
	await process_frame
	app.repository = repo
	app._refresh_save()
	var creator = app.creator
	check(not creator.visible and app.ui.menu.visible, "customization is hidden at startup")
	check(root.gui_get_focus_owner() == app.ui.menu.get_child(0), "initial menu retains keyboard focus")
	check(Catalog.countries().size() == 195 and Catalog.country_name("AZ") == "Azerbaijan", "real-country dataset available with stable codes")
	app.ui.new_requested.emit()
	check(creator.step == 0 and creator.visible, "New Career opens category selection")
	creator.select_category("female")
	creator._next()
	for index in range(3):
		creator.origin_buttons[index].pressed.emit()
		check(creator.draft.to_dict().age == [15, 17, 20][index], "origin %d has correct age" % index)
	creator._next()
	creator._next()
	creator._next()
	check(creator.step == 3 and not creator.error.text.is_empty() and not repo.has_file(), "blank names block summary and saving")
	creator.fields.first_name.text = "  Nadia  "
	creator.fields.last_name.text = "O’Connor"
	for i in range(creator.fields.country.item_count):
		if creator.fields.country.get_item_metadata(i) == "AZ":
			creator.fields.country.select(i)
	creator.fields.skin.select(5)
	creator.fields.hair_color.select(3)
	creator.fields.hairstyle.select(1)
	creator.fields.height.value = 195
	creator.fields.weight.value = 95
	creator.fields.shoulders.value = 1.2
	creator.fields.legs.value = 1.1
	creator._changed()
	check(creator.preview_model.styled_hair.style_id==11 and creator.preview_model.styled_hair.visible, "ponytail preview is distinct from curls")
	check(creator.preview_model.skin_material.albedo_color == Color("482d23"), "skin selection updates preview material")
	check(creator.preview_model.hair_material.albedo_color == Color("934b32"), "hair color updates preview material")
	check(creator.preview_model.scale.x > 1 and creator.preview_model.parts.torso.scale.x > 0.48, "height, weight and proportions visibly scale geometry")
	await process_frame
	creator._next()
	check(creator.step == 4 and "THE CHOSEN ONE" in creator.summary.text and "Azerbaijan" in creator.summary.text and "Age: 20" in creator.summary.text, "summary includes origin, country and derived age")
	var expected: Dictionary = creator.draft.to_dict()
	creator._back()
	creator._back()
	creator._next()
	check(creator.draft.to_dict() == expected and creator.fields.first_name.text == "  Nadia  ", "back and forward preserve all draft controls")
	creator._next()
	creator._next()
	check(app.exploring and not creator.visible and app.career_visual.visible, "confirmed creation saves and enters track with appearance")
	var saved: Dictionary = repo.load_snapshot()
	check(saved.kind == "career" and saved.schema_version == 3 and Career.from_dict(saved.career).to_dict() == expected, "all career fields persist in version 3")
	check(saved.career.athlete.first_name == "Nadia", "saved names are trimmed")
	app.athlete.position = Vector3(1.25, 0, -4.5)
	app._save_and_menu()
	check(Career.from_dict(repo.load_snapshot().career).to_dict() == expected, "track Save & Menu preserves complete career data")
	app._continue()
	check(app.current_career.to_dict() == expected and app.athlete.position == Vector3(1.25, 0, -4.5), "Continue restores identity, appearance and track position")
	app._menu()
	var before := FileAccess.get_file_as_string(PATH)
	app.ui.new_requested.emit()
	creator._next()
	creator._next()
	creator._next()
	creator.fields.first_name.text = "Replacement"
	creator._next()
	creator._next()
	check(app.ui.confirmation.visible and FileAccess.get_file_as_string(PATH) == before, "replacement waits for explicit final confirmation")
	app.ui.confirmation.hide()
	creator._back()
	check(FileAccess.get_file_as_string(PATH) == before and creator.draft.athlete.first_name == "Replacement", "cancel replacement retains old save and editable draft")
	var other = Career.from_dict(expected)
	check(not repo.save_career(other, Vector3.ZERO), "repository refuses unauthorized career replacement")
	for field: String in Appearance.LIMITS:
		for boundary: Variant in Appearance.LIMITS[field]:
			var boundary_data: Dictionary = expected.duplicate(true)
			boundary_data.athlete.appearance[field] = boundary
			var boundary_career = Career.from_dict(boundary_data)
			check(Career.validate(boundary_career.to_dict()).is_empty(), "valid appearance boundary: %s %s" % [field, boundary])
	for field: String in ["skin", "hair_color", "hairstyle", "height", "weight", "shoulders", "legs"]:
		var invalid: Dictionary = expected.duplicate(true)
		invalid.athlete.appearance[field] = INF
		check(not Career.validate(invalid).is_empty(), "reject nonfinite appearance: " + field)
	for invalid_value: Variant in [null, {}, "bad", {"origin_id": "missing", "age": 20}]:
		check(not Career.validate(invalid_value).is_empty(), "reject incomplete/malformed career")
	var invalid_country: Dictionary = expected.duplicate(true)
	invalid_country.athlete.country = "XX"
	check(not Career.validate(invalid_country).is_empty(), "reject invented country code")
	invalid_country = expected.duplicate(true)
	invalid_country.age = 15
	check(not Career.validate(invalid_country).is_empty(), "reject origin-age mismatch")
	for resolution: Vector2i in [Vector2i(640, 640), Vector2i(800, 600), Vector2i(1024, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		creator.show()
		for i in range(5):
			creator.step = i
			creator._show_step()
			await process_frame
			await process_frame
			var rect: Rect2 = creator.next_button.get_global_rect()
			check(rect.end.x <= creator.get_viewport_rect().size.x and rect.end.y <= creator.get_viewport_rect().size.y, "creation footer fits %s step %d" % [resolution, i])
	# Legacy file round-trip: load never migrates/rewrites it, and track saving stays v1.
	var legacy := '{"schema_version":1,"kind":"track_probe","position":[1.25,-4.5]}'
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(legacy)
	file.close()
	app._menu()
	app._continue()
	check(app.current_career == null and not app.career_visual.visible and app.athlete.position == Vector3(1.25, 0, -4.5), "legacy Continue preserves original placeholder and position")
	check(FileAccess.get_file_as_string(PATH) == legacy, "legacy load does not alter existing save bytes")
	app._save_and_menu()
	check(repo.load_snapshot().schema_version == 1, "legacy position save remains version 1")
	check(repo.save_career(other, Vector3.ZERO, true), "explicit authorization can replace legacy save")
	# Malformed v2 data blocks Continue without silent loss.
	var malformed: Dictionary = repo.load_snapshot()
	malformed.career.athlete.appearance.height = "invalid"
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(malformed))
	file.close()
	var damaged := FileAccess.get_file_as_string(PATH)
	app._refresh_save()
	check(app.ui.continue_button.disabled and not repo.error_message.is_empty(), "malformed v2 save disables Continue and reports validation error")
	check(not repo.save_position(Vector3.ZERO) and FileAccess.get_file_as_string(PATH) == damaged, "track cannot overwrite unreadable career")
	check(repo.save_career(other, Vector3.ZERO, true), "confirmed valid career can replace damaged slot")
	print("CAREER TEST FAILURES: ", failures)
	app.queue_free()
	await process_frame
	quit(failures)
