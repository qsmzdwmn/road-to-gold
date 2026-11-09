extends Control
## Presentation only. Existing app signals own careers and saves.
signal new_requested
signal continue_requested
signal settings_requested
const Brand = preload("res://scripts/branding/brand.gd")
var menu: VBoxContainer
var logo: TextureRect
var tagline: Label
var version: Label
var status: Label
var continue_button: Button
var panel: PanelContainer
var margin: MarginContainer
var stack: VBoxContainer
var breathing: Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin = MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101820")
	style.set_content_margin_all(0)
	panel.add_theme_stylebox_override("panel", style)
	row.add_child(panel)
	stack = VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 14)
	panel.add_child(stack)
	logo = Brand.logo()
	stack.add_child(logo)
	tagline = Label.new()
	tagline.text = "Your Story.\nYour Sacrifice.\nYour Legacy."
	tagline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tagline.add_theme_color_override("font_color", Color("e9e8e3"))
	tagline.add_theme_font_size_override("font_size", 18)
	stack.add_child(tagline)
	breathing = Control.new()
	breathing.custom_minimum_size.y = 6
	stack.add_child(breathing)
	menu = VBoxContainer.new()
	menu.add_theme_constant_override("separation", 10)
	stack.add_child(menu)
	_button("New Career", new_requested.emit, true)
	continue_button = _button("Continue", continue_requested.emit)
	_button("Settings", settings_requested.emit, false, true)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_OFF
	status.clip_text = true
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Color("b5bfc5"))
	stack.add_child(status)
	version = Label.new()
	version.text = Brand.version_label()
	version.add_theme_font_size_override("font_size", 13)
	version.add_theme_color_override("font_color", Color("b5bfc5"))
	stack.add_child(version)
	resized.connect(_layout)
	_layout()

func _button(text: String, callback: Callable, primary := false, tertiary := false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 20)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("28333b") if not tertiary else Color("101820")
		if state == "hover": style.bg_color = Color("35424a")
		if state == "pressed": style.bg_color = Color("463e30")
		style.border_color = Color("c6a66b") if primary or state == "focus" else Color("414e57")
		style.set_border_width_all(2 if state == "focus" else (1 if primary else 0))
		if state in ["hover", "pressed"]:
			style.border_color = Color("c6a66b")
			if tertiary: style.border_width_bottom = 1
			else: style.border_width_left = 2
		style.set_corner_radius_all(2)
		style.content_margin_left = 18
		style.content_margin_right = 18
		if state == "focus": style.bg_color = Color.TRANSPARENT
		button.add_theme_stylebox_override(state, style)
	button.add_theme_color_override("font_color", Color("e9e8e3"))
	button.add_theme_color_override("font_hover_color", Color("c6a66b"))
	button.add_theme_color_override("font_pressed_color", Color("e9e8e3"))
	button.add_theme_color_override("font_disabled_color", Color("a6b0b7"))
	button.pressed.connect(callback)
	menu.add_child(button)
	return button

func _layout() -> void:
	if panel == null: return
	var compact := size.y < 680
	var inset := 24 if size.x < 1000 or compact else 44
	for side: String in ["left", "top", "bottom", "right"]:
		margin.add_theme_constant_override("margin_" + side, inset)
	panel.custom_minimum_size.x = clampf(size.x * (0.42 if size.x < 1000 else 0.40) - inset, 290, 740)
	logo.custom_minimum_size = Vector2(0, clampf(size.y * 0.36, 155, 330))
	stack.add_theme_constant_override("separation", 8 if compact else 14)
	menu.add_theme_constant_override("separation", 8 if compact else 12)
	breathing.custom_minimum_size.y = 0 if compact else 6
	for child in menu.get_children():
		child.custom_minimum_size.y = 44 if compact else 48
