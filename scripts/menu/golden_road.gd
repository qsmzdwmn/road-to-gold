extends Node3D
## Symbolic menu set only: fixed camera, unshaded geometry, no frame callbacks.
var camera: Camera3D

func _ready() -> void:
	var floor_material := _material("111a22")
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(160, 220)
	var floor_instance := MeshInstance3D.new()
	floor_instance.mesh = floor_mesh
	floor_instance.material_override = floor_material
	floor_instance.position = Vector3(0, -0.04, -65)
	add_child(floor_instance)
	# A shallow raised ribbon with bevels and a smooth S-curve, rather than a wedge.
	_strip(-2.2, 2.2, 0.12, _material("9c8052"))
	_strip(-2.2, -1.96, 0.13, _material("77603d"))
	_strip(1.96, 2.2, 0.13, _material("b69b68"))
	_strip(-2.2, -2.15, 0.145, _material("d0b579"))
	_strip(2.15, 2.2, 0.145, _material("d0b579"))
	_ridge(-112, Color("17232c"), 0)
	_ridge(-73, Color("142029"), 4)
	var sun := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.4
	sphere.height = 0.8
	sphere.radial_segments = 16
	sphere.rings = 8
	sphere.material = _material("e8cf96")
	sun.mesh = sphere
	sun.position = Vector3(_center(40), 0.55, -86)
	add_child(sun)
	# One tiny radial texture softens the distant light without bloom or fog.
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.78, 0.65, 0.42, 0.20), Color(0.78, 0.65, 0.42, 0)])
	var radial := GradientTexture2D.new()
	radial.width = 64
	radial.height = 64
	radial.gradient = gradient
	radial.fill = GradientTexture2D.FILL_RADIAL
	radial.fill_from = Vector2(0.5, 0.5)
	radial.fill_to = Vector2(1, 0.5)
	var halo_material := _material("ffffff")
	halo_material.albedo_texture = radial
	halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	halo_material.no_depth_test = true
	halo_material.render_priority = 1
	halo_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var quad := QuadMesh.new()
	quad.size = Vector2(20, 20)
	quad.material = halo_material
	var halo := MeshInstance3D.new()
	halo.mesh = quad
	halo.position = sun.position + Vector3(0, 0, -0.1)
	add_child(halo)
	camera = Camera3D.new()
	camera.position = Vector3(0, 5.5, 13)
	camera.fov = 48
	camera.far = 250
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("101820")
	camera.environment = environment
	add_child(camera)
	camera.look_at(Vector3(0, 1.4, -40))

func _center(index: int) -> float:
	var t := index / 40.0
	return lerpf(8.5, 7.5, t) + 7.5 * sin(t * TAU) * sin(t * PI)

func _strip(left: float, right: float, y: float, material: Material) -> void:
	var vertices := PackedVector3Array()
	for index in range(40):
		var near_z := 14.0 - index * 2.5
		var far_z := near_z - 2.5
		var a := Vector3(_center(index) + left, y, near_z)
		var b := Vector3(_center(index) + right, y, near_z)
		var c := Vector3(_center(index + 1) + left, y, far_z)
		var d := Vector3(_center(index + 1) + right, y, far_z)
		vertices.append_array(PackedVector3Array([a, c, b, b, c, d]))
	var colors := PackedColorArray()
	for vertex in vertices:
		var warmth := clampf((-vertex.z + 14.0) / 100.0, 0, 1)
		colors.append(Color.WHITE.lerp(Color("e2d4b6"), warmth * 0.25))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	add_child(instance)

func _material(hex: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material

func _ridge(z: float, color: Color, offset: float) -> void:
	# Abstract low horizon silhouettes: a few dark triangles, no scenery assets.
	var vertices := PackedVector3Array()
	var heights := [0.5, 2.2, 1.1, 3.4, 1.4, 2.5, 0.3]
	for index in range(heights.size() - 1):
		var x := -18.0 + index * 14.0 + offset
		var a := Vector3(x, -0.02, z)
		var b := Vector3(x + 14, -0.02, z)
		var c := Vector3(x, heights[index], z)
		var d := Vector3(x + 14, heights[index + 1], z)
		vertices.append_array(PackedVector3Array([a, c, b, b, c, d]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _material(color.to_html(false)))
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	add_child(instance)
