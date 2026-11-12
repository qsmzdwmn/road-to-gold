extends SceneTree
const Course=preload("res://scenes/race/race_course.tscn")
const World=preload("res://scripts/race/race_world.gd")
const Session=preload("res://scripts/race/race_session.gd")
const State=preload("res://scripts/training/training_state.gd")
const Appearance=preload("res://scripts/data/appearance_data.gd")
var failures:=0
func check(ok:bool,message:String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func _initialize():run.call_deferred()
func run():
	var world=World.new();root.add_child(world)
	var race=Session.new(State.initial(),"male","hold",1,"Alex Gold")
	world.configure(race,Appearance.new(),"male");world.set_process(false)
	var course=world.course
	check(is_equal_approx(world.camera.position.y,6.6),"lower player-follow perspective is the default")
	world.establishing=true;world._update_camera(0.0)
	check(world.camera.position.y==82 and world.camera.far==350,"optional readiness view establishes venue without an extra timer")
	race.phase="running"
	check(course.is_visual_batched() and course.geometry_batches>0 and course.get_child_count()<90,"stadium is prebatched with bounded live scene nodes")
	check(course.spectator_count>0,"crowd uses shared simple instances, not detailed athlete scenes")
	var crowd_count:=0
	var finite:=true;var arc_vertices:=0;var indexed_arc_vertices:=0;var valid_indices:=true;var sand_outside:=false
	for node in course.get_children():
		if node is MultiMeshInstance3D:crowd_count+=1
		if not node is MeshInstance3D:continue
		var vertices:PackedVector3Array=node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var indices:PackedInt32Array=node.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]
		for index in indices:
			valid_indices=valid_indices and index>=0 and index<vertices.size()
			if node.material_override==course.materials.track and vertices[index].z < -120:indexed_arc_vertices+=1
		if node.material_override==course.materials.get("sand"):sand_outside=node.mesh.get_aabb().position.x>8.0
		for vertex in vertices:
			finite=finite and vertex.is_finite()
			if node.material_override==course.materials.track and vertex.z < -120:arc_vertices+=1
	check(crowd_count==1 and finite and arc_vertices>0,"one instanced crowd and finite oval/stadium geometry")
	check(indexed_arc_vertices>0 and valid_indices,"oval bends are referenced by valid triangle indices, not orphan vertices")
	check(sand_outside,"long-jump pit and decorative infield stay outside active sprint lanes")
	check(course.get_node("Sun").shadow_enabled and course.get_node("Sun").directional_shadow_mode==0,"daylight uses one orthogonal shadow map instead of cascades")
	for distance in [0.0,50.0,100.0]:
		for i in range(8):race.runners[i].distance=clampf(distance+i*0.1,0,100)
		world._process(0)
		var aligned:=true;var clear:=true
		for i in range(8):
			aligned=aligned and world.models[i].position.x==float(race.runners[i].lane)-3.5 and is_equal_approx(world.models[i].position.z,-race.runners[i].distance)
		var camera=world.camera.position
		clear=camera.x>1.0 and camera.x<5.0 and camera.y>5.5
		check(aligned and clear and is_equal_approx(camera.z,11-distance),"stadium preserves eight lane/distance bindings and clear camera corridor at %sm" % distance)
	race.phase="running";race.ticks=360;course.update_race(race)
	check(course.scoreboard.text.contains("6.0 s"),"scoreboard displays authoritative elapsed time")
	for resolution in [Vector2i(1280,720),Vector2i(800,600)]:
		root.size=resolution
		for frame in range(3):await process_frame
		var heights:Array=[]
		for distance in [0.0,70.0]:
			race.runners[0].distance=distance
			for i in range(1,8):race.runners[i].distance=100.0
			world._process(0)
			var feet:Vector3=world.models[0].global_position
			var head:Vector3=feet+Vector3(0,1.8,0)
			heights.append(world.camera.unproject_position(feet).distance_to(world.camera.unproject_position(head)))
		check(is_equal_approx(heights[0],heights[1]) and heights[1]>60,"player stays equally readable while trailing at %s (%0.1f pixels)" % [resolution,heights[1]])
	var above_track:=true
	for model in world.models:
		for node in model.get_children():
			if not node is MeshInstance3D or not node.visible:continue
			for vertex:Vector3 in node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
				above_track=above_track and (node.global_transform*vertex).y>=0.022
	check(above_track,"race-only render lift keeps all shoe vertices above track and painted start/finish surfaces")
	var summary={"static_triangles":course.static_triangles,"static_batches":course.geometry_batches,"spectators":course.spectator_count}
	print("STADIUM_GEOMETRY ",JSON.stringify(summary))
	world.queue_free();await process_frame;await process_frame
	print("STADIUM FAILURES: ",failures);quit(failures)
