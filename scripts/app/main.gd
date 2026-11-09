extends Node3D
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
const Controls = preload("res://scripts/input/placeholder_input.gd")
@onready var athlete = $Track/Athlete
@onready var ui = $CanvasLayer/UI
var repository = Repository.new()
var exploring := false
var replacement_confirmed := false

func _ready() -> void:
	Controls.install_actions()
	ui.new_requested.connect(_new_requested)
	ui.confirmation.confirmed.connect(_confirm_new)
	ui.continue_requested.connect(_continue)
	ui.save_requested.connect(_save_and_menu)
	ui.menu_requested.connect(_menu)
	ui.resume_requested.connect(_resume)
	_refresh_save()

func _refresh_save() -> void:
	var saved: Variant = repository.load_position()
	ui.continue_button.disabled = saved == null
	if not repository.error_message.is_empty():
		ui.status.text = repository.error_message
	elif saved == null:
		ui.status.text = "No saved test session."
	else:
		ui.status.text = "Saved test session available."

func _new_requested() -> void:
	if repository.has_file() and not replacement_confirmed:
		ui.confirmation.popup_centered()
		return
	replacement_confirmed = false
	athlete.position = Vector3.ZERO
	if repository.save_position(athlete.position):
		_enter_track()
		ui.status.text = _save_notice()
	else:
		_enter_track()
		ui.status.text = repository.error_message

func _confirm_new() -> void:
	replacement_confirmed = true
	_new_requested()

func _continue() -> void:
	var saved: Variant = repository.load_position()
	if saved == null:
		_refresh_save()
		return
	athlete.position = saved
	_enter_track()
	ui.status.text = "Loaded saved test position."

func _enter_track() -> void:
	exploring = true
	athlete.active = true
	ui.show_track()

func _save_and_menu() -> void:
	var succeeded: bool = repository.save_position(athlete.position)
	var message: String = _save_notice() if succeeded else repository.error_message
	_menu()
	ui.status.text = message

func _save_notice() -> String:
	if OS.has_feature("web"):
		if not OS.is_userfs_persistent():
			return "Browser storage is not persistent. This session may be lost when you close the tab."
		return "Save written. Browser storage may be temporary; keep this tab open briefly."
	return "Test position saved locally."

func _menu() -> void:
	exploring = false
	athlete.active = false
	ui.show_menu()
	_refresh_save()

func _resume() -> void:
	athlete.active = true
	ui.resume.hide()
	ui.status.text = ""
	get_viewport().gui_release_focus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready() and exploring:
		athlete.active = false
		ui.resume.show()
		ui.resume.grab_focus()
		ui.status.text = "Paused after focus loss. Choose Resume."

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_menu()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if exploring:
		ui.coordinates.text = "Position  %.1f / %.1f m" % [athlete.position.x, athlete.position.z]
