extends RefCounted
const Category = preload("res://scripts/data/athlete_category.gd")
const Athlete = preload("res://scripts/data/athlete_data.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
var athlete_category := ""
var origin_id := "from_nothing"
var athlete = Athlete.new()

func to_dict() -> Dictionary:
	var data := {"origin_id": origin_id, "age": Catalog.origin(origin_id).get("age", 0), "athlete": athlete.to_dict()}
	if not athlete_category.is_empty():
		data.athlete_category = athlete_category
	return data

func competition_scope(event_id: String) -> String:
	return Category.competition_scope(athlete_category, event_id)

static func validate(data: Variant, require_category := false) -> String:
	if not data is Dictionary or not data.get("origin_id") is String:
		return "Career origin is missing."
	if require_category and not Category.valid(data.get("athlete_category")):
		return "Choose Male Athlete or Female Athlete."
	if data.has("athlete_category") and not Category.valid(data.athlete_category):
		return "Athlete category is invalid."
	var origin := Catalog.origin(data.origin_id)
	if origin.is_empty() or data.get("age") != origin.age:
		return "Career origin or starting age is invalid."
	return Athlete.validate(data.get("athlete"))

static func from_dict(data: Dictionary):
	var result = load("res://scripts/career/career_data.gd").new()
	result.athlete_category = data.get("athlete_category", "")
	result.origin_id = data.origin_id
	result.athlete = Athlete.from_dict(data.athlete)
	return result
