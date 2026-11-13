extends Node
## One app-owned mixer. All synthesis is offline; a maximum of seven voices.
signal preferences_changed
const Preferences=preload("res://scripts/audio/audio_preferences.gd")
const STREAMS={
	"music":preload("res://assets/audio/hub_music.ogg"),
	"crowd":preload("res://assets/audio/stadium_crowd.ogg"),
	"cheer":preload("res://assets/audio/crowd_finish.ogg"),
	"pb":preload("res://assets/audio/crowd_pb.ogg"),
	"pistol":preload("res://assets/audio/start_pistol.wav"),
	"left":preload("res://assets/audio/footstep_left.wav"),
	"right":preload("res://assets/audio/footstep_right.wav"),
	"finish":preload("res://assets/audio/finish.wav"),
	"navigation":preload("res://assets/audio/ui_navigation.wav"),
	"confirm":preload("res://assets/audio/ui_confirm.wav")}
const BUSES={"music":"Music","sfx":"Sound Effects","crowd":"Stadium Crowd"}
var preferences:Dictionary=Preferences.DEFAULTS.duplicate()
var preference_path:=Preferences.PATH
var notice:=""
var writable:=true
var unlocked:=false
var suspended:=false
var context:="silent"
var crowd_target:=0.0
var gains={"music":0.0,"crowd":0.0}
var players:Dictionary={}
var counts:Dictionary={}
var peak_voices:=0
var last_ui_ms:=-1000
var focus_callback

func _ready():
	var loaded=Preferences.load_preferences(preference_path)
	preferences=loaded.values;notice=loaded.notice;writable=loaded.writable
	for slot:String in ["music","crowd","cheer","pistol","footstep","finish","ui"]:
		var player=AudioStreamPlayer.new();player.name=slot.capitalize()
		player.bus="Music" if slot=="music" else ("Stadium Crowd" if slot in ["crowd","cheer"] else "Sound Effects")
		# Web's sample playback avoids GDScript mixing and single-thread stream latency.
		player.playback_type=AudioServer.PLAYBACK_TYPE_SAMPLE if OS.has_feature("web") else AudioServer.PLAYBACK_TYPE_STREAM
		add_child(player);players[slot]=player
	players.music.stream=STREAMS.music
	players.crowd.stream=STREAMS.crowd
	_apply_preferences()
	get_tree().node_added.connect(_node_added)
	_wire_tree(get_tree().root)
	if OS.has_feature("web"):
		focus_callback=JavaScriptBridge.create_callback(_web_focus)
		for event:String in ["visibilitychange","freeze","resume"]:JavaScriptBridge.get_interface("document").addEventListener(event,focus_callback)
		for event:String in ["blur","focus"]:JavaScriptBridge.get_interface("window").addEventListener(event,focus_callback)

func _wire_tree(node:Node):
	_wire_button(node)
	for child:Node in node.get_children():_wire_tree(child)
func _node_added(node:Node):
	_wire_button(node)
func _wire_button(node:Node):
	if not is_instance_valid(node) or not node is BaseButton or node.has_meta("audio_wired"):return
	node.set_meta("audio_wired",true)
	node.pressed.connect(_button_pressed.bind(node))
func _button_pressed(button:BaseButton):
	if button is CheckBox or button is CheckButton or button is OptionButton:ui_sound(false)
	else:ui_sound(button.text in ["Begin Career","Create Career","Confirm","Ready","Save & Menu"])

func _input(event:InputEvent):
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventScreenTouch and event.pressed):
		unlock()
func unlock():
	# Godot resumes its own Web AudioContext from the same trusted input event.
	# No second context, deferred unlock, queued one-shots or catch-up playback.
	unlocked=true
	if not OS.has_feature("web") or not bool(JavaScriptBridge.eval("document.hidden",true)):set_suspended(false)

func set_preference(key:String,value:Variant) -> Error:
	if not key in Preferences.DEFAULTS:return ERR_INVALID_PARAMETER
	var next=preferences.duplicate();next[key]=value
	if not Preferences.valid(next):return ERR_INVALID_PARAMETER
	# Immediate listening preview, with an honest failure notice if persistence fails.
	preferences=next;_apply_preferences()
	var error=Preferences.save_preferences(preferences,preference_path) if writable else ERR_UNAVAILABLE
	notice=("Saved locally." if not OS.has_feature("web") else "Saved in this browser. Keep the tab open briefly.") if error==OK else "Audio changed for this session. Could not save preferences."
	if error==OK and OS.has_feature("web") and not OS.is_userfs_persistent():notice="Audio changed, but browser storage is temporary. Preferences may be lost."
	preferences_changed.emit()
	return error

func _apply_preferences():
	for key:String in BUSES:
		var index=AudioServer.get_bus_index(BUSES[key])
		if index>=0:
			var value:float=float(preferences[key])/100.0
			AudioServer.set_bus_volume_db(index,linear_to_db(maxf(value,0.0001)))
			AudioServer.set_bus_mute(index,value==0)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"),preferences.mute_all)
	if preferences.mute_all:
		for player:AudioStreamPlayer in players.values():player.stop()

func set_context(value:String):
	if value==context:return
	context=value
	if value!="race":
		crowd_target=0.0
		for slot:String in ["cheer","pistol","footstep","finish"]:players[slot].stop()
func set_crowd(value:float):crowd_target=clampf(value,0.0,1.0) if context=="race" else 0.0
func cancel_race_sounds():
	for slot:String in ["cheer","pistol","footstep","finish"]:players[slot].stop()

func one_shot(slot:String,sound:String,gain:=1.0) -> bool:
	if not unlocked or suspended or preferences.mute_all:return false
	if not players.has(slot) or not STREAMS.has(sound):return false
	var player:AudioStreamPlayer=players[slot]
	var category="crowd" if slot=="cheer" else "sfx"
	if preferences[category]==0:return false
	player.stop();player.stream=STREAMS[sound];player.volume_db=linear_to_db(maxf(gain,0.0001));player.play()
	counts[sound]=counts.get(sound,0)+1
	peak_voices=maxi(peak_voices,active_voices())
	if sound not in ["left","right","navigation","confirm"]:print("AUDIO_EVENT ",JSON.stringify({"cue":sound,"count":counts[sound]}))
	return true
func ui_sound(confirm:=false):
	var now=Time.get_ticks_msec()
	if now-last_ui_ms<100:return
	last_ui_ms=now;one_shot("ui","confirm" if confirm else "navigation",0.65)
func set_suspended(value:bool):
	if suspended==value:return
	suspended=value
	if value:
		for player:AudioStreamPlayer in players.values():player.stop()
		gains={"music":0.0,"crowd":0.0}
func _notification(what:int):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:set_suspended(true)
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:set_suspended(false)
func _web_focus(_args:Array):
	if not _args.is_empty() and str(_args[0].type)=="freeze":
		set_suspended(true);return
	set_suspended(bool(JavaScriptBridge.eval("document.hidden || !document.hasFocus()",true)))
func _process(delta:float):
	for slot:String in ["music","crowd"]:
		var target:float=(0.65 if context=="hub" else 0.0) if slot=="music" else crowd_target
		if not unlocked or suspended or preferences.mute_all or preferences[slot]==0:target=0.0
		gains[slot]=lerpf(float(gains[slot]),target,1.0-exp(-minf(delta,0.1)*6.0))
		var player:AudioStreamPlayer=players[slot]
		if gains[slot]<0.001:player.stop()
		elif not suspended and unlocked and not preferences.mute_all and preferences[slot]>0:
			player.volume_db=linear_to_db(gains[slot])
			if not player.playing:player.play()
	peak_voices=maxi(peak_voices,active_voices())
func active_voices() -> int:
	var count:=0
	for player:AudioStreamPlayer in players.values():
		if player.playing:count+=1
	return count
func metrics() -> Dictionary:
	return {"unlocked":unlocked,"suspended":suspended,"context":context,"voices":active_voices(),"peak_voices":peak_voices,"counts":counts.duplicate(),"preferences":preferences.duplicate()}
func _exit_tree():
	if focus_callback!=null:
		for event:String in ["visibilitychange","freeze","resume"]:JavaScriptBridge.get_interface("document").removeEventListener(event,focus_callback)
		for event:String in ["blur","focus"]:JavaScriptBridge.get_interface("window").removeEventListener(event,focus_callback)
