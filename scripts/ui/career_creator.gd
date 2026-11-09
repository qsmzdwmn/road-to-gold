extends Control
signal cancelled
signal confirmed(career)
const Category = preload("res://scripts/data/athlete_category.gd")
const Career = preload("res://scripts/career/career_data.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
const Appearance = preload("res://scripts/data/appearance_data.gd")
const Brand = preload("res://scripts/branding/brand.gd")
const Room = preload("res://scripts/customization/locker_room.gd")
const Model = preload("res://scripts/customization/procedural_athlete.gd")
var draft = Career.new()
var step := 0
var sections: Array[VBoxContainer] = []
var fields: Dictionary = {}
var pending_numeric: Dictionary = {}
var category_buttons: Array[Button] = []
var category_caption: Label
var origin_buttons: Array[Button] = []
var preview_model
var origin_caption: Label
var heading: Label
var summary: Label
var error: Label
var next_button: Button
var back_button: Button
var split: BoxContainer
var preview_pane: VBoxContainer
var viewport_container: SubViewportContainer
var outer_margin: MarginContainer
var layout: VBoxContainer
var scroll: ScrollContainer
var progress: Array[Label] = []
var description: Label
var age_caption: Label
var preview_room
const TITLES := ["CHOOSE YOUR ATHLETE", "YOUR STORY", "YOUR APPEARANCE", "YOUR IDENTITY", "BEGIN YOUR LEGACY"]
const NOTES := ["Every career begins with a choice. Both categories share every origin and customization option.", "Choose where your journey begins. Your origin sets your starting age.", "Make this athlete your own. Appearance never determines athletic ability.", "A name. A country. A career waiting to begin.", "Review your athlete before stepping onto the track."]

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("101820")
	theme = _creator_theme()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	outer_margin = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 28)
	add_child(margin)
	layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var masthead := HBoxContainer.new()
	layout.add_child(masthead)
	var official_emblem := Brand.logo(true)
	official_emblem.custom_minimum_size = Vector2(44, 34)
	masthead.add_child(official_emblem)
	var wordmark := _label(masthead, "ROAD TO GOLD", 24, Color("c6a66b"))
	wordmark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var subtitle := _label(masthead, "CAREER CREATION  /  THE LOCKER ROOM", 14)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	wordmark.autowrap_mode = TextServer.AUTOWRAP_OFF
	var steps := HBoxContainer.new()
	steps.add_theme_constant_override("separation", 8)
	layout.add_child(steps)
	for index in range(5):
		var indicator := _label(steps, "%02d  %s" % [index + 1, ["ATHLETE", "STORY", "APPEARANCE", "IDENTITY", "LEGACY"][index]], 14)
		indicator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress.append(indicator)
	layout.add_child(HSeparator.new())
	split = BoxContainer.new()
	split.add_theme_constant_override("separation", 24)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(split)
	scroll = ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_stretch_ratio = 0.85
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	heading = _label(content, "", 26)
	description = _label(content, "", 16, Color("b7c0c5"))
	content.add_theme_constant_override("separation", 16)
	for i in range(5):
		var section := VBoxContainer.new()
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_theme_constant_override("separation", 12)
		sections.append(section)
		content.add_child(section)
	category_caption = _label(sections[0], "Choose an athlete category to continue.", 16, Color("c6a66b"))
	var category_group := ButtonGroup.new()
	for id: String in Category.IDS:
		var button := Button.new()
		button.text = Category.label(id)
		button.toggle_mode = true
		button.button_group = category_group
		button.custom_minimum_size.y = 56
		button.pressed.connect(func(): select_category(id))
		category_buttons.append(button)
		sections[0].add_child(button)
	origin_caption = _label(sections[1], "Selected: FROM NOTHING — age 15", 16, Color("c6a66b"))
	var group := ButtonGroup.new()
	for entry: Dictionary in Catalog.origins():
		var button := Button.new()
		button.text = "%s — age %d\n%s" % [entry.title, entry.age, entry.description]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 92
		button.button_pressed = entry.id == draft.origin_id
		button.pressed.connect(func():
			draft.origin_id = entry.id
			origin_caption.text = "Selected: %s — age %d" % [entry.title, entry.age]
			age_caption.text = "STARTING AGE  /  %d" % entry.age
		)
		origin_buttons.append(button)
		sections[1].add_child(button)
	age_caption = _label(sections[3], "STARTING AGE  /  15", 16, Color("c6a66b"))
	_name_field("first_name", "First name")
	_name_field("last_name", "Last name")
	var country := OptionButton.new()
	for entry: Dictionary in Catalog.countries():
		country.add_item(entry.name)
		country.set_item_metadata(country.item_count - 1, entry.code)
		if entry.code == draft.athlete.country:
			country.select(country.item_count - 1)
	_field("country", "Country", country)
	country.item_selected.connect(func(_index): _changed())
	_option("skin", "Skin tone", ["Tone 1", "Tone 2", "Tone 3", "Tone 4", "Tone 5", "Tone 6"], draft.athlete.appearance.skin)
	_option("hairstyle", "Hairstyle", Appearance.STYLES, draft.athlete.appearance.hairstyle)
	_option("hair_color", "Hair color", Appearance.HAIR_NAMES, draft.athlete.appearance.hair_color)
	for key: String in ["height", "weight", "shoulders", "legs"]:
		var spin := SpinBox.new()
		spin.min_value = Appearance.LIMITS[key][0]
		spin.max_value = Appearance.LIMITS[key][1]
		spin.step = 0.05 if key in ["shoulders", "legs"] else 1.0
		spin.value = draft.athlete.appearance.get(key)
		spin.suffix = "cm" if key == "height" else ("kg" if key == "weight" else "×")
		_field(key, {"height": "Height", "weight": "Weight", "shoulders": "Shoulder width", "legs": "Leg proportion"}[key], spin)
		spin.value_changed.connect(func(_value): _changed())
		spin.get_line_edit().text_changed.connect(func(_text): pending_numeric[key] = true)
	_label(sections[2], "Cosmetic choices only. All athletes share the same movement controls.", 14, Color("b7c0c5"))
	summary = _label(sections[4], "", 18)
	_label(sections[4], "BEGIN CAREER saves this athlete and opens the test track. Existing progress is replaced only after confirmation.", 14)
	preview_pane = VBoxContainer.new()
	preview_pane.custom_minimum_size.x = 420
	preview_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(preview_pane)
	_label(preview_pane, "THE LOCKER ROOM  /  ATHLETE PREVIEW", 14, Color("c6a66b"))
	viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.custom_minimum_size = Vector2(200, 210)
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_pane.add_child(viewport_container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 400)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport_container.add_child(viewport)
	preview_room = Room.new()
	viewport.add_child(preview_room)
	preview_model = Model.new()
	# The model's +Z ponytail marks its back; local -Z is its forward direction.
	# Turn only this preview toward the fixed camera's +Z side (natural 3/4 view).
	preview_model.rotation.y = PI
	preview_room.add_child(preview_model)
	error = _label(layout, "", 17, Color("ffbc9c"))
	layout.add_child(HSeparator.new())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)
	back_button = _button(footer, "BACK", _back)
	var hint := _label(footer, "DRAFT  /  NOT SAVED UNTIL CONFIRMED", 12, Color("b7c0c5"))
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	next_button = _button(footer, "CONTINUE", _next)
	resized.connect(_resize_layout)
	_resize_layout()
	hide()
	_show_step()

func _label(parent: Node, text: String, size: int, color := Color("e9e8e3")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(180, 44)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _field(key: String, title: String, control: Control) -> void:
	var section: VBoxContainer = sections[3 if key in ["first_name", "last_name", "country"] else 2]
	_label(section, title, 15)
	control.custom_minimum_size.y = 38
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.tooltip_text = title
	section.add_child(control)
	fields[key] = control

func _name_field(key: String, title: String) -> void:
	var line := LineEdit.new()
	line.max_length = 32
	line.placeholder_text = title
	_field(key, title, line)
	line.text_changed.connect(func(_value): _changed())

func _option(key: String, title: String, choices: Array, selected: int) -> void:
	var option := OptionButton.new()
	for item: String in choices:
		option.add_item(item)
	option.select(selected)
	_field(key, title, option)
	option.item_selected.connect(func(_index): _changed())

func _capture(commit_edits := false) -> void:
	draft.athlete.first_name = fields.first_name.text
	draft.athlete.last_name = fields.last_name.text
	draft.athlete.country = fields.country.get_item_metadata(fields.country.selected)
	for key: String in ["skin", "hairstyle", "hair_color"]:
		draft.athlete.appearance.set(key, fields[key].selected)
	for key: String in ["height", "weight", "shoulders", "legs"]:
		if commit_edits and pending_numeric.get(key, false):
			fields[key].apply()
			pending_numeric.erase(key)
		draft.athlete.appearance.set(key, fields[key].value)

func _changed() -> void:
	if not is_node_ready():
		return
	_capture()
	preview_model.apply_appearance(draft.athlete.appearance, draft.athlete_category)
	error.text = ""

func select_category(id: String) -> void:
	if not Category.valid(id):
		return
	draft.athlete_category = id
	for index in range(category_buttons.size()):
		category_buttons[index].button_pressed = Category.IDS[index] == id
	category_caption.text = "Selected: " + Category.label(id)
	preview_model.apply_appearance(draft.athlete.appearance, id)
	error.text = ""

func open() -> void:
	step = 0
	show()
	_show_step()

func _show_step() -> void:
	heading.text = TITLES[step]
	description.text = NOTES[step]
	for index in range(progress.size()):
		progress[index].add_theme_color_override("font_color", Color("c6a66b") if index <= step else Color("a0abb3"))
		progress[index].text = "%02d  %s%s" % [index + 1, ["ATHLETE", "STORY", "APPEARANCE", "IDENTITY", "LEGACY"][index], " •" if index == step else ""]
	for index in range(sections.size()):
		sections[index].visible = index == step
	preview_pane.visible = true
	back_button.text = "MAIN MENU" if step == 0 else "BACK"
	next_button.text = "BEGIN CAREER" if step == 4 else "CONTINUE"
	error.text = ""
	scroll.scroll_vertical = 0
	if step == 4:
		var data: Dictionary = draft.to_dict()
		var origin := Catalog.origin(draft.origin_id)
		summary.text = "Category: %s\n%s\n%s %s\nCountry: %s\nAge: %d\nHeight: %.0f cm\nWeight: %.0f kg\nSkin: Tone %d\nHair: %s / %s\nShoulders: %.2f ×\nLeg proportion: %.2f ×" % [Category.label(draft.athlete_category), origin.title, data.athlete.first_name, data.athlete.last_name, Catalog.country_name(data.athlete.country), origin.age, data.athlete.appearance.height, data.athlete.appearance.weight, data.athlete.appearance.skin + 1, Appearance.STYLES[data.athlete.appearance.hairstyle], Appearance.HAIR_NAMES[data.athlete.appearance.hair_color], data.athlete.appearance.shoulders, data.athlete.appearance.legs]
	if visible:
		next_button.grab_focus()

func _next() -> void:
	_capture(true)
	if step == 0 and not Category.valid(draft.athlete_category):
		error.text = "Choose Male Athlete or Female Athlete."
		return
	if step >= 3:
		var message: String = Career.validate(draft.to_dict(), true)
		if not message.is_empty():
			error.text = message
			return
	if step == 4:
		confirmed.emit(Career.from_dict(draft.to_dict()))
		return
	step += 1
	_show_step()

func _back() -> void:
	_capture(true)
	if step == 0:
		hide()
		cancelled.emit()
	else:
		step -= 1
		_show_step()

func _resize_layout() -> void:
	if split == null:
		return
	split.vertical = size.x < 900
	preview_pane.custom_minimum_size.x = 0 if split.vertical else 420
	scroll.custom_minimum_size.y = 100 if split.vertical else 0
	viewport_container.custom_minimum_size.y = 150 if split.vertical else 210
	layout.add_theme_constant_override("separation", 8 if split.vertical else 12)
	for side: String in ["left", "right", "top", "bottom"]:
		outer_margin.add_theme_constant_override("margin_" + side, 16 if split.vertical else 28)

func _creator_theme() -> Theme:
	# Local theme: menu, track HUD and confirmation behavior remain unchanged.
	var result := Theme.new()
	result.default_font_size = 17
	result.set_color("font_color", "Label", Color("e9e8e3"))
	for type: String in ["Button", "OptionButton", "LineEdit", "SpinBox", "PopupMenu"]:
		result.set_color("font_color", type, Color("e9e8e3"))
		result.set_color("font_hover_color", type, Color("e9e8e3"))
		result.set_color("font_pressed_color", type, Color("e9e8e3"))
		for state: String in ["normal", "hover", "pressed", "focus", "panel"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color("28333b") if state in ["hover", "pressed"] else Color("172129")
			box.border_color = Color("c6a66b") if state in ["focus", "pressed"] else Color("41505b")
			box.set_border_width_all(2 if state == "focus" else 1)
			box.set_corner_radius_all(3)
			box.content_margin_left = 14
			box.content_margin_right = 14
			box.content_margin_top = 9
			box.content_margin_bottom = 9
			if state == "focus":
				box.bg_color = Color.TRANSPARENT
			result.set_stylebox(state, type, box)
	return result
