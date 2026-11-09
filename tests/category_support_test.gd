extends SceneTree
const Main = preload("res://scenes/app/main.tscn")
const Career = preload("res://scripts/career/career_data.gd")
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
const Category = preload("res://scripts/data/athlete_category.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
const PATH := "user://tests/categories.json"
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
	if "--reload-categories" in OS.get_cmdline_user_args():
		for category: String in Category.IDS:
			var fixture = Repository.new(PATH + "." + category)
			var record: Dictionary = fixture.load_snapshot()
			check(record.get("schema_version") == 3 and record.get("career", {}).get("athlete_category") == category, "separate-process reload restores " + category)
		quit(failures)
		return
	var app = Main.instantiate()
	root.add_child(app)
	await process_frame
	app.repository = repo
	var creator = app.creator
	DirAccess.remove_absolute(PATH)
	app._new_requested()
	check(creator.step == 0 and "CHOOSE YOUR ATHLETE" in creator.heading.text, "category screen is immediate New Career destination")
	check(creator.draft.athlete_category == "" and not creator.category_buttons[0].button_pressed and not creator.category_buttons[1].button_pressed, "no category is preselected")
	creator._next()
	check(creator.step == 0 and not creator.error.text.is_empty() and not repo.has_file(), "explicit category selection required before proceeding")
	var original_appearance: Dictionary = creator.draft.athlete.appearance.to_dict()
	creator.select_category("male")
	creator.select_category("female")
	check(creator.draft.athlete.appearance.to_dict() == original_appearance, "switching category never resets customization")
	var dimensions: Dictionary = {}
	for category: String in Category.IDS:
		for origin: Dictionary in Catalog.origins():
			app._menu()
			app._new_requested()
			creator.select_category(category)
			creator._next()
			for button: Button in creator.origin_buttons:
				if button.text.begins_with(origin.title):
					button.pressed.emit()
			creator._next()
			creator._next()
			check(creator.step == 3 and creator.fields.size() == 10, "%s / %s has every customization control" % [category, origin.id])
			creator.fields.first_name.text = "Alex"
			creator.fields.last_name.text = "Runner"
			creator.fields.skin.select(4)
			creator.fields.hairstyle.select(2)
			creator.fields.hair_color.select(1)
			creator.fields.height.value = 190
			creator.fields.weight.value = 90
			creator.fields.shoulders.value = 1.15
			creator.fields.legs.value = 1.1
			creator._changed()
			await process_frame
			var expected: Dictionary = creator.draft.to_dict()
			for i in range(3): creator._back()
			check(creator.step == 0 and creator.draft.athlete_category == category, "Back retains %s category" % category)
			creator.select_category("female" if category == "male" else "male")
			creator.select_category(category)
			check(creator.draft.to_dict() == expected, "switching categories preserves entered customizations for " + category)
			for i in range(3): creator._next()
			check(creator.draft.to_dict() == expected, "Next retains complete %s draft" % category)
			creator._next()
			check("Category: " + Category.label(category) in creator.summary.text and origin.title in creator.summary.text, "%s summary names category and origin" % category)
			var before := FileAccess.get_file_as_string(PATH) if repo.has_file() else ""
			creator._next()
			if not before.is_empty():
				check(app.ui.confirmation.visible and FileAccess.get_file_as_string(PATH) == before, "replacement still requires confirmation")
				app.ui.confirmation.hide()
				check(FileAccess.get_file_as_string(PATH) == before, "canceling replacement preserves saved career")
				app._confirm_new()
			var saved: Dictionary = repo.load_snapshot()
			check(saved.schema_version == 3 and saved.career.athlete_category == category and saved.career.origin_id == origin.id and saved.career.age == origin.age, "%s / %s saved with correct category and age" % [category, origin.id])
			app.athlete.position = Vector3(1, 0, -2)
			app._save_and_menu()
			app._continue()
			check(app.current_career.to_dict() == expected and app.career_visual.athlete_category == category and app.athlete.position == Vector3(1, 0, -2), "%s Continue restores full career and category model" % category)
			check(app.current_career.competition_scope("sprint_100m") == category + "/sprint_100m", "%s future competition namespace is explicit" % category)
			DirAccess.copy_absolute(PATH, PATH + "." + category)
			dimensions[category] = Vector2(app.career_visual.parts.torso.scale.x, app.career_visual.parts.shorts.scale.x)
	check(dimensions.male.x > dimensions.female.x and dimensions.male.y < dimensions.female.y, "same custom measurements produce visibly distinct modest category silhouettes")
	check(Category.competition_scope("", "sprint_100m") == "", "unselected category has no competition namespace")
	check(Category.competition_scope("female", "bad/event") == "", "invalid event identifier cannot create a namespace")
	var categorized: Dictionary = repo.load_snapshot()
	for bad: Variant in ["", "other", null, 3, false]:
		var data: Dictionary = categorized.career.duplicate(true)
		data.athlete_category = bad
		check(not Career.validate(data, true).is_empty(), "invalid category rejected: %s" % str(bad))
	# Exact v0.2 career fixture, with no category: no defaulting or write-on-load.
	var legacy_career: Dictionary = categorized.career.duplicate(true)
	legacy_career.erase("athlete_category")
	var legacy := JSON.stringify({"schema_version":2,"kind":"career","career":legacy_career,"position":[1,-2]})
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(legacy)
	file.close()
	app._menu()
	app._continue()
	check(app.current_career.athlete_category == "" and not app.current_career.to_dict().has("athlete_category"), "v2 career stays uncategorized in memory and round-trip serialization")
	check(app.current_career.competition_scope("sprint_100m").is_empty() and app.career_visual.athlete_category == "", "v2 career keeps neutral model and is excluded from future category routing")
	check(FileAccess.get_file_as_string(PATH) == legacy, "v2 Continue leaves file byte-for-byte unchanged")
	app._save_and_menu()
	var saved_legacy: Dictionary = repo.load_snapshot()
	check(saved_legacy.schema_version == 2 and not saved_legacy.career.has("athlete_category"), "v2 position save never injects a category or upgrades schema")
	var uncategorized = Career.from_dict(legacy_career)
	check(not repo.save_career(uncategorized, Vector3.ZERO, true), "new career writer refuses missing category even with replacement authorization")
	# A v3 record cannot omit the required category.
	file = FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"schema_version":3,"kind":"career","career":legacy_career,"position":[0,0]}))
	file.close()
	var invalid := FileAccess.get_file_as_string(PATH)
	app._refresh_save()
	check(app.ui.continue_button.disabled and not repo.error_message.is_empty(), "v3 missing category disables Continue with validation error")
	check(not repo.save_position(Vector3.ZERO) and FileAccess.get_file_as_string(PATH) == invalid, "invalid v3 data cannot be overwritten by track saving")
	print("CATEGORY TEST FAILURES: ", failures)
	app.queue_free()
	await process_frame
	quit(failures)
