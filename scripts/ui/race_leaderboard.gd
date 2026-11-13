extends VBoxContainer
## Read-only classification view. It does not calculate or persist race outcomes.
const Data=preload("res://scripts/race/competition_data.gd")
const GOLD=Color("c6a66b")
const MUTED=Color("a5b5be")
var scroll:ScrollContainer
var body:VBoxContainer
var cells:Dictionary={}
var ordered_ids:Array=[]

func _ready():
	add_theme_constant_override("separation",6)
	var header=HBoxContainer.new();header.add_theme_constant_override("separation",8);add_child(header)
	for entry:Array in [["Place",46],["Lane",42],["Athlete",0],["Time",86]]:
		var label=_cell(header,entry[0],entry[1],12,MUTED)
		if entry[0]=="Time":label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;scroll.focus_mode=Control.FOCUS_ALL;scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;add_child(scroll)
	scroll.gui_input.connect(_scroll_key)
	body=VBoxContainer.new();body.add_theme_constant_override("separation",2);body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(body)

func _cell(parent:Node,text:String,width:int,font:int,color:Color)->Label:
	var label=Label.new();label.text=text;label.custom_minimum_size.x=width;label.add_theme_font_size_override("font_size",font);label.add_theme_color_override("font_color",color)
	label.clip_text=true;label.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS;label.tooltip_text=text
	if width==0:label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(label);return label

func present(rows:Array):
	for child:Node in body.get_children():body.remove_child(child);child.queue_free()
	cells.clear();ordered_ids.clear()
	for row:Dictionary in Data.classify(rows):
		ordered_ids.append(row.id)
		var panel=PanelContainer.new();panel.focus_mode=Control.FOCUS_ALL;panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_child(panel)
		var player:bool=row.id=="player"
		var style=StyleBoxFlat.new();style.bg_color=Color("29332f") if player else (Color("15232e") if ordered_ids.size()%2==0 else Color("101e29"));style.border_color=GOLD if player else Color("2b3c48");style.set_border_width_all(1 if player else 0);style.set_corner_radius_all(3)
		style.content_margin_left=8;style.content_margin_right=8;style.content_margin_top=3;style.content_margin_bottom=3;panel.add_theme_stylebox_override("panel",style)
		var line=HBoxContainer.new();line.add_theme_constant_override("separation",8);panel.add_child(line)
		var color=GOLD if player else Color("e8ecee")
		var place=_cell(line,str(row.rank) if row.rank>0 else "DNF",38,15,color)
		var lane=_cell(line,str(row.lane+1),42,15,color)
		var athlete=_cell(line,row.name,0,15,color)
		var time=_cell(line,Data.time_text(row.time_us)+" s" if row.status=="FIN" else "DNF",78,15,color);time.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
		panel.tooltip_text="Place %s · Lane %s · %s · %s" % [place.text,lane.text,athlete.text,time.text]
		cells[row.id]={"panel":panel,"place":place,"lane":lane,"athlete":athlete,"time":time}

func _scroll_key(event:InputEvent):
	if not event is InputEventKey or not event.pressed:return
	var amount:=0
	match event.keycode:
		KEY_DOWN:amount=28
		KEY_UP:amount=-28
		KEY_PAGEDOWN:amount=180
		KEY_PAGEUP:amount=-180
		KEY_HOME:amount=-100000
		KEY_END:amount=100000
	if amount!=0:
		scroll.scroll_vertical+=amount;scroll.accept_event()
