extends Control
signal cancelled
signal confirmed(career)
const Career = preload("res://scripts/career/career_data.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
const Appearance = preload("res://scripts/data/appearance_data.gd")
const Model = preload("res://scripts/customization/procedural_athlete.gd")
var draft = Career.new()
var step := 0
var sections: Array[VBoxContainer] = []
var fields: Dictionary = {}
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
var scroll: ScrollContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("091119")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	_label(layout, "ROAD TO GOLD", 28, Color("eac45e"))
	heading = _label(layout, "", 22)
	split = BoxContainer.new()
	split.add_theme_constant_override("separation", 24)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(split)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	for i in range(4):
		var section := VBoxContainer.new()
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		section.add_theme_constant_override("separation", 12)
		sections.append(section)
		content.add_child(section)
	_label(sections[0], "Create a fictional athlete and choose where their career begins.\n\nYour draft stays with you when you go Back or Next. Saved progress is only replaced after you confirm the completed career.\n\nThis version returns to the existing test track. Story events and sporting progression come later.", 20)
	origin_caption = _label(sections[1], "Selected: FROM NOTHING — age 15", 18, Color("eac45e"))
	var group := ButtonGroup.new()
	for entry: Dictionary in Catalog.origins():
		var button := Button.new()
		button.text = "%s — age %d\n%s" % [entry.title, entry.age, entry.description]
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 100
		button.button_pressed = entry.id == draft.origin_id
		button.pressed.connect(func():
			draft.origin_id = entry.id
			origin_caption.text = "Selected: %s — age %d" % [entry.title, entry.age]
		)
		origin_buttons.append(button)
		sections[1].add_child(button)
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
	_label(sections[2], "Appearance and country do not change athletic ability.", 16)
	summary = _label(sections[3], "", 20)
	_label(sections[3], "Create Career saves this athlete and opens the test track.", 18)
	preview_pane = VBoxContainer.new()
	preview_pane.custom_minimum_size.x = 280
	preview_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(preview_pane)
	_label(preview_pane, "ATHLETE PREVIEW", 18, Color("eac45e"))
	var viewport_container := SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.custom_minimum_size = Vector2(200, 160)
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_pane.add_child(viewport_container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 400)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport_container.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	preview_model = Model.new()
	world.add_child(preview_model)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("091119")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.65
	environment_node.environment = environment
	world.add_child(environment_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -25, 0)
	light.shadow_enabled = false
	world.add_child(light)
	var camera := Camera3D.new()
	camera.position = Vector3(2.8, 1.9, 4.5)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.2
	world.add_child(camera)
	camera.look_at(Vector3(0, 1.2, 0))
	error = _label(layout, "", 17, Color("ffbc9c"))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)
	back_button = _button(footer, "Back", _back)
	next_button = _button(footer, "Next", _next)
	resized.connect(_resize_layout)
	_resize_layout()
	hide()
	_show_step()

func _label(parent: Node, text: String, size: int, color := Color("d8e1e3")) -> Label:
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
	button.custom_minimum_size = Vector2(160, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _field(key: String, title: String, control: Control) -> void:
	_label(sections[2], title, 18)
	control.custom_minimum_size.y = 42
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.tooltip_text = title
	sections[2].add_child(control)
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
		if commit_edits:
			fields[key].apply()
		draft.athlete.appearance.set(key, fields[key].value)

func _changed() -> void:
	if not is_node_ready():
		return
	_capture()
	preview_model.apply_appearance(draft.athlete.appearance)
	error.text = ""

func open() -> void:
	step = 0
	show()
	_show_step()

func _show_step() -> void:
	heading.text = "%d / 4 — %s" % [step + 1, ["Create Career", "Choose Origin", "Customize Athlete", "Career Summary"][step]]
	for index in range(sections.size()):
		sections[index].visible = index == step
	preview_pane.visible = step >= 2
	back_button.text = "Main Menu" if step == 0 else "Back"
	next_button.text = ["Choose Origin", "Customize Athlete", "Review Career", "Create Career"][step]
	error.text = ""
	scroll.scroll_vertical = 0
	if step == 3:
		var data: Dictionary = draft.to_dict()
		var origin := Catalog.origin(draft.origin_id)
		summary.text = "%s\n%s %s\nCountry: %s\nAge: %d\nHeight: %.0f cm\nWeight: %.0f kg\nSkin: Tone %d\nHair: %s / %s\nShoulders: %.2f ×\nLeg proportion: %.2f ×" % [origin.title, data.athlete.first_name, data.athlete.last_name, Catalog.country_name(data.athlete.country), origin.age, data.athlete.appearance.height, data.athlete.appearance.weight, data.athlete.appearance.skin + 1, Appearance.STYLES[data.athlete.appearance.hairstyle], Appearance.HAIR_NAMES[data.athlete.appearance.hair_color], data.athlete.appearance.shoulders, data.athlete.appearance.legs]
	if visible:
		next_button.grab_focus()

func _next() -> void:
	_capture(true)
	if step >= 2:
		var message: String = Career.validate(draft.to_dict())
		if not message.is_empty():
			error.text = message
			return
	if step == 3:
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
	split.vertical = size.x < 760
	preview_pane.custom_minimum_size.x = 0 if split.vertical else 280
	scroll.custom_minimum_size.y = 150 if split.vertical else 0
