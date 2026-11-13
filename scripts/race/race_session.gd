extends RefCounted
const Physics=preload("res://scripts/race/sprint_physics.gd")
const InputState=preload("res://scripts/race/sprint_input.gd")
const Roster=preload("res://scripts/race/race_roster.gd")
const Data=preload("res://scripts/race/competition_data.gd")
var phase:="preparation"
var message:=""
var ticks:=0
var phase_ticks:=0
var set_ticks:=90
var seed:=1
var category:="male"
var mode:="hold"
var runners:Array=[]
var ai:Array=[]
var controls=InputState.new()

func _init(profile:Dictionary,selected_category:String,selected_mode:String,start_seed:int,player_name:String):
	category=selected_category;mode=selected_mode;seed=start_seed;controls.mode=mode
	var random=RandomNumberGenerator.new();random.seed=seed;set_ticks=random.randi_range(60,132)
	runners.append(Physics.runner("player",player_name,3,profile.attributes,int(profile.fatigue)))
	ai=Roster.entries(category)
	for entry:Dictionary in ai:
		var runner=Physics.runner(entry.id,entry.name,entry.lane,entry.attributes,0)
		runner.reaction_us=entry.reaction_us;runners.append(runner)

func ready() -> void:
	if phase!="preparation":return
	if not category in ["male","female"]:phase="invalid";message="Choose an athlete category explicitly before racing.";return
	phase="marks";phase_ticks=0

func key(keycode:int,pressed:bool,echo:bool=false) -> void:
	var accepted:=controls.event(keycode,pressed,echo,float(ticks)*Physics.STEP)
	if not accepted:return
	if phase=="marks" or phase=="set":
		phase="invalid";message="False start — attempt invalid. No time or Personal Best recorded."
	elif phase=="running" and runners[0].reaction_us<0:runners[0].reaction_us=roundi(float(ticks)*Physics.STEP*1000000.0)

func interrupt(reason:="Race interrupted. Retry for a valid attempt.") -> void:
	if phase in ["marks","set","running"]:phase="invalid";message=reason

func step() -> void:
	if phase=="marks" or phase=="set":
		phase_ticks+=1
		if phase=="marks" and phase_ticks>=90:phase="set";phase_ticks=0
		elif phase=="set" and phase_ticks>=set_ticks:phase="running";phase_ticks=0;ticks=0
		return
	if phase!="running":return
	var time:=float(ticks)*Physics.STEP
	Physics.step(runners[0],time,controls.effort(time))
	for i in range(7):Physics.step(runners[i+1],time,float(ai[i].effort))
	ticks+=1
	var finished:=true
	for runner:Dictionary in runners:
		if runner.status=="RUN":
			if ticks>=2400:runner.status="DNF";runner.time_us=-1
			else:finished=false
	if finished:phase="results"

func result(source_token:String,career_fingerprint:String) -> Dictionary:
	if phase!="results":return {}
	var rows:Array=[]
	for runner:Dictionary in runners:
		rows.append({"id":runner.id,"name":runner.name,"lane":runner.lane,"status":runner.status,"time_us":runner.time_us,"reaction_us":runner.reaction_us})
	var value={"rules_version":1,"event_id":Data.EVENT,"category":category,"mode":mode,"seed":seed,"source_token":source_token,"career_fingerprint":career_fingerprint,"rows":Data.classify(rows)}
	value=Data.normalize_result(value);value.id=Data.result_id(value)
	return value
