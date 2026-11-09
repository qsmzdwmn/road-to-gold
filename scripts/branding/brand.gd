extends RefCounted
## Original approved PNGs are immutable; UI uses small aspect-preserving derivatives.
const FULL = preload("res://assets/branding/golden_path_full_ui.png")
const EMBLEM = preload("res://assets/branding/golden_path_emblem_ui.png")

static func version_label() -> String:
	return "VERSION " + str(ProjectSettings.get_setting("application/config/version"))

static func logo(emblem := false) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = EMBLEM if emblem else FULL
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.tooltip_text = "ROAD TO GOLD"
	return rect
