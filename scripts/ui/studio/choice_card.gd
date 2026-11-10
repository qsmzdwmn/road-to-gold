extends Button
const Icon = preload("res://scripts/ui/studio/studio_icon.gd")

func configure(title: String, subtitle := "", kind := "", index := 0, color := Color.TRANSPARENT) -> void:
	text = title
	tooltip_text = title + ("\n" + subtitle if not subtitle.is_empty() else "")
	toggle_mode = true
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Native Button text remains the accessible action name. Child labels give cards hierarchy.
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color", "font_disabled_color"]:
		add_theme_color_override(state, Color.TRANSPARENT)
	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side, 12)
	add_child(margin)
	var box: BoxContainer = HBoxContainer.new() if kind == "story" else VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)
	if color.a > 0:
		var chip := ColorRect.new()
		chip.color = color
		chip.custom_minimum_size.y = 24
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(chip)
	elif not kind.is_empty():
		var icon := Icon.new()
		icon.kind = kind
		icon.index = index
		icon.custom_minimum_size = Vector2(44,116 if kind == "athlete" else (32 if kind == "hair" else 44))
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(icon)
	var text_box := VBoxContainer.new()
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation",6)
	box.add_child(text_box)
	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if kind == "story" else HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("e9e8e3"))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(label)
	if not subtitle.is_empty():
		var description := Label.new()
		description.text = subtitle
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 14)
		description.add_theme_color_override("font_color", Color("b7c0c5"))
		description.mouse_filter = Control.MOUSE_FILTER_IGNORE
		description.max_lines_visible = 3
		text_box.add_child(description)
