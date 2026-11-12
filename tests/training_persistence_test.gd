extends SceneTree
const Repo=preload("res://scripts/persistence/prototype_save_repository.gd")
const Career=preload("res://scripts/career/career_data.gd")
const Rules=preload("res://scripts/training/training_service.gd")
const PATH="user://tests/training-persistence.json"
var failures:=0
class FailedWriter extends "res://scripts/persistence/prototype_save_repository.gd":
	func _write(_snapshot:Dictionary,_position:Vector3)->bool:
		error_message="Injected write failure."
		return false
class FailedBackup extends "res://scripts/persistence/prototype_save_repository.gd":
	func _backup(_original:String)->bool:
		error_message="Injected backup failure."
		return false
func check(ok:bool,message:String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func write(value:String):
	var f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(value);f.close()
func _initialize():
	DirAccess.make_dir_recursive_absolute("user://tests")
	var repo=Repo.new(PATH)
	var career=Career.new();career.athlete.first_name="Alex";career.athlete.last_name="Gold";career.athlete_category="male"
	for schema:int in [2,3]:
		var c=career.to_dict()
		if schema==2:c.erase("athlete_category");c.athlete.appearance.hairstyle=3
		var original=JSON.stringify({"schema_version":schema,"kind":"career","position":[0,0],"career":c})
		write(original)
		check(repo.load_snapshot().schema_version==schema and FileAccess.get_file_as_string(PATH)==original,"legacy read is byte preserving schema %d" % schema)
		var token=repo.snapshot_token();var preview=Rules.calculate(repo.training_for(repo.load_snapshot()),"sprint_drills")
		var result=repo.commit_training("sprint_drills",token,Vector3.ZERO)
		check(result.ok and result.after==preview.after,"migration and action match preview schema %d" % schema)
		var migrated=repo.load_snapshot()
		check(migrated.schema_version==4 and migrated.career==JSON.parse_string(original).career and migrated.training.attributes.speed==5060,"schema 4 preserves complete career and original category absence")
		check(FileAccess.get_file_as_string(repo.backup_path(original))==original,"original backup is byte-identical and verified")
		check(not repo.commit_training("sprint_drills",token,Vector3.ZERO).ok and repo.load_snapshot().training.actions_used==1,"duplicate/stale token cannot repeat action")
		check(repo.save_position(Vector3(1,0,-2)) and repo.load_snapshot().training==migrated.training,"track position save preserves training exactly")
		check(Repo.new(PATH).load_snapshot().training==migrated.training,"new repository reload keeps schema 4 progress")
		write(original)
		check(not FailedBackup.new(PATH).commit_training("start_practice",repo.snapshot_token(),Vector3.ZERO).ok and FileAccess.get_file_as_string(PATH)==original,"backup failure aborts migration")
		check(not FailedWriter.new(PATH).commit_training("start_practice",repo.snapshot_token(),Vector3.ZERO).ok and FileAccess.get_file_as_string(PATH)==original,"write failure leaves authoritative save unchanged")
	for broken:String in ['{"schema_version":99}','{"schema_version":4,"kind":"career"}','not json']:
		write(broken);check(not repo.commit_training("sprint_drills",repo.snapshot_token(),Vector3.ZERO).ok and not repo.save_position(Vector3.ZERO) and not repo.save_career(career,Vector3.ZERO,true) and FileAccess.get_file_as_string(PATH)==broken,"incompatible/malformed save protected across every write path")
	write(JSON.stringify({"schema_version":1,"kind":"track_probe","position":[0,0]}))
	check(not repo.commit_training("sprint_drills",repo.snapshot_token(),Vector3.ZERO).ok and repo.load_snapshot().schema_version==1,"position-only save never acquires invented athlete/training")
	var valid_career=career.to_dict()
	for bad_field:String in ["rules_version","day","actions_used","fatigue","recovery_used","revision","attributes"]:
		var bad_training=preload("res://scripts/training/training_state.gd").initial()
		bad_training[bad_field]=99 if bad_field=="rules_version" else "invalid"
		var raw=JSON.stringify({"schema_version":4,"kind":"career","position":[0,0],"career":valid_career,"training":bad_training});write(raw)
		check(repo.load_snapshot().is_empty() and not repo.commit_training("end_day",repo.snapshot_token(),Vector3.ZERO).ok and not repo.save_position(Vector3.ZERO) and not repo.save_career(career,Vector3.ZERO,true) and FileAccess.get_file_as_string(PATH)==raw,"malformed/future schema 4 field protected: "+bad_field)
	var large={"schema_version":3,"kind":"career","career":career.to_dict(),"position":[0,0],"preserved_extra":""}
	large.preserved_extra="x".repeat(Repo.MAX_BYTES-JSON.stringify(large).to_utf8_buffer().size()-50)
	var large_bytes=JSON.stringify(large);write(large_bytes)
	check(not repo.load_snapshot().is_empty() and not repo.commit_training("sprint_drills",repo.snapshot_token(),Vector3.ZERO).ok and FileAccess.get_file_as_string(PATH)==large_bytes and not repo.load_snapshot().is_empty(),"migration cannot enlarge a valid legacy save beyond the existing reader limit")
	print("TRAINING PERSISTENCE FAILURES: ",failures);quit(failures)
