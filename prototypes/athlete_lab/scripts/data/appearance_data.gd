extends RefCounted
const SKIN_COLORS := ["f4d4b4", "dfb18b", "be8b63", "996442", "70452f", "482d23"]
const HAIR_COLORS := ["171719", "533522", "d8b56c", "934b32", "acafb2"]
const HAIR_NAMES := ["Black", "Brown", "Blond", "Auburn", "Gray"]
const STYLES := ["Bald", "Cropped", "Short curls", "Ponytail"]
const LIMITS := {"skin": [0, 5], "hair_color": [0, 4], "hairstyle": [0, 3], "height": [140, 220], "weight": [40, 150], "shoulders": [0.8, 1.3], "legs": [0.85, 1.15]}
var skin := 2
var hair_color := 0
var hairstyle := 1
var height := 180.0
var weight := 75.0
var shoulders := 1.0
var legs := 1.0

func to_dict() -> Dictionary:
	return {"skin": skin, "hair_color": hair_color, "hairstyle": hairstyle, "height": height, "weight": weight, "shoulders": roundf(shoulders * 100.0) / 100.0, "legs": roundf(legs * 100.0) / 100.0}

static func validate(data: Variant) -> String:
	if not data is Dictionary:
		return "Appearance data is missing."
	for key: String in LIMITS:
		var value: Variant = data.get(key)
		if not (value is int or value is float):
			return "Invalid appearance value: " + key
		if not is_finite(float(value)) or value < LIMITS[key][0] or value > LIMITS[key][1]:
			return "Appearance value out of range: " + key
		if key in ["skin", "hair_color", "hairstyle"] and float(value) != floorf(float(value)):
			return "Appearance selection must be a whole number."
	return ""

static func from_dict(data: Dictionary):
	var result = load("res://scripts/data/appearance_data.gd").new()
	for key: String in LIMITS:
		result.set(key, data[key])
	return result
