extends MultiMeshInstance3D
## One tiny unlit, feathered contact-shadow batch; no textures or dynamic shadow pass.
func configure(count:int):
	var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for segment in range(12):
		var a=TAU*float(segment)/12.0;var b=TAU*float(segment+1)/12.0
		for vertex:Vector3 in [Vector3.ZERO,Vector3(cos(a)*0.42,0,sin(a)*0.28),Vector3(cos(b)*0.42,0,sin(b)*0.28)]:
			tool.set_normal(Vector3.UP);tool.set_color(Color(0.015,0.025,0.035,0.25 if vertex==Vector3.ZERO else 0.0));tool.add_vertex(vertex)
	var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.cull_mode=BaseMaterial3D.CULL_DISABLED
	var mesh=tool.commit();mesh.surface_set_material(0,material)
	multimesh=MultiMesh.new();multimesh.transform_format=MultiMesh.TRANSFORM_3D;multimesh.use_colors=true;multimesh.mesh=mesh;multimesh.instance_count=count;multimesh.custom_aabb=AABB(Vector3(-6,0,-115),Vector3(12,0.1,132))
	cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func refresh(models:Array):
	var data=PackedFloat32Array();data.resize(models.size()*16)
	for i in range(models.size()):
		var offset=i*16;var p:Vector3=models[i].position
		data[offset]=1;data[offset+3]=p.x;data[offset+5]=1;data[offset+7]=0.024;data[offset+10]=1;data[offset+11]=p.z;data[offset+12]=1;data[offset+13]=1;data[offset+14]=1;data[offset+15]=1
	multimesh.buffer=data
