extends RefCounted
const STEP := 1.0/60.0
const DISTANCE := 100.0
const TIMEOUT_US := 40000000

static func limits(attributes:Dictionary,fatigue:int) -> Dictionary:
	var f:=float(fatigue)/100.0
	return {"top":(7.6+3.4*float(attributes.speed)/10000.0)*(1.0-0.08*f),"acceleration":(2.5+2.5*float(attributes.acceleration)/10000.0)*(1.0-0.12*f),"fade":0.06+0.12*(1.0-float(attributes.stamina)/10000.0)+0.06*f}

static func runner(id:String,name:String,lane:int,attributes:Dictionary,fatigue:int) -> Dictionary:
	return {"id":id,"name":name,"lane":lane,"attributes":attributes.duplicate(true),"fatigue":fatigue,"distance":0.0,"speed":0.0,"reaction_us":-1,"time_us":-1,"status":"RUN"}

static func step(runner_state:Dictionary,time:float,effort:float) -> void:
	if runner_state.status!="RUN" or runner_state.reaction_us<0:return
	var start:=maxf(time,float(runner_state.reaction_us)/1000000.0)
	var dt:=maxf(0.0,time+STEP-start)
	if dt<=0:return
	var cap:=limits(runner_state.attributes,runner_state.fatigue)
	var fade:float=clampf((runner_state.distance-60.0)/40.0,0.0,1.0)*cap.fade
	var next_speed:=move_toward(float(runner_state.speed),cap.top*(1.0-fade)*clampf(effort,0.0,1.0),cap.acceleration*dt)
	var previous:=float(runner_state.distance)
	var distance:=previous+(float(runner_state.speed)+next_speed)*0.5*dt
	runner_state.speed=next_speed
	runner_state.distance=minf(DISTANCE,distance)
	if distance>=DISTANCE:
		runner_state.status="FIN"
		runner_state.time_us=roundi((start+dt*(DISTANCE-previous)/(distance-previous))*1000000.0)
