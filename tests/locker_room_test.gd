extends SceneTree
const Main = preload("res://scenes/app/main.tscn")
const Appearance = preload("res://scripts/data/appearance_data.gd")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failures += 1

func _run() -> void:
	var app = Main.instantiate()
	root.add_child(app)
	await process_frame
	var creator = app.creator
	app._new_requested()
	var camera: Camera3D = creator.preview_room.camera
	var transform := camera.transform
	var framing := camera.size
	creator.select_category("female")
	creator._next()
	check(creator.step == 1 and creator.origin_buttons[0].is_visible_in_tree(), "story immediately follows athlete selection")
	creator.origin_buttons[1].pressed.emit()
	creator._next()
	check(creator.step == 2 and creator.fields.skin.is_visible_in_tree() and not creator.fields.first_name.is_visible_in_tree(), "appearance precedes identity")
	creator._next()
	check(creator.step == 3 and creator.fields.first_name.is_visible_in_tree() and "17" in creator.age_caption.text, "identity displays origin-derived age")
	creator.fields.first_name.text = "\t"
	creator.fields.last_name.text = "Runner"
	creator._next()
	check(creator.step == 3 and not creator.error.text.is_empty(), "identity still rejects control-only names")
	creator.fields.first_name.text = "Alex"
	creator._next()
	check(creator.step == 4 and creator.next_button.text == "BEGIN CAREER", "final summary uses BEGIN CAREER action")
	for category: String in ["male", "female"]:
		creator.select_category(category)
		for key: String in ["height", "weight", "shoulders", "legs"]:
			var appearance = Appearance.new()
			appearance.set(key, Appearance.LIMITS[key][0])
			creator.preview_model.apply_appearance(appearance, category)
			var before: Vector3 = creator.preview_model.scale if key == "height" else creator.preview_model.parts["left_leg" if key == "legs" else "torso"].scale
			appearance.set(key, Appearance.LIMITS[key][1])
			creator.preview_model.apply_appearance(appearance, category)
			var after: Vector3 = creator.preview_model.scale if key == "height" else creator.preview_model.parts["left_leg" if key == "legs" else "torso"].scale
			check(before != after, category + " visibly responds to " + key)
		for style in range(4):
			var appearance = Appearance.new()
			appearance.hairstyle = style
			creator.preview_model.apply_appearance(appearance, category)
			check(creator.preview_model.parts.hair.visible == (style != 0) and creator.preview_model.parts.tail.visible == (style == 3) and creator.preview_model.parts.curl_left.visible == (style == 2), category + " hairstyle visibility " + str(style))
		for key: String in creator.preview_model.DETAILS:
			check(creator.preview_model.parts[key].visible, category + " refined body detail " + key)
	# Full body at the tallest/widest allowed settings remains inside the fixed camera.
	var largest = Appearance.new()
	largest.height = 220
	largest.weight = 150
	largest.shoulders = 1.3
	largest.legs = 1.15
	creator.preview_model.apply_appearance(largest, "male")
	for resolution: Vector2i in [Vector2i(640, 640), Vector2i(800, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = resolution
		for index in range(5):
			creator.step = index
			creator._show_step()
			await process_frame
			await process_frame
			check(creator.preview_pane.is_visible_in_tree() and camera.transform == transform and camera.size == framing, "fixed visible camera at %s step %d" % [resolution, index])
		var visible_body := true
		var viewport_size := camera.get_viewport().get_visible_rect().size
		for part: MeshInstance3D in creator.preview_model.parts.values():
			if not part.visible: continue
			var bounds := part.get_aabb()
			for endpoint in range(8):
				var point := part.global_transform * bounds.get_endpoint(endpoint)
				var projected := camera.unproject_position(point)
				visible_body = visible_body and Rect2(Vector2.ZERO, viewport_size).has_point(projected)
		check(visible_body, "largest full body fits camera at " + str(resolution))
	root.size = Vector2i(1280, 720)
	creator.step = 2
	creator._show_step()
	await process_frame
	await process_frame
	creator.fields.legs.get_line_edit().grab_focus()
	await process_frame
	await process_frame
	check(creator.scroll.scroll_vertical > 0 and creator.fields.legs.get_line_edit().has_focus(), "keyboard focus reveals offscreen appearance controls")
	check(creator.preview_room.get_child_count() < 50, "locker room remains a bounded static geometric set")
	creator.preview_model.apply_appearance(Appearance.new(), "")
	check(not creator.preview_model.parts.neck.visible and not creator.preview_model.parts.left_foot.visible, "legacy neutral appearance keeps original geometry")
	print("LOCKER ROOM TEST FAILURES: ", failures)
	app.queue_free()
	await process_frame
	quit(failures)
