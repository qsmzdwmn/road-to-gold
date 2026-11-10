extends SceneTree
const Main = preload("res://scenes/app/main.tscn")
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
const Career = preload("res://scripts/career/career_data.gd")
const Appearance = preload("res://scripts/data/appearance_data.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
const PATH := "user://tests/studio.json"
var failures := 0
func _initialize() -> void: _run.call_deferred()
func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ")+message)
	if not value: failures += 1
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://tests")
	DirAccess.remove_absolute(PATH)
	var app = Main.instantiate()
	root.add_child(app)
	await process_frame
	app.repository = Repository.new(PATH)
	app._new_requested()
	var ui = app.creator
	var model_id: int = ui.preview_model.get_instance_id()
	var camera: Camera3D = ui.preview_room.camera
	var camera_transform := camera.transform
	var toward_camera: Vector3 = camera.global_position-ui.preview_model.global_position
	toward_camera.y = 0
	check((-ui.preview_model.global_transform.basis.z.normalized()).dot(toward_camera.normalized())>0.85 and (ui.preview_model.parts.tail.global_position-ui.preview_model.parts.head.global_position).dot(toward_camera)<0 and app.career_visual.rotation==Vector3.ZERO, "preview front faces camera clearly without rotating camera or gameplay")
	check(ui.sections.size()==5 and ui.fields.size()==10, "five steps and all ten existing fields are retained")
	check(not app.repository.has_file() and ui.draft.athlete_category=="", "opening Studio never saves or invents a category")
	for category in range(2):
		ui.category_buttons[category].pressed.emit()
		check(ui.draft.athlete_category==["male","female"][category] and ui.category_buttons[category].button_pressed, "category card updates selection and preview "+str(category))
		ui._next()
		for index in range(3):
			ui.origin_buttons[index].button_pressed = true
			ui.origin_buttons[index].pressed.emit()
			check(ui.draft.to_dict().age==[15,17,20][index] and str([15,17,20][index]) in ui.age_caption.text, "origin card derives age %d for category %d" % [index,category])
		ui._back()
	ui._next()
	ui._next()
	check(ui.appearance_tab==0 and ui.fields.hairstyle.buttons.size()==4 and ui.fields.hair_color.buttons.size()==5 and ui.fields.skin.buttons.size()==6, "complete existing style and color catalogs become visible choices")
	for style in range(4):
		ui.fields.hairstyle.buttons[style].pressed.emit()
		check(ui.draft.athlete.appearance.hairstyle==style and ui.fields.hairstyle.buttons[style].button_pressed and ui.preview_model.parts.tail.visible==(style==3), "hairstyle tile selects model style "+str(style))
	for color in range(5):
		ui.fields.hair_color.buttons[color].pressed.emit()
		check(ui.draft.athlete.appearance.hair_color==color and ui.preview_model.hair_material.albedo_color==Color(Appearance.HAIR_COLORS[color]), "hair swatch updates material "+str(color))
	ui.select_appearance_tab(1)
	for tone in range(6):
		ui.fields.skin.buttons[tone].pressed.emit()
		check(ui.draft.athlete.appearance.skin==tone and ui.preview_model.skin_material.albedo_color==Color(Appearance.SKIN_COLORS[tone]), "skin swatch retains stable tone identifier "+str(tone))
	ui.select_appearance_tab(2)
	for key: String in ["height","weight","shoulders","legs"]:
		for bound in Appearance.LIMITS[key]:
			ui.body_editors[key].value = bound
			check(ui.fields[key].value==bound and ui.draft.athlete.appearance.get(key)==bound and ui.sliders[key].value==bound, "body, precise field, slider and draft agree at %s %s" % [key,bound])
	ui.sliders.shoulders.value = 1.0
	await process_frame
	await process_frame
	ui.sliders.shoulders.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_RIGHT
	key.physical_keycode = KEY_RIGHT
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	key = key.duplicate()
	key.pressed = false
	Input.parse_input_event(key)
	check(is_equal_approx(ui.fields.shoulders.value,1.05) and is_equal_approx(ui.draft.athlete.appearance.shoulders,1.05), "body slider supports precise keyboard increments")
	ui.body_editors.height.value = 190
	ui.body_editors.weight.value = 85
	ui.body_editors.shoulders.value = 1.1
	ui.body_editors.legs.value = 1.05
	var expected: Dictionary = ui.draft.to_dict()
	for tab in [0,1,2,0,2]:
		ui.select_appearance_tab(tab)
		check(ui.draft.to_dict()==expected and ui.preview_model.get_instance_id()==model_id, "tab switch retains complete draft and the same single model "+str(tab))
	await process_frame
	await process_frame
	ui.scroll.scroll_vertical = 10000
	await process_frame
	check(ui.heading.get_global_rect().position.y < ui.scroll.get_global_rect().position.y and ui.tab_buttons[0].get_global_rect().end.y <= ui.scroll.get_global_rect().position.y, "appearance title and tabs remain outside scrolling content")
	ui._next()
	check(ui.fields.height.is_visible_in_tree() and ui.fields.weight.is_visible_in_tree() and ui.fields.height.value==190 and ui.fields.weight.value==85, "identity exposes linked height and weight")
	ui._next()
	check(ui.step==3 and not ui.error.text.is_empty(), "identity validation still blocks blank names")
	ui.fields.first_name.text = "  Nadia  "
	ui.fields.last_name.text = "Runner"
	for index in range(ui.fields.country.item_count):
		if ui.fields.country.get_item_metadata(index)=="AZ": ui.fields.country.select(index)
	ui.fields.height.value = 195
	ui.fields.weight.value = 95
	ui._changed()
	check(ui.body_editors.height.value==195 and ui.body_editors.weight.value==95, "identity adjustments immediately update Body controls")
	await process_frame
	ui._next()
	await process_frame
	await process_frame
	check(ui.summary.profile_title.get_line_count()==1 and ui.summary.get_combined_minimum_size().y<420, "Player Card heading stays horizontal and card remains compact")
	check(ui.step==4 and ui.summary.name_label.text=="Nadia Runner" and ui.summary.country_label.text=="Azerbaijan", "Player Card shows actual trimmed identity and country")
	check(ui.summary.values.size()==10 and ui.summary.values.Age.text=="20" and ui.summary.values.Height.text=="195 cm" and ui.summary.values.Weight.text=="95 kg", "Player Card contains actual metrics and no fabricated ratings")
	check(ui.summary.values.Hairstyle.text=="Ponytail" and ui.summary.values["Hair color"].text=="Gray" and ui.summary.values.Skin.text=="Tone 6" and ui.summary.values.Shoulders.text=="1.10 ×", "Player Card mirrors every chosen appearance group")
	expected = ui.draft.to_dict()
	for i in range(4): ui._back()
	for i in range(4): ui._next()
	check(ui.draft.to_dict()==expected and ui.appearance_tab==2, "Back and Continue retain all fields and session tab")
	check(not app.repository.has_file(), "Player Card review never writes before BEGIN CAREER")
	ui._next()
	check(app.exploring and app.repository.load_snapshot().schema_version==3 and Career.from_dict(app.repository.load_snapshot().career).to_dict()==expected, "BEGIN CAREER saves existing schema and enters existing gameplay")
	app._menu()
	app._continue()
	check(app.current_career.to_dict()==expected, "Continue restores all Studio selections")
	app._menu()
	app._new_requested()
	for i in range(5): ui._next()
	var bytes := FileAccess.get_file_as_string(PATH)
	check(app.ui.confirmation.visible and Career.from_dict(app.repository.load_snapshot().career).to_dict()==expected, "replacement requires the original explicit modal")
	app.ui.confirmation.hide()
	check(FileAccess.get_file_as_string(PATH)==bytes, "replacement cancellation leaves saved bytes intact")
	for resolution: Vector2i in [Vector2i(800,600),Vector2i(1024,600),Vector2i(1280,720),Vector2i(1366,768),Vector2i(1920,1080)]:
		root.size = resolution
		ui.show()
		for stage in range(5):
			ui.step = stage
			ui._show_step()
			await process_frame
			await process_frame
			if stage==4:
				check(ui.summary.profile_title.get_line_count()==1 and ui.summary.name_label.get_global_rect().position.y<ui.summary.values.Height.get_global_rect().position.y, "Player Card title and identity lead the attributes at "+str(resolution))
			var footer: Rect2 = ui.next_button.get_global_rect()
			check(footer.end.y<=resolution.y and footer.end.x<=resolution.x and ui.preview_pane.is_visible_in_tree() and camera.transform==camera_transform, "Studio navigation and static preview fit %s step %d" % [resolution,stage])
		app.ui.confirmation.popup_centered()
		await process_frame
		var modal: Window = app.ui.confirmation
		check(modal.position.x>=0 and modal.position.y>=0 and modal.position.x+modal.size.x<=resolution.x and modal.position.y+modal.size.y<=resolution.y, "replacement modal fits "+str(resolution))
		modal.hide()
	DirAccess.remove_absolute(PATH)
	print("ATHLETE STUDIO TEST FAILURES: ",failures)
	app.queue_free()
	await process_frame
	quit(failures)
