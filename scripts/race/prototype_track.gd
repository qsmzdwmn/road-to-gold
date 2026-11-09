extends Node3D
## Static procedural geometry. No race, physics, or career simulation.
func _ready() -> void:
	_box(Vector3(35, 0.12, 42), Vector3(0, -0.24, 0), Color("12272a"))
	_box(Vector3(8, 0.12, 28), Vector3(0, -0.12, 0), Color("824934"))
	for i in range(9):
		_box(Vector3(0.035, 0.015, 28), Vector3(i - 4.0, -0.047, 0), Color("e4dac8"))
	for z in [-12.8, 12.8]:
		_box(Vector3(8, 0.02, 0.14), Vector3(0, -0.04, z), Color("f2cb66"))

func _box(size: Vector3, at: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	instance.mesh = mesh
	instance.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	instance.material_override = material
	add_child(instance)
