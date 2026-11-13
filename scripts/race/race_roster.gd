extends RefCounted
const MALE := ["Leo March","Noah Vale","Eli Rowan","Owen Ash","Kai Mercer","Adam Reed","Luca Stone"]
const FEMALE := ["Maya March","Nora Vale","Eva Rowan","Iris Ash","Zoe Mercer","Ada Reed","Lena Stone"]
const PROFILES := [
	[4700,5100,4900,220000,0.97],[5300,4800,5200,240000,0.98],
	[4900,5400,4500,190000,0.95],[5600,5000,5300,260000,0.99],
	[4400,4700,5500,230000,0.96],[5100,5200,5000,210000,0.97],
	[4800,4900,4800,250000,0.98]
]
static func entries(category:String) -> Array:
	var result:Array=[]
	if not category in ["male","female"]:return result
	var names:Array=MALE if category=="male" else FEMALE
	for i in range(7):
		var p:Array=PROFILES[i]
		result.append({"id":"ai_%d" % (i+1),"name":names[i],"lane":i if i<3 else i+1,"attributes":{"speed":p[0],"acceleration":p[1],"stamina":p[2],"recovery":5000},"reaction_us":p[3],"effort":p[4]})
	return result
