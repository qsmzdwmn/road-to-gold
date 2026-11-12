extends RefCounted
## Race-only preferences live outside career storage and never migrate or write a career.
const PATH="user://race_graphics.cfg"
const PERFORMANCE="performance"
const ENHANCED="enhanced"
static func valid(mode:Variant)->bool:return mode is String and mode in [PERFORMANCE,ENHANCED]
static func load_mode(path:=PATH)->String:
	var config=ConfigFile.new()
	if config.load(path)!=OK:return PERFORMANCE
	var mode=config.get_value("race","quality",PERFORMANCE)
	return mode if valid(mode) else PERFORMANCE
static func save_mode(mode:String,path:=PATH)->Error:
	if not valid(mode):return ERR_INVALID_PARAMETER
	var config=ConfigFile.new();config.set_value("race","quality",mode)
	return config.save(path)
static func apply_viewport(viewport:SubViewport,mode:String):
	viewport.msaa_3d=Viewport.MSAA_2X if mode==ENHANCED else Viewport.MSAA_DISABLED
