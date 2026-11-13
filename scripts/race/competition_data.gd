extends RefCounted
const State=preload("res://scripts/training/training_state.gd")
const Category=preload("res://scripts/data/athlete_category.gd")
const EVENT := "sprint_100m"
const VERSION := 1

static func digest(value:Variant) -> bool:
	if not value is String or value.length()!=64:return false
	for c:String in value:
		if not c in "0123456789abcdef":return false
	return true

@warning_ignore("integer_division")
static func centiseconds(time_us:int) -> int:
	return (time_us+9999)/10000

static func time_text(time_us:int) -> String:
	return "%.2f" % (float(centiseconds(time_us))/100.0) if time_us>=0 else "--"

static func classify(rows:Array) -> Array:
	var ordered:=rows.duplicate(true)
	ordered.sort_custom(func(a:Dictionary,b:Dictionary):
		if a.status!=b.status:return a.status=="FIN"
		if a.time_us!=b.time_us:return a.time_us<b.time_us
		return a.lane<b.lane)
	var prior_time:=-1;var prior_rank:=0
	for i in range(ordered.size()):
		if ordered[i].status=="FIN":
			ordered[i].rank=prior_rank if ordered[i].time_us==prior_time else i+1
			prior_rank=ordered[i].rank;prior_time=ordered[i].time_us
		else:ordered[i].rank=0
	return ordered

static func normalize_result(value:Dictionary) -> Dictionary:
	var rows:Array=[]
	for row:Dictionary in value.rows:
		rows.append({"id":row.id,"name":row.name,"lane":int(row.lane),"status":row.status,"time_us":int(row.time_us),"reaction_us":int(row.reaction_us),"rank":int(row.rank)})
	rows.sort_custom(func(a:Dictionary,b:Dictionary):return a.lane<b.lane)
	return {"rules_version":int(value.rules_version),"event_id":value.event_id,"category":value.category,"mode":value.mode,"seed":int(value.seed),"source_token":value.source_token,"career_fingerprint":value.career_fingerprint,"rows":rows}

static func result_id(value:Dictionary) -> String:
	return JSON.stringify(normalize_result(value)).sha256_text()

static func validate_result(value:Variant) -> String:
	if not value is Dictionary or value.get("rules_version")!=VERSION or value.get("event_id")!=EVENT:return "Unsupported race rules/event."
	if not Category.valid(value.get("category")) or not value.get("mode") in ["hold","rhythm"]:return "Invalid race category or controls."
	if not State.whole(value.get("seed"),1,2147483647) or not digest(value.get("source_token")) or not digest(value.get("career_fingerprint")):return "Invalid race identity."
	if not value.get("rows") is Array or value.rows.size()!=8:return "A race requires eight runners."
	var lanes:Dictionary={};var ids:Dictionary={};var player_count:=0
	for row:Variant in value.rows:
		if not row is Dictionary or not row.get("id") is String or not row.get("name") is String or row.name.strip_edges().is_empty() or row.name.length()>65:return "Invalid runner identity."
		if not row.id in ["player","ai_1","ai_2","ai_3","ai_4","ai_5","ai_6","ai_7"] or ids.has(row.id):return "Duplicate or unknown runner."
		if not State.whole(row.get("lane"),0,7) or lanes.has(int(row.lane)):return "Invalid or duplicate lane."
		ids[row.id]=true;lanes[int(row.lane)]=true
		if row.id=="player":player_count+=1
		if not row.get("status") in ["FIN","DNF"] or not State.whole(row.get("rank"),0,8) or not State.whole(row.get("reaction_us"),-1,40000000):return "Invalid runner status."
		if row.status=="FIN":
			if not State.whole(row.get("time_us"),5000000,40000000) or row.reaction_us<0 or row.reaction_us>=row.time_us or row.rank<1:return "Invalid finishing time."
		elif row.get("time_us")!=-1 or row.rank!=0:return "DNF must not contain a time/place."
	if player_count!=1:return "Missing player."
	var normalized:=normalize_result(value)
	for row:Dictionary in classify(normalized.rows):
		for original:Dictionary in normalized.rows:
			if row.id==original.id and row.rank!=original.rank:return "Incorrect race classification."
	if not digest(value.get("id")) or value.id!=result_id(normalized):return "Race result identity does not match its contents."
	return ""

static func player_row(result:Dictionary) -> Dictionary:
	for row:Dictionary in result.rows:
		if row.id=="player":return row
	return {}

static func validate(block:Variant,category:String) -> String:
	if not block is Dictionary or block.get("version")!=VERSION:return "Unsupported competition data."
	if not block.get("records") is Dictionary or block.records.size()>1:return "Invalid record collection."
	var error:=validate_result(block.get("latest"))
	if not error.is_empty():return error
	if block.latest.category!=category:return "Competition category differs from career."
	var scope:=Category.competition_scope(category,EVENT)
	for key:Variant in block.records:
		if key!=scope:return "Record belongs to a different competition category."
		var pb:Variant=block.records[key]
		if not pb is Dictionary or pb.get("rules_version")!=VERSION or not State.whole(pb.get("time_us"),5000000,40000000) or not State.whole(pb.get("time_cs"),500,4000) or pb.time_cs!=centiseconds(int(pb.time_us)) or not digest(pb.get("result_id")) or not pb.get("mode") in ["hold","rhythm"]:return "Invalid Personal Best."
	var player:=player_row(block.latest)
	if player.status=="FIN" and (not block.records.has(scope) or block.records[scope].time_cs>centiseconds(int(player.time_us))):return "Missing or inconsistent Personal Best."
	return ""

static func normalize_block(block:Dictionary) -> Dictionary:
	var result:=block.duplicate(true)
	result.version=int(result.version)
	var latest:=normalize_result(result.latest);latest.id=result.latest.id;result.latest=latest
	for pb:Dictionary in result.records.values():
		pb.rules_version=int(pb.rules_version);pb.time_us=int(pb.time_us);pb.time_cs=int(pb.time_cs)
	return result

static func apply(previous:Dictionary,result:Dictionary) -> Dictionary:
	var block:Dictionary=previous.duplicate(true) if not previous.is_empty() else {"version":VERSION,"records":{}}
	var normalized:=normalize_result(result);normalized.id=result.id
	block.latest=normalized
	var row:=player_row(normalized)
	var scope:=Category.competition_scope(result.category,EVENT)
	if row.status=="FIN" and (not block.records.has(scope) or centiseconds(row.time_us)<block.records[scope].time_cs):
		block.records[scope]={"rules_version":VERSION,"time_us":row.time_us,"time_cs":centiseconds(row.time_us),"mode":result.mode,"result_id":result.id}
	return block
