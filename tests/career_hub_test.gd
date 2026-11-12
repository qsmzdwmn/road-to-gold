extends SceneTree
const Main = preload("res://scenes/app/main.tscn")
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
const Career = preload("res://scripts/career/career_data.gd")
const Catalog = preload("res://scripts/data/career_catalog.gd")
const Category = preload("res://scripts/data/athlete_category.gd")
const Appearance = preload("res://scripts/data/appearance_data.gd")
const PATH := "user://tests/career-hub.json"
var failures := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, message: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+message)
	if not ok:failures+=1
func _write(text: String) -> void:
	var file := FileAccess.open(PATH,FileAccess.WRITE)
	file.store_string(text);file.close()
func _visible_text(node: Node) -> String:
	var text := ""
	if node is Label and node.is_visible_in_tree():text=node.text+"\n"
	for child: Node in node.get_children():text+=_visible_text(child)
	return text
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://tests")
	var repository=Repository.new(PATH)
	if "--reload-hub" in OS.get_cmdline_user_args():
		var app=Main.instantiate();root.add_child(app);await process_frame;app.repository=repository;app._continue()
		check(app.hub.visible and app.current_career.athlete.first_name=="Nadia","separate-process Continue restores a genuine career into Hub")
		check(app.hub.labels.name.text=="Nadia Gold" and repository.load_snapshot().schema_version==3,"separate-process Hub displays persisted actual profile without migration")
		app.queue_free();await process_frame;quit(failures);return
	DirAccess.remove_absolute(PATH)
	var app=Main.instantiate();root.add_child(app);await process_frame;app.repository=repository
	var hub=app.hub
	check(not hub.visible and hub.preview_viewport==null,"Hub starts hidden and allocates no extra 3D preview on the menu")
	check(hub.save_button.size_flags_horizontal==Control.SIZE_SHRINK_END and hub.nav_buttons.training.text=="Training","compact Save & Menu and clean Training navigation label")
	var expected: Dictionary = {}
	for category: String in ["male","female"]:
		for index in range(Catalog.origins().size()):
			var origin: Dictionary=Catalog.origins()[index]
			app._menu();app._new_requested();app.creator.select_category(category)
			app.creator.origin_buttons[index].pressed.emit()
			app.creator.fields.first_name.text="Alex" if category=="male" else "Nadia"
			app.creator.fields.last_name.text="Gold"
			for country in range(app.creator.fields.country.item_count):
				if app.creator.fields.country.get_item_metadata(country)=="AZ":app.creator.fields.country.select(country)
			app.creator.fields.hairstyle.select(4 if category=="male" else 2)
			app.creator.fields.height.value=192 if category=="male" else 178
			app.creator.fields.weight.value=82 if category=="male" else 67
			app.creator.fields.skin.select(3);app.creator.fields.hair_color.select(3)
			app.creator.fields.shoulders.value=1.05;app.creator.fields.legs.value=1.0;app.creator._changed()
			expected=app.creator.draft.to_dict()
			var prior:=FileAccess.get_file_as_string(PATH) if repository.has_file() else ""
			for step in range(5):app.creator._next()
			if not prior.is_empty():
				check(app.ui.confirmation.visible and FileAccess.get_file_as_string(PATH)==prior,"new Hub career still waits for overwrite confirmation")
				app.ui.confirmation.hide()
				check(FileAccess.get_file_as_string(PATH)==prior and not hub.visible,"cancel replacement leaves original slot and editable draft intact")
				app._confirm_new()
			await process_frame
			check(hub.visible and not app.creator.visible and not app.ui.visible and not app.exploring and not app.athlete.active,"BEGIN CAREER routes only to Hub after saving "+category+" / "+origin.id)
			var snapshot:Dictionary=repository.load_snapshot()
			check(snapshot.schema_version==3 and Career.from_dict(snapshot.career).to_dict()==expected,"complete saved identity/appearance unchanged "+category+" / "+origin.id)
			check(hub.labels.name.text==expected.athlete.first_name+" Gold" and "Azerbaijan" in hub.labels.identity.text and Category.label(category) in hub.labels.identity.text,"Overview uses actual name, country and category")
			check(origin.title in hub.labels.start.text and str(int(origin.age)) in hub.labels.start.text and hub.labels.origin_description.text==origin.description,"all three origin/starting-age descriptions remain data-driven")
			check(snapshot.keys().size()==4 and not snapshot.career.has("records") and not snapshot.career.has("events"),"no duplicate profile, invented records or new schema fields")
			var bytes:=FileAccess.get_file_as_string(PATH)
			for section: String in ["overview","my_athlete","training","calendar","records"]:
				hub.nav_buttons[section].pressed.emit()
				check(hub.active_section==section and hub.pages[section].visible and hub.pages.values().filter(func(p):return p.visible).size()==1,"navigation has exactly one active page "+section)
			check("No recorded performances" in _visible_text(hub.pages.records),"Records has an honest empty state without a fake result")
			hub.select_section("training")
			check("Training Day" in _visible_text(hub.pages.training) and hub.training_panel.token==app.career_token,"Training uses the current saved career and day")
			hub.select_section("calendar")
			check("No events scheduled" in _visible_text(hub.pages.calendar),"Calendar has no fictitious event schedule")
			hub.select_section("my_athlete")
			await process_frame
			check(hub.player_card.values.Height.text=="%d cm" % expected.athlete.appearance.height and hub.player_card.values.Weight.text=="%d kg" % expected.athlete.appearance.weight,"My Athlete reuses actual saved metrics and approved Player Card")
			check(hub.player_card.values.Hairstyle.text==Appearance.STYLES[expected.athlete.appearance.hairstyle] and hub.preview_model.appearance.to_dict()==app.current_career.athlete.appearance.to_dict(),"My Athlete preview and profile share exact saved customization")
			check(hub.preview_viewport.render_target_update_mode in [SubViewport.UPDATE_WHEN_VISIBLE,SubViewport.UPDATE_DISABLED] and absf(angle_difference(hub.preview_model.rotation.y,deg_to_rad(230)))<0.00001,"preview is static and is paused when hidden or clipped")
			var model_id: int=hub.preview_model.get_instance_id()
			hub.nav_buttons.settings.pressed.emit()
			check(not hub.visible and app.ui.settings.visible and app.settings_from_hub,"Settings reuses existing settings screen")
			(app.ui.settings.get_child(app.ui.settings.get_child_count()-1) as Button).pressed.emit()
			check(hub.visible and hub.active_section=="my_athlete" and hub.preview_model.get_instance_id()==model_id,"Settings Back returns to prior Hub page and same preview")
			check(FileAccess.get_file_as_string(PATH)==bytes,"Hub navigation, viewing and settings never rewrite the saved career")
			app._menu();app._continue()
			check(hub.visible and hub.active_section=="overview" and app.current_career.to_dict()==expected and FileAccess.get_file_as_string(PATH)==bytes,"Continue opens Overview without changing any saved bytes")
	# Layout, text and keyboard at both supported desktop sizes.
	for resolution: Vector2i in [Vector2i(1280,720),Vector2i(800,600)]:
		root.size=resolution
		for section: String in ["overview","my_athlete","training","calendar","records"]:
			hub.select_section(section);await process_frame;await process_frame
			check(hub.sidebar.get_global_rect().end.x<=resolution.x and hub.save_button.get_global_rect().end.x<=resolution.x and hub.menu_button.get_global_rect().end.y<=resolution.y,"fixed sidebar/save/menu stay inside window %s %s" % [resolution,section])
			check(hub.title.get_global_rect().position.y>=16,"Hub heading stays inside top padding")
			check(hub.scroll.get_global_rect().end.y<=hub.status.get_global_rect().position.y and hub.scroll.get_global_rect().end.x<=resolution.x,"scrolling content cannot overlap footer or extend horizontally")
			hub.scroll.scroll_vertical=100000;await process_frame
			check(hub.scroll.scroll_vertical>=0 and hub.nav_buttons.overview.is_visible_in_tree(),"long pages scroll independently with navigation reachable")
	root.size=Vector2i(1280,720);hub.select_section("overview");await process_frame;await process_frame
	hub.nav_buttons.overview.grab_focus()
	var event:=InputEventKey.new();event.keycode=KEY_TAB;event.physical_keycode=KEY_TAB;event.pressed=true;Input.parse_input_event(event);await process_frame
	var focused:Control=root.gui_get_focus_owner()
	check(focused!=null and hub.is_ancestor_of(focused) and focused!=hub.nav_buttons.overview,"Tab advances keyboard focus within visible Hub controls")
	event=event.duplicate();event.pressed=false;Input.parse_input_event(event)
	hub.select_section("records");event=InputEventKey.new();event.keycode=KEY_ESCAPE;event.pressed=true;app._unhandled_key_input(event)
	check(hub.active_section=="overview" and hub.visible,"Escape returns a Hub subpage to Overview")
	# Keep the original track reachable without adding competition/training behavior.
	hub.track_requested.emit();check(app.exploring and app.athlete.active and not hub.visible and app.ui.hub_button.visible,"explicit sandbox entry preserves existing track movement mode")
	app.athlete.position=Vector3(1,0,-2);app.ui.hub_requested.emit()
	check(hub.visible and not app.athlete.active and app.athlete.position==Vector3(1,0,-2),"Career HQ returns from sandbox without moving the athlete")
	hub.save_requested.emit();check(not hub.visible and app.ui.menu.visible and repository.load_position()==Vector3(1,0,-2),"Hub Save & Menu uses the existing slot and preserves track position")
	app._continue();var original_bytes:=FileAccess.get_file_as_string(PATH)
	repository.path="user://tests/hub-missing-dir/slot.json";hub.save_requested.emit()
	check(hub.visible and "Save failed" in hub.status.text and not repository.has_file(),"missing career slot never downgrades to a position-only profile")
	repository.path=PATH
	var replacement:Dictionary=repository.load_snapshot();replacement.career.athlete.first_name="Other";_write(JSON.stringify(replacement));var replaced_bytes:=FileAccess.get_file_as_string(PATH);hub.save_requested.emit()
	check(hub.visible and FileAccess.get_file_as_string(PATH)==replaced_bytes and "changed" in hub.status.text,"a changed career slot is not overwritten by stale Hub state")
	_write(original_bytes)
	# Genuine schema 2 career retains an unknown category and its legacy hair ID.
	var legacy:Dictionary=expected.duplicate(true);legacy.erase("athlete_category");legacy.athlete.appearance.hairstyle=3
	var legacy_text:=JSON.stringify({"schema_version":2,"kind":"career","career":legacy,"position":[1.25,-4.5]},"  ")
	_write(legacy_text);app._menu();app._continue();hub.select_section("my_athlete")
	check(hub.visible and app.current_career.athlete_category=="" and "Not selected (legacy)" in hub.labels.identity.text,"legacy career opens Hub without inventing male/female category")
	check(hub.preview_model.parts.tail.visible and not hub.preview_model.styled_hair.visible and hub.player_card.values.Hairstyle.text=="Ponytail","legacy model/hair retains existing meaning in My Athlete")
	check(FileAccess.get_file_as_string(PATH)==legacy_text,"legacy Hub viewing leaves original bytes untouched")
	hub.save_requested.emit();var saved_legacy:Dictionary=repository.load_snapshot()
	check(saved_legacy.schema_version==2 and not saved_legacy.career.has("athlete_category") and saved_legacy.career==JSON.parse_string(legacy_text).career,"explicit legacy save preserves schema and every career field")
	_write(JSON.stringify({"schema_version":1,"kind":"track_probe","position":[1.25,-4.5]}));app._menu();app._continue()
	check(app.exploring and not hub.visible and app.current_career==null and not app.ui.hub_button.visible,"schema 1 position-only Continue keeps original track, without fabricating athlete data")
	var future:="{\"schema_version\":99}";_write(future);app._menu();app._continue()
	check(not hub.visible and app.ui.continue_button.disabled and FileAccess.get_file_as_string(PATH)==future,"unsupported saves remain protected and are not opened as a career")
	# Leave a real valid fixture for the separate-process reload check.
	DirAccess.remove_absolute(PATH) # Only this disposable test fixture; incompatible saves cannot be replaced.
	check(repository.save_career(Career.from_dict(expected),Vector3.ZERO,true),"test fixture stores one real schema 3 career")
	app.queue_free();await process_frame
	print("CAREER HUB TEST FAILURES: ",failures);quit(failures)
