extends Node3D
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
const Controls = preload("res://scripts/input/placeholder_input.gd")
const Category = preload("res://scripts/data/athlete_category.gd")
const Career = preload("res://scripts/career/career_data.gd")
const CreatorScene = preload("res://scenes/ui/career_creator.tscn")
const HubScene = preload("res://scenes/ui/career_hub.tscn")
const RaceScene=preload("res://scenes/race/race_screen.tscn")
var race_view
const Model = preload("res://scripts/customization/procedural_athlete.gd")
@onready var athlete = $Track/Athlete
@onready var ui = $CanvasLayer/UI
var repository = Repository.new()
var exploring := false
var current_career = null
var career_token := ""
var training_snapshot: Dictionary = {}
var training_busy := false
var pending_career = null
var creator
var career_visual
var hub
var settings_from_hub := false

func _ready() -> void:
	Controls.install_actions()
	creator = CreatorScene.instantiate()
	creator.theme = ui.theme
	$CanvasLayer.add_child(creator)
	creator.cancelled.connect(_menu)
	creator.confirmed.connect(_career_requested)
	hub = HubScene.instantiate()
	hub.theme = ui.theme
	$CanvasLayer.add_child(hub)
	hub.menu_requested.connect(_menu)
	hub.save_requested.connect(_save_hub_and_menu)
	hub.track_requested.connect(_enter_track)
	hub.settings_requested.connect(_hub_settings)
	hub.training_requested.connect(_training_requested)
	hub.race_requested.connect(_enter_race)
	race_view=RaceScene.instantiate();race_view.theme=ui.theme;$CanvasLayer.add_child(race_view)
	race_view.hub_requested.connect(_return_from_race)
	race_view.category_requested.connect(_race_category)
	race_view.result_ready.connect(_race_finished)
	ui.settings_closed.connect(_settings_closed)
	ui.hub_requested.connect(func(): _enter_hub("Back at Athlete HQ. Save & Menu keeps your track position.",false))
	career_visual = Model.new()
	athlete.add_child(career_visual)
	career_visual.hide()
	ui.new_requested.connect(_new_requested)
	ui.confirmation.confirmed.connect(_confirm_new)
	ui.continue_requested.connect(_continue)
	ui.save_requested.connect(_save_and_menu)
	ui.menu_requested.connect(_menu)
	ui.resume_requested.connect(_resume)
	_set_track_visible(false)
	_refresh_save()

func _set_track_visible(active_track: bool) -> void:
	$Track.visible = active_track
	$GoldenRoad.visible = not active_track
	if active_track:
		$Track/Camera.make_current()
	else:
		$GoldenRoad.camera.make_current()

func _refresh_save() -> void:
	var saved: Dictionary = repository.load_snapshot()
	ui.set_continue_available(not saved.is_empty())
	if not repository.error_message.is_empty():
		ui.status.text = repository.error_message
	elif saved.is_empty():
		ui.status.text = "Your journey begins here."
	else:
		if saved.kind == "career":
			var athlete_data: Dictionary = saved.career.athlete
			ui.status.text = "Career: %s %s" % [athlete_data.first_name, athlete_data.last_name]
		else:
			ui.status.text = "Saved progress available."
	ui.status.tooltip_text = ui.status.text

func _new_requested() -> void:
	race_view.close()
	hub.hide()
	settings_from_hub = false
	exploring = false
	athlete.active = false
	$Track.hide()
	$GoldenRoad.hide()
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
	training_snapshot=repository.load_snapshot()
	career_token=repository.snapshot_token()
	current_career = pending_career
	pending_career = null
	athlete.position = Vector3.ZERO
	creator.hide()
	_enter_hub(_save_notice())

func _continue() -> void:
	var snapshot: Dictionary = repository.load_snapshot()
	if snapshot.is_empty():
		_refresh_save()
		return
	training_snapshot=snapshot
	career_token=repository.snapshot_token()
	current_career = Career.from_dict(snapshot.career) if snapshot.kind == "career" else null
	athlete.position = Vector3(snapshot.position[0], 0, snapshot.position[1])
	if current_career != null:
		_enter_hub("Loaded saved career.")
	else:
		_enter_track()
		ui.status.text = "Loaded saved test position."

func _enter_hub(message := "Loaded saved career.", reset_page := true) -> void:
	race_view.close()
	if current_career == null:
		_menu()
		return
	exploring = false
	athlete.active = false
	settings_from_hub = false
	$Track.hide()
	$GoldenRoad.hide()
	creator.hide()
	ui.hide()
	career_visual.apply_appearance(current_career.athlete.appearance,current_career.athlete_category)
	career_visual.show()
	hub.open(current_career,message,reset_page)
	hub.training_panel.present(repository.training_for(training_snapshot),career_token,training_snapshot.get("schema_version")!=4)
	hub.present_competition(training_snapshot.get("competition",{}))

func _save_hub_and_menu() -> void:
	# Never downgrade a missing/replaced career slot to an unrelated position probe.
	var snapshot: Dictionary = repository.load_snapshot()
	if snapshot.is_empty() or snapshot.kind!="career":
		hub.status.text="Save failed: the saved career could not be verified. Your session is still open; no replacement was written."
		hub.status.tooltip_text=hub.status.text+" " + repository.error_message
		return
	if Career.from_dict(snapshot.career).to_dict()!=current_career.to_dict():
		hub.status.text="Save failed: the saved career changed. Return to the menu and Continue to reopen it."
		hub.status.tooltip_text=hub.status.text
		return
	_save_and_menu()

func _hub_settings() -> void:
	settings_from_hub = true
	hub.hide()
	ui.show()
	ui.show_settings()

func _settings_closed() -> void:
	if settings_from_hub:
		_enter_hub("Loaded saved career.",false)

func _enter_track() -> void:
	race_view.close()
	hub.hide()
	settings_from_hub = false
	_set_track_visible(true)
	exploring = true
	athlete.active = true
	creator.hide()
	ui.show()
	ui.show_track()
	ui.hub_button.visible = current_career != null
	career_visual.visible = current_career != null
	for child: Node in athlete.get_children():
		if child is MeshInstance3D:
			child.visible = current_career == null
	if current_career != null:
		career_visual.apply_appearance(current_career.athlete.appearance, current_career.athlete_category)

func _save_and_menu() -> void:
	var succeeded: bool = repository.save_position(athlete.position,career_token)
	var message: String = _save_notice() if succeeded else repository.error_message
	_menu()
	if not succeeded or (OS.has_feature("web") and not OS.is_userfs_persistent()):
		ui.status.text = message
	ui.status.tooltip_text = ui.status.text + "\n" + message

func _save_notice() -> String:
	if OS.has_feature("web"):
		if not OS.is_userfs_persistent():
			return "Browser storage is not persistent. This session may be lost when you close the tab."
		return "Save written. Browser storage may be temporary; keep this tab open briefly."
	return "Progress saved locally."

func _menu() -> void:
	race_view.close()
	hub.hide()
	settings_from_hub = false
	_set_track_visible(false)
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
		if settings_from_hub and ui.settings.visible:
			_enter_hub("Loaded saved career.",false)
		elif creator.visible:
			creator._back()
		elif hub.visible and hub.active_section!="overview":
			hub.select_section("overview")
		else:
			_menu()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if exploring:
		ui.coordinates.text = "Position  %.1f / %.1f m" % [athlete.position.x, athlete.position.z]

func _training_requested(id: String, expected_token: String) -> void:
	if training_busy:return
	training_busy=true
	if not hub.visible or hub.active_section!="training" or expected_token!=career_token:
		hub.training_panel.failed("Training preview is no longer current.")
		training_busy=false
		return
	var result: Dictionary=repository.commit_training(id,expected_token,athlete.position)
	if result.ok:
		career_token=result.token
		training_snapshot=repository.load_snapshot()
		hub.training_panel.present(result.after,career_token,false,"Saved · "+("End Training Day" if id=="end_day" else preload("res://scripts/training/training_service.gd").ACTIVITIES[id].title)+"\n"+result.summary+"\n"+_save_notice())
	else:hub.training_panel.failed(result.error)
	training_busy=false

func _enter_race() -> void:
	var snapshot:=repository.load_snapshot()
	if snapshot.is_empty() or snapshot.get("kind")!="career" or repository.snapshot_token()!=career_token:
		hub.status.text="Saved progress changed or is unavailable. Return to the menu and Continue before racing."
		return
	exploring=false;athlete.active=false;hub.hide();ui.hide();creator.hide();$Track.hide();$GoldenRoad.hide()
	race_view.open(snapshot,current_career,career_token,repository.career_fingerprint(snapshot))

func _return_from_race() -> void:
	_enter_hub("Returned from Development Meet. Training and sandbox progress preserved.")

func _race_category(category:String) -> void:
	var result:Dictionary=repository.choose_race_category(category,career_token,athlete.position)
	if not result.ok:
		race_view.readiness_status.text=result.error
		return
	career_token=result.token;training_snapshot=repository.load_snapshot();current_career=Career.from_dict(training_snapshot.career)
	race_view.open(training_snapshot,current_career,career_token,repository.career_fingerprint(training_snapshot))

func _race_finished(result:Dictionary) -> void:
	var outcome:Dictionary=repository.commit_race(result,race_view.source_token,athlete.position)
	if outcome.ok:
		career_token=outcome.token;training_snapshot=repository.load_snapshot()
		# Race Again gets a fresh entry snapshot; pending result keeps its original identity.
		race_view.snapshot=training_snapshot.duplicate(true)
		race_view.source_token=career_token
	race_view.save_outcome(outcome)
