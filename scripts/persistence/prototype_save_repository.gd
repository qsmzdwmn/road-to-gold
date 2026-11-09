extends RefCounted
## Deliberately isolated from the future CareerState save format.
const DEFAULT_PATH := "user://prototype_v1.json"
const MAX_BYTES := 4096
var path: String
var error_message := ""

func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path

func has_file() -> bool:
	return FileAccess.file_exists(path)

func load_position() -> Variant:
	error_message = ""
	if not has_file():
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		error_message = "Cannot open prototype save (%s)." % FileAccess.get_open_error()
		return null
	if file.get_length() > MAX_BYTES:
		error_message = "Prototype save is too large; it was left unchanged."
		return null
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _invalid()
	if parsed.get("schema_version") != 1 or parsed.get("kind") != "track_probe":
		return _invalid()
	var coords: Variant = parsed.get("position")
	if not coords is Array or coords.size() != 2:
		return _invalid()
	for value: Variant in coords:
		if not (value is float or value is int):
			return _invalid()
		if not is_finite(float(value)):
			return _invalid()
	if absf(float(coords[0])) > 3.3 or absf(float(coords[1])) > 12.0:
		return _invalid()
	return Vector3(float(coords[0]), 0.0, float(coords[1]))

func _invalid() -> Variant:
	error_message = "Invalid or unsupported prototype save; it was left unchanged."
	return null

func save_position(position: Vector3) -> bool:
	error_message = ""
	if not position.is_finite() or absf(position.x) > 3.3 or absf(position.z) > 12.0:
		error_message = "Position is outside the prototype track."
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error_message = "Save failed (%s). Session is unsaved." % FileAccess.get_open_error()
		return false
	file.store_string(JSON.stringify({
		"schema_version": 1, "kind": "track_probe",
		"position": [position.x, position.z],
	}))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		error_message = "Save write failed. Session is unsaved."
		return false
	var result := DirAccess.rename_absolute(path + ".tmp", path)
	if result != OK:
		error_message = "Save replacement failed (%s). Session is unsaved." % result
		return false
	return true
