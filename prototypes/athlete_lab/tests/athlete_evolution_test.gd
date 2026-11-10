extends SceneTree
const Showcase = preload("res://scenes/athlete_showcase.tscn")
const Appearance = preload("res://scripts/data/appearance_data.gd")
var failures := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + message)
	if not ok: failures += 1
func _run() -> void:
	var app = Showcase.instantiate()
	root.add_child(app)
	await process_frame
	var model = app.models[0]
	var camera: Camera3D = app.get_viewport().get_camera_3d()
	var original_camera := camera.transform
	var original_yaw: Vector3 = model.rotation
	var stats := {}
	for category: String in ["male", "female"]:
		var data = Appearance.new()
		model.apply_appearance(data, category)
		var skeleton: Skeleton3D = model.asset_skeletons[category]
		check(skeleton.get_bone_count()==22 and skeleton.find_bone("LHand")>=0 and skeleton.find_bone("RFoot")>=0, category+" real humanoid skeleton with hand and foot joints")
		check(model.parts.values().all(func(p): return p.layers==0), category+" fallback reference meshes never duplicate rendering")
		var valid_meshes := true
		var valid_weights := true
		var degenerate := 0
		for mesh: MeshInstance3D in model.asset_meshes[category]:
			valid_meshes = valid_meshes and mesh.skin.get_bind_count()==22 and mesh.mesh.get_blend_shape_count()==3
			for surface in range(mesh.mesh.get_surface_count()):
				var arrays := mesh.mesh.surface_get_arrays(surface)
				var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				for index in indices: valid_meshes = valid_meshes and index>=0 and index<points.size()
				for i in range(0,indices.size(),3):
					if (points[indices[i+1]]-points[indices[i]]).cross(points[indices[i+2]]-points[indices[i]]).length()<0.000000001: degenerate+=1
				var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
				for i in range(0,weights.size(),4): valid_weights = valid_weights and absf(weights[i]+weights[i+1]+weights[i+2]+weights[i+3]-1.0)<0.002
		check(valid_meshes and degenerate==0, category+" imported mesh indices, morphs, skin binds and triangle areas are valid")
		check(valid_weights, category+" imported vertex skin weights sum to one")
		check(model.skin_material.cull_mode==BaseMaterial3D.CULL_BACK, category+" normal backface culling stays enabled")
		for style in range(4):
			data.hairstyle=style
			model.apply_appearance(data,category)
			var visible_hair := 0
			for mesh: MeshInstance3D in model.asset_meshes[category]:
				if String(mesh.name).begins_with("Hair_") and mesh.visible: visible_hair+=1
			check(visible_hair==(0 if style==0 else 1) and model.parts.tail.visible==(style==3),category+" stored hairstyle identifier "+str(style)+" selects correct asset")
			stats[category+"/"+str(style)]=model.geometry_stats()
		var generation: int = model.mesh_generation_count
		for tone in range(6):
			data.skin=tone
			model.apply_appearance(data,category)
			check(model.skin_material.albedo_color==Color(Appearance.SKIN_COLORS[tone]) and model.mesh_generation_count==generation,category+" skin tone "+str(tone)+" updates without geometry regeneration")
		for color in range(5):
			data.hair_color=color
			model.apply_appearance(data,category)
			check(model.hair_material.albedo_color==Color(Appearance.HAIR_COLORS[color]) and model.mesh_generation_count==generation,category+" hair color "+str(color)+" updates without geometry regeneration")
		for key: String in ["weight","shoulders","legs"]:
			data.set(key,Appearance.LIMITS[key][0]);model.apply_appearance(data,category)
			var low := Vector3(model.rendered.get_blend_shape_value(0),model.rendered.get_blend_shape_value(1),model.rendered.get_blend_shape_value(2))
			data.set(key,Appearance.LIMITS[key][1]);model.apply_appearance(data,category)
			var high := Vector3(model.rendered.get_blend_shape_value(0),model.rendered.get_blend_shape_value(1),model.rendered.get_blend_shape_value(2))
			check(low!=high,category+" "+key+" drives real imported shape channels")
		data.height=220;model.apply_appearance(data,category)
		check(is_equal_approx(model.scale.x,220.0/180.0),category+" height retains original uniform stature scaling")
		var accurate_bind := true
		for mesh: MeshInstance3D in model.asset_meshes[category]:
			for index in range(mesh.skin.get_bind_count()):
				var bone := skeleton.find_bone(mesh.skin.get_bind_name(index))
				var identity := skeleton.get_bone_global_rest(bone)*mesh.skin.get_bind_pose(index)
				accurate_bind = accurate_bind and identity.origin.length()<0.00001 and identity.basis.is_equal_approx(Basis.IDENTITY)
		check(accurate_bind,category+" extreme-customization rest and inverse-bind transforms agree")

		var before: Dictionary = data.to_dict()
		app.models[1].apply_appearance(data,category)
		check(app.models[1].geometry_stats().triangles==model.geometry_stats().triangles and data.to_dict()==before,category+" shared asset instances without mutating appearance data")
		app.models[1].skin_material.albedo_color=Color.RED
		check(model.skin_material.albedo_color!=Color.RED,category+" separate model material instances stay independent")
	model.apply_appearance(Appearance.new(),"")
	check(model.active_asset==null and not model.parts.neck.visible and model.parts.torso.layers==1,"uncategorized legacy returns to original neutral fallback without inference")
	model.use_fallback=true;model.apply_appearance(Appearance.new(),"female")
	check(model.active_asset==null and model.parts.neck.visible and model.parts.torso.layers==1,"explicit fallback switch retains working original character")
	check(camera.transform==original_camera and model.rotation==original_yaw,"fixed lab camera and model orientations unchanged")
	print("EVOLUTION GEOMETRY STATS: ",JSON.stringify(stats))
	print("ATHLETE EVOLUTION TEST FAILURES: ",failures)
	app.queue_free();await process_frame;quit(failures)
