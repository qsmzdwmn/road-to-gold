extends RefCounted
## One validated local slot: v1 track probes remain readable; v2 adds career data.
const Career = preload("res://scripts/career/career_data.gd")
const DEFAULT_PATH := "user://prototype_v1.json"
const MAX_BYTES := 16384
var path: String
var error_message := ""

func _init(save_path: String = DEFAULT_PATH) -> void:
	path = save_path

func has_file() -> bool:
	return FileAccess.file_exists(path)

func load_snapshot() -> Dictionary:
	error_message = ""
	if not has_file():
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		error_message = "Cannot open saved progress (%s)." % FileAccess.get_open_error()
		return {}
	if file.get_length() > MAX_BYTES:
		return _invalid("Saved progress is too large; it was left unchanged.")
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return _invalid()
	if not ((parsed.get("schema_version") == 1 and parsed.get("kind") == "track_probe") or (parsed.get("schema_version") == 2 and parsed.get("kind") == "career")):
		return _invalid()
	var coords: Variant = parsed.get("position")
	if not coords is Array or coords.size() != 2:
		return _invalid()
	for value: Variant in coords:
		if not (value is float or value is int) or not is_finite(float(value)):
			return _invalid()
	if absf(float(coords[0])) > 3.30001 or absf(float(coords[1])) > 12.0:
		return _invalid()
	if parsed.schema_version == 2:
		var message: String = Career.validate(parsed.get("career"))
		if not message.is_empty():
			return _invalid(message + " Saved progress was left unchanged.")
	return parsed

func load_position() -> Variant:
	var snapshot := load_snapshot()
	if snapshot.is_empty():
		return null
	return Vector3(snapshot.position[0], 0, snapshot.position[1])

func _invalid(message := "Invalid or unsupported saved progress; it was left unchanged.") -> Dictionary:
	error_message = message
	return {}

func save_position(position: Vector3) -> bool:
	var snapshot := load_snapshot()
	if snapshot.is_empty():
		if has_file():
			return false # Never replace an unreadable/future save from the track screen.
		snapshot = {"schema_version": 1, "kind": "track_probe"}
	return _write(snapshot, position)

func save_career(career, position: Vector3, replace_authorized := false) -> bool:
	error_message = Career.validate(career.to_dict())
	if not error_message.is_empty():
		return false
	if has_file() and not replace_authorized:
		error_message = "Confirm before replacing saved progress."
		return false
	return _write({"schema_version": 2, "kind": "career", "career": career.to_dict()}, position)

func _write(snapshot: Dictionary, position: Vector3) -> bool:
	error_message = ""
	if not position.is_finite() or absf(position.x) > 3.30001 or absf(position.z) > 12.0:
		error_message = "Position is outside the prototype track."
		return false
	snapshot.position = [position.x, position.z]
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error_message = "Save failed (%s). Session is unsaved." % FileAccess.get_open_error()
		return false
	file.store_string(JSON.stringify(snapshot))
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
