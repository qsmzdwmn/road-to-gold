extends SceneTree
const Repo=preload("res://scripts/persistence/prototype_save_repository.gd")
const Career=preload("res://scripts/career/career_data.gd")
const Session=preload("res://scripts/race/race_session.gd")
const Data=preload("res://scripts/race/competition_data.gd")
const PATH="user://tests/race-persistence.json"
var failures:=0
class FailedWriter extends "res://scripts/persistence/prototype_save_repository.gd":
	func _write(_data:Dictionary,_position:Vector3)->bool:
		error_message="Injected failed result write."
		return false
func check(ok:bool,message:String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func write(value:String):
	var f=FileAccess.open(PATH,FileAccess.WRITE);f.store_string(value);f.close()
func result(repo):
	var snapshot=repo.load_snapshot();var race=Session.new(repo.training_for(snapshot),snapshot.career.athlete_category,"hold",123,"Alex Gold");race.ready()
	while race.phase!="results":
		if race.phase=="running" and race.ticks==12:race.key(KEY_SPACE,true)
		race.step()
	return race.result(repo.snapshot_token(),repo.career_fingerprint(snapshot))
func _initialize():
	DirAccess.make_dir_recursive_absolute("user://tests")
	var repo=Repo.new(PATH);var career=Career.new();career.athlete.first_name="Alex";career.athlete.last_name="Gold"
	for category:String in ["male","female"]:
		DirAccess.remove_absolute(PATH);career.athlete_category=category;repo.save_career(career,Vector3.ZERO)
		var original=FileAccess.get_file_as_string(PATH);var race=result(repo);var token=repo.snapshot_token()
		check(not FailedWriter.new(PATH).commit_race(race,token,Vector3.ZERO).ok and FileAccess.get_file_as_string(PATH)==original,"failed result save leaves original schema 3 untouched")
		var saved=repo.commit_race(race,token,Vector3.ZERO)
		check(saved.ok and saved.new_pb and repo.load_snapshot().schema_version==4,"first finish migrates and stores a real PB "+category)
		check(FileAccess.get_file_as_string(repo.backup_path(original))==original,"first race migration retains verified original backup")
		var snapshot=repo.load_snapshot();var bytes=FileAccess.get_file_as_string(PATH)
		check(snapshot.competition.records.has(category+"/sprint_100m") and snapshot.competition.records.size()==1,"records are category scoped")
		check(repo.commit_race(race,token,Vector3.ZERO).ok and FileAccess.get_file_as_string(PATH)==bytes,"duplicate result retry is idempotent even with its original token")
		check(repo.save_position(Vector3(1,0,-2)) and repo.load_snapshot().competition==snapshot.competition,"sandbox saving preserves competition block")
		check(repo.commit_training("sprint_drills",repo.snapshot_token(),Vector3(1,0,-2)).ok and repo.load_snapshot().competition==snapshot.competition,"training preserves race results and PB")
		var stable_block=repo.load_snapshot().competition
		var slower=stable_block.latest.duplicate(true)
		for row:Dictionary in slower.rows:
			if row.id=="player":row.time_us+=30000
		slower.rows=Data.classify(slower.rows);slower.id=Data.result_id(slower)
		check(Data.apply(stable_block,slower).records==stable_block.records,"a slower valid finish cannot replace the PB")
		var faster=stable_block.latest.duplicate(true)
		for row:Dictionary in faster.rows:
			if row.id=="player":row.time_us-=10000
		faster.rows=Data.classify(faster.rows);faster.id=Data.result_id(faster)
		check(Data.apply(stable_block,faster).records[category+"/sprint_100m"].time_cs==stable_block.records[category+"/sprint_100m"].time_cs-1,"a faster official hundredth updates the PB")
		var dnf=stable_block.latest.duplicate(true)
		for row:Dictionary in dnf.rows:
			if row.id=="player":row.status="DNF";row.time_us=-1
		dnf.rows=Data.classify(dnf.rows);dnf.id=Data.result_id(dnf)
		check(Data.validate_result(dnf)=="" and Data.apply(stable_block,dnf).records==stable_block.records,"DNF records no time and preserves an existing PB")
		check(Data.apply({},dnf).records.is_empty(),"a first DNF cannot create a PB")
		var stale=result(repo);var before=repo.snapshot_token();repo.save_position(Vector3.ZERO)
		check(not repo.commit_race(stale,before,Vector3.ZERO).ok,"stale race cannot overwrite a newer slot")
		var newer=repo.load_snapshot();newer.competition.version=99;write(JSON.stringify(newer));var future=FileAccess.get_file_as_string(PATH)
		check(repo.load_snapshot().is_empty() and not repo.save_position(Vector3.ZERO) and not repo.commit_training("end_day",repo.snapshot_token(),Vector3.ZERO).ok and not repo.save_career(career,Vector3.ZERO,true) and FileAccess.get_file_as_string(PATH)==future,"future competition block protects every existing write path")
	var legacy=career.to_dict();legacy.erase("athlete_category");legacy.athlete.appearance.hairstyle=3
	var raw=JSON.stringify({"schema_version":2,"kind":"career","career":legacy,"position":[0,0]});write(raw)
	check(not repo.load_snapshot().career.has("athlete_category") and FileAccess.get_file_as_string(PATH)==raw,"legacy viewing does not infer category or migrate")
	check(repo.choose_race_category("female",repo.snapshot_token(),Vector3.ZERO).ok and repo.load_snapshot().career.athlete.appearance.hairstyle==3 and repo.load_snapshot().schema_version==4,"explicit legacy category selection preserves appearance and upgrades safely")
	check(FileAccess.get_file_as_string(repo.backup_path(raw))==raw and not repo.choose_race_category("male",repo.snapshot_token(),Vector3.ZERO).ok,"legacy category backup verified; selected categories cannot be switched")
	var block=repo.load_snapshot();block.competition={"version":1,"records":{},"latest":{}};write(JSON.stringify(block));check(repo.load_snapshot().is_empty(),"malformed competition data is not silently reset")
	print("RACE PERSISTENCE FAILURES: ",failures);quit(failures)
