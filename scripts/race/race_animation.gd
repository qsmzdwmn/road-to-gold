extends RefCounted
## Cosmetic rig over disposable race instances only. No skeleton, mesh rebuilding or simulation writes.
const Batch=preload("res://scripts/race/static_mesh_batch.gd")
const LIMBS=["left_arm","right_arm","left_hand","right_hand","left_leg","right_leg","left_foot","right_foot"]
var model:Node3D
var lean:Node3D
var joints:Array[Node3D]=[]
var skin_parts:Array=[]
var shoe_parts:Array=[]
var phase:=0.0
var strength:=0.0
var previous_speed:=0.0
var base_y:=0.0

func build(athlete:Node3D,index:int):
	model=athlete;base_y=model.position.y;phase=float(index)*0.61
	var hip:float=model.parts.left_leg.position.y+model.parts.left_leg.scale.y*0.5
	lean=Node3D.new();lean.name="RaceLean";lean.position.y=hip;model.add_child(lean)
	for side:String in ["left_","right_"]:
		var arm:MeshInstance3D=model.parts[side+"arm"]
		var arm_joint=Node3D.new();arm_joint.position=arm.position+Vector3(0,arm.scale.y*0.5,0);model.add_child(arm_joint);arm_joint.reparent(lean,true);joints.append(arm_joint)
		for key:String in ["arm","hand"]:
			var part:MeshInstance3D=model.parts[side+key];part.reparent(arm_joint,true);part.hide();skin_parts.append(part)
	for side:String in ["left_","right_"]:
		var leg:MeshInstance3D=model.parts[side+"leg"]
		var leg_joint=Node3D.new();leg_joint.position=Vector3(leg.position.x,hip,0);model.add_child(leg_joint);joints.append(leg_joint)
		leg.reparent(leg_joint,true);leg.hide();skin_parts.append(leg)
		var foot:MeshInstance3D=model.parts[side+"foot"];foot.reparent(leg_joint,true);foot.hide();shoe_parts.append(foot)
	# Everything remaining visible is the unchanged body/head/hair/clothing geometry.
	for node:Node in model.get_children():
		if node==lean or node in joints or node is MeshInstance3D and not node.visible:continue
		node.reparent(lean,true)
	Batch.compact(lean)

func advance(delta:float,speed:float):
	var dt:=clampf(delta,0.0,0.25)
	var acceleration:=maxf(0.0,(speed-previous_speed)/maxf(dt,0.001));previous_speed=speed
	strength=move_toward(strength,clampf(speed/5.0,0.0,1.0),dt*4.0)
	phase+=speed*dt*1.8
	var stride:=sin(phase)*0.58*strength
	joints[0].rotation.x=-stride*0.85;joints[1].rotation.x=stride*0.85
	joints[2].rotation.x=stride;joints[3].rotation.x=-stride
	lean.rotation.x=lerpf(lean.rotation.x,-(0.025+clampf(acceleration/5.0,0.0,1.0)*0.09)*strength,1.0-exp(-dt*9.0))
	model.position.y=base_y+pow(sin(phase),2.0)*0.015*strength
	# Contact correction is cosmetic; lane x/z and authoritative race state remain untouched.
	var lowest:=INF
	for foot:MeshInstance3D in shoe_parts:
		var aabb:=foot.mesh.get_aabb()
		for corner in range(8):lowest=minf(lowest,(foot.global_transform*aabb.get_endpoint(corner)).y)
	if lowest<0.023:model.position.y+=0.023-lowest
