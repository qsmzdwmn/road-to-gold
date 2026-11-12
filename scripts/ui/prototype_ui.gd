extends Control
## Small responsive UI builder; navigation and persistence belong to Main.
signal new_requested
signal continue_requested
signal save_requested
signal menu_requested
signal resume_requested
signal hub_requested
signal settings_closed

const RaceQuality=preload("res://scripts/race/race_quality.gd")
const GoldenMenu = preload("res://scripts/ui/golden_menu.gd")
const Brand = preload("res://scripts/branding/brand.gd")
var golden_menu
var legacy_margin: MarginContainer
var legacy_status: Label
var menu: VBoxContainer
var race_quality:OptionButton
var quality_notice:Label
var settings: VBoxContainer
var hud: VBoxContainer
var resume: Button
var hub_button: Button
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
	legacy_margin = margin
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
	_label(stack, Brand.version_label(), 14)
	settings = _section(stack)
	_label(settings, "SETTINGS", 24)
	_label(settings, "Move: WASD or arrow keys\nEscape: menu / pause\nSave & Menu: store position\n\nNo audio in this prototype.", 18)
	_label(settings,"Race graphics",18)
	race_quality=OptionButton.new();race_quality.add_item("Performance (recommended)");race_quality.set_item_metadata(0,RaceQuality.PERFORMANCE);race_quality.add_item("Enhanced");race_quality.set_item_metadata(1,RaceQuality.ENHANCED);race_quality.custom_minimum_size.y=40;settings.add_child(race_quality)
	race_quality.select(1 if RaceQuality.load_mode()==RaceQuality.ENHANCED else 0)
	race_quality.item_selected.connect(_race_quality_selected)
	quality_notice=_label(settings,"Race only. All eight runners and stadium architecture retained.",14)
	_button(settings, "Back", _settings_back)
	hud = _section(stack)
	_label(hud, "TRACK EXPLORATION", 24)
	_label(hud, "WASD / arrows to move\nEscape to pause", 18)
	coordinates = _label(hud, "", 18)
	resume = _button(hud, "Resume", func(): resume_requested.emit())
	_button(hud, "Save & Menu", func(): save_requested.emit())
	_button(hud, "Menu (without saving)", func(): menu_requested.emit())
	hub_button = _button(hud,"Career HQ",func(): hub_requested.emit())
	hub_button.hide()
	legacy_status = _label(stack, "", 16)
	status = legacy_status
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Replace prototype save?"
	confirmation.dialog_text = "New Career resets your saved test position.\nNo full career data is stored in this prototype."
	add_child(confirmation)
	golden_menu = GoldenMenu.new()
	add_child(golden_menu)
	menu = golden_menu.menu
	continue_button = golden_menu.continue_button
	golden_menu.new_requested.connect(func(): new_requested.emit())
	golden_menu.continue_requested.connect(func(): continue_requested.emit())
	golden_menu.settings_requested.connect(show_settings)
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

func _race_quality_selected(_index:int):
	var mode:String=race_quality.get_selected_metadata()
	if RaceQuality.save_mode(mode)==OK:
		quality_notice.text="Applies to the next race. Career data is unchanged."
	else:
		race_quality.select(1 if RaceQuality.load_mode()==RaceQuality.ENHANCED else 0)
		quality_notice.text="Could not save graphics preference. Previous quality retained."

func _settings_back() -> void:
	show_menu()
	settings_closed.emit()

func show_menu() -> void:
	legacy_margin.hide()
	golden_menu.show()
	status = golden_menu.status
	menu.show()
	settings.hide()
	hud.hide()
	(menu.get_child(0) as Button).grab_focus()

func show_settings() -> void:
	golden_menu.hide()
	legacy_margin.show()
	status = legacy_status
	menu.hide()
	settings.show()
	hud.hide()
	(settings.get_child(settings.get_child_count() - 1) as Button).grab_focus()

func show_track() -> void:
	golden_menu.hide()
	legacy_margin.show()
	status = legacy_status
	menu.hide()
	settings.hide()
	hud.show()
	resume.hide()
	get_viewport().gui_release_focus()

func set_continue_available(available: bool) -> void:
	continue_button.disabled = not available
	continue_button.focus_mode = Control.FOCUS_ALL if available else Control.FOCUS_NONE
