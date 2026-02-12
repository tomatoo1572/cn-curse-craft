extends RefCounted
class_name MesherGreedy

const SIZE: int = 16

# We operate directly on the subchunk byte array (4096 bytes).
# id==0 => air, id!=0 => solid opaque (for M3).
# Transparent surface is kept but empty (placeholder for later).

static func build_mesh_arrays_from_bytes(sub_bytes: PackedByteArray) -> Dictionary:
	var opaque_arrays: Dictionary = _build_greedy_arrays(sub_bytes)
	var transparent_arrays: Dictionary = _empty_arrays()
	return {
		"opaque": opaque_arrays,
		"transparent": transparent_arrays
	}

static func _empty_arrays() -> Dictionary:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array()
	return {"arrays": arrays}

static func _idx(x: int, y: int, z: int) -> int:
	return x + (z * SIZE) + (y * SIZE * SIZE)

static func _get_id(bytes: PackedByteArray, x: int, y: int, z: int) -> int:
	if x < 0 or x >= SIZE or y < 0 or y >= SIZE or z < 0 or z >= SIZE:
		return 0
	return int(bytes[_idx(x, y, z)])

static func _is_solid(id: int) -> bool:
	return id != 0

static func _build_greedy_arrays(bytes: PackedByteArray) -> Dictionary:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var index_cursor: int = 0

	# Greedy meshing algorithm (classic 3-axis sweep).
	# d = sweep axis (0=x, 1=y, 2=z)
	for d in range(3):
		var u: int = (d + 1) % 3
		var v: int = (d + 2) % 3

		var x := [0, 0, 0]
		var q := [0, 0, 0]
		q[d] = 1

		# mask stores signed block id:
		#  0 => no face
		#  +id => face in +d direction (normal +)
		#  -id => face in -d direction (normal -)
		var mask: PackedInt32Array = PackedInt32Array()
		mask.resize(SIZE * SIZE)

		for xd in range(-1, SIZE):
			x[d] = xd

			# Build mask for this slice
			var n: int = 0
			for xv in range(SIZE):
				x[v] = xv
				for xu in range(SIZE):
					x[u] = xu

					var a: int = 0
					var b: int = 0

					# a = voxel on "current" side of plane
					if x[d] >= 0:
						a = _get_id(bytes, x[0], x[1], x[2])
					else:
						a = 0

					# b = voxel on "next" side of plane
					if x[d] < SIZE - 1:
						b = _get_id(bytes, x[0] + q[0], x[1] + q[1], x[2] + q[2])
					else:
						b = 0

					var a_solid: bool = _is_solid(a)
					var b_solid: bool = _is_solid(b)

					if a_solid == b_solid:
						mask[n] = 0
					elif a_solid and not b_solid:
						mask[n] = a # face points +d
					else:
						mask[n] = -b # face points -d
					n += 1

			# Greedy merge rectangles in mask
			var j: int = 0
			while j < SIZE:
				var i: int = 0
				while i < SIZE:
					var c: int = int(mask[i + j * SIZE])
					if c == 0:
						i += 1
						continue

					# Compute width
					var w: int = 1
					while i + w < SIZE and int(mask[(i + w) + j * SIZE]) == c:
						w += 1

					# Compute height
					var h: int = 1
					var done: bool = false
					while j + h < SIZE and not done:
						for k in range(w):
							if int(mask[(i + k) + (j + h) * SIZE]) != c:
								done = true
								break
						if not done:
							h += 1

					# Emit quad
					x[u] = i
					x[v] = j

					var du := [0, 0, 0]
					var dv := [0, 0, 0]
					du[u] = w
					dv[v] = h

					# Position base depends on face direction
					var normal_sign: int = 1
					if c < 0:
						normal_sign = -1

					var base := [x[0], x[1], x[2]]
					if normal_sign > 0:
						# +d face is at x[d] + 1
						base[d] = xd + 1
					else:
						# -d face is at x[d]
						base[d] = xd

					index_cursor = _emit_quad(
						verts, norms, uvs, indices, index_cursor,
						base, du, dv, d, normal_sign
					)

					# Clear mask for merged area
					for y2 in range(h):
						for x2 in range(w):
							mask[(i + x2) + (j + y2) * SIZE] = 0

					i += w
				j += 1

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	return {"arrays": arrays}

static func _emit_quad(
	verts: PackedVector3Array,
	norms: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	index_cursor: int,
	base: Array,
	du: Array,
	dv: Array,
	d_axis: int,
	normal_sign: int
) -> int:
	var x0 := Vector3(float(base[0]), float(base[1]), float(base[2]))
	var x1 := x0 + Vector3(float(du[0]), float(du[1]), float(du[2]))
	var x2 := x0 + Vector3(float(dv[0]), float(dv[1]), float(dv[2]))
	var x3 := x0 + Vector3(float(du[0] + dv[0]), float(du[1] + dv[1]), float(du[2] + dv[2]))

	var nrm := Vector3.ZERO
	if d_axis == 0:
		nrm = Vector3(float(normal_sign), 0.0, 0.0)
	elif d_axis == 1:
		nrm = Vector3(0.0, float(normal_sign), 0.0)
	else:
		nrm = Vector3(0.0, 0.0, float(normal_sign))

	# Winding: flip depending on normal sign so normals face outward
	if normal_sign > 0:
		# x0, x2, x3, x1
		verts.append(x0)
		verts.append(x2)
		verts.append(x3)
		verts.append(x1)
	else:
		# x0, x1, x3, x2
		verts.append(x0)
		verts.append(x1)
		verts.append(x3)
		verts.append(x2)

	for _i in range(4):
		norms.append(nrm)

	# UVs (placeholder). We tile by size; later we’ll map to an atlas.
	uvs.append(Vector2(0, 0))
	uvs.append(Vector2(0, 1))
	uvs.append(Vector2(1, 1))
	uvs.append(Vector2(1, 0))

	indices.append(index_cursor + 0)
	indices.append(index_cursor + 1)
	indices.append(index_cursor + 2)
	indices.append(index_cursor + 0)
	indices.append(index_cursor + 2)
	indices.append(index_cursor + 3)

	return index_cursor + 4
