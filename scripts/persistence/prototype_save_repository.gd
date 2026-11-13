extends RefCounted
## One validated local slot, schemas 1–4. Training belongs only to schema 4; legacy category absence is preserved.
const Career = preload("res://scripts/career/career_data.gd")
const TrainingState = preload("res://scripts/training/training_state.gd")
const Rules = preload("res://scripts/training/training_service.gd")
const Competition=preload("res://scripts/race/competition_data.gd")
const Category=preload("res://scripts/data/athlete_category.gd")
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
	var json := JSON.new()
	if json.parse(file.get_as_text())!=OK:return _invalid()
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		return _invalid()
	if not ((parsed.get("schema_version") == 1 and parsed.get("kind") == "track_probe") or ((parsed.get("schema_version")==2 or parsed.get("schema_version")==3 or parsed.get("schema_version")==4) and parsed.get("kind") == "career")):
		return _invalid()
	var coords: Variant = parsed.get("position")
	if not coords is Array or coords.size() != 2:
		return _invalid()
	for value: Variant in coords:
		if not (value is float or value is int) or not is_finite(float(value)):
			return _invalid()
	if absf(float(coords[0])) > 3.30001 or absf(float(coords[1])) > 12.0:
		return _invalid()
	if parsed.schema_version==2 or parsed.schema_version==3 or parsed.schema_version==4:
		var message: String = Career.validate(parsed.get("career"), parsed.schema_version == 3)
		if not message.is_empty():
			return _invalid(message + " Saved progress was left unchanged.")
	if parsed.schema_version==4:
		var training_error := TrainingState.validate(parsed.get("training"))
		if not training_error.is_empty():return _invalid(training_error+" Saved progress was left unchanged.")
		parsed.training=TrainingState.normalize(parsed.training)
	if parsed.has("competition"):
		if parsed.schema_version!=4:return _invalid("Competition data requires schema 4; saved progress was left unchanged.")
		var competition_error:=Competition.validate(parsed.competition,parsed.career.get("athlete_category",""))
		if not competition_error.is_empty():return _invalid(competition_error+" Saved progress was left unchanged.")
		parsed.competition=Competition.normalize_block(parsed.competition)
	return parsed

func load_position() -> Variant:
	var snapshot := load_snapshot()
	if snapshot.is_empty():
		return null
	return Vector3(snapshot.position[0], 0, snapshot.position[1])

func _invalid(message := "Invalid or unsupported saved progress; it was left unchanged.") -> Dictionary:
	error_message = message
	return {}

func save_position(position: Vector3, expected_token := "") -> bool:
	if not expected_token.is_empty() and snapshot_token()!=expected_token:
		error_message="Save failed: saved progress changed. Continue again before saving."
		return false
	var snapshot := load_snapshot()
	if snapshot.is_empty():
		if has_file():
			return false # Never replace an unreadable/future save from the track screen.
		snapshot = {"schema_version": 1, "kind": "track_probe"}
	return _write(snapshot, position)

func save_career(career, position: Vector3, replace_authorized := false) -> bool:
	error_message = Career.validate(career.to_dict(), true)
	if not error_message.is_empty():
		return false
	if has_file() and load_snapshot().is_empty():
		error_message="Invalid or incompatible saved progress cannot be replaced."
		return false
	if has_file() and not replace_authorized:
		error_message = "Confirm before replacing saved progress."
		return false
	return _write({"schema_version": 3, "kind": "career", "career": career.to_dict()}, position)

func _write(snapshot: Dictionary, position: Vector3) -> bool:
	error_message = ""
	if not position.is_finite() or absf(position.x) > 3.30001 or absf(position.z) > 12.0:
		error_message = "Position is outside the prototype track."
		return false
	snapshot.position = [position.x, position.z]
	var payload := JSON.stringify(snapshot)
	if payload.to_utf8_buffer().size()>MAX_BYTES:
		error_message="Save would exceed supported storage size. No progress was changed."
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		error_message = "Save failed (%s). Session is unsaved." % FileAccess.get_open_error()
		return false
	file.store_string(payload)
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

func snapshot_token() -> String:
	return FileAccess.get_file_as_string(path).sha256_text() if has_file() else ""

func training_for(snapshot: Dictionary) -> Dictionary:
	return snapshot.training.duplicate(true) if snapshot.get("schema_version")==4 else TrainingState.initial()

func backup_path(original: String) -> String:
	return path+".pre-training-"+original.sha256_text().substr(0,16)+".bak"

func _backup(original: String) -> bool:
	var target := backup_path(original)
	if FileAccess.file_exists(target):
		if FileAccess.get_file_as_string(target)==original:return true
		error_message="Original-save backup conflicts; no progress was changed."
		return false
	var file := FileAccess.open(target+".tmp",FileAccess.WRITE)
	if file==null:
		error_message="Cannot create original-save backup. No progress was changed."
		return false
	file.store_string(original);file.flush()
	var error := file.get_error();file.close()
	if error!=OK or FileAccess.get_file_as_string(target+".tmp")!=original or DirAccess.rename_absolute(target+".tmp",target)!=OK:
		error_message="Cannot verify original-save backup. No progress was changed."
		return false
	return true

func commit_training(id: String, expected_token: String, position: Vector3) -> Dictionary:
	var snapshot := load_snapshot()
	if snapshot.is_empty() or snapshot.get("kind")!="career":
		return {"ok":false,"error":"A valid saved career is required. "+error_message}
	var original := FileAccess.get_file_as_string(path)
	if expected_token.is_empty() or original.sha256_text()!=expected_token:
		return {"ok":false,"error":"Saved progress changed. Return to the menu and Continue before training."}
	var result := Rules.calculate(training_for(snapshot),id)
	if not result.ok:return result
	if not position.is_finite() or absf(position.x)>3.30001 or absf(position.z)>12.0:
		return {"ok":false,"error":"Invalid track position; no training was applied."}
	if snapshot.schema_version!=4 and not _backup(original):return {"ok":false,"error":error_message}
	# Recheck after backup; this is optimistic protection, not a multi-tab transaction.
	if snapshot_token()!=expected_token:return {"ok":false,"error":"Saved progress changed during preparation. No training was applied."}
	snapshot.schema_version=4
	snapshot.training=result.after
	if not _write(snapshot,position):return {"ok":false,"error":error_message}
	result.token=snapshot_token()
	return result

func career_fingerprint(snapshot:Dictionary) -> String:
	return JSON.stringify(Career.from_dict(snapshot.career).to_dict()).sha256_text()

func choose_race_category(category:String,expected_token:String,position:Vector3) -> Dictionary:
	var snapshot:=load_snapshot()
	if snapshot.is_empty() or snapshot.get("kind")!="career" or not Category.valid(category):return {"ok":false,"error":"A valid saved career and explicit category are required."}
	if snapshot.career.has("athlete_category"):return {"ok":false,"error":"This career already has an athlete category."}
	if expected_token.is_empty() or snapshot_token()!=expected_token:return {"ok":false,"error":"Saved progress changed. Continue again before selecting a category."}
	var original:=FileAccess.get_file_as_string(path)
	if not _backup(original):return {"ok":false,"error":error_message}
	if snapshot_token()!=expected_token:return {"ok":false,"error":"Saved progress changed during preparation."}
	if snapshot.schema_version!=4:snapshot.training=TrainingState.initial()
	snapshot.schema_version=4;snapshot.career.athlete_category=category
	if not _write(snapshot,position):return {"ok":false,"error":error_message}
	return {"ok":true,"token":snapshot_token()}

func commit_race(result:Dictionary,expected_token:String,position:Vector3) -> Dictionary:
	var snapshot:=load_snapshot()
	if snapshot.is_empty() or snapshot.get("kind")!="career":return {"ok":false,"error":"Saved career is unavailable or incompatible. "+error_message}
	var validation:=Competition.validate_result(result)
	if not validation.is_empty():return {"ok":false,"error":validation}
	if snapshot.career.get("athlete_category","")!=result.category or career_fingerprint(snapshot)!=result.career_fingerprint:return {"ok":false,"error":"Race result belongs to a different career/category."}
	if snapshot.has("competition") and snapshot.competition.latest.id==result.id:
		return {"ok":true,"duplicate":true,"token":snapshot_token(),"new_pb":false}
	if expected_token.is_empty() or snapshot_token()!=expected_token or result.source_token!=expected_token:return {"ok":false,"error":"Saved progress changed. This result cannot overwrite a newer save."}
	var previous:Dictionary=snapshot.get("competition",{})
	var next:=Competition.apply(previous,result)
	validation=Competition.validate(next,result.category)
	if not validation.is_empty():return {"ok":false,"error":validation}
	var original:=FileAccess.get_file_as_string(path)
	if snapshot.schema_version!=4:
		if not _backup(original):return {"ok":false,"error":error_message}
		snapshot.training=TrainingState.initial()
	if snapshot_token()!=expected_token:return {"ok":false,"error":"Saved progress changed during preparation."}
	var scope:=Category.competition_scope(result.category,Competition.EVENT)
	var new_pb:bool=next.records.has(scope) and (not previous.get("records",{}).has(scope) or next.records[scope].time_cs<previous.records[scope].time_cs)
	snapshot.schema_version=4;snapshot.competition=next
	if not _write(snapshot,position):return {"ok":false,"error":error_message}
	return {"ok":true,"duplicate":false,"token":snapshot_token(),"new_pb":new_pb}
