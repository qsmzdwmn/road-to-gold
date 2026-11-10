extends SceneTree
const Main = preload("res://scenes/app/main.tscn")
const Appearance = preload("res://scripts/data/appearance_data.gd")
const Hairstyles = preload("res://scripts/data/hairstyle_catalog.gd")
const Career = preload("res://scripts/career/career_data.gd")
const Repository = preload("res://scripts/persistence/prototype_save_repository.gd")
var failures := 0
func _initialize() -> void: _run.call_deferred()
func check(ok: bool, text: String) -> void:
	print(("PASS: " if ok else "FAIL: ")+text)
	if not ok: failures+=1
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://tests")
	var app = Main.instantiate()
	root.add_child(app)
	await process_frame
	var ui = app.creator
	app._new_requested()
	var camera: Transform3D = ui.preview_room.camera.transform
	check(ui.draft.athlete_category=="", "new draft still requires explicit category, without legacy inference")
	ui.select_category("male")
	check(ui.draft.athlete.appearance.hairstyle==5 and ui.preview_model.styled_hair.style_id==5, "male default Crew Cut updates live selection preview")
	ui.select_category("female")
	check(ui.draft.athlete.appearance.hairstyle==10 and ui.preview_model.styled_hair.style_id==10, "female default Long Straight updates live selection preview")
	var geometry_stats := {}
	for category: String in ["male","female"]:
		ui.select_category(category)
		check(ui.fields.hairstyle.buttons.size()==6 and ui.fields.hairstyle.buttons.map(func(b): return b.text)==Hairstyles.names(category),category+" has exactly its six relevant labels")
		var signatures := {}
		for index in range(6):
			ui.fields.hairstyle.buttons[index].pressed.emit()
			var id: int = Hairstyles.ids(category)[index]
			var hair = ui.preview_model.styled_hair
			check(ui.draft.athlete.appearance.hairstyle==id and hair.style_id==id,category+" tile immediately updates saved ID and rendered mesh "+str(id))
			check(hair.mesh.get_surface_count()==1 and hair.material_override==ui.preview_model.hair_material,"one shared-material hair surface "+str(id))
			var arrays: Array = hair.mesh.surface_get_arrays(0)
			var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var clockwise := true
			for face in range(0,indices.size(),3):
				var a := indices[face];var b := indices[face+1];var c := indices[face+2]
				clockwise = clockwise and (points[b]-points[a]).cross(points[c]-points[a]).dot(normals[a]+normals[b]+normals[c])<=0.00000001
			check(clockwise,"hair winding agrees with Godot backface culling "+str(id))
			var signature: int = hash(arrays[Mesh.ARRAY_VERTEX])
			check(not signatures.has(signature),"distinct geometry for "+Hairstyles.label(id))
			signatures[signature]=true
			geometry_stats[Hairstyles.label(id)]={"triangles":hair.triangle_count,"aabb":str(hair.get_aabb())}
			if id in [10,11,12,13]:check(hair.get_aabb().position.y<=-.42,"long hair has measurable length below head "+str(id))
			var extreme = Appearance.from_dict(ui.draft.athlete.appearance.to_dict())
			extreme.height=220;extreme.weight=150;extreme.shoulders=1.3;extreme.legs=1.15
			ui.preview_model.apply_appearance(extreme,category)
			var visible := true
			var view: Camera3D = ui.preview_room.camera
			var screen := Rect2(Vector2.ZERO,view.get_viewport().get_visible_rect().size)
			for endpoint in range(8): visible = visible and screen.has_point(view.unproject_position(hair.global_transform*hair.get_aabb().get_endpoint(endpoint)))
			check(visible,"hair fits unchanged camera at maximum body settings "+str(id))
			ui._changed()
			var data: Dictionary = ui.draft.athlete.appearance.to_dict()
			check(Appearance.validate(data).is_empty() and Appearance.from_dict(data).to_dict()==data,"new ID round trip without schema change "+str(id))
		var remembered: int = ui.draft.athlete.appearance.hairstyle
		ui.select_category("male" if category=="female" else "female")
		ui.select_category(category)
		check(ui.draft.athlete.appearance.hairstyle==remembered,category+" hairstyle selection survives category round trip")
	# All four existing identifiers retain both names and old primitive rendering.
	for style in range(4):
		var data = Appearance.new();data.hairstyle=style
		ui.preview_model.apply_appearance(data,"female")
		check(not ui.preview_model.styled_hair.visible and ui.preview_model.parts.hair.visible==(style!=0) and ui.preview_model.parts.tail.visible==(style==3) and ui.preview_model.parts.curl_left.visible==(style==2),"legacy ID retains original geometry "+str(style))
		check(Appearance.STYLES[style]==["Bald","Cropped","Short curls","Ponytail"][style] and Appearance.validate(data.to_dict()).is_empty(),"legacy ID and label unchanged "+str(style))
	ui.select_category("female")
	ui.step=2;ui._show_step();ui.select_appearance_tab(2)
	check(ui.numeric_editors.size()==4 and ui.numeric_editors.all(func(e): return ui.appearance_panels[2].is_ancestor_of(e)),"all four unique numeric editors exist only in Appearance Body")
	ui.fields.height.value=195;ui.fields.weight.value=95
	ui.fields.first_name.text="Nadia";ui.fields.last_name.text="Runner"
	ui._next()
	check(ui.step==3 and not ui.fields.height.is_visible_in_tree() and not ui.fields.weight.is_visible_in_tree() and ui.fields.first_name.is_visible_in_tree(),"Identity contains unique identity fields without duplicate body controls")
	ui._next()
	check(ui.step==4 and ui.summary.values.Height.text=="195 cm" and ui.summary.values.Weight.text=="95 kg" and ui.summary.values.Hairstyle.text=="High Bun","unchanged Player Card displays canonical Appearance data and new style label")
	var repo=Repository.new("user://tests/refinement.json")
	check(repo.save_career(ui.draft,Vector3.ZERO,true),"new hairstyle saves through unchanged schema 3 repository")
	var saved:Dictionary=repo.load_snapshot()
	check(saved.schema_version==3 and Career.from_dict(saved.career).to_dict()==ui.draft.to_dict(),"new hairstyle and all appearance values survive real local reload")
	check(ui.preview_room.camera.transform==camera and app.career_visual.rotation==Vector3.ZERO,"fixed camera and gameplay orientation unchanged")
	print("REFINEMENT HAIR GEOMETRY: ",JSON.stringify(geometry_stats))
	print("STUDIO REFINEMENT TEST FAILURES: ",failures)
	app.queue_free();await process_frame;quit(failures)
