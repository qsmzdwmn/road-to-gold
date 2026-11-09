extends SceneTree
## Run with --headless --path . --script tests/prototype_test.gd
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
const MainScene = preload("res://scenes/app/main.tscn")
const TEST_PATH := "user://tests/prototype.json"
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		failures += 1
		push_error("FAIL: " + message)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://tests")
	var repository = Repository.new(TEST_PATH)
	if "--reload-check" in OS.get_cmdline_user_args():
		check(repository.load_position() == Vector3(1.25, 0, -4.5), "save persists across separate Godot processes")
		quit(failures)
		return
	DirAccess.remove_absolute(TEST_PATH)
	check(repository.load_position() == null, "missing save returns no position")
	var app = MainScene.instantiate()
	root.add_child(app)
	await process_frame
	app.repository = repository
	app._refresh_save()
	check(app.ui.continue_button.disabled, "Continue disabled with no save")
	app.ui.show_settings()
	check(app.ui.settings.visible and not app.ui.menu.visible, "Settings opens")
	(app.ui.settings.get_child(app.ui.settings.get_child_count() - 1) as Button).pressed.emit()
	check(app.ui.menu.visible and not app.ui.settings.visible, "Back returns to menu")
	app.ui.new_requested.emit()
	check(app.creator.visible and not app.exploring, "New Career opens draft instead of starting track")
	check(not repository.has_file(), "opening creation does not write a save")
	app.creator.select_category("male")
	app.creator.fields.first_name.text = "Test"
	app.creator.fields.last_name.text = "Runner"
	for i in range(5):
		app.creator._next()
	check(repository.load_position() == Vector3.ZERO, "confirmed career saves initial position")
	var before: Vector3 = app.athlete.position
	key(KEY_W, true)
	for i in range(15):
		await physics_frame
	key(KEY_W, false)
	check(app.athlete.position.z < before.z, "physical W key input moves athlete forward")
	before = app.athlete.position
	key(KEY_RIGHT, true)
	for i in range(15):
		await physics_frame
	key(KEY_RIGHT, false)
	check(app.athlete.position.x > before.x, "physical Right arrow moves athlete sideways")
	app.athlete.position = Vector3(3.3, 0, 12)
	key(KEY_D, true)
	for i in range(3):
		await physics_frame
	key(KEY_D, false)
	check(is_equal_approx(app.athlete.position.x, 3.3), "movement stays within track bounds")
	app._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not app.athlete.active and app.ui.resume.visible, "focus loss pauses and offers Resume")
	app.ui.resume_requested.emit()
	check(app.athlete.active and not app.ui.resume.visible, "explicit Resume restores movement")
	app.athlete.position = Vector3(1.25, 0, -4.5)
	app.ui.save_requested.emit()
	check(not app.exploring and not app.ui.continue_button.disabled, "Save & Menu enables Continue")
	check(repository.load_position() == Vector3(1.25, 0, -4.5), "saved coordinates round-trip")
	app.athlete.position = Vector3.ZERO
	app.ui.continue_requested.emit()
	check(app.athlete.position == Vector3(1.25, 0, -4.5), "Continue restores saved position")
	app._menu()
	app.ui.new_requested.emit()
	check(not app.ui.confirmation.visible, "opening a draft leaves existing save untouched")
	for i in range(5):
		app.creator._next()
	check(app.ui.confirmation.visible and not app.exploring, "final Create Career requests replacement confirmation")
	app.ui.confirmation.hide()
	check(repository.load_position() == Vector3(1.25, 0, -4.5), "cancel leaves save unchanged")
	app._confirm_new()
	check(repository.load_position() == Vector3.ZERO, "confirmed New Career resets prototype save")
	app._menu()
	for resolution: Vector2i in [Vector2i(1024, 600), Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080)]:
		root.size = resolution
		for screen: Callable in [app.ui.show_menu, app.ui.show_settings, app.ui.show_track]:
			screen.call()
			await process_frame
			await process_frame
			var panel: Control = app.ui.get_child(0).get_child(0).get_child(0)
			var rect := panel.get_global_rect()
			check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= resolution.x and rect.end.y <= resolution.y, "UI fits %s (%s)" % [resolution, "menu" if app.ui.menu.visible else ("settings" if app.ui.settings.visible else "track")])
	var corrupt := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	corrupt.store_string('{"schema_version":99}')
	corrupt.close()
	app._refresh_save()
	check(app.ui.continue_button.disabled and not repository.error_message.is_empty(), "unsupported save disables Continue with visible error")
	check(FileAccess.get_file_as_string(TEST_PATH) == '{"schema_version":99}', "invalid save is not silently overwritten")
	check(not repository.save_position(Vector3(INF, 0, 0)), "nonfinite position rejected")
	var denied = Repository.new("user://missing-directory/save.json")
	check(not denied.save_position(Vector3.ZERO) and not denied.error_message.is_empty(), "write failure returns actionable unsaved error")
	DirAccess.remove_absolute(TEST_PATH)
	repository.save_position(Vector3(1.25, 0, -4.5))
	print("TEST FAILURES: ", failures)
	app.queue_free()
	await process_frame
	quit(failures)
