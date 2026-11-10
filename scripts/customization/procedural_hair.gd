extends MeshInstance3D
## Twelve cosmetic styles; closed, low-resolution pieces baked into ONE surface.
## Immutable style meshes are shared; each athlete keeps its own material override.
static var cache: Dictionary = {}
var style_id := -1
var triangle_count := 0
var builder: SurfaceTool
func set_style(id: int, material: StandardMaterial3D) -> void:
	material_override = material
	if id == style_id: return
	style_id = id
	if not cache.has(id): cache[id] = _build(id)
	mesh = cache[id]
	triangle_count = mesh.surface_get_array_index_len(0) / 3
func _oval(size: Vector3, at: Vector3, rotation := Vector3.ZERO) -> void:
	var source := SphereMesh.new()
	source.radius = 0.5
	source.height = 1.0
	source.radial_segments = 8
	source.rings = 3
	builder.append_from(source, 0, Transform3D(Basis.from_euler(rotation).scaled(size), at))
func _lock(rings: Array, depth_ratio := 0.7, segments := 8, smooth_normals := false) -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var N: int = segments
	for ring in range(rings.size()):
		var shape: Vector4 = rings[ring] # center x/y/z and cross-section radius
		for j in range(N):
			var angle := TAU*j/N
			vertices.append(Vector3(shape.x + sin(angle)*shape.w, shape.y, shape.z + cos(angle)*shape.w*depth_ratio))
			var normal := Vector3(sin(angle),0,cos(angle)).normalized()
			if smooth_normals:
				var delta: Vector4 = rings[mini(ring+1,rings.size()-1)]-rings[maxi(ring-1,0)]
				var around := Vector3(cos(angle),0,-depth_ratio*sin(angle))
				var along := Vector3(delta.x+sin(angle)*delta.w,delta.y,delta.z+depth_ratio*cos(angle)*delta.w)
				normal = around.cross(along).normalized()
			normals.append(normal)
	for k in range(rings.size()-1):
		for j in range(N):
			var a := k*N+j
			var b := k*N+(j+1)%N
			indices.append_array(PackedInt32Array([a,a+N,b,b,a+N,b+N]))
	for k in [0,rings.size()-1]:
		var center := vertices.size()
		vertices.append(Vector3(rings[k].x,rings[k].y,rings[k].z))
		normals.append(Vector3.DOWN if k==0 else Vector3.UP)
		for j in range(N):
			var a: int = k*N+j
			var b: int = k*N+(j+1)%N
			indices.append_array(PackedInt32Array([center,a,b] if k==0 else [center,b,a]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	var source := ArrayMesh.new()
	source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	builder.append_from(source,0,Transform3D.IDENTITY)
func _cap() -> void:
	_oval(Vector3(.35,.20,.36),Vector3(0,.14,.012))
func _smooth_lock(controls: Array, depth_ratio := 0.7) -> void:
	# Catmull-Rom sampling rounds the drape while keeping low-poly cross-sections.
	var rings := []
	for i in range(controls.size()-1):
		var a: Vector4 = controls[maxi(i-1,0)]
		var b: Vector4 = controls[i]
		var c: Vector4 = controls[i+1]
		var d: Vector4 = controls[mini(i+2,controls.size()-1)]
		for sample in range(3):
			var t := sample/3.0
			rings.append((b*2.0+(c-a)*t+(a*2.0-b*5.0+c*4.0-d)*t*t+(-a+b*3.0-c*3.0+d)*t*t*t)*0.5)
	rings.append(controls[-1])
	_lock(rings,depth_ratio,10,true)
func _curtain(length: float, wavy := false, bob := false) -> void:
	_smooth_lock([Vector4(0,-length,.16,.10 if not bob else .12),Vector4(0,-length*.65,.18,.145),Vector4(0,-.08,.17,.17),Vector4(0,.11,.10,.16)])
	for side: float in [-1,1]:
		if bob:
			_smooth_lock([Vector4(side*.16,-length,-.12,.018),Vector4(side*.205,-.19,-.10,.045),Vector4(side*.18,-.04,-.035,.055),Vector4(side*.15,.11,0,.047)])
		elif wavy:
			_smooth_lock([Vector4(side*.17,-length,-.17,.012),Vector4(side*.245,-.41,-.15,.047),Vector4(side*.165,-.25,-.13,.055),Vector4(side*.235,-.08,-.06,.053),Vector4(side*.15,.11,0,.045)])
		else:
			_smooth_lock([Vector4(side*.16,-length,-.17,.010),Vector4(side*.185,-.37,-.16,.032),Vector4(side*.18,-.15,-.095,.047),Vector4(side*.15,.11,0,.050)])
func _parted_cap() -> void:
	# One continuous crown, with a recessed off-center seam instead of separate lumps.
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var columns := [-1.0,-.8,-.45,0.0,.22,.32,.42,.7,1.0]
	var depths := [-.17,-.12,-.06,0.0,.06,.12,.17]
	var width := columns.size()
	for z: float in depths:
		var radius := .17*sqrt(maxf(.01,1.0-pow(z/.185,2)))
		for col in range(width):
			var x: float = columns[col]*radius
			var y := .12+.14*sqrt(maxf(0,1.0-pow(x/.17,2)-pow(z/.185,2)))
			if col==5: y-=.043
			elif col<5: y+=.010
			vertices.append(Vector3(x,y,z+.005))
	for row in range(depths.size()):
		for col in range(width):
			var along_x := vertices[row*width+mini(col+1,width-1)]-vertices[row*width+maxi(col-1,0)]
			var along_z := vertices[mini(row+1,depths.size()-1)*width+col]-vertices[maxi(row-1,0)*width+col]
			normals.append(along_z.cross(along_x).normalized())
	for row in range(depths.size()-1):
		for col in range(width-1):
			var a := row*width+col
			indices.append_array(PackedInt32Array([a,a+1,a+width,a+1,a+width+1,a+width]))
	var edge: Array[int] = []
	for col in range(width):edge.append(col)
	for row in range(1,depths.size()):edge.append(row*width+width-1)
	for col in range(width-2,-1,-1):edge.append((depths.size()-1)*width+col)
	for row in range(depths.size()-2,0,-1):edge.append(row*width)
	for i in range(edge.size()):
		var a := vertices[edge[i]]
		var b := vertices[edge[(i+1)%edge.size()]]
		var normal := Vector3(a.x+b.x,0,a.z+b.z).normalized()
		var start := vertices.size()
		vertices.append_array(PackedVector3Array([a,Vector3(a.x,.07,a.z),b,Vector3(b.x,.07,b.z)]))
		normals.append_array(PackedVector3Array([normal,normal,normal,normal]))
		indices.append_array(PackedInt32Array([start,start+1,start+2,start+2,start+1,start+3]))
		start=vertices.size()
		vertices.append_array(PackedVector3Array([Vector3(0,.07,0),Vector3(a.x,.07,a.z),Vector3(b.x,.07,b.z)]))
		normals.append_array(PackedVector3Array([Vector3.DOWN,Vector3.DOWN,Vector3.DOWN]))
		indices.append_array(PackedInt32Array([start,start+2,start+1]))
	# Keep the recessed seam crisp; face normals must agree with its concave facets.
	var flat_vertices := PackedVector3Array()
	var flat_normals := PackedVector3Array()
	var flat_indices := PackedInt32Array()
	for face in range(0,indices.size(),3):
		var a := vertices[indices[face]]
		var b := vertices[indices[face+1]]
		var c := vertices[indices[face+2]]
		var normal := -(b-a).cross(c-a).normalized()
		var start := flat_vertices.size()
		flat_vertices.append_array(PackedVector3Array([a,b,c]))
		flat_normals.append_array(PackedVector3Array([normal,normal,normal]))
		flat_indices.append_array(PackedInt32Array([start,start+1,start+2]))
	vertices=flat_vertices;normals=flat_normals;indices=flat_indices
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_INDEX]=indices
	var source := ArrayMesh.new()
	source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	builder.append_from(source,0,Transform3D.IDENTITY)
func _build(id: int) -> ArrayMesh:
	builder = SurfaceTool.new()
	match id:
		4: # tightly cropped buzz silhouette
			_lock([Vector4(0,.02,0,.170),Vector4(0,.075,0,.158),Vector4(0,.125,0,.130),Vector4(0,.165,0,.085),Vector4(0,.205,0,.012)],1.08)
		5: # softened crew crown, still visibly longer and flatter than the buzz
			_lock([Vector4(0,.07,.008,.167),Vector4(0,.145,.008,.175),Vector4(0,.19,.008,.165),Vector4(0,.225,.008,.12),Vector4(0,.24,.008,.055)],1.0)
		6:
			_cap()
			for i in range(5): _oval(Vector3(.10,.095,.18),Vector3(-.12+i*.055,.22,-.045),Vector3(.15,0,-.22))
		7: # rounded high crown, tight sides
			_oval(Vector3(.29,.27,.31),Vector3(0,.16,.012))
			_oval(Vector3(.329,.055,.34),Vector3(0,.11,.012))
		8:
			_parted_cap()
		9:
			_cap()
			for i in range(8):
				var angle := TAU*i/8
				_oval(Vector3(.105,.12,.11),Vector3(sin(angle)*.115,.215,cos(angle)*.10))
		10:
			_cap()
			_curtain(.53)
		11:
			_cap()
			_oval(Vector3(.13,.12,.13),Vector3(0,.24,.17))
			_lock([Vector4(.24,-.43,.23,.045),Vector4(.23,-.22,.28,.065),Vector4(.14,.05,.27,.07),Vector4(0,.23,.17,.06)])
		12:
			_cap()
			_curtain(.55,true)
		13:
			_cap()
			for side: float in [-1,1]:
				_smooth_lock([Vector4(side*.175,-.49,-.205,.016),Vector4(side*.175,-.20,-.105,.023),Vector4(side*.155,.105,0,.036)])
				for i in range(8):
					_oval(Vector3(.063,.11,.062),Vector3(side*(.175+(.008 if i%2==0 else -.008)),.005-i*.067,-.035-i*.024),Vector3(0,0,side*(.20 if i%2==0 else -.20)))
		14:
			_cap()
			_curtain(.26,false,true)
		15:
			_cap()
			_oval(Vector3(.19,.18,.19),Vector3(0,.29,.05))
			_oval(Vector3(.12,.05,.13),Vector3(0,.205,.04))
	return builder.commit()
