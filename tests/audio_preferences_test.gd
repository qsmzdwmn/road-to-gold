extends SceneTree
const Prefs=preload("res://scripts/audio/audio_preferences.gd")
const PATH="user://tests/audio-settings.cfg"
var failures:=0
func check(ok:bool,message:String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func _initialize():
	DirAccess.make_dir_recursive_absolute("user://tests");DirAccess.remove_absolute(PATH)
	check(Prefs.load_preferences(PATH).values==Prefs.DEFAULTS,"missing audio preference has safe defaults")
	var values={"music":23,"sfx":71,"crowd":44,"mute_all":true}
	check(Prefs.save_preferences(values,PATH)==OK and Prefs.load_preferences(PATH).values==values,"independent volumes and mute round-trip")
	var bytes=FileAccess.get_file_as_string(PATH)
	for bad:Variant in [-1,101,NAN,INF,"50",true,null]:
		var invalid=values.duplicate();invalid.music=bad
		check(Prefs.save_preferences(invalid,PATH)==ERR_INVALID_PARAMETER and FileAccess.get_file_as_string(PATH)==bytes,"invalid volume cannot overwrite preferences: "+str(bad))
	var invalid=values.duplicate();invalid.mute_all=1
	check(not Prefs.valid(invalid),"mute must be boolean")
	check(Prefs.save_preferences(values,"user://missing-parent/audio.cfg")!=OK,"failed write is reported")
	var bad=ConfigFile.new();bad.set_value("audio","music","bad");bad.save(PATH)
	check(Prefs.load_preferences(PATH).values==Prefs.DEFAULTS,"invalid stored value falls back without conversion")
	bad.set_value("audio","version",2);bad.save(PATH);bytes=FileAccess.get_file_as_string(PATH)
	check(not Prefs.load_preferences(PATH).writable and Prefs.save_preferences(values,PATH)==ERR_UNAVAILABLE and FileAccess.get_file_as_string(PATH)==bytes,"future preference version is preserved")
	var file=FileAccess.open(PATH,FileAccess.WRITE);file.store_string("not a config [");file.close()
	check(Prefs.load_preferences(PATH).values==Prefs.DEFAULTS,"malformed preference file defaults safely")
	check(Prefs.PATH!="user://prototype_v1.json" and Prefs.PATH!="user://race_graphics.cfg","preference path separate from career and graphics")
	DirAccess.remove_absolute(PATH)
	print("AUDIO PREFERENCE FAILURES: ",failures);quit(failures)
