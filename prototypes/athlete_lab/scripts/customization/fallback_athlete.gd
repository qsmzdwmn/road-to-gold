extends Node3D
## Cosmetic geometry only. Never changes movement speed or collision bounds.
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
	apply_appearance(appearance, athlete_category)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material

func _part(key: String, dimensions: Vector3, at: Vector3) -> void:
	parts[key].scale = dimensions
	parts[key].position = at

func apply_appearance(data, category := "") -> void:
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
