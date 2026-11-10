extends Control
signal cancelled
signal confirmed(career)
const Category = preload("res://scripts/data/athlete_category.gd")
const Career = preload("res://scripts/career/career_data.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
const Hairstyles = preload("res://scripts/data/hairstyle_catalog.gd")
var category_hairstyles := {"male": 5, "female": 10}
const Appearance = preload("res://scripts/data/appearance_data.gd")
const Brand = preload("res://scripts/branding/brand.gd")
const Room = preload("res://scripts/customization/locker_room.gd")
const Model = preload("res://scripts/customization/procedural_athlete.gd")
const Card = preload("res://scripts/ui/studio/choice_card.gd")
const Choices = preload("res://scripts/ui/studio/choice_grid.gd")
const PlayerCard = preload("res://scripts/ui/studio/player_card.gd")
const TITLES := ["CHOOSE YOUR ATHLETE", "WHERE IT ALL BEGINS", "MAKE IT YOURS", "DEFINE YOUR IDENTITY", "BEGIN YOUR LEGACY"]
const NOTES := ["Every champion has a beginning.", "Choose the story that starts your journey.", "Create the athlete you want to become.", "Give your athlete a name and a home.", "Your journey starts here."]
var draft = Career.new()
var step := 0
var appearance_tab := 0
var sections: Array[VBoxContainer] = []
var fields: Dictionary = {}
var numeric_editors: Array[SpinBox] = []
var pending_numeric: Dictionary = {}
var sliders: Dictionary = {}
var body_editors: Dictionary = {}
var category_buttons: Array[Button] = []
var origin_buttons: Array[Button] = []
var tab_buttons: Array[Button] = []
var appearance_panels: Array[VBoxContainer] = []
var category_caption: Label
var origin_caption: Label
var age_caption: Label
var heading: Label
var description: Label
var summary
var error: Label
var next_button: Button
var back_button: Button
var split: BoxContainer
var preview_pane: VBoxContainer
var viewport_container: SubViewportContainer
var outer_margin: MarginContainer
var layout: VBoxContainer
var left_pane: VBoxContainer
var appearance_tabs: HBoxContainer
var scroll: ScrollContainer
var progress: Array[Label] = []
var preview_room
var preview_model

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = _creator_theme()
	var background := ColorRect.new()
	background.color = Color("101820")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	outer_margin = MarginContainer.new()
	outer_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(outer_margin)
	layout = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	outer_margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var emblem := Brand.logo(true)
	emblem.custom_minimum_size = Vector2(44,34)
	header.add_child(emblem)
	var wordmark := _label(header, "ROAD TO GOLD", 24, Color("c6a66b"))
	wordmark.autowrap_mode = TextServer.AUTOWRAP_OFF
	wordmark.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var subtitle := _label(header, "CAREER CREATION / THE LOCKER ROOM", 13)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_OFF
	var steps := HBoxContainer.new()
	layout.add_child(steps)
	for index in range(5):
		var indicator := _label(steps, "", 14)
		indicator.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		progress.append(indicator)
	layout.add_child(HSeparator.new())
	split = BoxContainer.new()
	split.add_theme_constant_override("separation", 24)
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(split)
	left_pane = VBoxContainer.new()
	left_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_pane.size_flags_stretch_ratio = 1.22
	left_pane.add_theme_constant_override("separation", 12)
	split.add_child(left_pane)
	heading = _label(left_pane, "", 26)
	description = _label(left_pane, "", 17, Color("b7c0c5"))
	appearance_tabs = HBoxContainer.new()
	appearance_tabs.add_theme_constant_override("separation", 8)
	left_pane.add_child(appearance_tabs)
	scroll = ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_pane.add_child(scroll)
	var padding := MarginContainer.new()
	padding.add_theme_constant_override("margin_right", 16)
	padding.add_theme_constant_override("margin_bottom", 16)
	padding.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(padding)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	padding.add_child(content)
	for index in range(5):
		var section := VBoxContainer.new()
		section.add_theme_constant_override("separation", 12)
		section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sections.append(section)
		content.add_child(section)
	_build_categories()
	_build_origins()
	_build_identity()
	_build_appearance()
	summary = PlayerCard.new()
	sections[4].add_child(summary)
	_label(sections[4], "Your career is saved only when you choose BEGIN CAREER. Replacing existing progress requires confirmation.", 14, Color("b7c0c5"))
	_build_preview()
	layout.add_child(HSeparator.new())
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 12)
	layout.add_child(footer)
	back_button = _button(footer, "BACK", _back)
	var message := VBoxContainer.new()
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.add_theme_constant_override("separation", 2)
	footer.add_child(message)
	var hint := _label(message, "DRAFT / NOT SAVED UNTIL CONFIRMED", 12, Color("b7c0c5"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	error = _label(message, "", 14, Color("ffbc9c"))
	error.custom_minimum_size.y = 36
	error.max_lines_visible = 2
	error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	next_button = _button(footer, "CONTINUE", _next)
	resized.connect(_resize_layout)
	_resize_layout()
	hide()
	_show_step()

func _build_categories() -> void:
	category_caption = _label(sections[0], "Choose an athlete category to continue.", 16, Color("c6a66b"))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	sections[0].add_child(row)
	var group := ButtonGroup.new()
	for index in range(Category.IDS.size()):
		var id: String = Category.IDS[index]
		var button = Card.new()
		button.configure(Category.label(id).to_upper(), "All origins • Full customization", "athlete", index)
		button.custom_minimum_size = Vector2(140,224)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.button_group = group
		button.pressed.connect(func(): select_category(id))
		row.add_child(button)
		category_buttons.append(button)
	_label(sections[0], "Choose how you compete. Your story and appearance remain yours.", 15, Color("b7c0c5"))

func _build_origins() -> void:
	origin_caption = _label(sections[1], "Selected: FROM NOTHING — age 15", 15, Color("c6a66b"))
	var group := ButtonGroup.new()
	var index := 0
	for entry: Dictionary in Catalog.origins():
		var button = Card.new()
		button.configure(entry.title, "AGE %d  /  %s" % [entry.age, entry.description], "story", index)
		button.custom_minimum_size.y = 124
		button.button_group = group
		button.button_pressed = entry.id == draft.origin_id
		button.pressed.connect(func():
			draft.origin_id = entry.id
			origin_caption.text = "Selected: %s — age %d" % [entry.title, entry.age]
			age_caption.text = "STARTING AGE / %d" % entry.age
		)
		sections[1].add_child(button)
		origin_buttons.append(button)
		index += 1

func _build_identity() -> void:
	age_caption = _label(sections[3], "STARTING AGE / 15", 15, Color("c6a66b"))
	for key: String in ["first_name", "last_name"]:
		var line := LineEdit.new()
		line.max_length = 32
		line.placeholder_text = "First name" if key == "first_name" else "Last name"
		_field(sections[3], line.placeholder_text, line)
		fields[key] = line
		line.text_changed.connect(func(_text): _changed())
	var country := OptionButton.new()
	for entry: Dictionary in Catalog.countries():
		country.add_item(entry.name)
		country.set_item_metadata(country.item_count-1, entry.code)
		if entry.code == draft.athlete.country: country.select(country.item_count-1)
	_field(sections[3], "Country", country)
	fields.country = country
	country.item_selected.connect(func(_index): _changed())

func _build_appearance() -> void:
	var tabs := appearance_tabs
	var group := ButtonGroup.new()
	for index in range(3):
		var button := _button(tabs, ["HAIR", "SKIN", "BODY"][index], func(): select_appearance_tab(index))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.x = 70
		button.toggle_mode = true
		button.button_group = group
		tab_buttons.append(button)
		var panel := VBoxContainer.new()
		panel.add_theme_constant_override("separation", 12)
		appearance_panels.append(panel)
		sections[2].add_child(panel)
	fields.hairstyle = _choices(appearance_panels[0], "HAIRSTYLE", Hairstyles.names("male"), 1, "hair_male")
	fields.hair_color = _choices(appearance_panels[0], "HAIR COLOR", Appearance.HAIR_NAMES, draft.athlete.appearance.hair_color, "color", Appearance.HAIR_COLORS)
	fields.skin = _choices(appearance_panels[1], "SKIN TONE", ["Tone 1","Tone 2","Tone 3","Tone 4","Tone 5","Tone 6"], draft.athlete.appearance.skin, "color", Appearance.SKIN_COLORS)
	_label(appearance_panels[1], "Your skin tone is cosmetic and never determines athletic ability.", 15, Color("b7c0c5"))
	for key: String in ["height", "weight", "shoulders", "legs"]:
		var editor := _number(appearance_panels[2], key, fields.get(key))
		body_editors[key] = editor
		if not fields.has(key): fields[key] = editor
	_label(appearance_panels[2], "Height, weight and body proportions are cosmetic; movement stays the same.", 14, Color("b7c0c5"))
	select_appearance_tab(appearance_tab)

func _choices(parent: Node, title: String, labels: Array, initial: int, kind: String, colors: Array = []):
	_label(parent, title, 14, Color("b7c0c5"))
	var picker = Choices.new()
	parent.add_child(picker)
	picker.configure(labels, initial, kind, colors)
	picker.item_selected.connect(func(_index): _changed())
	return picker

func _number(parent: Node, key: String, canonical = null) -> SpinBox:
	var title: String = {"height":"Height","weight":"Weight","shoulders":"Shoulder width","legs":"Leg proportion"}[key]
	_label(parent, title, 15)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var slider := HSlider.new()
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 80
	slider.tooltip_text = title + " / arrow keys adjust precisely"
	row.add_child(slider)
	var spin := SpinBox.new()
	spin.min_value = Appearance.LIMITS[key][0]
	spin.max_value = Appearance.LIMITS[key][1]
	spin.step = 0.05 if key in ["shoulders", "legs"] else 1.0
	spin.value = draft.athlete.appearance.get(key)
	spin.suffix = "cm" if key == "height" else ("kg" if key == "weight" else "×")
	spin.custom_minimum_size = Vector2(112,40)
	spin.tooltip_text = title + " / exact value"
	row.add_child(spin)
	if canonical != null: canonical.share(spin)
	spin.share(slider)
	if not sliders.has(key): sliders[key] = slider
	numeric_editors.append(spin)
	if canonical == null: spin.value_changed.connect(func(_value): _changed())
	spin.get_line_edit().text_changed.connect(func(_text): pending_numeric[spin.get_instance_id()] = spin)
	return spin

func _build_preview() -> void:
	preview_pane = VBoxContainer.new()
	preview_pane.custom_minimum_size.x = 320
	preview_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview_pane.size_flags_vertical = Control.SIZE_EXPAND_FILL
	split.add_child(preview_pane)
	_label(preview_pane, "ATHLETE STUDIO / LIVE PREVIEW", 13, Color("c6a66b"))
	viewport_container = SubViewportContainer.new()
	viewport_container.stretch = true
	viewport_container.custom_minimum_size = Vector2(200,170)
	viewport_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	viewport_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_pane.add_child(viewport_container)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320,400)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport_container.add_child(viewport)
	preview_room = Room.new()
	viewport.add_child(preview_room)
	preview_model = Model.new()
	# Preview only: local -Z front is presented at a clear ~30-degree three-quarter angle.
	# Camera and shared/gameplay meshes retain their existing transforms.
	preview_model.rotation.y = deg_to_rad(230.0)
	preview_room.add_child(preview_model)

func _label(parent: Node, text: String, font_size: int, color := Color("e9e8e3")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(140,44)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _field(parent: Node, title: String, control: Control) -> void:
	_label(parent, title, 15)
	control.custom_minimum_size.y = 40
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.tooltip_text = title
	parent.add_child(control)

func select_appearance_tab(index: int) -> void:
	if index < 0 or index >= appearance_panels.size(): return
	if is_node_ready(): _capture(true)
	appearance_tab = index
	for i in range(appearance_panels.size()):
		appearance_panels[i].visible = i == index
		tab_buttons[i].set_pressed_no_signal(i == index)
	if scroll != null: scroll.scroll_vertical = 0

func _capture(commit_edits := false) -> void:
	if commit_edits:
		for editor: SpinBox in numeric_editors:
			if pending_numeric.has(editor.get_instance_id()):
				editor.apply()
				pending_numeric.erase(editor.get_instance_id())
	draft.athlete.first_name = fields.first_name.text
	draft.athlete.last_name = fields.last_name.text
	draft.athlete.country = fields.country.get_item_metadata(fields.country.selected)
	for key: String in ["skin","hair_color"]: draft.athlete.appearance.set(key, fields[key].selected)
	if Category.valid(draft.athlete_category):
		draft.athlete.appearance.hairstyle = Hairstyles.ids(draft.athlete_category)[fields.hairstyle.selected]
		category_hairstyles[draft.athlete_category] = draft.athlete.appearance.hairstyle
	for key: String in ["height","weight","shoulders","legs"]: draft.athlete.appearance.set(key, fields[key].value)

func _changed() -> void:
	if not is_node_ready(): return
	_capture()
	for key: String in ["skin","hairstyle","hair_color"]: fields[key].select(fields[key].selected)
	preview_model.apply_appearance(draft.athlete.appearance, draft.athlete_category)
	error.text = ""

func select_category(id: String) -> void:
	if not Category.valid(id): return
	_capture(true)
	draft.athlete_category = id
	draft.athlete.appearance.hairstyle = category_hairstyles[id]
	fields.hairstyle.configure(Hairstyles.names(id), Hairstyles.ids(id).find(category_hairstyles[id]), "hair_" + id)
	for index in range(category_buttons.size()): category_buttons[index].set_pressed_no_signal(Category.IDS[index] == id)
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
		progress[index].text = "%02d  %s%s" % [index+1,["ATHLETE","STORY","APPEARANCE","IDENTITY","LEGACY"][index]," •" if index == step else ""]
		progress[index].add_theme_color_override("font_color", Color("c6a66b") if index == step else Color("a0abb3"))
	for index in range(sections.size()): sections[index].visible = index == step
	appearance_tabs.visible = step == 2
	back_button.text = "MAIN MENU" if step == 0 else "BACK"
	next_button.text = "BEGIN CAREER" if step == 4 else "CONTINUE"
	error.text = ""
	scroll.scroll_vertical = 0
	if step == 4: summary.present(draft)
	if visible: next_button.grab_focus()

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
	if split == null: return
	split.vertical = size.x < 620
	preview_pane.custom_minimum_size.x = 0 if split.vertical else (260 if size.x < 800 else 320)
	scroll.custom_minimum_size.y = 80 if split.vertical else 0
	if fields.has("hair_color"):
		fields.hair_color.grid.columns = 3 if size.x < 1000 else 5
	viewport_container.custom_minimum_size.y = 150 if split.vertical else 170
	layout.add_theme_constant_override("separation", 8 if size.y < 680 else 12)
	for side: String in ["left","right","top","bottom"]: outer_margin.add_theme_constant_override("margin_"+side,16 if size.x < 1000 else 24)

func _creator_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 17
	result.set_color("font_color", "Label", Color("e9e8e3"))
	for type: String in ["Button","OptionButton","LineEdit","SpinBox","PopupMenu"]:
		for color_name: String in ["font_color","font_hover_color","font_pressed_color"]: result.set_color(color_name,type,Color("e9e8e3"))
		for state: String in ["normal","hover","pressed","focus","panel"]:
			var box := StyleBoxFlat.new()
			box.bg_color = Color("28333b") if state in ["hover","pressed"] else Color("172129")
			box.border_color = Color("c6a66b") if state in ["focus","pressed"] else Color("41505b")
			box.set_border_width_all(2 if state == "focus" else 1)
			box.set_corner_radius_all(5)
			box.content_margin_left = 12
			box.content_margin_right = 12
			box.content_margin_top = 8
			box.content_margin_bottom = 8
			if state == "focus": box.bg_color = Color.TRANSPARENT
			result.set_stylebox(state,type,box)
	var track := StyleBoxFlat.new()
	track.bg_color = Color("28333b")
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	result.set_stylebox("slider","HSlider",track)
	var fill := track.duplicate()
	fill.bg_color = Color("c6a66b")
	result.set_stylebox("grabber_area","HSlider",fill)
	result.set_stylebox("grabber_area_highlight","HSlider",fill)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("c6a66b")
	focus.set_border_width_all(1)
	result.set_stylebox("focus","HSlider",focus)
	for state: String in ["grabber","grabber_highlight"]:
		var image := Image.create(16,16,false,Image.FORMAT_RGBA8)
		image.fill(Color.TRANSPARENT)
		for y in range(16):
			for x in range(16):
				if Vector2(x-7.5,y-7.5).length() <= 6:
					image.set_pixel(x,y,Color("c6a66b" if state=="grabber" else "e9e8e3"))
		result.set_icon(state,"HSlider",ImageTexture.create_from_image(image))
	return result
