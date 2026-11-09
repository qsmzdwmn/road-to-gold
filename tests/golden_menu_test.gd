extends SceneTree
const Main = preload("res://scenes/app/main.tscn")
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
const Brand = preload("res://scripts/branding/brand.gd")
const PATH := "user://tests/golden.json"
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	print(("PASS: " if value else "FAIL: ") + message)
	if not value: failures += 1

func _run() -> void:
	check(FileAccess.get_sha256("res://assets/branding/golden_path_full.png") == "2dba23bd22654e6285cf80ef31dc7dfd4094bfb9435e2121acc709981ed6e9c7", "original full logo is byte-for-byte preserved")
	check(FileAccess.get_sha256("res://assets/branding/golden_path_emblem.png") == "ba918fba2db9e0c83b1450c5e1caad57519f746b23b65e76851e9d1ed2dd3cca", "original emblem is byte-for-byte preserved")
	check(Brand.FULL.get_width() == 768 and Brand.EMBLEM.get_width() == 256, "appropriately sized approved derivatives load")
	check(Brand.FULL.get_image().detect_alpha() != Image.ALPHA_NONE and Brand.EMBLEM.get_image().detect_alpha() != Image.ALPHA_NONE, "derivatives retain transparency")
	DirAccess.make_dir_recursive_absolute("user://tests")
	DirAccess.remove_absolute(PATH)
	var app = Main.instantiate()
	root.add_child(app)
	await process_frame
	app.repository = Repository.new(PATH)
	app._refresh_save()
	var ui = app.ui
	var menu = ui.golden_menu
	var camera: Camera3D = app.get_node("GoldenRoad").camera
	var fixed := camera.transform
	check(menu.logo.texture == Brand.FULL and menu.logo.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "menu uses official full logo without distortion")
	check(menu.version.text == "VERSION 0.2.3" and menu.version.text == Brand.version_label(), "version display derives from project metadata")
	check(ui.status.text == "Your journey begins here.", "fresh menu displays approved journey message")
	check(menu.tagline.text.replace("\n", " ") == "Your Story. Your Sacrifice. Your Legacy.", "approved tagline is exact")
	check(ui.continue_button.disabled and ui.continue_button.focus_mode == Control.FOCUS_NONE and not app.repository.has_file(), "fresh menu disables Continue without writing a save")
	check(not app.get_node("Track").visible and app.get_node("GoldenRoad").visible and camera.current, "menu replaces isolated track presentation with Golden Road")
	check(app.get_node("GoldenRoad").get_child_count() <= 16, "symbolic road is bounded static geometry")
	for resolution: Vector2i in [Vector2i(800,600),Vector2i(1024,600),Vector2i(1280,720),Vector2i(1366,768),Vector2i(1920,1080)]:
		root.size = resolution
		await process_frame
		await process_frame
		for control: Control in [menu.logo, menu.tagline, menu.menu.get_child(0), menu.continue_button, menu.menu.get_child(2), menu.version, menu.status]:
			var rect := control.get_global_rect()
			check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= resolution.x and rect.end.y <= resolution.y, "menu control fits %s: %s" % [resolution, control.get_class()])
		check(camera.transform == fixed, "menu camera stays fixed at " + str(resolution))
	(ui.menu.get_child(2) as Button).pressed.emit()
	check(ui.settings.visible and not menu.visible, "Settings action retains existing settings screen")
	(ui.settings.get_child(ui.settings.get_child_count()-1) as Button).pressed.emit()
	check(menu.visible and ui.menu.visible, "Settings Back restores branded menu")
	(ui.menu.get_child(0) as Button).pressed.emit()
	check(app.creator.visible and app.creator.step == 0 and not app.exploring, "New Career enters existing first category step")
	check(not app.get_node("GoldenRoad").visible and not app.get_node("Track").visible, "menu and gameplay sets are hidden during creation")
	for category: String in ["male", "female"]:
		app.creator.select_category(category)
		var preview = app.creator.preview_model
		var to_camera: Vector3 = app.creator.preview_room.camera.global_position - preview.global_position
		to_camera.y = 0
		to_camera = to_camera.normalized()
		var forward: Vector3 = -preview.global_transform.basis.z.normalized()
		var rear: Vector3 = preview.parts.tail.global_position - preview.parts.head.global_position
		check(forward.dot(to_camera) > 0.85 and rear.dot(to_camera) < 0, category + " preview faces the static camera with ponytail behind the head")
	check(app.career_visual.rotation == Vector3.ZERO, "preview orientation never rotates the gameplay athlete")
	check(app.creator.preview_room.camera != camera, "locker room keeps its independent camera")
	app.creator._back()
	check(menu.is_visible_in_tree() and not app.creator.visible, "creator cancellation returns to Golden Road")
	app.repository.save_position(Vector3(1.25,0,-4.5))
	app._refresh_save()
	ui.continue_button.pressed.emit()
	check(ui.continue_button.focus_mode == Control.FOCUS_ALL and app.exploring and app.get_node("Track").visible and not app.get_node("GoldenRoad").visible and app.get_node("Track/Camera").current, "Continue restores original playable track and camera")
	check(app.athlete.position == Vector3(1.25,0,-4.5) and app.repository.load_snapshot().schema_version == 1, "Continue retains legacy position and schema")
	app._menu()
	check(camera.current and app.get_node("GoldenRoad").visible, "returning to menu restores static road camera")
	var shell := FileAccess.get_file_as_string("res://web/loading.html")
	check('alt="ROAD TO GOLD emblem"' in shell and 'data:image/png;base64,' in shell, "loader embeds lightweight approved emblem")
	check('onProgress(current, total)' in shell and 'current / total' in shell and 'overlay.remove()' in shell and not 'setTimeout' in shell, "loader retains engine progress and immediate completion with no artificial delay")
	check(not app.repository.load_snapshot().has("career"), "menu testing never invents legacy career data")
	var career = preload("res://scripts/career/career_data.gd").new()
	career.athlete_category = "female"
	career.athlete.first_name = "Jordan"
	career.athlete.last_name = "Gold"
	app.repository.save_career(career, Vector3.ZERO, true)
	app._menu()
	check(ui.status.text == "Career: Jordan Gold", "existing career menu shows saved athlete name")
	app._continue()
	app._save_and_menu()
	check(ui.status.text == "Career: Jordan Gold" and "saved" in ui.status.tooltip_text.to_lower(), "successful Save and Menu retains athlete caption and save feedback")
	career.athlete.first_name = "W".repeat(32)
	career.athlete.last_name = "W".repeat(32)
	app.repository.save_career(career, Vector3.ZERO, true)
	app._menu()
	for resolution: Vector2i in [Vector2i(800,600), Vector2i(1280,720), Vector2i(1920,1080)]:
		root.size = resolution
		await process_frame
		await process_frame
		check(ui.status.get_global_rect().end.x <= resolution.x and menu.version.get_global_rect().end.y <= resolution.y and career.athlete.last_name in ui.status.tooltip_text, "long saved athlete name fits and remains available in tooltip at " + str(resolution))
	app.repository = Repository.new("user://tests/nonexistent-dir/golden.json")
	app._save_and_menu()
	check("failed" in ui.status.text.to_lower() and ui.status.text in ui.status.tooltip_text, "failed saving keeps its warning visible instead of showing a career caption")
	DirAccess.remove_absolute(PATH)
	print("GOLDEN MENU TEST FAILURES: ", failures)
	app.queue_free()
	await process_frame
	quit(failures)
