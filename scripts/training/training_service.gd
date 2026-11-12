extends RefCounted
const State = preload("res://scripts/training/training_state.gd")
const ACTIVITIES := {
	"sprint_drills":{"title":"Sprint Drills","gains":{"speed":60,"acceleration":20},"fatigue":22},
	"start_practice":{"title":"Start Practice","gains":{"acceleration":60,"speed":10},"fatigue":18},
	"endurance_run":{"title":"Endurance Run","gains":{"stamina":60,"recovery":10},"fatigue":26},
	"recovery_session":{"title":"Recovery Session","gains":{"recovery":20},"fatigue":0}
}

static func display(value: int) -> String:
	return "%.2f" % (float(value)/100.0)

@warning_ignore("integer_division")
static func gain(base: int, value: int, fatigue_percent: int) -> int:
	return int((base*maxi(1000,10000-value)*fatigue_percent+250000)/500000)

@warning_ignore("integer_division")
static func calculate(state: Dictionary, id: String) -> Dictionary:
	var error := State.validate(state)
	if not error.is_empty():return {"ok":false,"error":error}
	var next := state.duplicate(true)
	if state.revision>=9007199254740991:return {"ok":false,"error":"Training revision exceeds supported storage precision."}
	if id=="end_day":
		if state.day>=9007199254740991:return {"ok":false,"error":"Training day exceeds supported storage precision."}
		next.day=int(state.day)+1
		next.fatigue=maxi(0,int(state.fatigue)-8-int(state.attributes.recovery)/1000)
		next.actions_used=0
		next.recovery_used=false
	else:
		if not ACTIVITIES.has(id):return {"ok":false,"error":"Unknown activity."}
		if state.actions_used>=2:return {"ok":false,"error":"No actions remaining. End Training Day to continue."}
		var recovery := id=="recovery_session"
		if recovery and (state.recovery_used or state.fatigue<20):return {"ok":false,"error":"Recovery needs at least 20 fatigue and is available once per training day."}
		if not recovery and state.fatigue>=80:return {"ok":false,"error":"Fatigue is 80 or higher. Recover or end the training day first."}
		var multiplier := 100 if recovery or state.fatigue<30 else (75 if state.fatigue<60 else 50)
		var useful := false
		for attribute: String in ACTIVITIES[id].gains:
			var value := int(state.attributes[attribute])
			next.attributes[attribute]=mini(10000,value+gain(ACTIVITIES[id].gains[attribute],value,multiplier))
			useful=useful or next.attributes[attribute]>value
		if not recovery and not useful:return {"ok":false,"error":"The attributes trained by this activity are already at their maximum."}
		next.fatigue=maxi(0,int(state.fatigue)-30-int(state.attributes.recovery)/1000) if recovery else mini(100,int(state.fatigue)+int(ACTIVITIES[id].fatigue))
		next.actions_used=int(state.actions_used)+1
		next.recovery_used=state.recovery_used or recovery
	next.revision=int(state.revision)+1
	var lines: PackedStringArray=[]
	for attribute: String in State.ATTRIBUTES:
		if next.attributes[attribute]!=state.attributes[attribute]:lines.append("%s: %s -> %s" % [attribute.capitalize(),display(state.attributes[attribute]),display(next.attributes[attribute])])
	lines.append("Fatigue: %d -> %d / 100" % [state.fatigue,next.fatigue])
	lines.append("Training Day: %d -> %d · Actions remaining: %d -> %d" % [state.day,next.day,2-int(state.actions_used),2-int(next.actions_used)])
	return {"ok":true,"id":id,"before":state.duplicate(true),"after":next,"summary":"\n".join(lines)}
