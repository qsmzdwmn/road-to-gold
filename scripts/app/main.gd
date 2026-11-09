extends Node3D
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
const Controls = preload("res://scripts/input/placeholder_input.gd")
const Category = preload("res://scripts/data/athlete_category.gd")
const Career = preload("res://scripts/career/career_data.gd")
const CreatorScene = preload("res://scenes/ui/career_creator.tscn")
const Model = preload("res://scripts/customization/procedural_athlete.gd")
@onready var athlete = $Track/Athlete
@onready var ui = $CanvasLayer/UI
var repository = Repository.new()
var exploring := false
var current_career = null
var pending_career = null
var creator
var career_visual

func _ready() -> void:
	Controls.install_actions()
	creator = CreatorScene.instantiate()
	creator.theme = ui.theme
	$CanvasLayer.add_child(creator)
	creator.cancelled.connect(_menu)
	creator.confirmed.connect(_career_requested)
	career_visual = Model.new()
	athlete.add_child(career_visual)
	career_visual.hide()
	ui.new_requested.connect(_new_requested)
	ui.confirmation.confirmed.connect(_confirm_new)
	ui.continue_requested.connect(_continue)
	ui.save_requested.connect(_save_and_menu)
	ui.menu_requested.connect(_menu)
	ui.resume_requested.connect(_resume)
	_refresh_save()

func _refresh_save() -> void:
	var saved: Dictionary = repository.load_snapshot()
	ui.continue_button.disabled = saved.is_empty()
	if not repository.error_message.is_empty():
		ui.status.text = repository.error_message
	elif saved.is_empty():
		ui.status.text = "No saved test session."
	else:
		ui.status.text = "Saved career available." if saved.kind == "career" else "Saved test session available."

func _new_requested() -> void:
	exploring = false
	athlete.active = false
	ui.hide()
	creator.open()

func _career_requested(career) -> void:
	pending_career = career
	if repository.has_file():
		ui.confirmation.title = "Replace saved progress?"
		ui.confirmation.dialog_text = "Your existing career or test session will be replaced.\nCancel keeps your saved progress and your new draft."
		ui.confirmation.popup_centered()
	else:
		_commit_career(false)

func _confirm_new() -> void:
	if pending_career != null:
		_commit_career(true)

func _commit_career(replace_authorized: bool) -> void:
	if not repository.save_career(pending_career, Vector3.ZERO, replace_authorized):
		creator.error.text = repository.error_message
		return
	current_career = pending_career
	pending_career = null
	athlete.position = Vector3.ZERO
	creator.hide()
	_enter_track()
	ui.status.text = _save_notice()

func _continue() -> void:
	var snapshot: Dictionary = repository.load_snapshot()
	if snapshot.is_empty():
		_refresh_save()
		return
	current_career = Career.from_dict(snapshot.career) if snapshot.kind == "career" else null
	athlete.position = Vector3(snapshot.position[0], 0, snapshot.position[1])
	_enter_track()
	ui.status.text = ("Loaded saved career. Category: " + Category.label(current_career.athlete_category)) if current_career != null else "Loaded saved test position."

func _enter_track() -> void:
	exploring = true
	athlete.active = true
	creator.hide()
	ui.show()
	ui.show_track()
	career_visual.visible = current_career != null
	for child: Node in athlete.get_children():
		if child is MeshInstance3D:
			child.visible = current_career == null
	if current_career != null:
		career_visual.apply_appearance(current_career.athlete.appearance, current_career.athlete_category)

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
	return "Progress saved locally."

func _menu() -> void:
	exploring = false
	athlete.active = false
	creator.hide()
	ui.show()
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
		if creator.visible:
			creator._back()
		else:
			_menu()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if exploring:
		ui.coordinates.text = "Position  %.1f / %.1f m" % [athlete.position.x, athlete.position.z]
