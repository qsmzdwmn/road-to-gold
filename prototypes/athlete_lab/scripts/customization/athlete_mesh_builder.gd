extends RefCounted
## Small reusable meshes. Unit dimensions let named parts retain meaningful scales.
static func oval(segments := 12, rings := 6) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = segments
	mesh.rings = rings
	return mesh

static func tapered(profile: Array, segments := 12) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for ring in range(profile.size()):
		var shape: Vector3 = profile[ring] # y, x radius, z radius
		var previous: Vector3 = profile[maxi(0, ring - 1)]
		var following: Vector3 = profile[mini(profile.size() - 1, ring + 1)]
		var dy := maxf(following.x - previous.x, 0.001)
		for segment in range(segments):
			var angle := TAU * segment / segments
			vertices.append(Vector3(sin(angle) * shape.y, shape.x, cos(angle) * shape.z))
			var slope := ((following.y - previous.y) * sin(angle) * sin(angle) + (following.z - previous.z) * cos(angle) * cos(angle)) / dy
			normals.append(Vector3(sin(angle), -slope, cos(angle)).normalized())
	for ring in range(profile.size() - 1):
		for segment in range(segments):
			var a := ring * segments + segment
			var b := ring * segments + (segment + 1) % segments
			var c := a + segments
			var d := b + segments
			indices.append_array(PackedInt32Array([a, c, b, b, c, d]))
	# Close ends; the caps are mostly hidden by adjoining forms.
	for end in [0, profile.size() - 1]:
		var center := vertices.size()
		vertices.append(Vector3(0, profile[end].x, 0))
		normals.append(Vector3.DOWN if end == 0 else Vector3.UP)
		for segment in range(segments):
			var a: int = end * segments + segment
			var b: int = end * segments + (segment + 1) % segments
			indices.append_array(PackedInt32Array([center, b, a] if end == 0 else [center, a, b]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
