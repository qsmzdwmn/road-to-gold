extends RefCounted
## IDs 0..3 belong to existing saves. Never reuse or reinterpret them.
const LEGACY_NAMES := ["Bald", "Cropped", "Short curls", "Ponytail"]
const MALE_NAMES := ["Buzz Cut", "Crew Cut", "Textured Crop", "Short Fade", "Side Part", "Curly Top"]
const FEMALE_NAMES := ["Long Straight", "High Ponytail", "Long Wavy", "Braided Hair", "Shoulder Length", "High Bun"]
const MALE_IDS := [4,5,6,7,8,9]
const FEMALE_IDS := [10,11,12,13,14,15]
static func ids(category: String) -> Array:
	return FEMALE_IDS if category == "female" else MALE_IDS
static func names(category: String) -> Array:
	return FEMALE_NAMES if category == "female" else MALE_NAMES
static func default_id(category: String) -> int:
	return 10 if category == "female" else 5
static func label(id: int) -> String:
	return (LEGACY_NAMES + MALE_NAMES + FEMALE_NAMES)[id]
