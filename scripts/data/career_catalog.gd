extends RefCounted
## Small authored text datasets, no network or external runtime dependencies.
static var _origins: Array = []
static var _countries: Array = []

static func origins() -> Array:
	if _origins.is_empty():
		_origins = JSON.parse_string(FileAccess.get_file_as_string("res://resources/origins/origins.json"))
	return _origins

static func countries() -> Array:
	if _countries.is_empty():
		_countries = JSON.parse_string(FileAccess.get_file_as_string("res://resources/countries/countries.json"))
	return _countries

static func origin(id: String) -> Dictionary:
	for entry: Dictionary in origins():
		if entry.id == id:
			return entry
	return {}

static func country_name(code: String) -> String:
	for entry: Dictionary in countries():
		if entry.code == code:
			return entry.name
	return ""
