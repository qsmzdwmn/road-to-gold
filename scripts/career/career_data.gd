extends RefCounted
const Athlete = preload("res://scripts/data/athlete_data.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
var origin_id := "from_nothing"
var athlete = Athlete.new()

func to_dict() -> Dictionary:
	return {"origin_id": origin_id, "age": Catalog.origin(origin_id).get("age", 0), "athlete": athlete.to_dict()}

static func validate(data: Variant) -> String:
	if not data is Dictionary or not data.get("origin_id") is String:
		return "Career origin is missing."
	var origin := Catalog.origin(data.origin_id)
	if origin.is_empty() or data.get("age") != origin.age:
		return "Career origin or starting age is invalid."
	return Athlete.validate(data.get("athlete"))

static func from_dict(data: Dictionary):
	var result = load("res://scripts/career/career_data.gd").new()
	result.origin_id = data.origin_id
	result.athlete = Athlete.from_dict(data.athlete)
	return result
