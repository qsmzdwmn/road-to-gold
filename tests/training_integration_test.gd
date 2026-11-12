extends SceneTree
const Main=preload("res://scenes/app/main.tscn")
const Repo=preload("res://scripts/persistence/prototype_save_repository.gd")
const Career=preload("res://scripts/career/career_data.gd")
const Catalog=preload("res://scripts/data/career_catalog.gd")
const PATH="user://tests/training-integration.json"
var failures:=0
class FailedWriter extends "res://scripts/persistence/prototype_save_repository.gd":
	func _write(_snapshot:Dictionary,_position:Vector3)->bool:
		error_message="Injected full disk/write failure."
		return false
func check(ok:bool,message:String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func _initialize():run.call_deferred()
func submit(panel,id:String):
	panel.preview(id);panel.confirmation.hide();panel.confirmation.confirmed.emit()
func run():
	DirAccess.make_dir_recursive_absolute("user://tests");root.size=Vector2i(1280,720)
	var repo=Repo.new(PATH)
	var app=Main.instantiate();root.add_child(app);await process_frame;app.repository=repo
	if "--reload-training" in OS.get_cmdline_user_args():
		app._continue();app.hub.select_section("training")
		check(app.hub.training_panel.state==repo.load_snapshot().training and repo.load_snapshot().schema_version==4,"separate-process Continue loads exact trained schema 4 state")
		check(not app.current_career.to_dict().has("training") and app.current_career.to_dict().age==20,"training day never mutates athlete age/identity")
		app.queue_free();await process_frame;quit(failures);return
	DirAccess.remove_absolute(PATH)
	var parity:Dictionary={}
	for category:String in ["male","female"]:
		for origin:Dictionary in Catalog.origins():
			var career=Career.new();career.athlete.first_name="Alex";career.athlete.last_name="Gold";career.athlete_category=category;career.origin_id=origin.id
			check(repo.save_career(career,Vector3.ZERO,true),"create test career "+category+"/"+origin.id)
			app._continue();app.hub.select_section("training");await process_frame
			var panel=app.hub.training_panel
			var before=FileAccess.get_file_as_string(PATH)
			panel.preview("sprint_drills")
			check(panel.confirmation.visible and "50.00 -> 50.60" in panel.confirmation.dialog_text and "backup" in panel.confirmation.dialog_text,"preview exact effects and migration notice before first write")
			panel.confirmation.hide()
			check(FileAccess.get_file_as_string(PATH)==before and panel.state.attributes.speed==5000,"cancel preview never writes or applies gains")
			submit(panel,"sprint_drills")
			check(panel.state.attributes.speed==5060 and panel.state.actions_used==1 and repo.load_snapshot().training==panel.state,"confirmed action autosaves before publishing authoritative state")
			check("50.00 -> 50.60" in panel.result_label.text and "Saved" in panel.result_label.text,"result reports explicit before/after and saved outcome")
			var once=FileAccess.get_file_as_string(PATH);panel._confirm();check(FileAccess.get_file_as_string(PATH)==once and panel.state.actions_used==1,"duplicate confirmation cannot execute again")
			submit(panel,"start_practice")
			check(panel.state.actions_used==2 and panel.buttons.sprint_drills.disabled,"all activity buttons enforce exhausted actions")
			submit(panel,"end_day");check(panel.state.day==2 and panel.state.fatigue==27 and panel.state.actions_used==0,"End Training Day autosaves and restores daily allowance")
			submit(panel,"recovery_session");check(panel.state.fatigue==0 and panel.state.recovery_used and panel.state.attributes.recovery==5020,"recovery updates fatigue/rating and daily flag")
			if parity.is_empty():parity=panel.state.duplicate(true)
			check(panel.state==parity and app.current_career.to_dict()==career.to_dict(),"identical outcomes across categories/origins without changing career age/appearance")
			var trained=panel.state.duplicate(true);app._enter_track();app.athlete.position=Vector3(1,0,-2);app._save_and_menu();app._continue()
			check(repo.load_snapshot().training==trained and app.athlete.position==Vector3(1,0,-2),"sandbox and Save & Menu preserve training and position")
			app.hub.select_section("training");app.repository=FailedWriter.new(PATH)
			var bytes=FileAccess.get_file_as_string(PATH);submit(panel,"sprint_drills")
			check(panel.state==trained and FileAccess.get_file_as_string(PATH)==bytes and "No training applied" in panel.result_label.text,"failed write preserves visible authoritative state and saved bytes")
			app.repository=repo
			# Stale save revision must also block both training and regular Hub saving.
			var stale=app.career_token;repo.save_position(Vector3.ZERO);submit(panel,"sprint_drills")
			check(panel.state==trained and app.career_token==stale and "changed" in panel.result_label.text,"external slot change rejects stale training preview")
			var external=FileAccess.get_file_as_string(PATH);app._save_hub_and_menu();check(FileAccess.get_file_as_string(PATH)==external,"stale Hub Save & Menu cannot overwrite newer training/position")
	# Preserve a schema 4 fixture with the last category/origin for process reload.
	app._continue();app.hub.select_section("training")
	for resolution:Vector2i in [Vector2i(1280,720),Vector2i(800,600)]:
		root.size=resolution;await process_frame;await process_frame
		check(app.hub.save_button.get_global_rect().end.x<=resolution.x and app.hub.scroll.get_global_rect().end.y<=app.hub.status.get_global_rect().position.y,"training scroll keeps header/navigation/footer reachable at %s" % resolution)
	print("TRAINING INTEGRATION FAILURES: ",failures)
	app.queue_free();await process_frame;quit(failures)
