extends SceneTree
const Director=preload("res://scripts/audio/audio_director.gd")
const Presenter=preload("res://scripts/audio/race_audio_presenter.gd")
const Main=preload("res://scenes/app/main.tscn")
const Session=preload("res://scripts/race/race_session.gd")
const State=preload("res://scripts/training/training_state.gd")
var failures:=0
var path="user://tests/audio-lifecycle.cfg"
func check(ok:bool,message:String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func _initialize():run.call_deferred()
func run():
	DirAccess.make_dir_recursive_absolute("user://tests");DirAccess.remove_absolute(path)
	var career_before=FileAccess.get_file_as_bytes("user://prototype_v1.json") if FileAccess.file_exists("user://prototype_v1.json") else PackedByteArray()
	var audio=Director.new();audio.preference_path=path;root.add_child(audio)
	check(audio.players.size()==7 and not audio.unlocked and audio.active_voices()==0,"bounded seven-slot mixer is silent before input")
	check(not audio.one_shot("pistol","pistol"),"no queued pistol before unlock")
	audio.set_process(false);audio.set_context("hub");audio._process(1)
	check(not audio.players.music.playing,"Hub cannot bypass user interaction gate")
	audio.unlock();audio._process(.1)
	check(audio.players.music.playing and audio.players.music.stream.loop,"Hub loop starts after interaction")
	var music=audio.players.music;audio.set_context("hub")
	check(audio.players.music==music,"Hub refresh reuses one music player")
	check(audio.set_preference("music",12)==OK and audio.set_preference("sfx",83)==OK and audio.set_preference("crowd",46)==OK,"three independent preferences save")
	for entry:Array in [["Music",.12],["Sound Effects",.83],["Stadium Crowd",.46]]:
		check(absf(db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(entry[0])))-entry[1])<.001,"independent bus gain "+entry[0])
	audio.set_preference("mute_all",true)
	check(AudioServer.is_bus_mute(0) and audio.active_voices()==0 and not audio.one_shot("pistol","pistol"),"Mute All stops voices and suppresses new ones")
	audio.set_preference("mute_all",false)
	check(audio.preferences.music==12 and audio.preferences.sfx==83 and audio.preferences.crowd==46,"unmute retains category preferences")
	var presenter=Presenter.new(audio);presenter.reset();presenter.phase_changed("marks");presenter.phase_changed("invalid")
	check(audio.counts.get("pistol",0)==0,"false start has no pistol")
	presenter.reset();presenter.phase_changed("set");presenter.phase_changed("running");presenter.phase_changed("running")
	check(audio.counts.get("pistol",0)==1,"actual Set to Running transition fires once")
	var runner={"distance":10.0,"speed":8.0,"status":"RUN"}
	presenter.player_state(runner,0.1);presenter.player_state(runner,PI+.1);presenter.player_state(runner,PI+.2)
	check(audio.counts.get("right",0)==1,"one footstep per gait half-cycle")
	presenter.player_state(runner,PI*10+.1)
	check(audio.counts.get("left",0)==1,"missed gait phases never produce a catch-up burst")
	runner.speed=0;presenter.player_state(runner,PI*11+.1)
	check(audio.counts.get("right",0)==1,"no footsteps when stopped")
	runner.distance=100;runner.status="FIN";presenter.player_state(runner,PI*12);presenter.player_state(runner,PI*13)
	check(audio.counts.get("finish",0)==1 and audio.counts.get("cheer",0)==1,"finish and crowd cue are once-only")
	presenter.phase_changed("results");presenter.saved_result(false,true)
	check(audio.counts.get("pb",0)==0,"failed result save cannot celebrate a PB")
	presenter.saved_result(true,false);check(audio.counts.get("pb",0)==0,"existing PB is not celebrated")
	presenter.saved_result(true,true);presenter.saved_result(true,true)
	check(audio.counts.get("pb",0)==1,"successfully saved new PB celebrated once")
	audio.set_suspended(true);presenter.reset();presenter.phase_changed("set");presenter.phase_changed("running")
	check(audio.active_voices()==0 and audio.counts.pistol==1,"suspension silences all slots and drops missed cues")
	audio.set_suspended(false);presenter.phase_changed("running")
	check(audio.counts.pistol==1,"resume never replays skipped pistol")
	presenter.reset();presenter.phase_changed("set");presenter.phase_changed("running")
	check(audio.counts.pistol==2,"fresh retry can play one new start")
	audio.set_crowd(0.4);audio._process(.1)
	check(audio.players.crowd.playing,"crowd loop active before race-exit verification")
	presenter.close();check(not audio.players.pistol.playing and not audio.players.footstep.playing and not audio.players.cheer.playing,"screen exit stops race one-shots")
	for frame in range(30):audio._process(.1)
	check(not audio.players.crowd.playing and not audio.players.pistol.playing and not audio.players.footstep.playing and not audio.players.cheer.playing,"race exit leaves no race audio after the short fade")
	audio.set_context("hub");audio._process(.1)
	check(audio.players.music.playing and not audio.players.crowd.playing,"Hub music resumes without stadium ambience")
	audio.counts.erase("navigation");audio.last_ui_ms=-1000
	for i in range(20):audio.ui_sound()
	check(audio.counts.get("navigation",0)==1,"rapid UI activation is rate limited")
	check(audio.peak_voices<=7,"voice cap is respected")
	# Full deterministic simulations with and without the presentation observer.
	for category:String in ["male","female"]:
		for mode:String in ["hold","rhythm"]:
			var observed=Session.new(State.initial(),category,mode,51,"Audio Athlete")
			var baseline=Session.new(State.initial(),category,mode,51,"Audio Athlete")
			observed.ready();baseline.ready();presenter.reset();presenter.phase_changed("marks")
			var old_count:int=audio.counts.get("finish",0);var gait:=0.0
			for tick in range(2600):
				if observed.phase=="results":break
				if observed.phase=="running":
					if mode=="hold" and observed.ticks==0:
						observed.key(KEY_SPACE,true);baseline.key(KEY_SPACE,true)
					elif mode=="rhythm" and observed.ticks%15==0:
						var key=KEY_A if observed.ticks%30==0 else KEY_D
						observed.key(key,true);observed.key(key,false);baseline.key(key,true);baseline.key(key,false)
				var previous:String=observed.phase
				observed.step();baseline.step();gait+=float(observed.runners[0].speed)/60.0*1.8
				if previous=="running":presenter.player_state(observed.runners[0],gait)
				if previous!=observed.phase:presenter.phase_changed(observed.phase)
			check(observed.phase=="results" and JSON.stringify(observed.runners)==JSON.stringify(baseline.runners),"audio observer preserves all eight timings and physics "+category+" "+mode)
			check(audio.counts.get("finish",0)==old_count+1,"full race emits one player finish even on Results transition "+category+" "+mode)
	print("AUDIO_TEST_METRICS ",JSON.stringify(audio.metrics()))
	var values=audio.preferences.duplicate();audio.preference_path="user://missing-parent/audio.cfg"
	check(audio.set_preference("music",42)!=OK and audio.preferences.music==42 and audio.notice.contains("Could not save"),"failed preference write keeps honest immediate session preview")
	audio.queue_free();await process_frame
	var reloaded=Director.new();reloaded.preference_path=path;root.add_child(reloaded)
	check(reloaded.preferences==values,"saved preferences survive a fresh director")
	reloaded.queue_free();await process_frame
	var app=Main.instantiate();root.add_child(app);await process_frame
	for size:Vector2i in [Vector2i(1280,720),Vector2i(800,600)]:
		root.size=size;app.ui.show_settings()
		for i in range(8):await process_frame
		var bounds=Rect2(Vector2.ZERO,Vector2(size));var back=app.ui.settings.get_child(app.ui.settings.get_child_count()-1)
		check(bounds.encloses(back.get_global_rect()),"Settings Back pinned inside viewport "+str(size))
		for key:String in ["music","sfx","crowd"]:
			app.ui.settings_scroll.ensure_control_visible(app.ui.audio_settings.sliders[key]);await process_frame
			check(bounds.encloses(app.ui.audio_settings.sliders[key].get_global_rect()),"slider reachable with scroll "+key+" "+str(size))
		var panel=app.ui.audio_settings
		for control:Control in [panel.sliders.music,panel.sliders.sfx,panel.sliders.crowd,panel.mute,app.ui.race_quality]:
			app.ui.settings_scroll.ensure_control_visible(control)
			for frame in range(3):await process_frame
			check(app.ui.settings_scroll.get_global_rect().encloses(control.get_global_rect()) and not control.get_global_rect().intersects(back.get_global_rect()),"Settings control fully inside scroll clip, above Back: "+control.name+" "+str(size))
		check(panel.mute.get_theme_icon("checked").get_width()==56 and panel.mute.get_theme_icon("unchecked").get_height()==28,"large high-contrast Mute All icons "+str(size))
		var previous:bool=app.audio.preferences.mute_all
		app.audio.preferences.mute_all=true;panel.refresh()
		check(panel.mute.text.contains("ON") and panel.mute.button_pressed,"Mute All visibly says ON "+str(size))
		app.audio.preferences.mute_all=false;panel.refresh()
		check(panel.mute.text.contains("OFF") and not panel.mute.button_pressed,"Mute All visibly says OFF "+str(size))
		app.audio.preferences.mute_all=previous;panel.refresh()
		app.ui.settings_scroll.ensure_control_visible(app.ui.race_quality);await process_frame
		check(bounds.encloses(app.ui.race_quality.get_global_rect()),"existing graphics choice remains accessible "+str(size))
	var career_after=FileAccess.get_file_as_bytes("user://prototype_v1.json") if FileAccess.file_exists("user://prototype_v1.json") else PackedByteArray()
	check(career_after==career_before,"audio lifecycle never touches career bytes")
	app.queue_free();DirAccess.remove_absolute(path);await process_frame;await process_frame
	print("AUDIO LIFECYCLE FAILURES: ",failures);quit(failures)
