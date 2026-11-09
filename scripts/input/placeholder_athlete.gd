extends Node3D
const Controls = preload("res://scripts/input/placeholder_input.gd")
const SPEED := 4.0
var active := false

func _physics_process(delta: float) -> void:
	if not active:
		return
	var axis := Controls.direction()
	position += Vector3(axis.x, 0.0, axis.y) * SPEED * delta
	position.x = clampf(position.x, -3.3, 3.3)
	position.z = clampf(position.z, -12.0, 12.0)
