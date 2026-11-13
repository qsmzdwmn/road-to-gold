extends SceneTree
const Main=preload("res://scenes/app/main.tscn")
const Repo=preload("res://scripts/persistence/prototype_save_repository.gd")
const Career=preload("res://scripts/career/career_data.gd")
const Data=preload("res://scripts/race/competition_data.gd")
const PATH="user://tests/race-integration.json"
class FailedWriter extends "res://scripts/persistence/prototype_save_repository.gd":
	func _write(_data:Dictionary,_position:Vector3)->bool:
		error_message="Injected result-save failure."
		return false
var failures:=0
func check(ok:bool,message:String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func _initialize():run.call_deferred()
func run():
	DirAccess.make_dir_recursive_absolute("user://tests");root.size=Vector2i(1280,720)
	var initial_budget=Engine.max_physics_steps_per_frame
	var app=Main.instantiate();root.add_child(app);await process_frame
	app.repository=Repo.new(PATH);DirAccess.remove_absolute(PATH)
	var c=Career.new();c.athlete.first_name="Alex";c.athlete.last_name="Gold";c.athlete_category="male"
	app.repository.save_career(c,Vector3(1,0,-2));app._continue();app.hub.race_requested.emit();await process_frame;await process_frame
	var screen=app.race_view
	check(Engine.max_physics_steps_per_frame>=128,"race catch-up budget covers valid sub-two-second frames without changing fixed tick rate")
	check(screen.visible and not app.hub.visible and not app.exploring and not app.athlete.active,"Hub Enter 100m opens separate readiness and disables sandbox movement")
	check(screen.world.models.size()==8 and screen.snapshot.schema_version==3 and not screen.ready_button.disabled,"eight visible entrants without writing/migrating on readiness")
	check(screen.world_viewport.own_world_3d and screen.world_container.stretch_shrink==2,"race-only reduced-resolution 3D viewport leaves HUD full resolution")
	var original=FileAccess.get_file_as_string(PATH);screen.mode_select.select(1);screen.start()
	screen.session.key(KEY_SPACE,true);screen._refresh_phase()
	check(screen.session.phase=="invalid" and FileAccess.get_file_as_string(PATH)==original and screen.pending_result.is_empty(),"false start recalls attempt without saving fake results")
	screen.retry();screen.mode_select.select(1);screen.start()
	check(screen.session.phase=="marks","retry returns to explicit Ready, then new starter sequence")
	var working_repository=app.repository;app.repository=FailedWriter.new(PATH)
	var frames:=0
	var checked_midpoint:=false
	var start_positions=screen.world.models.map(func(model):return model.position.z)
	while screen.session.phase!="results" and frames<2800:
		if screen.session.phase=="running" and screen.session.ticks==12:screen.session.key(KEY_SPACE,true)
		screen._physics_process(1.0/60.0);frames+=1
		if not checked_midpoint and screen.session.runners[0].distance>=50.0:
			checked_midpoint=true;screen.world._process(1.0/60.0)
			var match_all:=true
			for i in range(8):
				var model=screen.world.models[i];var runner=screen.session.runners[i]
				match_all=match_all and is_equal_approx(model.position.z,-runner.distance) and model.position.z<start_positions[i]
			check(match_all,"all eight actual scene instances move forward to their individual simulated halfway distances")
			var distance:float=screen.session.runners[0].distance
			check(is_equal_approx(screen.world.camera.position.z,11.0-distance) and is_equal_approx(screen.world.camera.position.y,6.6),"stadium camera follows player distance at halfway with fixed height and offset")
			screen._process(0.0)
			check(screen.player_marker.visible and screen.player_marker.text=="YOU · L4" and Rect2(Vector2.ZERO,screen.size).has_point(screen.player_marker.position),"projected player identity remains visible at halfway")
			screen._refresh_hud()
			check(screen.hud.text.contains("%.1f / 100 m" % distance) and screen.hud.text.contains(Data.time_text(roundi(float(screen.session.ticks)/60.0*1000000.0))),"live HUD distance and timer reflect authoritative race state")
	check(not screen.saved and screen.retry_save.visible and screen.pending_result.rows.size()==8 and FileAccess.get_file_as_string(PATH)==original,"failed result write leaves data intact and offers explicit Retry Save")
	app.repository=working_repository;screen._save_result()
	check(screen.saved and screen.pending_result.rows.size()==8 and screen.result_status.text.contains("Saved"),"completed field presents eight real results and autosaves")
	screen.world._process(1.0/60.0)
	var match_finish:=true
	for i in range(8):match_finish=match_finish and is_equal_approx(screen.world.models[i].position.z,-screen.session.runners[i].distance)
	check(checked_midpoint and match_finish and screen.world.models[0].position.z==-100.0 and screen.world.camera.position.z==-89.0,"all eight render instances finish at simulated positions and stadium camera follows to 100m")
	var saved=app.repository.load_snapshot();var training=saved.training.duplicate(true)
	check(saved.schema_version==4 and saved.competition.records.has("male/sprint_100m") and saved.position==[1.0,-2.0],"race migration/PB preserve sandbox position")
	check(Data.validate(saved.competition,"male")=="" and screen.result_note.text.contains("Reaction"),"validated official classification and reaction feedback")
	var board=screen.results_rows
	check(board.cells.size()==8 and board.ordered_ids==Data.classify(screen.pending_result.rows).map(func(row):return row.id),"leaderboard presents all eight in exact official order")
	var player_row=board.cells.player
	check(player_row.athlete.text=="Alex Gold" and player_row.lane.text=="4" and player_row.time.text==Data.time_text(screen.session.runners[0].time_us)+" s","leaderboard columns display actual athlete, lane and finish time")
	check(player_row.panel.get_theme_stylebox("panel").border_color==screen.GOLD and player_row.panel.get_theme_stylebox("panel").border_width_left==1,"player leaderboard row has muted gold border")
	for resolution:Vector2i in [Vector2i(1280,720),Vector2i(800,600)]:
		root.size=resolution
		for frame in range(5):await process_frame
		var bounds=Rect2(Vector2.ZERO,Vector2(resolution))
		check(bounds.encloses(screen.race_again.get_global_rect()) and bounds.encloses(screen.results_hub.get_global_rect()) and bounds.encloses(screen.results_panel.get_global_rect()),"leaderboard and fixed action buttons fit %s" % resolution)
		board.scroll.grab_focus();var down=InputEventKey.new();down.pressed=true;down.keycode=KEY_END;board._scroll_key(down)
		await process_frame
		check(board.scroll.focus_mode==Control.FOCUS_ALL and board.scroll.scroll_vertical>=0,"leaderboard supports keyboard scrolling at %s" % resolution)
	var bytes=FileAccess.get_file_as_string(PATH);screen._save_result();check(FileAccess.get_file_as_string(PATH)==bytes,"saved screen cannot double-submit")
	screen.request_hub();await process_frame
	check(Engine.max_physics_steps_per_frame==initial_budget,"return to Hub restores the original physics catch-up budget")
	check(app.hub.visible and not screen.visible and app.hub.pb_overview.text.contains("100m"),"return to Hub displays saved real PB")
	app.hub.select_section("records");check(app.hub.records_body.get_child_count()>=4,"Records page includes actual saved event")
	check(app.repository.load_snapshot().training==training,"race never changes fatigue, training actions/day or ratings")
	app._enter_race();screen.start();screen._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(screen.session.phase=="invalid" and screen.pending_result.is_empty(),"focus loss invalidates attempt without PB/save")
	app._return_from_race();await process_frame
	app._enter_race();screen.start()
	while screen.session.phase!="running":screen.session.step()
	screen.last_physics_us=Time.get_ticks_usec()-2100000;screen._physics_process(1.0/60.0)
	check(screen.session.phase=="invalid" and screen.pending_result.is_empty(),"long render/physics pause invalidates before advancement or result save")
	app._return_from_race();await process_frame
	# Legacy selection is explicit and doesn't rewrite stored cosmetic identifiers.
	var legacy=c.to_dict();legacy.erase("athlete_category");legacy.athlete.appearance.hairstyle=3
	var file=FileAccess.open(PATH,FileAccess.WRITE);file.store_string(JSON.stringify({"schema_version":2,"kind":"career","career":legacy,"position":[0,0]}));file.close()
	app._continue();app._enter_race();await process_frame
	check(screen.category_form.visible and screen.ready_button.disabled and screen.world.models.size()==1,"uncategorized legacy athlete gets no inferred race category/AI field")
	app._race_category("female");await process_frame
	check(not screen.category_form.visible and screen.world.models.size()==8 and app.current_career.athlete_category=="female" and app.current_career.athlete.appearance.hairstyle==3,"explicit category saves safely and opens matching eight-runner field")
	for resolution:Vector2i in [Vector2i(1280,720),Vector2i(800,600)]:
		root.size=resolution;await process_frame;await process_frame
		check(screen.preparation.size.y<=screen.area.size.y and screen.preparation.size.x<=screen.area.size.x,"readiness stays inside scrollable area at %s" % resolution)
		for frame in range(4):await process_frame
		var bounds=Rect2(Vector2.ZERO,Vector2(resolution))
		check(bounds.encloses(screen.ready_button.get_global_rect()) and bounds.encloses(screen.mode_select.get_global_rect()),"Ready and control selector remain visible at %s" % resolution)
	print("RACE INTEGRATION FAILURES: ",failures)
	app.queue_free();await process_frame;await process_frame;quit(failures)
