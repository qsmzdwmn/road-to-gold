extends Node3D
## Cosmetic geometry only. Never changes movement speed or collision bounds.
const Geometry = preload("res://scripts/customization/athlete_mesh_builder.gd")
const Category = preload("res://scripts/data/athlete_category.gd")
const Appearance = preload("res://scripts/data/appearance_data.gd")
var athlete_category := ""
var appearance = Appearance.new()
var parts: Dictionary = {}
var skin_material: StandardMaterial3D
var hair_material: StandardMaterial3D
var kit_material: StandardMaterial3D
const DETAILS := ["neck", "left_shoulder", "right_shoulder", "left_hand", "right_hand", "left_foot", "right_foot"]

func _ready() -> void:
	skin_material = _material(Color(Appearance.SKIN_COLORS[appearance.skin]))
	hair_material = _material(Color(Appearance.HAIR_COLORS[appearance.hair_color]))
	kit_material = _material(Color("f2b83b"))
	var dark := _material(Color("121f2b"))
	for key: String in ["torso", "shorts", "left_leg", "right_leg", "left_arm", "right_arm", "left_hand", "right_hand", "left_foot", "right_foot"]:
		var part := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE
		mesh.material = kit_material if key == "torso" else (dark if key in ["shorts", "left_foot", "right_foot"] else skin_material)
		part.mesh = mesh
		parts[key] = part
		add_child(part)
	for key: String in ["head", "hair", "curl_left", "curl_right", "tail", "neck", "left_shoulder", "right_shoulder"]:
		var part := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 8
		mesh.rings = 4
		mesh.material = skin_material if key in ["head", "neck"] else (kit_material if "shoulder" in key else hair_material)
		part.mesh = mesh
		parts[key] = part
		add_child(part)
	_setup_evolution(dark)
	apply_appearance(appearance, athlete_category)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material

func _part(key: String, dimensions: Vector3, at: Vector3) -> void:
	parts[key].scale = dimensions
	parts[key].position = at

func _legacy_appearance(data, category := "") -> void:
	appearance = data
	athlete_category = category
	if not is_node_ready():
		return
	skin_material.albedo_color = Color(Appearance.SKIN_COLORS[data.skin])
	hair_material.albedo_color = Color(Appearance.HAIR_COLORS[data.hair_color])
	var stature: float = data.height / 180.0
	var build: float = clampf(pow(data.weight / 75.0, 0.35), 0.82, 1.26)
	var profile: Dictionary = Category.PROFILES.get(athlete_category, Category.PROFILES[""])
	var base_width: float = 0.48 * build * data.shoulders
	var width: float = base_width * profile.shoulders
	var hips: float = base_width * profile.hips
	var leg: float = 0.72 * data.legs
	_part("torso", Vector3(width, 0.65, 0.3 * build), Vector3(0, leg + 0.38, 0))
	_part("shorts", Vector3(hips, 0.22, 0.31 * build), Vector3(0, leg + 0.03, 0))
	for side: float in [-1.0, 1.0]:
		_part("left_leg" if side < 0 else "right_leg", Vector3(0.15 * build, leg, 0.18 * build), Vector3(side * hips * (0.27 / 0.86), leg * 0.5, 0))
		_part("left_arm" if side < 0 else "right_arm", Vector3(0.14 * build, 0.65, 0.17), Vector3(side * (width * 0.5 + 0.09), leg + 0.31, 0))
	var head_y: float = leg + 0.93
	_part("head", Vector3(0.38, 0.4, 0.38), Vector3(0, head_y, 0))
	_part("hair", Vector3(0.4, 0.22, 0.4), Vector3(0, head_y + 0.15, 0.01))
	_part("curl_left", Vector3(0.24, 0.26, 0.32), Vector3(-0.12, head_y + 0.18, 0))
	_part("curl_right", Vector3(0.24, 0.26, 0.32), Vector3(0.12, head_y + 0.18, 0))
	_part("tail", Vector3(0.16, 0.5, 0.16), Vector3(0, head_y - 0.05, 0.25))
	# Retain the original neutral legacy model; refine both explicitly selected bases.
	var refined := Category.valid(category)
	kit_material.albedo_color = Color("c6a66b" if refined else "f2b83b")
	for key: String in DETAILS:
		parts[key].visible = refined
	if refined:
		_part("neck", Vector3(0.18, 0.22, 0.19), Vector3(0, leg + 0.76, 0))
		_part("head", Vector3(0.32, 0.37, 0.34), Vector3(0, head_y, 0))
		_part("hair", Vector3(0.34, 0.2, 0.35), Vector3(0, head_y + 0.14, 0.01))
		for side: float in [-1.0, 1.0]:
			var prefix := "left_" if side < 0 else "right_"
			_part(prefix + "shoulder", Vector3(0.22 * build, 0.24, 0.3 * build), Vector3(side * width * 0.43, leg + 0.58, 0))
			_part(prefix + "arm", Vector3(0.12 * build, 0.54, 0.15 * build), Vector3(side * (width * 0.5 + 0.07), leg + 0.23, 0))
			_part(prefix + "hand", Vector3(0.11 * build, 0.14, 0.15 * build), Vector3(side * (width * 0.5 + 0.07), leg - 0.1, 0))
			_part(prefix + "foot", Vector3(0.18 * build, 0.1, 0.3 * build), Vector3(side * hips * (0.27 / 0.86), 0.02, 0.05))
	parts.hair.visible = data.hairstyle != 0
	parts.curl_left.visible = data.hairstyle == 2
	parts.curl_right.visible = data.hairstyle == 2
	parts.tail.visible = data.hairstyle == 3
	scale = Vector3.ONE * stature

# Named construction parts retain stable dimensions/visibility for customization and
# diagnostics. Explicit categories render one batched mesh, not each source part.
var original_meshes: Dictionary = {}
var evolved_meshes: Dictionary = {}
var evolved_materials: Dictionary = {}
var rendered: MeshInstance3D
var geometry_signature := ""
var mesh_generation_count := 0
var face_material: StandardMaterial3D
var white_material: StandardMaterial3D

func _setup_evolution(dark: StandardMaterial3D) -> void:
	for key: String in parts:
		original_meshes[key] = parts[key].mesh
	face_material = _material(Color("292325"))
	white_material = _material(Color("eee9dc"))
	var oval := Geometry.oval()
	var head := Geometry.tapered([Vector3(-0.5, 0.22, 0.29), Vector3(-0.34, 0.36, 0.38), Vector3(-0.12, 0.47, 0.46), Vector3(0.12, 0.49, 0.49), Vector3(0.34, 0.43, 0.43), Vector3(0.48, 0.25, 0.25), Vector3(0.5, 0.05, 0.05)], 12)
	var small := Geometry.oval(8, 4)
	var neckline := TorusMesh.new()
	neckline.inner_radius = 0.4
	neckline.outer_radius = 0.5
	neckline.rings = 12
	neckline.ring_segments = 6
	var torso := Geometry.tapered([Vector3(-0.5, 0.40, 0.43), Vector3(-0.25, 0.39, 0.44), Vector3(0.12, 0.46, 0.48), Vector3(0.35, 0.49, 0.44), Vector3(0.46, 0.39, 0.35), Vector3(0.5, 0.19, 0.26)])
	var limb := Geometry.tapered([Vector3(-0.5, 0.34, 0.36), Vector3(-0.28, 0.41, 0.42), Vector3(0.12, 0.49, 0.49), Vector3(0.5, 0.44, 0.44)], 10)
	var shin := Geometry.tapered([Vector3(-0.5, 0.27, 0.3), Vector3(-0.1, 0.39, 0.40), Vector3(0.24, 0.5, 0.5), Vector3(0.5, 0.43, 0.45)], 10)
	var shorts := Geometry.tapered([Vector3(-0.5, 0.5, 0.47), Vector3(0.05, 0.48, 0.5), Vector3(0.5, 0.39, 0.43)])
	var brow := Geometry.tapered([Vector3(-0.5, 0.15, 0.35), Vector3(0.0, 0.5, 0.5), Vector3(0.5, 0.35, 0.35)], 6)
	for key: String in ["torso", "shorts", "head", "hair", "curl_left", "curl_right", "tail", "neck", "nose", "mouth", "left_shoulder", "right_shoulder", "left_arm", "right_arm", "left_forearm", "right_forearm", "left_hand", "right_hand", "left_leg", "right_leg", "left_shin", "right_shin", "left_knee", "right_knee", "left_foot", "right_foot", "left_sole", "right_sole", "left_eye", "right_eye", "left_pupil", "right_pupil", "left_brow", "right_brow", "left_ear", "right_ear", "left_short", "right_short", "collar", "left_lace", "right_lace", "left_elbow", "right_elbow", "left_wrist", "right_wrist", "left_ankle", "right_ankle"]:
		if not parts.has(key):
			var source := MeshInstance3D.new()
			source.name = key
			parts[key] = source
			add_child(source)
		var mesh: Mesh = small
		if key == "torso": mesh = torso
		elif key == "collar": mesh = neckline
		elif key == "shorts" or key.ends_with("_short"): mesh = shorts
		elif key.ends_with("_arm") or key.ends_with("_forearm") or key.ends_with("_leg"): mesh = limb
		elif key.ends_with("_shin"): mesh = shin
		elif key.ends_with("_brow"): mesh = brow
		elif key == "head": mesh = head
		elif key in ["hair", "tail"]: mesh = oval
		evolved_meshes[key] = mesh
		var material := skin_material
		if key in ["hair", "curl_left", "curl_right", "tail"]: material = hair_material
		elif key == "torso": material = kit_material
		elif key == "collar": material = dark
		elif key in ["shorts", "left_short", "right_short", "left_foot", "right_foot"]: material = dark
		elif key.ends_with("_eye") or key.ends_with("_sole") or key.ends_with("_lace"): material = white_material
		elif key.ends_with("_pupil") or key.ends_with("_brow") or key == "mouth": material = face_material
		evolved_materials[key] = material
	rendered = MeshInstance3D.new()
	rendered.name = "AthleteBatchedMesh"
	add_child(rendered)

func apply_appearance(data, category := "") -> void:
	appearance = data
	athlete_category = category
	if not is_node_ready(): return
	# Keep uncategorized legacy characters neutral; never guess a category.
	if not Category.valid(category):
		rendered.hide()
		geometry_signature = ""
		for key: String in parts:
			parts[key].visible = original_meshes.has(key)
			parts[key].layers = 1
			parts[key].rotation = Vector3.ZERO
			parts[key].material_override = null
			if original_meshes.has(key): parts[key].mesh = original_meshes[key]
		_legacy_appearance(data, category)
		return
	skin_material.albedo_color = Color(Appearance.SKIN_COLORS[data.skin])
	hair_material.albedo_color = Color(Appearance.HAIR_COLORS[data.hair_color])
	kit_material.albedo_color = Color("c9a65d")
	var signature := "%s/%d/%s/%s/%s" % [category, data.hairstyle, data.weight, data.shoulders, data.legs]
	scale = Vector3.ONE * (data.height / 180.0)
	rendered.show()
	if signature == geometry_signature: return
	geometry_signature = signature
	for key: String in parts:
		parts[key].mesh = evolved_meshes[key]
		parts[key].material_override = evolved_materials[key]
		parts[key].layers = 0
		parts[key].visible = true
		parts[key].rotation = Vector3.ZERO
	var build := clampf(pow(data.weight / 75.0, 0.35), 0.82, 1.26)
	var profile: Dictionary = Category.PROFILES[category]
	var width: float = 0.48 * build * data.shoulders * profile.shoulders
	var hips: float = 0.48 * build * profile.hips
	var leg: float = 0.78 * data.legs
	var torso_depth := 0.275 * build
	# Same sliders and bounds; subtle base waist/shoulder distinction only.
	var female := category == "female"
	var waist_factor := 0.92 if female else 1.0
	var torso_mesh := Geometry.tapered([Vector3(-0.5, 0.40 * waist_factor, 0.43), Vector3(-0.25, 0.39 * waist_factor, 0.44), Vector3(0.12, 0.46, 0.48), Vector3(0.35, 0.49, 0.44), Vector3(0.46, 0.39, 0.35), Vector3(0.5, 0.19, 0.26)])
	parts.torso.mesh = torso_mesh
	_part("torso", Vector3(width, 0.58, torso_depth), Vector3(0, leg + 0.38, 0))
	_part("shorts", Vector3(hips, 0.17, 0.29 * build), Vector3(0, leg + 0.045, 0))
	_part("neck", Vector3(0.15, 0.13, 0.15), Vector3(0, leg + 0.72, 0))
	var head_y := leg + 0.885
	_part("head", Vector3(0.25, 0.31, 0.268), Vector3(0, head_y, -0.005))
	_part("nose", Vector3(0.034, 0.05, 0.038), Vector3(0, head_y - 0.018, -0.137))
	_part("mouth", Vector3(0.047, 0.006, 0.005), Vector3(0, head_y - 0.064, -0.117))
	_part("collar", Vector3(0.18, 0.09, 0.16), Vector3(0, leg + 0.665, 0))
	for side: float in [-1.0, 1.0]:
		var prefix := "left_" if side < 0 else "right_"
		var x: float = side * hips * (0.27 / 0.86)
		_part(prefix + "short", Vector3(hips * 0.49, 0.19, 0.29 * build), Vector3(x, leg - 0.055, 0))
		_part(prefix + "leg", Vector3(0.195 * build, leg * 0.48, 0.215 * build), Vector3(x, leg * 0.72, 0.005))
		_part(prefix + "knee", Vector3(0.133 * build, 0.14, 0.15 * build), Vector3(x, leg * 0.46, -0.004))
		_part(prefix + "shin", Vector3(0.155 * build, leg * 0.43, 0.16 * build), Vector3(x, leg * 0.255, 0.008))
		_part(prefix + "foot", Vector3(0.165 * build, 0.11, 0.31 * build), Vector3(x, 0.065, -0.048))
		_part(prefix + "sole", Vector3(0.17 * build, 0.035, 0.315 * build), Vector3(x, 0.025, -0.048))
		_part(prefix + "lace", Vector3(0.095 * build, 0.018, 0.10), Vector3(x, 0.111, -0.075))
		var shoulder_x: float = side * width * 0.44
		_part(prefix + "shoulder", Vector3(0.15 * build, 0.175, 0.18 * build), Vector3(shoulder_x, leg + 0.59, 0))
		_part(prefix + "arm", Vector3(0.124 * build, 0.285, 0.14 * build), Vector3(side * (width * 0.50 + 0.024), leg + 0.41, 0))
		parts[prefix + "arm"].rotation.z = side * 0.12
		_part(prefix + "forearm", Vector3(0.10 * build, 0.265, 0.114 * build), Vector3(side * (width * 0.50 + 0.045), leg + 0.15, -0.012))
		_part(prefix + "hand", Vector3(0.078 * build, 0.125, 0.07 * build), Vector3(side * (width * 0.50 + 0.045), leg - 0.025, -0.018))
		_part(prefix + "elbow", Vector3(0.085 * build, 0.095, 0.10 * build), Vector3(side * (width * 0.50 + 0.04), leg + 0.277, -0.006))
		_part(prefix + "wrist", Vector3(0.061 * build, 0.07, 0.07 * build), Vector3(side * (width * 0.50 + 0.045), leg + 0.016, -0.018))
		_part(prefix + "ankle", Vector3(0.084 * build, 0.09, 0.095 * build), Vector3(x, 0.115, 0.008))
		_part(prefix + "ear", Vector3(0.043, 0.075, 0.043), Vector3(side * 0.123, head_y - 0.003, 0))
		_part(prefix + "eye", Vector3(0.037, 0.019, 0.008), Vector3(side * 0.050, head_y + 0.025, -0.126))
		_part(prefix + "pupil", Vector3(0.014, 0.016, 0.006), Vector3(side * 0.050, head_y + 0.025, -0.132))
		_part(prefix + "brow", Vector3(0.008, 0.044, 0.008), Vector3(side * 0.050, head_y + 0.050, -0.124))
		parts[prefix + "brow"].rotation.z = PI * 0.5 + side * 0.08
	_part("hair", Vector3(0.269, 0.135, 0.282), Vector3(0, head_y + 0.115, 0.012))
	_part("curl_left", Vector3(0.19, 0.14, 0.25), Vector3(-0.072, head_y + 0.13, 0.005))
	_part("curl_right", Vector3(0.19, 0.14, 0.25), Vector3(0.072, head_y + 0.13, 0.005))
	_part("tail", Vector3(0.095, 0.32, 0.105), Vector3(0, head_y - 0.015, 0.185))
	parts.tail.rotation.x = -0.18
	parts.hair.visible = data.hairstyle != 0
	parts.curl_left.visible = data.hairstyle == 2
	parts.curl_right.visible = data.hairstyle == 2
	parts.tail.visible = data.hairstyle == 3
	_batch_geometry()

func _batch_geometry() -> void:
	var mesh := ArrayMesh.new()
	var groups: Dictionary = {}
	for key: String in parts:
		if not parts[key].visible: continue
		var material: Material = evolved_materials[key]
		if not groups.has(material): groups[material] = SurfaceTool.new()
		groups[material].append_from(parts[key].mesh, 0, parts[key].transform)
	for material: Material in groups:
		groups[material].set_material(material)
		groups[material].commit(mesh)
	rendered.mesh = mesh
	mesh_generation_count += 1

func geometry_stats() -> Dictionary:
	var triangles := 0
	var surfaces := 0
	if rendered.visible and rendered.mesh != null:
		surfaces = rendered.mesh.get_surface_count()
		for surface in range(surfaces):
			triangles += rendered.mesh.surface_get_array_index_len(surface) / 3
	else:
		for part: MeshInstance3D in parts.values():
			if not part.visible: continue
			for surface in range(part.mesh.get_surface_count()):
				triangles += part.mesh.surface_get_array_index_len(surface) / 3
				surfaces += 1
	return {"triangles": triangles, "material_surfaces": surfaces, "mesh_rebuilds": mesh_generation_count}
