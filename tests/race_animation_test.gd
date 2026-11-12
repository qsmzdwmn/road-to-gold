extends SceneTree
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
	for category in ["male","female"]:
		var world=World.new();root.add_child(world)
		var race=Session.new(State.initial(),category,"hold",1,"Alex Gold")
		var look=Appearance.new();look.height=220 if category=="male" else 140;look.legs=1.15;look.hairstyle=9 if category=="male" else 15
		world.configure(race,look,category);world.set_process(false)
		check(world.animations.size()==8 and world.limb_batch.skin.instance_count==48 and world.limb_batch.shoes.instance_count==16,"%s uses two shared limb MultiMeshes for eight unmodified appearances" % category)
		race.phase="running"
		for i in range(8):race.runners[i].speed=0 if i==0 else 8.0;race.runners[i].distance=40.0+i
		var state=JSON.stringify(race.runners)
		var contact:=true
		for frame in range(40):
			world._process(1.0/60.0)
			for rig in world.animations:
				for foot in rig.shoe_parts:
					for corner in range(8):contact=contact and (foot.global_transform*foot.mesh.get_aabb().get_endpoint(corner)).y>=0.0229
		await process_frame
		var buffer=world.limb_batch.skin_buffer;var expected:Vector3=world.models[0].parts.left_arm.global_position
		check(Vector3(buffer[3],buffer[7],buffer[11]).is_equal_approx(expected) and buffer[15]==1.0,"%s packed render buffer encodes actual animated limb position and opacity" % category)
		check(contact,"%s animated shoes stay above track at all sampled strides" % category)
		check(world.animations[0].strength==0 and world.animations[1].strength>0.9 and not is_zero_approx(world.animations[1].joints[0].rotation.x),"%s actual speed drives moving limbs while stopped runner remains idle" % category)
		check(is_equal_approx(world.animations[1].joints[2].rotation.x,-world.animations[1].joints[3].rotation.x) and world.animations[1].lean.rotation.x<0,"%s opposing stride and forward lean" % category)
		check(JSON.stringify(race.runners)==state and world.models[0].position.z==-40.0,"%s animation never changes authoritative runner state or lane/distance bindings" % category)
		var previous_upload=world.limb_batch.skin_buffer;var previous_z=previous_upload[11]
		race.runners[0].distance+=1.0;world._process(1.0/60.0)
		check(previous_upload[11]==previous_z and world.limb_batch.skin_buffer[11]!=previous_z,"%s new frame preserves immutable prior GPU upload while updating runner location" % category)
		for runner in race.runners:runner.status="FIN"
		for frame in range(90):world._process(1.0/60.0)
		check(world.animations[1].strength==0 and absf(world.animations[1].lean.rotation.x)<0.001 and world.animations[1].joints[2].rotation.x==0,"%s finished runners ease back to idle" % category)
		world.queue_free();await process_frame;await process_frame
	var legacy_world=World.new();root.add_child(legacy_world)
	var legacy_race=Session.new(State.initial(),"","hold",1,"Legacy Athlete")
	legacy_world.configure(legacy_race,Appearance.new(),"")
	check(legacy_world.models.size()==1 and legacy_world.animations.is_empty() and legacy_world.limb_batch==null,"uncategorized legacy readiness retains original neutral model without inferred anatomy or hidden detail meshes")
	legacy_world.queue_free();await process_frame;await process_frame
	print("RACE ANIMATION FAILURES: ",failures);quit(failures)
