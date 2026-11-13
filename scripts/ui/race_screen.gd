extends Control
signal hub_requested
signal category_requested(category:String)
signal result_ready(result:Dictionary)
const Quality=preload("res://scripts/race/race_quality.gd")
const Leaderboard=preload("res://scripts/ui/race_leaderboard.gd")
const Session=preload("res://scripts/race/race_session.gd")
const World=preload("res://scripts/race/race_world.gd")
const Physics=preload("res://scripts/race/sprint_physics.gd")
const Data=preload("res://scripts/race/competition_data.gd")
const Category=preload("res://scripts/data/athlete_category.gd")
const TrainingState=preload("res://scripts/training/training_state.gd")
const TrainingRules=preload("res://scripts/training/training_service.gd")
const GOLD=Color("c6a66b")
const MUTED=Color("a5b5be")
var audio_presenter
var session
var world
var world_container
var world_viewport
var snapshot:Dictionary={}
var profile:Dictionary={}
var career
var source_token:=""
var fingerprint:=""
var pending_result:Dictionary={}
var saved:=false
var result_emitted:=false
var warmup_frames:=0
var physics_budget_before:=-1
var last_physics_us:=0
var attempt_counter:=0
var seed_value:=1
var web_visibility_callback
var ui_root:MarginContainer
var area:Control
var preparation:PanelContainer
var results_panel:PanelContainer
var invalid_panel:PanelContainer
var info:Label
var readiness:Label
var readiness_status:Label
var mode_select:OptionButton
var category_form:VBoxContainer
var category_select:OptionButton
var ready_button:Button
var stadium_button:Button
var hud:Label
var player_marker:Label
var cue:Label
var invalid_message:Label
var results_title:Label
var results_rows:VBoxContainer
var result_status:Label
var result_note:Label
var previous_pb:Dictionary={}
var footer_text:Label
var race_again:Button
var results_hub:Button
var retry_save:Button
var leave_dialog:ConfirmationDialog

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_root=MarginContainer.new();ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side:String in ["left","right","top","bottom"]:ui_root.add_theme_constant_override("margin_"+side,16)
	add_child(ui_root)
	var layout=VBoxContainer.new();layout.add_theme_constant_override("separation",12);ui_root.add_child(layout)
	var top=_panel(layout);var top_row=HBoxContainer.new();top.add_child(top_row)
	var heading=_label(top_row,"ROAD TO GOLD  /  DEVELOPMENT MEET 100m",18,GOLD);heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	stadium_button=_button(top_row,"Stadium View",_toggle_stadium);stadium_button.add_theme_font_size_override("font_size",14)
	_button(top_row,"Career Hub",request_hub)
	var stats=_panel(layout);var stats_style=stats.get_theme_stylebox("panel").duplicate();stats_style.set_content_margin_all(6);stats.add_theme_stylebox_override("panel",stats_style)
	hud=_label(stats,"",15);hud.add_theme_color_override("font_shadow_color",Color.BLACK);hud.add_theme_constant_override("shadow_offset_x",1);hud.add_theme_constant_override("shadow_offset_y",1)
	area=Control.new();area.size_flags_vertical=Control.SIZE_EXPAND_FILL;layout.add_child(area);area.resized.connect(_resize)
	preparation=PanelContainer.new();area.add_child(preparation);_style(preparation)
	var prep_frame=VBoxContainer.new();prep_frame.add_theme_constant_override("separation",6);preparation.add_child(prep_frame)
	_label(prep_frame,"RACE READINESS",13,GOLD)
	var prep_scroll=_scroll(prep_frame);prep_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var prep=VBoxContainer.new();prep.add_theme_constant_override("separation",6);prep.size_flags_horizontal=Control.SIZE_EXPAND_FILL;prep_scroll.add_child(prep)
	info=_label(prep,"",18);info.max_lines_visible=1;info.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
	readiness=_label(prep,"",14,MUTED)
	mode_select=OptionButton.new();mode_select.add_item("Rhythm Sprint - alternate A/D or arrows");mode_select.set_item_metadata(0,"rhythm");mode_select.add_item("Hold Sprint - hold Space");mode_select.set_item_metadata(1,"hold");mode_select.add_theme_font_size_override("font_size",14);mode_select.custom_minimum_size.y=36;prep_frame.add_child(mode_select)
	_label(prep_frame,"Rhythm: 4 alternating presses/s. Hold: Space. Equal ceiling.",12,MUTED)
	category_form=VBoxContainer.new();category_form.add_theme_constant_override("separation",4);prep_frame.add_child(category_form)
	var category_notice=_label(category_form,"Legacy career: choose a category, then Save Category. Original backup kept.",13,GOLD)
	category_notice.tooltip_text="Category is never inferred. Saving this explicit choice keeps an original backup and preserves appearance values, age and training."
	var category_row=HBoxContainer.new();category_row.add_theme_constant_override("separation",6);category_form.add_child(category_row)
	category_select=OptionButton.new();category_select.add_item("Choose athlete category");category_select.set_item_metadata(0,"");category_select.add_item("Male Athlete");category_select.set_item_metadata(1,"male");category_select.add_item("Female Athlete");category_select.set_item_metadata(2,"female");category_select.add_theme_font_size_override("font_size",14);category_select.size_flags_horizontal=Control.SIZE_EXPAND_FILL;category_row.add_child(category_select)
	var save_category=_button(category_row,"Save Category",func():
		var selected:String=category_select.get_selected_metadata()
		if Category.valid(selected):category_requested.emit(selected)
		else:readiness_status.text="Choose Male Athlete or Female Athlete explicitly.";readiness_status.show())
	save_category.add_theme_font_size_override("font_size",14);save_category.custom_minimum_size.y=36
	readiness_status=_label(prep_frame,"",13,GOLD);readiness_status.hide()
	ready_button=_button(prep_frame,"Ready (Enter)",start)
	results_panel=PanelContainer.new();area.add_child(results_panel);_style(results_panel)
	results_panel.minimum_size_changed.connect(func():_resize.call_deferred())
	var result_body=VBoxContainer.new();result_body.add_theme_constant_override("separation",8);results_panel.add_child(result_body)
	results_title=_label(result_body,"RESULTS",20,GOLD)
	result_status=_label(result_body,"",14,GOLD)
	result_note=_label(result_body,"",14,MUTED)
	results_rows=Leaderboard.new();results_rows.size_flags_vertical=Control.SIZE_EXPAND_FILL;result_body.add_child(results_rows)
	var buttons=HBoxContainer.new();buttons.add_theme_constant_override("separation",12);result_body.add_child(buttons)
	retry_save=_button(buttons,"Retry Save",_save_result)
	race_again=_button(buttons,"Race Again",retry)
	results_hub=_button(buttons,"Career Hub",request_hub)
	invalid_panel=PanelContainer.new();area.add_child(invalid_panel);_style(invalid_panel)
	var invalid_body=VBoxContainer.new();invalid_body.add_theme_constant_override("separation",16);invalid_panel.add_child(invalid_body)
	_label(invalid_body,"ATTEMPT INVALID",24,GOLD);invalid_message=_label(invalid_body,"",18)
	_button(invalid_body,"Retry Race",retry)
	cue=_label(area,"",46,GOLD);cue.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;cue.mouse_filter=Control.MOUSE_FILTER_IGNORE;cue.set_anchors_and_offsets_preset(Control.PRESET_CENTER);cue.position=Vector2(-180,-80);cue.size=Vector2(360,100)
	player_marker=_label(self,"YOU · L4",14,GOLD);player_marker.size=Vector2(90,22);player_marker.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;player_marker.mouse_filter=Control.MOUSE_FILTER_IGNORE;player_marker.add_theme_color_override("font_shadow_color",Color.BLACK);player_marker.add_theme_constant_override("shadow_offset_x",1);player_marker.add_theme_constant_override("shadow_offset_y",1);player_marker.hide()
	var footer=_panel(layout);footer_text=_label(footer,"",13,MUTED)
	leave_dialog=ConfirmationDialog.new();leave_dialog.title="Leave unsaved results?";leave_dialog.dialog_text="This result has not been saved. Return to Career Hub without saving it?";leave_dialog.confirmed.connect(func():hub_requested.emit());add_child(leave_dialog)
	resized.connect(_resize)
	if OS.has_feature("web"):
		web_visibility_callback=JavaScriptBridge.create_callback(_web_visibility_changed)
		JavaScriptBridge.get_interface("document").addEventListener("visibilitychange",web_visibility_callback)
		JavaScriptBridge.get_interface("window").addEventListener("blur",web_visibility_callback)
	hide()

func _style(panel:PanelContainer):
	var style=StyleBoxFlat.new();style.bg_color=Color(0.055,0.09,0.13,0.96);style.border_color=Color("41515b");style.set_border_width_all(1);style.set_corner_radius_all(6);style.set_content_margin_all(12);panel.add_theme_stylebox_override("panel",style)
func _panel(parent:Node)->PanelContainer:
	var panel=PanelContainer.new();parent.add_child(panel);_style(panel);return panel
func _scroll(parent:Node)->ScrollContainer:
	var scroll=ScrollContainer.new();scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;parent.add_child(scroll);return scroll
func _label(parent:Node,text:String,font:int,color:=Color("e8ecee"))->Label:
	var label=Label.new();label.text=text;label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;label.add_theme_font_size_override("font_size",font);label.add_theme_color_override("font_color",color);parent.add_child(label);return label
func _button(parent:Node,text:String,callback:Callable)->Button:
	var button=Button.new();button.text=text;button.custom_minimum_size.y=40;button.add_theme_font_size_override("font_size",16);button.pressed.connect(callback);parent.add_child(button);return button
func _resize():
	if area==null:return
	preparation.size=Vector2(minf(420,area.size.x),minf(400 if category_form.visible else 330,area.size.y))
	results_panel.size=area.size;invalid_panel.size=Vector2(minf(600,area.size.x),minf(240,area.size.y))

func open(value:Dictionary,athlete_career,token:String,career_fingerprint:String):
	if audio_presenter!=null:audio_presenter.reset()
	if physics_budget_before<0:physics_budget_before=Engine.max_physics_steps_per_frame
	Engine.max_physics_steps_per_frame=maxi(128,physics_budget_before)
	snapshot=value.duplicate(true);career=athlete_career;source_token=token;fingerprint=career_fingerprint
	profile=snapshot.training.duplicate(true) if snapshot.get("schema_version")==4 else TrainingState.initial()
	pending_result={};saved=false;result_emitted=false;warmup_frames=12
	if world_container!=null:world_container.queue_free()
	world_container=SubViewportContainer.new();world_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);world_container.stretch=true;world_container.stretch_shrink=2;world_container.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(world_container);move_child(world_container,0);world_container.resized.connect(func(): _update_render_mode.call_deferred())
	world_viewport=SubViewport.new();Quality.apply_viewport(world_viewport,Quality.load_mode());world_viewport.own_world_3d=true;world_viewport.size=Vector2i(640,360);world_container.add_child(world_viewport)
	world=World.new();world_viewport.add_child(world)
	attempt_counter+=1;seed_value=1+(int(Time.get_ticks_usec())+attempt_counter)%2147483000
	session=Session.new(profile,career.athlete_category,mode_select.get_selected_metadata(),seed_value,career.athlete.first_name+" "+career.athlete.last_name)
	world.configure(session,career.athlete.appearance,career.athlete_category)
	world.set_quality(Quality.load_mode())
	info.text=session.runners[0].name;info.tooltip_text=info.text
	readiness.text="Speed %s  ·  Acceleration %s\nStamina %s  ·  Recovery %s\nFatigue %d / 100  ·  Top -%.1f%%, acceleration -%.1f%%" % [TrainingRules.display(profile.attributes.speed),TrainingRules.display(profile.attributes.acceleration),TrainingRules.display(profile.attributes.stamina),TrainingRules.display(profile.attributes.recovery),profile.fatigue,float(profile.fatigue)*0.08,float(profile.fatigue)*0.12]
	var pb=_previous_pb();previous_pb=pb.duplicate(true)
	readiness.text+="\nPersonal Best: "+(Data.time_text(pb.time_us)+" s" if not pb.is_empty() else "No recorded time")
	category_form.visible=not Category.valid(career.athlete_category);category_select.select(0)
	ready_button.disabled=category_form.visible;readiness_status.text="";readiness_status.hide()
	show();world.show();_refresh_phase();_resize.call_deferred();ready_button.grab_focus()

func _previous_pb() -> Dictionary:
	return snapshot.get("competition",{}).get("records",{}).get(Category.competition_scope(career.athlete_category,Data.EVENT),{})

func _toggle_stadium():
	if session==null or session.phase!="preparation" or world==null:return
	world.establishing=not world.establishing;world._update_camera(float(session.runners[0].distance))
	stadium_button.text="Race View" if world.establishing else "Stadium View"
	world_viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func start():
	if session==null or session.phase!="preparation" or not Category.valid(career.athlete_category):return
	for key:int in [KEY_A,KEY_D,KEY_LEFT,KEY_RIGHT,KEY_SPACE]:
		if Input.is_physical_key_pressed(key):readiness_status.text="Release all sprint keys, then choose Ready again.";readiness_status.show();return
	session=Session.new(profile,career.athlete_category,mode_select.get_selected_metadata(),seed_value,session.runners[0].name);world.session=session
	world.frame_samples.clear();world.last_frame_us=0;world.draw_calls=0
	pending_result={};saved=false;result_emitted=false;last_physics_us=Time.get_ticks_usec();session.ready();get_viewport().gui_release_focus();_refresh_phase()

func _physics_process(_delta:float):
	if not visible or session==null:return
	var now:=Time.get_ticks_usec()
	if session.phase=="running" and last_physics_us!=0 and now-last_physics_us>2000000:
		print("RACE_STALL ",JSON.stringify({"gap_ms":float(now-last_physics_us)/1000.0}));session.interrupt("Race interrupted by a long frame pause. Retry for a valid attempt.");last_physics_us=now;_refresh_phase();return
	last_physics_us=now
	var before:String=session.phase;session.step()
	if audio_presenter!=null and before=="running" and world!=null and not world.animations.is_empty():audio_presenter.player_state(session.runners[0],world.animations[0].phase)
	if session.phase!=before:_refresh_phase()
	if session.phase=="results" and not result_emitted:
		result_emitted=true;pending_result=session.result(source_token,fingerprint);_render_results();_save_result()
	_refresh_hud()

func _refresh_hud():
	if session==null:return
	var player:Dictionary=session.runners[0]
	var position:=1
	for runner:Dictionary in session.runners:
		if runner.id=="player":continue
		if player.status=="FIN":
			if runner.status=="FIN" and runner.time_us<player.time_us:position+=1
		elif runner.distance>player.distance:position+=1
	hud.text="%s  |  %s  |  %.1f / 100 m  |  %s s  |  Position %d / 8" % [Category.label(career.athlete_category),"Hold Sprint" if session.mode=="hold" else "Rhythm Sprint",player.distance,Data.time_text(player.time_us if player.time_us>=0 else roundi(float(session.ticks)*Physics.STEP*1000000.0)),position]
	if session.phase=="running":cue.text="GO" if session.ticks<45 else ""

func _refresh_phase():
	if audio_presenter!=null:audio_presenter.phase_changed(session.phase)
	print("RACE_PHASE ",JSON.stringify({"phase":session.phase,"category":session.category,"mode":session.mode,"message":session.message}))
	stadium_button.visible=session.phase=="preparation";stadium_button.text="Race View" if world!=null and world.establishing else "Stadium View"
	preparation.visible=session.phase=="preparation";results_panel.visible=session.phase=="results";invalid_panel.visible=session.phase=="invalid"
	cue.visible=session.phase in ["marks","set","running"]
	cue.text="ON YOUR MARKS" if session.phase=="marks" else ("SET" if session.phase=="set" else "GO")
	if session.phase=="invalid":invalid_message.text=session.message
	footer_text.text="In-game results: places use unrounded times; hundredths round up. Exact ties share place. DNF has no time." if session.phase=="results" else "A/D or arrows: rhythm  |  Space: hold  |  Esc: interrupt / Hub  |  In-game timing"
	_resize.call_deferred();_update_render_mode.call_deferred()

func _input(event:InputEvent):
	if not visible or session==null or not event is InputEventKey:return
	if event.pressed and event.keycode==KEY_ESCAPE:
		if session.phase in ["marks","set","running"]:session.interrupt();_refresh_phase()
		else:request_hub()
		get_viewport().set_input_as_handled();return
	var key:int=event.physical_keycode if event.physical_keycode!=0 else event.keycode
	if session.phase in ["marks","set","running"] and session.controls.eligible(key):
		var old_phase:String=session.phase
		session.key(key,event.pressed,event.echo)
		if session.phase!=old_phase:_refresh_phase()
		get_viewport().set_input_as_handled()

func _notification(what:int):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT or (what==NOTIFICATION_WM_WINDOW_FOCUS_OUT and not OS.has_feature("web")):_interrupt_unfocused()

func _render_results():
	results_title.text="DEVELOPMENT MEET - RESULTS"
	results_rows.present(pending_result.rows)
	_update_result_summary()
	result_status.text="Saving result...";retry_save.show()
	print("RACE_METRICS ",JSON.stringify(world.metrics()))
	print("RACE_INPUT ",JSON.stringify({"mode":session.mode,"valid_presses":session.controls.valid_presses,"reaction_us":Data.player_row(pending_result).reaction_us}))

func _update_result_summary():
	if pending_result.is_empty():return
	var player:=Data.player_row(pending_result);var pb:=_previous_pb()
	result_note.text="Personal Best: "+(Data.time_text(pb.time_us)+" s" if not pb.is_empty() else "None")+"  ·  Reaction: "+("%.3f s" % (float(player.reaction_us)/1000000.0) if player.reaction_us>=0 else "No start")+"\nPrevious PB: "+(Data.time_text(previous_pb.time_us)+" s" if not previous_pb.is_empty() else "None")

func _save_result():
	if pending_result.is_empty() or saved:return
	result_ready.emit(pending_result)

func save_outcome(result:Dictionary):
	if audio_presenter!=null:audio_presenter.saved_result(result.get("ok",false),result.get("new_pb",false))
	saved=result.get("ok",false)
	if saved:
		result_status.text="Saved - "+("NEW PERSONAL BEST" if result.get("new_pb",false) else "Result recorded")
		if OS.has_feature("web"):result_status.text+=". Browser-local storage; keep this tab open briefly."
	else:result_status.text="NOT SAVED - "+result.get("error","Unknown save error.")
	retry_save.visible=not saved
	_update_result_summary()

func request_hub():
	if not pending_result.is_empty() and not saved:leave_dialog.popup_centered(Vector2i(520,200))
	else:
		if session!=null:session.interrupt("Race abandoned. No time or Personal Best recorded.")
		hub_requested.emit()

func retry():
	if not pending_result.is_empty() and not saved:
		result_status.text="Save this result or return to Hub and confirm leaving it before starting another attempt."
		return
	open(snapshot,career,source_token,fingerprint)

func close():
	if audio_presenter!=null:audio_presenter.close()
	_restore_physics_budget()
	hide()
	if world_container!=null:world_container.queue_free();world_container=null;world_viewport=null;world=null
	session=null

func _update_render_mode():
	if world_viewport!=null and session!=null:
		world_viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS if session.phase in ["marks","set","running"] else (SubViewport.UPDATE_ALWAYS if session.phase=="preparation" and warmup_frames>0 else SubViewport.UPDATE_ONCE)

func _interrupt_unfocused():
	if visible and session!=null and session.phase in ["marks","set","running"]:
		session.interrupt();_refresh_phase()

func _web_visibility_changed(_arguments:Array):
	if OS.has_feature("web"):
		var hidden:bool=bool(JavaScriptBridge.eval("document.hidden",true))
		var focused:bool=bool(JavaScriptBridge.eval("document.hasFocus()",true))
		print("RACE_VISIBILITY ",JSON.stringify({"hidden":hidden,"focused":focused}))
		if hidden or not focused:_interrupt_unfocused()

func _exit_tree():
	_restore_physics_budget()
	if web_visibility_callback!=null:
		JavaScriptBridge.get_interface("document").removeEventListener("visibilitychange",web_visibility_callback)
		JavaScriptBridge.get_interface("window").removeEventListener("blur",web_visibility_callback)

func _restore_physics_budget():
	if physics_budget_before>=0:
		Engine.max_physics_steps_per_frame=physics_budget_before
		physics_budget_before=-1

func _process(_delta:float):
	if audio_presenter!=null and visible and session!=null and world!=null and not world.animations.is_empty():
		audio_presenter.player_state(session.runners[0],world.animations[0].phase)
	if player_marker!=null:
		player_marker.visible=visible and session!=null and session.phase in ["marks","set","running"] and world!=null
		if player_marker.visible:
			var target:Vector3=world.models[0].global_position+Vector3(0,float(career.athlete.appearance.height)/100.0+0.3,0)
			player_marker.position=world.camera.unproject_position(target)*Vector2(world_container.size)/Vector2(world_viewport.size)-Vector2(45,22)
	if visible and warmup_frames>0:
		warmup_frames-=1
		if warmup_frames==0:_update_render_mode()
