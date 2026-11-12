extends Node3D
## Two shared cube MultiMeshes render all animated limbs, regardless of athlete skin tones.
var skin:MultiMesh
var shoes:MultiMesh
var rigs:Array=[]
var skin_buffer:=PackedFloat32Array()
var shoe_buffer:=PackedFloat32Array()

func _batch(count:int)->MultiMesh:
	var mesh=BoxMesh.new();mesh.size=Vector3.ONE
	var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.vertex_color_is_srgb=true;material.roughness=0.92;mesh.material=material
	var multi=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true;multi.mesh=mesh;multi.instance_count=count
	multi.custom_aabb=AABB(Vector3(-6,-1,-115),Vector3(12,6,132))
	var node=MultiMeshInstance3D.new();node.multimesh=multi;add_child(node);return multi

func configure(value:Array):
	rigs=value;skin=_batch(rigs.size()*6);shoes=_batch(rigs.size()*2)
	skin_buffer.resize(rigs.size()*6*16);shoe_buffer.resize(rigs.size()*2*16);refresh()

func _write(buffer:PackedFloat32Array,index:int,transform:Transform3D,color:Color):
	var offset=index*16
	var b=transform.basis;var p=transform.origin
	# Row-major 3x4 transform followed by RGBA, matching MultiMesh's documented buffer layout.
	var values=[b.x.x,b.y.x,b.z.x,p.x,b.x.y,b.y.y,b.z.y,p.y,b.x.z,b.y.z,b.z.z,p.z,color.r,color.g,color.b,color.a]
	for i in range(16):buffer[offset+i]=values[i]

func refresh():
	# Fresh buffers avoid sharing mutable upload data with the Compatibility renderer.
	skin_buffer=PackedFloat32Array();skin_buffer.resize(rigs.size()*6*16)
	shoe_buffer=PackedFloat32Array();shoe_buffer.resize(rigs.size()*2*16)
	var skin_index:=0;var shoe_index:=0
	var inverse:=global_transform.affine_inverse()
	for rig in rigs:
		for part in rig.skin_parts:_write(skin_buffer,skin_index,inverse*part.global_transform,rig.model.skin_material.albedo_color);skin_index+=1
		for part in rig.shoe_parts:_write(shoe_buffer,shoe_index,inverse*part.global_transform,Color("121f2b"));shoe_index+=1
	skin.buffer=skin_buffer;shoes.buffer=shoe_buffer
