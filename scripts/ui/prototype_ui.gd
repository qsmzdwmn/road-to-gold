extends Control
## Small responsive UI builder; navigation and persistence belong to Main.
signal new_requested
signal continue_requested
signal save_requested
signal menu_requested
signal resume_requested

var menu: VBoxContainer
var settings: VBoxContainer
var hud: VBoxContainer
var resume: Button
var continue_button: Button
var status: Label
var coordinates: Label
var confirmation: ConfirmationDialog

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme_resource := Theme.new()
	theme_resource.default_font_size = 20
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("172630") if state != "hover" else Color("30434a")
		style.border_color = Color("eac45e") if state == "focus" else Color("41515b")
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(4)
		style.content_margin_left = 16
		style.content_margin_right = 16
		theme_resource.set_stylebox(state, "Button", style)
	theme_resource.set_color("font_color", "Button", Color("f1eee4"))
	theme_resource.set_color("font_disabled_color", "Button", Color("78858b"))
	theme = theme_resource
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 380
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.025, 0.045, 0.065, 0.96)
	background.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", background)
	row.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 16)
	panel.add_child(stack)
	_label(stack, "ROAD TO GOLD", 32, Color("eac45e"))
	_label(stack, "VERSION 0.2 / CAREER CREATION", 14)
	menu = _section(stack)
	_button(menu, "New Career", func(): new_requested.emit())
	continue_button = _button(menu, "Continue", func(): continue_requested.emit())
	_button(menu, "Settings", show_settings)
	_label(menu, "Create your athlete.\nExplore the test track.", 18)
	settings = _section(stack)
	_label(settings, "SETTINGS", 24)
	_label(settings, "Move: WASD or arrow keys\nEscape: menu / pause\nSave & Menu: store position\n\nFixed low-cost graphics.\nNo audio in this prototype.", 18)
	_button(settings, "Back", show_menu)
	hud = _section(stack)
	_label(hud, "TRACK EXPLORATION", 24)
	_label(hud, "WASD / arrows to move\nEscape to pause", 18)
	coordinates = _label(hud, "", 18)
	resume = _button(hud, "Resume", func(): resume_requested.emit())
	_button(hud, "Save & Menu", func(): save_requested.emit())
	_button(hud, "Menu (without saving)", func(): menu_requested.emit())
	status = _label(stack, "", 16)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Replace prototype save?"
	confirmation.dialog_text = "New Career resets your saved test position.\nNo full career data is stored in this prototype."
	add_child(confirmation)
	show_menu()

func _section(parent: Node) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	parent.add_child(box)
	return box

func _label(parent: Node, text: String, size: int, color := Color("d8e1e3")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.x = 320
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func show_menu() -> void:
	menu.show()
	settings.hide()
	hud.hide()
	(menu.get_child(0) as Button).grab_focus()

func show_settings() -> void:
	menu.hide()
	settings.show()
	hud.hide()
	(settings.get_child(settings.get_child_count() - 1) as Button).grab_focus()

func show_track() -> void:
	menu.hide()
	settings.hide()
	hud.show()
	resume.hide()
	get_viewport().gui_release_focus()
