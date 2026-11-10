extends PanelContainer
const Brand = preload("res://scripts/branding/brand.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
const Category = preload("res://scripts/data/athlete_category.gd")
const Appearance = preload("res://scripts/data/appearance_data.gd")
var profile_title: Label
var name_label: Label
var country_label: Label
var values: Dictionary = {}
var text: String:
	get:
		var lines := PackedStringArray([name_label.text, "Country: " + country_label.text])
		for key: String in values: lines.append(key + ": " + values[key].text)
		return "\n".join(lines)

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("28333b")
	style.border_color = Color("c6a66b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	add_child(layout)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	layout.add_child(header)
	var emblem := Brand.logo(true)
	emblem.custom_minimum_size = Vector2(32,24)
	header.add_child(emblem)
	profile_title = _label(header, "ATHLETE PROFILE", 12, Color("c6a66b"))
	profile_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	profile_title.custom_minimum_size.x = 130
	profile_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label = _label(layout, "", 26)
	name_label.max_lines_visible = 2
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	country_label = _label(layout, "", 17)
	values.Category = _label(layout, "", 15, Color("b7c0c5"))
	var origin_row := HBoxContainer.new()
	origin_row.add_theme_constant_override("separation", 12)
	layout.add_child(origin_row)
	values.Origin = _label(origin_row, "", 15)
	values.Origin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var age_caption := _label(origin_row, "AGE", 12, Color("c6a66b"))
	age_caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	age_caption.custom_minimum_size.x = 28
	values.Age = _label(origin_row, "", 15, Color("c6a66b"))
	values.Age.autowrap_mode = TextServer.AUTOWRAP_OFF
	values.Age.custom_minimum_size.x = 24
	layout.add_child(HSeparator.new())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	layout.add_child(grid)
	for key: String in ["Height", "Weight", "Hairstyle", "Hair color", "Skin", "Shoulders", "Leg proportion"]:
		var cell := VBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 2)
		grid.add_child(cell)
		_label(cell, key.to_upper(), 12, Color("b7c0c5"))
		values[key] = _label(cell, "", 17)

func _label(parent: Node, content: String, font_size: int, color := Color("e9e8e3")) -> Label:
	var label := Label.new()
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func present(career) -> void:
	var data: Dictionary = career.to_dict()
	var appearance: Dictionary = data.athlete.appearance
	name_label.text = data.athlete.first_name + " " + data.athlete.last_name
	name_label.tooltip_text = name_label.text
	country_label.text = Catalog.country_name(data.athlete.country)
	var entries := {"Category": Category.label(career.athlete_category), "Origin": Catalog.origin(career.origin_id).title, "Age": str(int(data.age)), "Height": "%.0f cm" % appearance.height, "Weight": "%.0f kg" % appearance.weight, "Skin": "Tone %d" % (appearance.skin+1), "Hairstyle": Appearance.STYLES[appearance.hairstyle], "Hair color": Appearance.HAIR_NAMES[appearance.hair_color], "Shoulders": "%.2f ×" % appearance.shoulders, "Leg proportion": "%.2f ×" % appearance.legs}
	for key: String in entries: values[key].text = entries[key]
