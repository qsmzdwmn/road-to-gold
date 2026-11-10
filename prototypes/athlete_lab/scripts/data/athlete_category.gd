extends RefCounted
## Explicit career/competition identifiers. Empty means never selected, not male.
const IDS := ["male", "female"]
const LABELS := {"male": "Male Athlete", "female": "Female Athlete"}
const PROFILES := {
	"male": {"shoulders": 1.03, "hips": 0.88},
	"female": {"shoulders": 0.90, "hips": 0.98},
	"": {"shoulders": 1.0, "hips": 0.86}, # Original v0.2 appearance, unchanged.
}

static func valid(value: Variant) -> bool:
	return value is String and value in IDS

static func label(value: String) -> String:
	return LABELS.get(value, "Not selected (legacy)")

static func competition_scope(category: String, event_id: String) -> String:
	if not valid(category) or not event_id.is_valid_identifier():
		return ""
	return category + "/" + event_id
