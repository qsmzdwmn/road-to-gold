extends VBoxContainer
signal command_requested(id: String, token: String)
const State=preload("res://scripts/training/training_state.gd")
const Rules=preload("res://scripts/training/training_service.gd")
const GOLD=Color("c6a66b")
const MUTED=Color("a5b5be")
var state:Dictionary=State.initial()
var token:=""
var migration:=false
var busy:=false
var selected:=""
var preview_token:=""
var day_label:Label
var fatigue_label:Label
var fatigue_bar:ProgressBar
var attribute_grid:GridContainer
var attributes:Dictionary={}
var buttons:Dictionary={}
var reasons:Dictionary={}
var result_label:Label
var confirmation:ConfirmationDialog
var end_button:Button

func _ready():
	add_theme_constant_override("separation",12)
	day_label=_label(self,"",18,GOLD)
	_label(self,"Training days are separate from athlete age and calendar dates.",13,MUTED)
	fatigue_label=_label(self,"",15)
	fatigue_bar=_bar(self,100)
	attribute_grid=GridContainer.new();attribute_grid.add_theme_constant_override("h_separation",16);attribute_grid.add_theme_constant_override("v_separation",8);add_child(attribute_grid)
	for id:String in State.ATTRIBUTES:
		var box=VBoxContainer.new();box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;attribute_grid.add_child(box)
		attributes[id]={"label":_label(box,"",15),"bar":_bar(box,10000)}
	var activities=GridContainer.new();activities.columns=2;activities.add_theme_constant_override("h_separation",12);activities.add_theme_constant_override("v_separation",10);add_child(activities)
	for id:String in Rules.ACTIVITIES:
		var panel=PanelContainer.new();panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var style=StyleBoxFlat.new();style.bg_color=Color("15232e");style.border_color=Color("2b3c48");style.set_border_width_all(1);style.set_corner_radius_all(6);style.set_content_margin_all(12);panel.add_theme_stylebox_override("panel",style);activities.add_child(panel)
		var box=VBoxContainer.new();box.add_theme_constant_override("separation",6);panel.add_child(box)
		buttons[id]=_button(box,Rules.ACTIVITIES[id].title,func(): preview(id))
		reasons[id]=_label(box,"",13,MUTED)
	end_button=_button(self,"End Training Day · Preview",func(): preview("end_day"))
	result_label=_label(self,"",14);result_label.focus_mode=Control.FOCUS_ALL;result_label.hide()
	confirmation=ConfirmationDialog.new();confirmation.title="Confirm training";confirmation.get_ok_button().text="Confirm & Save";confirmation.dialog_autowrap=true;confirmation.min_size=Vector2i(520,300);add_child(confirmation)
	var dialog_style=StyleBoxFlat.new();dialog_style.bg_color=Color("111f2a");dialog_style.border_color=GOLD;dialog_style.set_border_width_all(1);dialog_style.set_content_margin_all(16)
	confirmation.add_theme_stylebox_override("panel",dialog_style)
	confirmation.add_theme_color_override("title_color",GOLD)
	confirmation.get_label().add_theme_font_size_override("font_size",16)
	confirmation.confirmed.connect(_confirm)
	resized.connect(_resize);_resize();present(State.initial(),"",false)

func _label(parent:Node,text:String,font:int,color:=Color("e8ecee"))->Label:
	var label=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",font);label.add_theme_color_override("font_color",color);parent.add_child(label);return label

func _bar(parent:Node,maximum:int)->ProgressBar:
	var bar=ProgressBar.new();bar.max_value=maximum;bar.show_percentage=false;bar.custom_minimum_size.y=7;bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var fill=StyleBoxFlat.new();fill.bg_color=GOLD;fill.set_corner_radius_all(3);bar.add_theme_stylebox_override("fill",fill)
	var background=StyleBoxFlat.new();background.bg_color=Color("2b3c48");background.set_corner_radius_all(3);bar.add_theme_stylebox_override("background",background);parent.add_child(bar);return bar

func _button(parent:Node,text:String,callback:Callable)->Button:
	var button=Button.new();button.text=text;button.custom_minimum_size.y=40;button.add_theme_font_size_override("font_size",15);button.size_flags_horizontal=Control.SIZE_EXPAND_FILL;button.pressed.connect(callback);parent.add_child(button);return button

func _resize():
	if attribute_grid:attribute_grid.columns=4 if size.x>=800 else 2

func present(value:Dictionary,save_token:String,needs_migration:bool,message:=""):
	state=value.duplicate(true);token=save_token;migration=needs_migration;busy=false
	day_label.text="Training Day %d  ·  %d / 2 actions remaining" % [state.day,2-int(state.actions_used)]
	var level="Fresh" if state.fatigue<30 else ("Tired" if state.fatigue<60 else ("High fatigue" if state.fatigue<80 else "Recovery recommended"))
	fatigue_label.text="Fatigue %d / 100  ·  %s" % [state.fatigue,level];fatigue_bar.value=state.fatigue
	for id:String in attributes:
		attributes[id].label.text=id.capitalize()+"  "+Rules.display(state.attributes[id]);attributes[id].bar.value=state.attributes[id]
	for id:String in buttons:
		var preview_result=Rules.calculate(state,id)
		buttons[id].disabled=token.is_empty() or not preview_result.ok
		buttons[id].tooltip_text=preview_result.get("error","Preview exact gains before confirming.")
		if preview_result.ok:
			var parts:PackedStringArray=[]
			for attribute:String in State.ATTRIBUTES:
				var delta=int(preview_result.after.attributes[attribute])-int(state.attributes[attribute])
				if delta>0:parts.append(attribute.capitalize()+" +"+Rules.display(delta))
			parts.append("Fatigue %+d · 1 action" % (int(preview_result.after.fatigue)-int(state.fatigue)))
			reasons[id].text=" · ".join(parts)
		else:reasons[id].text=preview_result.error
	end_button.disabled=token.is_empty() or not Rules.calculate(state,"end_day").ok
	var lines:PackedStringArray=message.split("\n")
	if message.begins_with("Saved · "):
		var rating_lines:PackedStringArray=[]
		var other_lines:PackedStringArray=[]
		for line:String in lines:
			if line.begins_with("Speed:") or line.begins_with("Acceleration:") or line.begins_with("Stamina:") or line.begins_with("Recovery:"):rating_lines.append(line)
			else:other_lines.append(line)
		if not rating_lines.is_empty():other_lines.insert(1," · ".join(rating_lines))
		lines=other_lines
	result_label.text="\n".join(lines);result_label.tooltip_text=message
	result_label.visible=not message.is_empty()

func preview(id:String):
	if busy or token.is_empty() or confirmation.visible:return
	var candidate=Rules.calculate(state,id)
	if not candidate.ok:return
	selected=id;preview_token=token
	confirmation.title="End Training Day" if id=="end_day" else Rules.ACTIVITIES[id].title
	confirmation.dialog_text=candidate.summary+"\n\n"+("First training save upgrades this career to schema 4. A verified original-save backup will be kept. Older game versions cannot read schema 4.\n\n" if migration else "")+"Confirm to save these changes. Cancel keeps your current values."
	confirmation.popup_centered(Vector2i(mini(600,int(get_viewport_rect().size.x)-40),380 if not migration else 460))

func _confirm():
	if busy or selected.is_empty():return
	busy=true
	var command:=selected;selected=""
	for button:Button in buttons.values():button.disabled=true
	end_button.disabled=true
	command_requested.emit(command,preview_token)

func failed(message:String):
	# Keep the exact authoritative values and token. User can retry only via a new preview.
	present(state,token,migration,"Not saved. No training applied.\n"+message)
