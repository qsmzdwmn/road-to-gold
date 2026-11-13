extends Node3D
## Race-only metre-space stadium. Runner lanes remain x = lane - 3.5, start z=0, finish z=-100.
## Static geometry is built directly into material batches, not thousands of live nodes.
const TRACK=Color("843e35")
const PAINT=Color("f6f0df")
var tools:Dictionary={}
var materials:Dictionary={}
var box_mesh:=BoxMesh.new()
var scoreboard:Label3D
var last_clock:=-1
var crowd_transforms:Array[Transform3D]=[]
var crowd_colors:Array[Color]=[]
var spectator_count:=0
var static_triangles:=0
var geometry_batches:=0

func _ready():
	_ground_and_track()
	_grandstand()
	_architecture()
	_equipment()
	_infield()
	_flush()
	_crowd()

func is_visual_batched()->bool:return true

func _material(key:String,color:Color,unshaded:=false)->StandardMaterial3D:
	if materials.has(key):return materials[key]
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=0.95
	if unshaded:mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	materials[key]=mat;return mat

func _append(mesh:Mesh,transform:Transform3D,key:String,color:Color,shadow:=true):
	var batch_key=key+("/shadow" if shadow else "/flat")
	if not tools.has(batch_key):
		var tool=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES);tools[batch_key]={"tool":tool,"mat":_material(key,color),"shadow":shadow}
	tools[batch_key].tool.append_from(mesh,0,transform)

func _box(size:Vector3,at:Vector3,key:String,color:Color,shadow:=true):
	_append(box_mesh,Transform3D(Basis.IDENTITY.scaled(size),at),key,color,shadow)

func _beam(a:Vector3,b:Vector3,width:float,key:String,color:Color):
	var delta=b-a
	var basis=Basis.looking_at(delta.normalized(),Vector3.UP)
	_append(box_mesh,Transform3D(basis.scaled(Vector3(width,width,delta.length())),(a+b)*0.5),key,color)

func _arc(inner:float,outer:float,z_center:float,positive:bool,key:String,color:Color,y:float):
	# Two semicircles complete the oval; winding faces upward, with explicit normals.
	var t=SurfaceTool.new();t.begin(Mesh.PRIMITIVE_TRIANGLES)
	var start=0.0 if positive else PI
	for i in range(48):
		var a=start+PI*float(i)/48.0;var b=start+PI*float(i+1)/48.0
		var p=[Vector3(34+cos(a)*inner,y,z_center+sin(a)*inner),Vector3(34+cos(a)*outer,y,z_center+sin(a)*outer),Vector3(34+cos(b)*outer,y,z_center+sin(b)*outer),Vector3(34+cos(b)*inner,y,z_center+sin(b)*inner)]
		for index:int in [0,1,2,0,2,3]:t.set_normal(Vector3.UP);t.add_vertex(p[index])
	# append_from must receive indices: the destination batch already contains indexed boxes.
	t.index()
	_append(t.commit(),Transform3D.IDENTITY,key,color,false)

func _ground_and_track():
	_box(Vector3(154,0.4,224),Vector3(35,-0.32,-50),"plaza",Color("b6c2b9"),false)
	_box(Vector3(124,0.15,200),Vector3(34,-0.12,-50),"grass",Color("355b42"),false)
	# The sprint straight is a true 100 m, with 14 m clear run-in and run-out.
	_box(Vector3(8,0.12,128),Vector3(0,-0.06,-50),"track",TRACK,false)
	_box(Vector3(8,0.12,100),Vector3(68,-0.06,-50),"track",TRACK,false)
	for end in [0,-100]:_arc(30,38,end,end==0,"track",TRACK,0.001)
	for lane in range(9):
		_box(Vector3(0.055,0.01,128),Vector3(lane-4.0,0.009,-50),"paint",PAINT,false)
		_box(Vector3(0.055,0.01,100),Vector3(64+lane,0.009,-50),"paint",PAINT,false)
		for end in [0,-100]:_arc(30+lane-0.0275,30+lane+0.0275,end,end==0,"paint",PAINT,0.014)
	for z in [0,-100]:_box(Vector3(8,0.012,0.12),Vector3(0,0.016,z),"paint",PAINT,false)
	# Alternating mown bands on the infield, clear of the sprint course.
	for band in range(10):
		_box(Vector3(59,0.02,9.9),Vector3(34,0.0,-5-band*10),"grass_alt" if band%2==0 else "grass",Color("3c6749") if band%2==0 else Color("355b42"),false)
	for distance in [20,40,60,80,100]:
		for side in [-1,1]:
			_box(Vector3(0.6,0.012,0.06),Vector3(side*4.45,0.022,-distance),"paint",PAINT,false)
		_label(str(distance)+"m",Vector3(5.1,0.035,-distance),0.011,40,Vector3(-90,0,0),Color("f6f0df"))
	for lane in range(8):
		_label(str(lane+1),Vector3(lane-3.5,0.035,1.1),0.02,48,Vector3(-90,0,0),PAINT)
		_label(str(lane+1),Vector3(lane-3.5,0.035,-98.7),0.016,40,Vector3(-90,0,0),PAINT)
	# White curb and safe service walkway on the stand side.
	_box(Vector3(0.18,0.18,130),Vector3(-4.8,0.03,-50),"paint",PAINT,false)
	_box(Vector3(4.4,0.1,138),Vector3(-7.1,-0.02,-50),"walkway",Color("718383"),false)

func _grandstand():
	var navy=Color("1c3e51");var concrete=Color("a7b6b8");var gold=Color("c9a961")
	# Six blocks separated by clear stair aisles. Nine ascending seating rows.
	for section in range(6):
		var z=-4.0-section*18.0
		for row in range(9):
			var x=-11.0-row*0.92;var y=0.4+row*0.46
			_box(Vector3(0.94,y,15.8),Vector3(x,y*0.5,z),"concrete",concrete)
			for seat in range(16):
				var seat_z=z-7.1+seat*0.94
				var seat_color=gold if (seat+section*3)%7==0 else navy
				var seat_key="gold_seat" if (seat+section*3)%7==0 else "navy_seat"
				_box(Vector3(0.63,0.11,0.73),Vector3(x+0.03,y+0.18,seat_z),seat_key,seat_color,false)
				_box(Vector3(0.13,0.62,0.73),Vector3(x-0.3,y+0.48,seat_z),seat_key,seat_color,false)
		# Aisle steps and white edges, visible between seating blocks.
		for step in range(18):
			var y=0.2+step*0.23;var x=-10.6-step*0.46
			_box(Vector3(0.48,y,1.8),Vector3(x,y*0.5,z+9),"concrete",concrete)
			_box(Vector3(0.055,0.02,1.8),Vector3(x+0.21,y+0.02,z+9),"paint",PAINT,false)
		_beam(Vector3(-10.5,1.2,z+9),Vector3(-19,5.5,z+9),0.06,"rail",Color("d3dcd8"))
		for support in [-7,7]:
			_box(Vector3(0.34,7.8,0.34),Vector3(-20.3,3.9,z+support),"steel",Color("455c69"))
			_beam(Vector3(-20.3,7.6,z+support),Vector3(-9.8,6.9,z+support),0.16,"steel",Color("455c69"))
		_box(Vector3(11.8,0.23,17.8),Vector3(-15.1,7.6,z),"roof",Color("d8e0d9"))
		_box(Vector3(0.2,0.4,17.8),Vector3(-9.2,7.45,z),"gold",gold)
	_box(Vector3(0.24,1,116),Vector3(-9.6,0.5,-49),"navy",navy)
	_box(Vector3(0.08,0.08,116),Vector3(-9.5,1.15,-49),"rail",Color("d3dcd8"))
	for z in range(-106,9,6):_box(Vector3(0.07,1.1,0.07),Vector3(-9.5,0.6,z),"rail",Color("d3dcd8"))
	for z in [-8,-40,-72,-100]:
		_box(Vector3(0.05,0.9,10),Vector3(-9.43,0.7,z),"banner",Color("132e40"),false)
		_label("ROAD TO GOLD",Vector3(-9.38,0.75,z),0.008,44,Vector3(0,90,0),gold)

func _architecture():
	# Far stand gives the infield an enclosing stadium horizon without blocking camera.
	for row in range(5):
		var y=0.5+row*0.6
		for section in range(4):
			var z=-11.0-section*26
			_box(Vector3(1.1,y,23),Vector3(79+row*1.05,y*0.5,z),"far_concrete",Color("839b9e"))
			_box(Vector3(0.65,0.55,22),Vector3(79+row*1.05,y+0.25,z),"far_seat",Color("254b60"),false)
		for z in [2,-24,-50,-76,-102]:
			_box(Vector3(1.1,y,2.6),Vector3(79+row*1.05,y*0.5,z),"concrete",Color("a7b6b8"))
	_box(Vector3(8,0.2,105),Vector3(83,6.3,-50),"roof",Color("d8e0d9"))
	for z in [-101,-76,-50,-24,1]:
		_box(Vector3(0.2,6.3,0.2),Vector3(86,3.15,z),"steel",Color("455c69"))
		_beam(Vector3(86,6.2,z),Vector3(79,5.9,z),0.12,"steel",Color("455c69"))
	_box(Vector3(1,7,122),Vector3(86,3.4,-50),"navy",Color("1c3e51"))
	for z in range(-108,10,12):
		_box(Vector3(3,1.5,5),Vector3(86.5,4.9,z),"glass",Color("567e8b"),false)
	for x in [-26,94]:
		_box(Vector3(0.4,2.5,190),Vector3(x,1.1,-50),"perimeter",Color("6b858a"))
	for z in [43,-143]:_box(Vector3(120,2.5,0.4),Vector3(34,1.1,z),"perimeter",Color("6b858a"))
	for x in [-24,90]:
		for z in [23,-123]:
			_box(Vector3(0.4,18,0.4),Vector3(x,9,z),"steel",Color("455c69"))
			_box(Vector3(5,1.4,0.6),Vector3(x,18,z),"light_housing",Color("253d48"))
			for lamp in range(5):_box(Vector3(0.7,0.8,0.1),Vector3(x-2+lamp,18,z+0.36),"paint",PAINT,false)
	# Compact service pavilions and entrance portals bound the distant horizon.
	for z in [-18,-78]:
		_box(Vector3(6,5,20),Vector3(90,2.5,z),"concrete",Color("a7b6b8"))
		_box(Vector3(0.05,1.5,17),Vector3(86.95,3.6,z),"glass",Color("567e8b"),false)
		_box(Vector3(7,0.22,21),Vector3(90,5.2,z),"navy",Color("1c3e51"))
	for z in [41,-141]:
		for x in [26,42]:_box(Vector3(1.5,6,1.5),Vector3(x,3,z),"concrete",Color("a7b6b8"))
		_box(Vector3(18,1.6,1.5),Vector3(34,5.3,z),"navy",Color("1c3e51"))
		_label("ROAD TO GOLD  /  ATHLETICS",Vector3(34,5.3,z+(-0.8 if z>0 else 0.8)),0.01,38,Vector3(0,180 if z>0 else 0,0),Color("c9a961"))
	# Four low-poly trees outside the athlete/camera corridor.
	var canopy=SphereMesh.new();canopy.radial_segments=6;canopy.rings=3;canopy.radius=1;canopy.height=2
	for z in [28,-30,-85,-130]:
		_box(Vector3(0.45,4,0.45),Vector3(-31,2,z),"trunk",Color("795d46"))
		_append(canopy,Transform3D(Basis.IDENTITY.scaled(Vector3(3,3,3)),Vector3(-31,5.7,z)),"foliage",Color("466d4e"))

func _equipment():
	for lane in range(8):
		var x=lane-3.5
		_box(Vector3(0.09,0.035,0.75),Vector3(x,0.04,0.8),"steel",Color("455c69"),false)
		for offset in [-0.16,0.16]:_box(Vector3(0.21,0.13,0.24),Vector3(x+offset,0.09,0.8+offset),"blocks",Color("253d48"))
	for z in [0,-100]:
		_label("START  /  100m" if z==0 else "FINISH",Vector3(-6.6,1.9,z),0.009,42,Vector3(0,90,0),Color("f6f0df"))
		for x in [-5.3,5.3]:
			_box(Vector3(0.12,1.5,0.12),Vector3(x,0.75,z),"paint",PAINT)
			_box(Vector3(0.28,0.2,0.3),Vector3(x,1.4,z),"timing",Color("172e3d"))
			_box(Vector3(0.08,0.08,0.04),Vector3(x,1.4,z+0.17),"gold",Color("c9a961"),false)
	# Electronic scoreboard behind the finish; it shows live in-game time, never invented results.
	for x in [-16,-8]:_box(Vector3(0.35,5,0.35),Vector3(x,2.5,-116),"steel",Color("455c69"))
	_box(Vector3(11,4.5,0.5),Vector3(-12,6,-116),"score_case",Color("172e3d"))
	_box(Vector3(10.5,4,0.03),Vector3(-12,6,-115.72),"score_face",Color("091b26"),false)
	_label("ROAD TO GOLD",Vector3(-12,7.2,-115.68),0.01,48,Vector3.ZERO,Color("d6b66d"))
	scoreboard=_label("DEVELOPMENT MEET\n100 METRES",Vector3(-12,5.7,-115.65),0.011,40,Vector3.ZERO,PAINT)
	for z in [-18,-82]:
		_box(Vector3(0.7,0.6,3.2),Vector3(6,0.3,z),"planter",Color("8d9b94"))
		_box(Vector3(0.6,0.5,3),Vector3(6,0.85,z),"foliage",Color("466d4e"),false)

func _infield():
	# All equipment is decorative and stays beyond x=8; no collision or sport systems.
	# Long-jump runway, take-off board and recessed-looking sand pit.
	_box(Vector3(1.25,0.025,34),Vector3(16,0.025,-31),"track",TRACK,false)
	for side in [-1,1]:_box(Vector3(0.045,0.02,34),Vector3(16+side*0.58,0.043,-31),"paint",PAINT,false)
	_box(Vector3(1.25,0.025,0.24),Vector3(16,0.045,-47),"paint",PAINT,false)
	_box(Vector3(3.6,0.12,8),Vector3(16,0.05,-53),"trunk",Color("795d46"),false)
	_box(Vector3(3.3,0.025,7.7),Vector3(16,0.12,-53),"sand",Color("b8a17a"),false)
	_label("LONG JUMP",Vector3(19,0.04,-53),0.011,32,Vector3(-90,0,0),PAINT)
	# Small warm-up zone, distinct from the active sprint lanes.
	for lane in range(5):_box(Vector3(0.045,0.02,22),Vector3(33+lane*1.2,0.03,-78),"paint",PAINT,false)
	for z in [-67,-89]:_box(Vector3(4.85,0.02,0.06),Vector3(35.4,0.03,z),"paint",PAINT,false)
	_label("WARM UP",Vector3(35.4,0.04,-64),0.014,32,Vector3(-90,0,0),PAINT)
	# Parked lightweight hurdles and cones; shared stadium materials.
	for z in [-26,-29,-32,-35]:
		for x in [28.0,29.1]:
			_box(Vector3(0.05,0.72,0.05),Vector3(x,0.39,z),"paint",PAINT)
			_box(Vector3(0.06,0.06,0.6),Vector3(x,0.06,z),"steel",Color("455c69"))
		_box(Vector3(1.2,0.14,0.09),Vector3(28.55,0.78,z),"navy",Color("1c3e51"))
	var cone=CylinderMesh.new();cone.top_radius=0.025;cone.bottom_radius=0.13;cone.height=0.34;cone.radial_segments=6;cone.rings=1
	for i in range(8):_append(cone,Transform3D(Basis.IDENTITY,Vector3(39,0.19,-68-i*2.8)),"gold",Color("c9a961"),false)
	for z in [-20,-76]:
		_box(Vector3(0.8,0.15,3),Vector3(8.5,0.6,z),"navy",Color("1c3e51"))
		for offset in [-1,1]:_box(Vector3(0.5,0.5,0.15),Vector3(8.5,0.28,z+offset),"steel",Color("455c69"))
	# A small field circle gives context only; javelin/throwing gameplay is not implemented.
	var circle=CylinderMesh.new();circle.top_radius=1.3;circle.bottom_radius=1.3;circle.height=0.025;circle.radial_segments=24;circle.rings=1
	_append(circle,Transform3D(Basis.IDENTITY,Vector3(48,0.03,-38)),"concrete",Color("a7b6b8"),false)

func _label(text:String,at:Vector3,pixel:float,font:int,rotation:Vector3,color:Color)->Label3D:
	var label=Label3D.new();label.text=text;label.position=at;label.rotation_degrees=rotation;label.pixel_size=pixel;label.font_size=font;label.modulate=color;label.outline_size=0;label.no_depth_test=false;label.shaded=false;label.double_sided=true;add_child(label);return label

func _flush():
	for entry:Dictionary in tools.values():
		var instance=MeshInstance3D.new();instance.mesh=entry.tool.commit();instance.material_override=entry.mat;instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if entry.shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(instance)
		static_triangles+=instance.mesh.get_faces().size()/3;geometry_batches+=1
	tools.clear()

func _crowd():
	# One MultiMesh, one shared mesh and per-instance shirt colors. No crowd scripts or skeletons.
	var t=SurfaceTool.new();t.begin(Mesh.PRIMITIVE_TRIANGLES)
	var torso=CylinderMesh.new();torso.top_radius=0.17;torso.bottom_radius=0.22;torso.height=0.43;torso.radial_segments=5;torso.rings=1
	var head=SphereMesh.new();head.radius=0.13;head.height=0.26;head.radial_segments=5;head.rings=2
	t.append_from(torso,0,Transform3D(Basis.IDENTITY,Vector3(0,0.35,0)));t.append_from(head,0,Transform3D(Basis.IDENTITY,Vector3(0,0.71,0)))
	var multi=MultiMesh.new();multi.transform_format=MultiMesh.TRANSFORM_3D;multi.use_colors=true;multi.mesh=t.commit()
	var transforms:Array[Transform3D]=[];var colors:Array[Color]=[];var palette=[Color("b9bdb1"),Color("bf9158"),Color("365766"),Color("855f55"),Color("77949b"),Color("a0956c"),Color("78677d"),Color("c5c4b7")]
	for section in range(6):
		for row in range(9):
			for seat in range(16):
				if (floori(float(seat)/3.0)+row*3+section*11)%5>1:continue
				transforms.append(Transform3D(Basis.IDENTITY,Vector3(-10.97-row*0.92,0.55+row*0.46,-11.1-section*18+seat*0.94)));colors.append(palette[(section*3+row+seat)%palette.size()])
	crowd_transforms=transforms;crowd_colors=colors
	multi.instance_count=transforms.size();spectator_count=transforms.size()
	for i in range(transforms.size()):multi.set_instance_transform(i,transforms[i]);multi.set_instance_color(i,colors[i])
	var mat=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=1;multi.mesh.surface_set_material(0,mat)
	var crowd=MultiMeshInstance3D.new();crowd.multimesh=multi;crowd.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(crowd)

func update_race(race):
	var tenth:=int(float(race.ticks)/6.0)
	if tenth==last_clock or scoreboard==null:return
	last_clock=tenth
	scoreboard.text="100 METRES\n%.1f s" % (float(race.ticks)/60.0) if race.phase in ["running","results"] else "DEVELOPMENT MEET\n100 METRES"
