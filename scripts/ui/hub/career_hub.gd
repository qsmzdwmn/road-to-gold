extends Control
## Career presentation and training commands. Main routes; Repository is the only writer.
signal menu_requested
signal save_requested
signal track_requested
signal settings_requested
signal training_requested(id: String, token: String)
const TrainingPanel=preload("res://scripts/ui/hub/training_panel.gd")
var training_panel
const Brand = preload("res://scripts/branding/brand.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
const Category = preload("res://scripts/data/athlete_category.gd")
const PlayerCard = preload("res://scripts/ui/studio/player_card.gd")
const Model = preload("res://scripts/customization/procedural_athlete.gd")
const Room = preload("res://scripts/customization/locker_room.gd")
const SECTIONS := {"overview":"Overview", "my_athlete":"My Athlete", "training":"Training", "calendar":"Calendar", "records":"Records", "settings":"Settings"}
const GOLD := Color("c6a66b")
const MUTED := Color("a5b5be")
var career
var active_section := "overview"
var pages: Dictionary = {}
var nav_buttons: Dictionary = {}
var labels: Dictionary = {}
var sidebar: PanelContainer
var main_margin: MarginContainer
var title: Label
var status: Label
var scroll: ScrollContainer
var overview_grid: GridContainer
var athlete_layout: BoxContainer
var player_card
var preview_container: SubViewportContainer
var preview_model
var preview_room
var preview_viewport: SubViewport
var menu_button: Button
var save_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("0c151e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shell := HBoxContainer.new()
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("separation",0)
	add_child(shell)
	sidebar = PanelContainer.new()
	sidebar.add_theme_stylebox_override("panel",_surface(Color("111f2a"),16))
	shell.add_child(sidebar)
	var rail := VBoxContainer.new()
	rail.add_theme_constant_override("separation",12)
	sidebar.add_child(rail)
	var brand_row := HBoxContainer.new()
	brand_row.add_theme_constant_override("separation",10)
	rail.add_child(brand_row)
	var emblem := Brand.logo(true)
	emblem.custom_minimum_size=Vector2(30,38)
	brand_row.add_child(emblem)
	_label(brand_row,"ROAD TO\nGOLD",17,GOLD)
	_label(rail,"ATHLETE HQ",12,MUTED)
	rail.add_child(HSeparator.new())
	var links := VBoxContainer.new()
	links.add_theme_constant_override("separation",6)
	rail.add_child(links)
	var group := ButtonGroup.new()
	for id: String in SECTIONS:
		var button := _button(links,SECTIONS[id],func(): select_section(id))
		if id=="training":
			button.text="Training"
			button.tooltip_text="Train attributes and manage fatigue."
		button.toggle_mode=true
		button.button_group=group
		button.alignment=HORIZONTAL_ALIGNMENT_LEFT
		nav_buttons[id]=button
	var spacer := Control.new()
	spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL
	rail.add_child(spacer)
	menu_button=_button(rail,"Main Menu",func(): menu_requested.emit())
	_label(rail,"LOCAL CAREER\nOne saved profile",12,MUTED)
	main_margin=MarginContainer.new()
	main_margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	shell.add_child(main_margin)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation",16)
	main_margin.add_child(main)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation",16)
	main.add_child(header)
	var heading := VBoxContainer.new()
	heading.add_theme_constant_override("separation",4)
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	var kicker := _label(heading,"YOUR GOLDEN LEGACY",12,GOLD)
	kicker.autowrap_mode=TextServer.AUTOWRAP_OFF
	title=_label(heading,"Overview",28)
	title.autowrap_mode=TextServer.AUTOWRAP_OFF
	save_button=_button(header,"Save & Menu",func(): save_requested.emit())
	save_button.size_flags_horizontal=Control.SIZE_SHRINK_END
	save_button.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	save_button.custom_minimum_size.x=132
	scroll=ScrollContainer.new()
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus=true
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	main.add_child(scroll)
	var inset := MarginContainer.new()
	inset.add_theme_constant_override("margin_right",12)
	inset.add_theme_constant_override("margin_bottom",12)
	inset.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(inset)
	var page_stack := VBoxContainer.new()
	page_stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	inset.add_child(page_stack)
	for id: String in SECTIONS:
		if id=="settings":continue
		var page := VBoxContainer.new()
		page.add_theme_constant_override("separation",16)
		page.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		page_stack.add_child(page)
		pages[id]=page
	_build_overview(pages.overview)
	_build_athlete(pages.my_athlete)
	training_panel=TrainingPanel.new()
	pages.training.add_child(training_panel)
	training_panel.command_requested.connect(func(id: String, token: String): training_requested.emit(id,token))
	_empty(pages.calendar,"No events scheduled","The career calendar is not available yet. There are no competitions to enter or dates to advance.")
	_empty(pages.records,"No recorded performances","No race results or personal bests have been recorded. Competitions and record tracking are not available yet.")
	main.add_child(HSeparator.new())
	status=_label(main,"",13,MUTED)
	status.custom_minimum_size.y=36
	status.max_lines_visible=3
	status.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	resized.connect(_resize)
	_resize()
	hide()
	select_section("overview")

func _surface(color: Color, padding := 16, accent := false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=GOLD if accent else Color("2b3c48")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(padding)
	return style

func _card(parent: Node, accent := false) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel",_surface(Color("15232e"),16,accent))
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",8)
	panel.add_child(stack)
	return stack

func _label(parent: Node, text: String, font_size: int, color := Color("e8ecee")) -> Label:
	var label := Label.new()
	label.text=text
	label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text=text
	button.custom_minimum_size.y=44
	button.add_theme_font_size_override("font_size",16)
	button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for state: String in ["normal","hover","pressed","focus"]:
		var style := _surface(Color("233744") if state in ["hover","pressed"] else Color("15232e"),10,state in ["pressed","focus"])
		style.set_border_width_all(2 if state=="focus" else 1)
		button.add_theme_stylebox_override(state,style)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_overview(page: VBoxContainer) -> void:
	page.add_theme_constant_override("separation",14)
	var hero := _card(page,true)
	var hero_row := HBoxContainer.new()
	hero_row.add_theme_constant_override("separation",20)
	hero.add_child(hero_row)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation",5)
	hero_row.add_child(identity)
	_label(identity,"YOUR ATHLETE",12,GOLD)
	labels.name=_label(identity,"",26)
	labels.name.max_lines_visible=2
	labels.name.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	labels.identity=_label(identity,"",15,MUTED)
	labels.start=_label(identity,"",13,GOLD)
	hero_row.add_child(VSeparator.new())
	var state := VBoxContainer.new()
	state.custom_minimum_size.x=152
	state.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	state.add_theme_constant_override("separation",6)
	hero_row.add_child(state)
	_label(state,"CAREER STATUS",12,GOLD)
	_label(state,"Profile ready",19)
	_label(state,"Training available",13,MUTED)
	_label(state,"Choose Training to begin",12,MUTED)
	var origin_row := VBoxContainer.new()
	origin_row.add_theme_constant_override("separation",4)
	page.add_child(origin_row)
	labels.origin=_label(origin_row,"",14,GOLD)
	labels.origin_description=_label(origin_row,"",14,MUTED)
	overview_grid=GridContainer.new()
	overview_grid.add_theme_constant_override("h_separation",14)
	overview_grid.add_theme_constant_override("v_separation",14)
	page.add_child(overview_grid)
	var event := _card(overview_grid)
	_label(event,"UPCOMING EVENT",12,GOLD)
	_label(event,"No events scheduled",19)
	event.add_child(HSeparator.new())
	_label(event,"Competition scheduling is coming soon.",14,MUTED)
	var records := _card(overview_grid)
	_label(records,"PERSONAL BEST",12,GOLD)
	_label(records,"No recorded performances",19)
	records.add_child(HSeparator.new())
	_label(records,"Your results will appear here when competitions are available.",14,MUTED)
	var sandbox := HBoxContainer.new()
	sandbox.add_theme_constant_override("separation",16)
	page.add_child(sandbox)
	_label(sandbox,"TRACK SANDBOX\nMovement test only · No races or results",13,MUTED)
	var track := _button(sandbox,"Explore Track",func(): track_requested.emit())
	track.size_flags_horizontal=Control.SIZE_SHRINK_END
	track.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	track.custom_minimum_size.x=140

func _build_athlete(page: VBoxContainer) -> void:
	_label(page,"Your saved athlete. Profile and appearance are view-only.",15,MUTED)
	athlete_layout=BoxContainer.new()
	athlete_layout.add_theme_constant_override("separation",16)
	page.add_child(athlete_layout)
	player_card=PlayerCard.new()
	player_card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	player_card.size_flags_stretch_ratio=1.1
	athlete_layout.add_child(player_card)
	var presentation := _card(athlete_layout)
	_label(presentation,"ATHLETE PREVIEW",12,GOLD)
	preview_container=SubViewportContainer.new()
	preview_container.custom_minimum_size=Vector2(220,330)
	preview_container.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	preview_container.size_flags_vertical=Control.SIZE_EXPAND_FILL
	preview_container.stretch=true
	preview_container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	presentation.add_child(preview_container)
	preview_container.visibility_changed.connect(func(): _update_preview_mode.call_deferred())

func _ensure_preview() -> void:
	if preview_viewport!=null:return
	preview_viewport=SubViewport.new()
	preview_viewport.own_world_3d=true
	preview_viewport.size=Vector2i(320,400)
	preview_viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE
	preview_container.add_child(preview_viewport)
	preview_room=Room.new()
	preview_viewport.add_child(preview_room)
	preview_model=Model.new()
	preview_model.rotation.y=deg_to_rad(230.0)
	preview_room.add_child(preview_model)

func _update_preview_mode() -> void:
	if preview_viewport!=null:
		preview_viewport.render_target_update_mode=SubViewport.UPDATE_WHEN_VISIBLE if preview_container.is_visible_in_tree() else SubViewport.UPDATE_DISABLED

func _empty(page: VBoxContainer, heading: String, explanation: String) -> void:
	var card := _card(page)
	_label(card,heading,24)
	_label(card,explanation,16,MUTED)

func open(saved_career, message: String, reset_page := true) -> void:
	career=saved_career
	var data: Dictionary = career.to_dict()
	var origin := Catalog.origin(career.origin_id)
	labels.name.text=data.athlete.first_name+" "+data.athlete.last_name
	labels.name.tooltip_text=labels.name.text
	labels.identity.text=Catalog.country_name(data.athlete.country)+"  ·  "+Category.label(career.athlete_category)
	labels.start.text=origin.title+"  ·  Starting age "+str(int(data.age))
	labels.origin.text=origin.title
	labels.origin_description.text=origin.description
	player_card.present(career)
	status.text=message
	status.tooltip_text=message
	show()
	select_section("overview" if reset_page else active_section)

func select_section(id: String) -> void:
	if not SECTIONS.has(id):return
	if id=="settings":
		settings_requested.emit()
		return
	active_section=id
	title.text=SECTIONS[id]
	for page_id: String in pages:pages[page_id].visible=page_id==id
	for page_id: String in nav_buttons:nav_buttons[page_id].set_pressed_no_signal(page_id==id)
	scroll.scroll_vertical=0
	if id=="my_athlete" and career!=null:
		_ensure_preview()
		preview_model.apply_appearance(career.athlete.appearance,career.athlete_category)
	_update_preview_mode.call_deferred()
	if visible:nav_buttons[id].grab_focus()

func _resize() -> void:
	sidebar.custom_minimum_size.x=164 if size.x<1000 else 212
	for edge: String in ["left","right","top","bottom"]:main_margin.add_theme_constant_override("margin_"+edge,16 if size.x<1000 else 24)
	overview_grid.columns=2
	athlete_layout.vertical=size.x<1100
