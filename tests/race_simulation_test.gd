extends SceneTree
const Session=preload("res://scripts/race/race_session.gd")
const Physics=preload("res://scripts/race/sprint_physics.gd")
const InputState=preload("res://scripts/race/sprint_input.gd")
const State=preload("res://scripts/training/training_state.gd")
const Data=preload("res://scripts/race/competition_data.gd")
var failures:=0
func check(ok:bool,message:String):
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func run_race(profile:Dictionary,category:="male",mode:="hold"):
	var race=Session.new(profile,category,mode,123,"Alex Gold");race.ready()
	while race.phase!="running":race.step()
	var key=KEY_A
	for tick in range(2401):
		if tick==12 and mode=="hold":race.key(KEY_SPACE,true)
		if mode=="rhythm" and tick>=12 and (tick-12)%15==0:
			race.key(KEY_D if key==KEY_A else KEY_A,false);race.key(key,true);key=KEY_D if key==KEY_A else KEY_A
		if race.phase=="results":break
		race.step()
	return race
func _initialize():
	var base=State.initial();var a=run_race(base);var b=run_race(base)
	check(a.phase=="results" and a.runners.size()==8,"eight runners complete a true 100m event")
	check(a.runners[0].time_us==12471338,"approved baseline 50/0 fatigue with 200ms reaction retains validated finish time")
	check(a.runners==b.runners,"fixed seed/input produces identical simulation")
	var rows=a.result("a".repeat(64),"b".repeat(64));check(Data.validate_result(rows)=="","classified completed result validates")
	check(a.runners[0].distance==100 and a.runners[0].reaction_us==200000,"metre distance and reaction share race clock")
	check(run_race(base,"female").runners[0].time_us==a.runners[0].time_us,"category parity uses identical physics")
	check(run_race(base,"male","rhythm").runners[0].time_us==a.runners[0].time_us,"ideal alternating rhythm and Hold have identical maximum race performance")
	var high=base.duplicate(true);high.attributes.speed=8000;check(run_race(high).runners[0].time_us<a.runners[0].time_us,"Speed improves finish")
	high=base.duplicate(true);high.attributes.acceleration=8000;check(run_race(high).runners[0].time_us<a.runners[0].time_us,"Acceleration improves finish")
	high=base.duplicate(true);high.attributes.stamina=8000;check(run_race(high).runners[0].time_us<a.runners[0].time_us,"Stamina improves late-race finish")
	high=base.duplicate(true);high.attributes.recovery=10000;check(run_race(high).runners[0].time_us==a.runners[0].time_us,"Recovery has no direct race speed bonus")
	high=base.duplicate(true);high.fatigue=100;check(run_race(high).runners[0].time_us>a.runners[0].time_us,"fatigue reduces readiness")
	var input=InputState.new();input.mode="rhythm"
	check(input.event(KEY_A,true,false,0) and not input.event(KEY_A,true,true,0.1),"repeat events ignored")
	input.event(KEY_A,false,false,0.1);check(not input.event(KEY_LEFT,true,false,0.2),"same-side aliases cannot spoof alternating presses")
	input.event(KEY_LEFT,false,false,0.2);check(not input.event(KEY_D,true,false,0.01),"too-fast alternation ignored")
	input.event(KEY_D,false,false,0.02);input.event(KEY_D,true,false,0.25)
	check(input.effort(0.25)==1.0,"ideal rhythm reaches same ceiling as held Space")
	check(input.effort(2)==0.0,"no rhythm input decays to zero effort")
	var race=Session.new(base,"male","hold",1,"Alex Gold");race.ready();race.key(KEY_SPACE,true)
	check(race.phase=="invalid" and race.result("a".repeat(64),"b".repeat(64)).is_empty(),"false start recalls race without fabricated times/results")
	race=Session.new(base,"male","hold",1,"Alex Gold");race.ready();race.interrupt();check(race.phase=="invalid","focus interruption invalidates attempt")
	race=Session.new(base,"male","hold",1,"Alex Gold");race.ready()
	while race.phase!="results":race.step()
	check(race.runners[0].status=="DNF" and race.runners[0].time_us==-1,"no input produces DNF without an invented time")
	var tie=Data.classify([{"status":"FIN","time_us":11000001,"lane":1},{"status":"FIN","time_us":11000000,"lane":0},{"status":"FIN","time_us":11000001,"lane":2},{"status":"DNF","time_us":-1,"lane":3}])
	check(tie[0].rank==1 and tie[1].rank==2 and tie[2].rank==2 and tie[3].rank==0,"unrounded ordering, exact ties and DNF classification")
	check(Data.centiseconds(11000001)==1101 and Data.centiseconds(11000000)==1100,"official displayed hundredths round upward")
	var equal_display=Data.classify([{"status":"FIN","time_us":11000001,"lane":0},{"status":"FIN","time_us":11000002,"lane":1}])
	check(equal_display[0].rank==1 and equal_display[1].rank==2 and Data.centiseconds(equal_display[0].time_us)==Data.centiseconds(equal_display[1].time_us),"equal displayed hundredths retain fair unrounded places")
	# GO resets the race clock; preparation-held input is not a reaction.
	race=Session.new(base,"male","hold",1,"Alex Gold")
	race.key(KEY_SPACE,true);race.ready()
	while race.phase!="running":race.step()
	for tick in range(30):race.step()
	check(race.runners[0].reaction_us==-1 and race.runners[0].distance==0.0,"pre-held Space cannot register reaction or move player after GO")
	race.key(KEY_SPACE,true,true);race.step()
	check(race.runners[0].reaction_us==-1,"held-key repeat after GO cannot grant a start")
	race.key(KEY_SPACE,false);race.key(KEY_SPACE,true)
	check(race.runners[0].reaction_us==roundi(31.0/60.0*1000000.0),"fresh post-GO press measures reaction from GO, excluding starter sequence")
	race=Session.new(base,"male","hold",1,"Alex Gold");race.ready()
	while race.phase!="set":race.step()
	race.key(KEY_SPACE,true)
	check(race.phase=="invalid","false starts during Set are invalid as during Marks")
	print("RACE SIMULATION FAILURES: ",failures);quit(failures)
