extends Node3D
const Course=preload("res://scenes/race/race_course.tscn")
const Model=preload("res://scripts/customization/procedural_athlete.gd")
const Batch=preload("res://scripts/race/static_mesh_batch.gd")
const RunAnimation=preload("res://scripts/race/race_animation.gd")
const LimbBatch=preload("res://scripts/race/race_limb_batch.gd")
const ContactShadows=preload("res://scripts/race/race_contact_shadows.gd")
const Quality=preload("res://scripts/race/race_quality.gd")
const Appearance=preload("res://scripts/data/appearance_data.gd")
var full_crowd:MultiMesh
var reduced_crowd:MultiMesh
var quality_mode:=Quality.ENHANCED
var contact_shadows
var establishing:=false
var models:Array=[]
var animations:Array=[]
var limb_batch
var camera:Camera3D
var course
var course_batched:=false
var session
var frame_samples:Array[float]=[]
var draw_calls:=0
var memory_bytes:=0
var last_frame_us:=0

func _ready():
	course=Course.instantiate();add_child(course)
	camera=Camera3D.new();camera.fov=60;camera.near=0.2;camera.far=180;add_child(camera)
	_update_camera(0.0);camera.make_current()

func configure(value,appearance,category:String,avatar_count:=8,optimize_visuals:=true):
	session=value
	for child:Node in models:child.queue_free()
	models.clear();animations.clear()
	if limb_batch!=null:limb_batch.queue_free();limb_batch=null
	if contact_shadows!=null:contact_shadows.queue_free();contact_shadows=null
	frame_samples.clear();last_frame_us=0;draw_calls=0
	for i in range(mini(session.runners.size(),avatar_count)):
		var model=Model.new();add_child(model)
		var data=appearance if i==0 else Appearance.new()
		if i>0:
			data.skin=i%6;data.hairstyle=(4+i%6) if category=="male" else (10+i%6);data.hair_color=i%5
		model.apply_appearance(data,category)
		var shoe_lift:float=0.03*model.scale.y if category in ["male","female"] else 0.0
		model.position=Vector3(float(session.runners[i].lane)-3.5,shoe_lift+0.025,0)
		models.append(model)
		if optimize_visuals and category in ["male","female"]:
			var animation=RunAnimation.new();animation.build(model,i);animations.append(animation)
	if optimize_visuals:
		optimize()
		if not animations.is_empty():
			limb_batch=LimbBatch.new();add_child(limb_batch);limb_batch.configure(animations)
	set_quality(quality_mode);_update_camera(0.0)

func set_quality(mode:String):
	quality_mode=mode if Quality.valid(mode) else Quality.PERFORMANCE
	var enhanced:bool=quality_mode==Quality.ENHANCED
	course.get_node("Sun").shadow_enabled=enhanced
	for node:Node in course.get_children():
		if node is MultiMeshInstance3D:
			if full_crowd==null:full_crowd=node.multimesh
			if not enhanced and reduced_crowd==null:
				reduced_crowd=MultiMesh.new();reduced_crowd.transform_format=MultiMesh.TRANSFORM_3D;reduced_crowd.use_colors=true;reduced_crowd.mesh=full_crowd.mesh
				reduced_crowd.instance_count=ceili(float(full_crowd.instance_count)/3.0)
				# Evenly sample all seating blocks, rather than filling only the first section.
				for i in range(reduced_crowd.instance_count):
					var index=mini(full_crowd.instance_count-1,int(float(i)*full_crowd.instance_count/reduced_crowd.instance_count))
					reduced_crowd.set_instance_transform(i,course.crowd_transforms[index]);reduced_crowd.set_instance_color(i,course.crowd_colors[index])
			node.multimesh=full_crowd if enhanced else reduced_crowd
	if not enhanced and contact_shadows==null:
		contact_shadows=ContactShadows.new();add_child(contact_shadows);contact_shadows.configure(models.size())
	if contact_shadows!=null:
		contact_shadows.visible=not enhanced;contact_shadows.refresh(models)

func optimize():
	if not course_batched:
		if not course.has_method("is_visual_batched"):Batch.compact(course)
		course_batched=true
	if animations.is_empty():
		for model:Node3D in models:Batch.compact(model)
	frame_samples.clear();last_frame_us=0;draw_calls=0

func _process(delta:float):
	if not visible or session==null:return
	var now:=Time.get_ticks_usec()
	if last_frame_us>0 and frame_samples.size()<2400:frame_samples.append(float(now-last_frame_us)/1000.0)
	last_frame_us=now
	if frame_samples.size()>5:draw_calls=maxi(draw_calls,int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	memory_bytes=maxi(memory_bytes,int(Performance.get_monitor(Performance.MEMORY_STATIC)))
	for i in range(models.size()):
		models[i].position.z=-float(session.runners[i].distance)
		if i<animations.size():animations[i].advance(delta,float(session.runners[i].speed) if session.runners[i].status=="RUN" and session.phase=="running" else 0.0)
	if limb_batch!=null:limb_batch.refresh()
	if contact_shadows!=null and contact_shadows.visible:contact_shadows.refresh(models)
	course.update_race(session)
	var distance:=float(session.runners[0].distance)
	_update_camera(distance)

func _update_camera(distance:float):
	if session!=null and session.phase=="preparation" and establishing:
		# An immediate static establishing view; Ready cuts directly to racing with no added wait.
		camera.far=350;camera.position=Vector3(108,82,60);camera.look_at(Vector3(30,0,-50))
	else:
		camera.far=180;camera.position=Vector3(2.5,6.6,11-distance);camera.look_at(Vector3(3.5,1,-10-distance))

func metrics() -> Dictionary:
	var samples:=frame_samples.duplicate();samples.sort()
	if samples.is_empty():return {"frames":0}
	var sum:=0.0
	for sample:float in samples:sum+=sample
	return {"frames":samples.size(),"mean_frame_ms":snappedf(sum/samples.size(),0.01),"p95_frame_ms":snappedf(samples[mini(samples.size()-1,int(samples.size()*0.95))],0.01),"max_draw_calls":draw_calls,"godot_static_memory_bytes":memory_bytes,"runners":models.size()}
