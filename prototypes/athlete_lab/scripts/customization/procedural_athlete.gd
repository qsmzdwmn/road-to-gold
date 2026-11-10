extends "res://scripts/customization/fallback_athlete.gd"
## Compatibility adapter: appearance/save API unchanged; render original rigged assets.
const Male = preload("res://assets/athletes/male.glb")
const Female = preload("res://assets/athletes/female.glb")
@export var use_fallback := false
var asset_roots: Dictionary = {}
var asset_meshes: Dictionary = {}
var asset_skeletons: Dictionary = {}
var base_rests: Dictionary = {}
var base_binds: Dictionary = {}
var rendered: MeshInstance3D
var mesh_generation_count := 0
var active_asset: Node3D
var dark_material: StandardMaterial3D
var white_material: StandardMaterial3D
var face_material: StandardMaterial3D

func _ready() -> void:
	super._ready()
	dark_material = _material(Color("15232e"))
	white_material = _material(Color("e1dbcc"))
	face_material = _material(Color("302322"))
	apply_appearance(appearance, athlete_category)

func _prepare_asset(category: String) -> void:
	var node: Node3D = (Male if category == "male" else Female).instantiate()
	node.name = "NewGeneration_" + category
	add_child(node)
	asset_roots[category] = node
	var meshes: Array[MeshInstance3D] = []
	var skeleton: Skeleton3D = node.find_children("*", "Skeleton3D", true, false)[0]
	asset_skeletons[category] = skeleton
	var rests: Array[Transform3D] = []
	for index in range(skeleton.get_bone_count()): rests.append(skeleton.get_bone_global_rest(index))
	base_rests[category] = rests
	var binds: Dictionary = {}
	for child: Node in node.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = child
		meshes.append(mesh)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var poses: Array[Transform3D] = []
		mesh.skin = mesh.skin.duplicate()
		for index in range(mesh.skin.get_bind_count()): poses.append(mesh.skin.get_bind_pose(index))
		binds[mesh.get_instance_id()] = poses
		for surface in range(mesh.mesh.get_surface_count()):
			var imported: Material = mesh.mesh.surface_get_material(surface)
			var name_key := imported.resource_name.get_slice(".", 0)
			var materials := {"Skin": skin_material, "Hair": hair_material, "Kit": kit_material, "Dark": dark_material, "White": white_material, "Face": face_material}
			mesh.set_surface_override_material(surface, materials[name_key])
	asset_meshes[category] = meshes
	base_binds[category] = binds
	mesh_generation_count += 1

func apply_appearance(data, category := "") -> void:
	# The original named parts remain meaningful diagnostic bounds and style markers.
	super.apply_appearance(data, category)
	if not is_node_ready() or dark_material == null: return
	for node: Node3D in asset_roots.values(): node.hide()
	active_asset = null
	for part: MeshInstance3D in parts.values(): part.layers = 1
	if use_fallback or not Category.valid(category): return
	if not asset_roots.has(category): _prepare_asset(category)
	active_asset = asset_roots[category]
	active_asset.show()
	kit_material.albedo_color = Color("d7aa4e")
	# Source references do not render in addition to the imported character.
	for part: MeshInstance3D in parts.values(): part.layers = 0
	var build := clampf(pow(data.weight / 75.0, 0.35), 0.82, 1.26)
	for mesh: MeshInstance3D in asset_meshes[category]:
		var mesh_name := String(mesh.name)
		mesh.visible = not mesh_name.begins_with("Hair_") or mesh_name.begins_with(["Hair_None", "Hair_Cropped", "Hair_Curls", "Hair_Ponytail"][data.hairstyle])
		if not mesh_name.begins_with("Hair_"): rendered = mesh
		for index in range(mesh.mesh.get_blend_shape_count()):
			match String(mesh.mesh.get_blend_shape_name(index)):
				"Build": mesh.set_blend_shape_value(index, (build - 1.0) / 0.26)
				"Shoulders": mesh.set_blend_shape_value(index, (data.shoulders - 1.0) / 0.3)
				"Legs": mesh.set_blend_shape_value(index, (data.legs - 1.0) / 0.15)
	_fit_skeleton(category, data, build)

func _deform(point: Vector3, data, build: float) -> Vector3:
	var bulk := (build - 1.0) * clampf((1.54 - point.y) / 0.12, 0, 1)
	var shoulders: float = (data.shoulders - 1.0) * clampf((point.y - 0.95) / 0.30, 0, 1) * clampf((1.55 - point.y) / 0.1, 0, 1)
	return Vector3(point.x * (1.0 + bulk + shoulders), point.y * data.legs if point.y < 0.92 else point.y + 0.92 * (data.legs - 1.0), point.z * (1.0 + bulk))

func _fit_skeleton(category: String, data, build: float) -> void:
	var skeleton: Skeleton3D = asset_skeletons[category]
	var global_rests: Array[Transform3D] = []
	for rest: Transform3D in base_rests[category]:
		rest.origin = _deform(rest.origin, data, build)
		global_rests.append(rest)
	for index in range(skeleton.get_bone_count()):
		var parent := skeleton.get_bone_parent(index)
		var rest: Transform3D = global_rests[parent].affine_inverse() * global_rests[index] if parent >= 0 else global_rests[index]
		skeleton.set_bone_rest(index, rest)
		# Imported pose defaults carry the original rest; align the static pose too.
		skeleton.set_bone_pose_position(index, rest.origin)
		skeleton.set_bone_pose_rotation(index, rest.basis.get_rotation_quaternion())
		skeleton.set_bone_pose_scale(index, rest.basis.get_scale())
	for mesh: MeshInstance3D in asset_meshes[category]:
		for index in range(mesh.skin.get_bind_count()):
			var bone := mesh.skin.get_bind_bone(index)
			if bone < 0: bone = skeleton.find_bone(mesh.skin.get_bind_name(index))
			var original: Transform3D = base_binds[category][mesh.get_instance_id()][index]
			mesh.skin.set_bind_pose(index, original * base_rests[category][bone] * global_rests[bone].affine_inverse())

func geometry_stats() -> Dictionary:
	var triangles := 0
	var surfaces := 0
	if active_asset != null:
		for mesh: MeshInstance3D in asset_meshes[athlete_category]:
			if not mesh.visible: continue
			for surface in range(mesh.mesh.get_surface_count()):
				triangles += mesh.mesh.surface_get_array_index_len(surface) / 3
				surfaces += 1
	else:
		for part: MeshInstance3D in parts.values():
			if not part.visible: continue
			for surface in range(part.mesh.get_surface_count()):
				triangles += part.mesh.surface_get_array_index_len(surface) / 3
				surfaces += 1
	return {"triangles": triangles, "material_surfaces": surfaces, "mesh_rebuilds": mesh_generation_count, "bones": 22 if active_asset != null else 0}
