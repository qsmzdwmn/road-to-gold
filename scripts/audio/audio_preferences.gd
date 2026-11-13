extends RefCounted
## Preferences only: never opens a career or graphics save.
const PATH = "user://audio_settings.cfg"
const DEFAULTS = {"music":35, "sfx":65, "crowd":30, "mute_all":false}
const VOLUMES = ["music", "sfx", "crowd"]

static func valid(values:Dictionary) -> bool:
	if values.size()!=4 or not values.get("mute_all") is bool:return false
	for key:String in VOLUMES:
		var value:Variant=values.get(key)
		if not (value is int or value is float):return false
		if not is_finite(float(value)) or value<0 or value>100:return false
	return true

static func load_preferences(path:=PATH) -> Dictionary:
	var config=ConfigFile.new()
	var error=config.load(path)
	if error!=OK:
		return {"values":DEFAULTS.duplicate(),"writable":true,"notice":"" if error==ERR_FILE_NOT_FOUND else "Audio preferences could not be read. Defaults are active."}
	if config.get_value("audio","version",1)!=1:
		return {"values":DEFAULTS.duplicate(),"writable":false,"notice":"Unsupported audio preference version. File preserved."}
	var values:Dictionary={}
	for key:String in DEFAULTS:values[key]=config.get_value("audio",key,DEFAULTS[key])
	if not valid(values):return {"values":DEFAULTS.duplicate(),"writable":true,"notice":"Invalid audio preferences. Defaults are active."}
	return {"values":values,"writable":true,"notice":""}

static func save_preferences(values:Dictionary,path:=PATH) -> Error:
	if not valid(values):return ERR_INVALID_PARAMETER
	if not load_preferences(path).writable:return ERR_UNAVAILABLE
	var config=ConfigFile.new();config.set_value("audio","version",1)
	for key:String in DEFAULTS:config.set_value("audio",key,values[key])
	var temporary=path+".tmp"
	var result=config.save(temporary)
	if result!=OK:return result
	result=DirAccess.rename_absolute(temporary,path)
	if result!=OK:DirAccess.remove_absolute(temporary)
	return result
