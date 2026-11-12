extends SceneTree
const Quality=preload("res://scripts/race/race_quality.gd")
const World=preload("res://scripts/race/race_world.gd")
const Session=preload("res://scripts/race/race_session.gd")
const State=preload("res://scripts/training/training_state.gd")
const Appearance=preload("res://scripts/data/appearance_data.gd")
const Main=preload("res://scenes/app/main.tscn")
const PATH="user://tests/race-quality.cfg"
var failures:=0
func check(ok:bool,message:String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func _initialize():run.call_deferred()
func run():
	DirAccess.make_dir_recursive_absolute("user://tests");DirAccess.remove_absolute(PATH)
	check(Quality.load_mode(PATH)==Quality.PERFORMANCE,"missing preference defaults to Performance")
	check(Quality.save_mode(Quality.ENHANCED,PATH)==OK and Quality.load_mode(PATH)==Quality.ENHANCED,"Enhanced preference round-trips separately from career")
	var bytes=FileAccess.get_file_as_string(PATH)
	check(Quality.save_mode("unknown",PATH)==ERR_INVALID_PARAMETER and FileAccess.get_file_as_string(PATH)==bytes,"invalid quality cannot overwrite preference")
	var bad=ConfigFile.new();bad.set_value("race","quality",123);bad.save(PATH)
	check(Quality.load_mode(PATH)==Quality.PERFORMANCE,"malformed quality safely falls back")
	var world=World.new();root.add_child(world);world.set_process(false)
	var race=Session.new(State.initial(),"female","hold",123,"Quality Athlete")
	world.configure(race,Appearance.new(),"female");var state=JSON.stringify(race.runners);var geometry=world.course.static_triangles
	world.set_quality(Quality.PERFORMANCE)
	var crowd=world.course.get_children().filter(func(node):return node is MultiMeshInstance3D)[0]
	check(not world.course.get_node("Sun").shadow_enabled and crowd.multimesh.instance_count==116,"Performance avoids shadow map and reduces crowd to 116 instances")
	check(world.models.size()==8 and world.animations.size()==8 and world.contact_shadows.multimesh.instance_count==8,"all eight animated runners and cheap contact shadows retained")
	check(world.course.static_triangles==geometry and JSON.stringify(race.runners)==state,"quality retains entire stadium mesh and authoritative race state")
	var view=SubViewport.new();root.add_child(view);Quality.apply_viewport(view,Quality.PERFORMANCE)
	check(view.msaa_3d==Viewport.MSAA_DISABLED,"Performance disables multisample rendering")
	world.set_quality(Quality.ENHANCED);Quality.apply_viewport(view,Quality.ENHANCED)
	check(world.course.get_node("Sun").shadow_enabled and crowd.multimesh.visible_instance_count==-1 and not world.contact_shadows.visible and view.msaa_3d==Viewport.MSAA_2X,"Enhanced restores approved original shadows, crowd and antialiasing")
	check(world.course.static_triangles==geometry and JSON.stringify(race.runners)==state,"quality round-trip changes no geometry or runner data")
	var app=Main.instantiate();root.add_child(app);await process_frame
	var saved_mode=Quality.load_mode();var career_bytes=FileAccess.get_file_as_string("user://prototype_v1.json") if FileAccess.file_exists("user://prototype_v1.json") else ""
	for size in [Vector2i(1280,720),Vector2i(800,600)]:
		root.size=size;app.ui.show_settings()
		for frame in range(5):await process_frame
		var back=app.ui.settings.get_child(app.ui.settings.get_child_count()-1)
		check(Rect2(Vector2.ZERO,Vector2(size)).encloses(back.get_global_rect()) and Rect2(Vector2.ZERO,Vector2(size)).encloses(app.ui.race_quality.get_global_rect()),"quality selector and Back accessible at %s" % size)
	app.ui.race_quality.select(1);app.ui._race_quality_selected(1)
	check(Quality.load_mode()==Quality.ENHANCED,"Settings control persists actual quality choice")
	var current_bytes=FileAccess.get_file_as_string("user://prototype_v1.json") if FileAccess.file_exists("user://prototype_v1.json") else ""
	check(current_bytes==career_bytes,"quality preference never touches career save bytes")
	Quality.save_mode(saved_mode);DirAccess.remove_absolute(PATH)
	app.queue_free();world.queue_free();view.queue_free();await process_frame;await process_frame
	print("QUALITY FAILURES: ",failures);quit(failures)
