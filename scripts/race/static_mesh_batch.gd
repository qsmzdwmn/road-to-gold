extends RefCounted
## Bake only disposable race instances. Shared customization scenes/scripts stay unchanged.
static func collect(node:Node,output:Array) -> void:
	if node is MeshInstance3D and node.visible and node.is_visible_in_tree() and node.mesh!=null:output.append(node)
	for child:Node in node.get_children():collect(child,output)

static func compact(root:Node3D) -> int:
	var meshes:Array=[];collect(root,meshes)
	var batches:Dictionary={};var materials:Dictionary={}
	for node:MeshInstance3D in meshes:
		for surface in range(node.mesh.get_surface_count()):
			var material=node.get_active_material(surface)
			if not material is StandardMaterial3D:continue
			var key:String=material.albedo_color.to_html()+"/"+str(material.roughness)
			if not batches.has(key):
				var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);batches[key]=tool;materials[key]=material
			batches[key].append_from(node.mesh,surface,root.global_transform.affine_inverse()*node.global_transform)
	for node:MeshInstance3D in meshes:node.hide();node.queue_free()
	for key:String in batches:
		var instance=MeshInstance3D.new();instance.mesh=batches[key].commit();instance.material_override=materials[key];root.add_child(instance)
	return batches.size()
