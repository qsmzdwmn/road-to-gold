extends RefCounted
## Reads presentation/simulation state; never mutates runners or timing.
var director
var phase:=""
var pistol_seen:=false
var finish_seen:=false
var pb_seen:=false
var gait_index:=-1
func _init(value):director=value
func reset():
	phase="";pistol_seen=false;finish_seen=false;pb_seen=false;gait_index=-1
	director.cancel_race_sounds();director.set_context("race");director.set_crowd(0.22)
func phase_changed(value:String):
	if phase==value:return
	var previous=phase;phase=value
	if value=="running" and previous=="set" and not pistol_seen:
		pistol_seen=true;director.one_shot("pistol","pistol",0.8)
	if value=="invalid":director.cancel_race_sounds()
	director.set_crowd({"preparation":0.22,"marks":0.16,"set":0.08,"running":0.38,"results":0.22}.get(value,0.0))
func player_state(runner:Dictionary,gait_phase:float):
	if phase!="running":gait_index=-1;return
	director.set_crowd(lerpf(0.38,0.80,clampf((float(runner.distance)-75.0)/25.0,0.0,1.0)))
	if runner.status=="FIN":
		if not finish_seen:
			finish_seen=true;director.players.footstep.stop();director.one_shot("finish","finish",0.65);director.one_shot("cheer","cheer",0.65)
		return
	var current=int(floor(gait_phase/PI))
	if runner.status=="RUN" and runner.speed>0.5 and gait_index>=0 and current!=gait_index:
		director.one_shot("footstep","left" if current%2==0 else "right",clampf(float(runner.speed)/10.0,0.15,0.65))
	gait_index=current
func saved_result(ok:bool,new_pb:bool):
	if phase!="results" or not ok or not new_pb or pb_seen:return
	pb_seen=true;director.one_shot("cheer","pb",0.75)
func close():
	phase="";director.cancel_race_sounds();director.set_crowd(0.0)
