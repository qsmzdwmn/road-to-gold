extends Node3D
## Static, texture-free presentation set. No physics, shadows or frame callbacks.
var camera: Camera3D

func _ready() -> void:
	var midnight := _material("101820")
	var graphite := _material("28333b")
	var metal := _material("35424a")
	var gold := _material("c6a66b")
	_box(Vector3(8, 0.12, 7), Vector3(0, -0.1, -0.5), midnight)
	_box(Vector3(8, 3.4, 0.12), Vector3(0, 1.6, -1.65), midnight)
	_box(Vector3(0.12, 3.4, 6), Vector3(-3.4, 1.6, 0), graphite)
	for x: float in [-2.4, -1.6, -0.8, 0.8, 1.6, 2.4]:
		_box(Vector3(0.72, 2.5, 0.45), Vector3(x, 1.22, -1.35), graphite)
		_box(Vector3(0.018, 0.2, 0.025), Vector3(x + 0.23, 1.25, -1.11), gold)
		for y: float in [2.15, 2.22, 2.29]:
			_box(Vector3(0.32, 0.018, 0.015), Vector3(x, y, -1.115), metal)
	_box(Vector3(1.65, 0.08, 0.5), Vector3(-1.8, 0.45, 0.15), graphite)
	for x: float in [-2.4, -1.2]:
		_box(Vector3(0.08, 0.42, 0.35), Vector3(x, 0.21, 0.15), metal)
	var glow := _material("e9e8e3")
	glow.emission_enabled = true
	glow.emission = Color("e9e8e3")
	_box(Vector3(3.7, 0.025, 0.18), Vector3(0, 2.9, -0.8), glow)
	# A flat contact disc gives depth without a shadow map or transparent layers.
	var contact := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.48
	disc.bottom_radius = 0.48
	disc.height = 0.005
	disc.radial_segments = 16
	disc.material = _material("090e13")
	contact.mesh = disc
	contact.position.y = -0.033
	add_child(contact)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("101820")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d7dfe5")
	environment.ambient_light_energy = 0.6
	environment_node.environment = environment
	add_child(environment_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -25, 0)
	light.light_energy = 0.9
	light.shadow_enabled = false
	add_child(light)
	camera = Camera3D.new()
	camera.position = Vector3(1.8, 1.65, 5)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	camera.size = 3.3
	add_child(camera)
	camera.look_at(Vector3(0, 1.2, 0))

func _material(hex: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(hex)
	material.roughness = 1.0
	return material

func _box(dimensions: Vector3, at: Vector3, material: Material) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.material = material
	instance.mesh = mesh
	instance.position = at
	add_child(instance)
