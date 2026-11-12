extends RefCounted
const ATTRIBUTES := ["speed", "acceleration", "stamina", "recovery"]

static func initial() -> Dictionary:
	return {"rules_version":1,"attributes":{"speed":5000,"acceleration":5000,"stamina":5000,"recovery":5000},"fatigue":0,"day":1,"actions_used":0,"recovery_used":false,"revision":0}

static func whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floorf(float(value)) and value>=low and value<=high

static func validate(data: Variant) -> String:
	if not data is Dictionary or data.get("rules_version")!=1:
		return "Unsupported training rules."
	if not data.get("attributes") is Dictionary or data.attributes.size()!=4:
		return "Invalid training attributes."
	for id: String in ATTRIBUTES:
		if not whole(data.attributes.get(id),0,10000):return "Invalid attribute: "+id
	if not whole(data.get("fatigue"),0,100) or not whole(data.get("actions_used"),0,2):return "Invalid fatigue or action count."
	# JSON's exact integer range; a serialization constraint, not a career duration rule.
	if not whole(data.get("day"),1,9007199254740991) or not whole(data.get("revision"),0,9007199254740991):return "Invalid training day or revision."
	if not data.get("recovery_used") is bool or (data.recovery_used and data.actions_used<1):return "Invalid daily recovery state."
	return ""

static func normalize(data: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for field: String in ["rules_version","fatigue","day","actions_used","revision"]:result[field]=int(result[field])
	for attribute: String in ATTRIBUTES:result.attributes[attribute]=int(result.attributes[attribute])
	return result
