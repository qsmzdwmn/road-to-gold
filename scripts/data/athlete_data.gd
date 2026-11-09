extends RefCounted
const Appearance = preload("res://scripts/data/appearance_data.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
var first_name := ""
var last_name := ""
var country := "US"
var appearance = Appearance.new()

func to_dict() -> Dictionary:
	return {"first_name": first_name.strip_edges(), "last_name": last_name.strip_edges(), "country": country, "appearance": appearance.to_dict()}

static func validate(data: Variant) -> String:
	if not data is Dictionary:
		return "Athlete data is missing."
	for field: String in ["first_name", "last_name"]:
		var value: Variant = data.get(field)
		if not value is String or value.strip_edges().is_empty() or value.length() > 32:
			return "Enter a first and last name (1–32 characters each)."
		for character: String in value:
			if character.unicode_at(0) < 32:
				return "Names cannot contain control characters."
	if not data.get("country") is String or Catalog.country_name(data.country).is_empty():
		return "Choose a country from the list."
	return Appearance.validate(data.get("appearance"))

static func from_dict(data: Dictionary):
	var result = load("res://scripts/data/athlete_data.gd").new()
	result.first_name = data.first_name
	result.last_name = data.last_name
	result.country = data.country
	result.appearance = Appearance.from_dict(data.appearance)
	return result
