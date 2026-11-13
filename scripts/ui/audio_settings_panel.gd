extends VBoxContainer
## Small reusable preference view. No career-save dependency.
var director
var sliders:Dictionary={}
var percentages:Dictionary={}
var mute:CheckButton
var status:Label
func _ready():
	add_theme_constant_override("separation",6)
	var heading=Label.new();heading.text="Audio";heading.add_theme_font_size_override("font_size",18);add_child(heading)
	for entry:Array in [["music","Music"],["sfx","Sound Effects"],["crowd","Stadium Crowd"]]:
		var row=HBoxContainer.new();add_child(row)
		var label=Label.new();label.text=entry[1];label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",16);row.add_child(label)
		var value=Label.new();value.custom_minimum_size.x=46;value.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;value.add_theme_font_size_override("font_size",16);row.add_child(value);percentages[entry[0]]=value
		var slider=HSlider.new();slider.name=entry[0].capitalize()+"Volume";slider.min_value=0;slider.max_value=100;slider.step=1;slider.custom_minimum_size.y=26;slider.size_flags_horizontal=Control.SIZE_EXPAND_FILL;slider.tooltip_text=entry[1]+" volume. Left/Right arrows adjust; zero is silent.";slider.accessibility_name=entry[1]+" volume";add_child(slider);sliders[entry[0]]=slider
		slider.value_changed.connect(_volume_changed.bind(entry[0]))
	mute=CheckButton.new();mute.text="Mute All";mute.custom_minimum_size.y=40
	mute.add_theme_icon_override("checked",_switch_icon(true));mute.add_theme_icon_override("unchecked",_switch_icon(false))
	mute.tooltip_text="Mute all audio while preserving each volume. Space toggles this switch.";mute.accessibility_name="Mute all audio"
	add_child(mute);mute.toggled.connect(_mute_changed)
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",14);status.add_theme_color_override("font_color",Color("a5b5be"));add_child(status)
func bind_director(value):
	director=value;director.preferences_changed.connect(refresh);refresh()
func refresh():
	if director==null:return
	for key:String in sliders:
		sliders[key].set_value_no_signal(director.preferences[key]);percentages[key].text="%d%%" % director.preferences[key]
	mute.set_pressed_no_signal(director.preferences.mute_all)
	mute.text="Mute All · ON" if director.preferences.mute_all else "Mute All · OFF"
	status.text=director.notice if not director.notice.is_empty() else "Audio starts after interaction. Preferences are separate from careers."
func _volume_changed(value:float,key:String):
	if director!=null:director.set_preference(key,int(value))
func _mute_changed(value:bool):
	if director!=null:director.set_preference("mute_all",value)

func _switch_icon(enabled:bool) -> Texture2D:
	# Two tiny original UI textures, generated once when Settings is built.
	var svg='<svg xmlns="http://www.w3.org/2000/svg" width="56" height="28"><rect x="1" y="1" width="54" height="26" rx="13" fill="%s" stroke="%s" stroke-width="2"/><circle cx="%d" cy="14" r="9" fill="%s"/></svg>' % ["#c6a66b" if enabled else "#172630","#eacb86" if enabled else "#a5b5be",42 if enabled else 14,"#101c28" if enabled else "#f1eee4"]
	var image=Image.new();image.load_svg_from_string(svg)
	return ImageTexture.create_from_image(image)
