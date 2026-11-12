extends SceneTree
const State=preload("res://scripts/training/training_state.gd")
const Rules=preload("res://scripts/training/training_service.gd")
var failures:=0
func check(value:bool,message:String):
	print(("PASS: " if value else "FAIL: ")+message)
	if not value:failures+=1
func _initialize():
	var s=State.initial()
	check(State.validate(s)=="" and s.attributes.speed==5000,"initial ratings and state valid")
	var r=Rules.calculate(s,"sprint_drills")
	check(r.after.attributes.speed==5060 and r.after.attributes.acceleration==5020 and r.after.fatigue==22,"exact Sprint Drills baseline")
	check(s==State.initial() and Rules.calculate(s,"sprint_drills")==r,"pure deterministic preview without mutation")
	for boundary in [[29,60],[30,45],[59,45],[60,30],[79,30]]:
		s.fatigue=boundary[0];check(Rules.calculate(s,"sprint_drills").after.attributes.speed==5000+boundary[1],"fatigue boundary %d" % boundary[0])
	s.fatigue=80;check(not Rules.calculate(s,"start_practice").ok,"workouts blocked at 80")
	s.fatigue=100;r=Rules.calculate(s,"recovery_session")
	check(r.after.fatigue==65 and r.after.attributes.recovery==5020 and r.after.recovery_used,"recovery uses pre-session Recovery")
	check(not Rules.calculate(r.after,"recovery_session").ok,"one recovery per day")
	s=State.initial();s.fatigue=19;check(not Rules.calculate(s,"recovery_session").ok,"no recovery farming while fresh")
	s=Rules.calculate(State.initial(),"sprint_drills").after;s=Rules.calculate(s,"start_practice").after
	check(not Rules.calculate(s,"endurance_run").ok,"two-action daily limit")
	r=Rules.calculate(s,"end_day");check(r.after.day==2 and r.after.actions_used==0 and r.after.fatigue==27,"explicit day transition and passive recovery")
	check(Rules.gain(60,8000,100)==24 and Rules.gain(60,9900,100)==12,"diminishing returns with floor")
	s=State.initial();s.attributes.speed=9999;r=Rules.calculate(s,"sprint_drills");check(r.after.attributes.speed==10000,"rating clamps at 100")
	s.attributes.acceleration=10000;s.attributes.speed=10000;check(not Rules.calculate(s,"sprint_drills").ok,"no pointless maxed workout")
	check(not Rules.calculate(s,"unknown").ok,"invalid activity rejected")
	for field in ["day","actions_used","revision","fatigue"]:
		var bad=State.initial();bad[field]=-1;check(State.validate(bad)!="","negative "+field+" rejected")
	s=State.initial();s.attributes.speed=5000.5;check(State.validate(s)!="","fractional hundredths rejected")
	# Independent of frame rate, origin, category or appearance: none enters the rules API.
	for activity:String in Rules.ACTIVITIES:
		s=State.initial();s.fatigue=40
		check(Rules.calculate(s,activity)==Rules.calculate(s.duplicate(true),activity),"repeatable "+activity)
	check(Rules.gain(10,7000,75)==5,"half-hundredth rounds upward deterministically")
	s=State.initial();r=Rules.calculate(s,"endurance_run")
	check(r.after.attributes.stamina==5060 and r.after.attributes.recovery==5010 and r.after.fatigue==26,"exact Endurance Run baseline")
	r=Rules.calculate(s,"start_practice")
	check(r.after.attributes.acceleration==5060 and r.after.attributes.speed==5010 and r.after.fatigue==18,"exact Start Practice baseline")
	for day in range(2000):
		s=Rules.calculate(s,"end_day").after
		if day%200==0:check(State.validate(s)=="","long training chronology remains valid without career-length limits")
	check(s.day==2001 and s.attributes==State.initial().attributes,"ending days creates no attribute gains")
	print("TRAINING RULE FAILURES: ",failures);quit(failures)
