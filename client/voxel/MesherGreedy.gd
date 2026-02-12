extends RefCounted
class_name MesherGreedy

const SIZE: int = 16
const LAYER: int = SIZE * SIZE
const TOTAL: int = SIZE * SIZE * SIZE

static func build_mesh_arrays_from_bytes(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() < TOTAL:
		return {"opaque": {}, "transparent": {}}

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	# Greedy meshing across 3 axes
	for d in range(3):
		var u: int = (d + 1) % 3
		var v: int = (d + 2) % 3

		var q := Vector3i(0, 0, 0)
		q[d] = 1

		var mask: Array[int] = []
		mask.resize(SIZE * SIZE)

		for slice in range(-1, SIZE):
			# 1) Build mask for this slice
			for j in range(SIZE):
				for i in range(SIZE):
					var x := Vector3i(0, 0, 0)
					x[u] = i
					x[v] = j
					x[d] = slice

					var a: int = 0
					var b: int = 0

					if slice >= 0:
						a = _get_voxel(bytes, x.x, x.y, x.z)
					if slice < SIZE - 1:
						b = _get_voxel(bytes, x.x + q.x, x.y + q.y, x.z + q.z)

					var mi: int = i + j * SIZE
					if (a != 0) != (b != 0):
						# +id => face points +d, -id => face points -d
						mask[mi] = a if a != 0 else -b
					else:
						mask[mi] = 0

			# 2) Greedy merge rectangles in mask
			for j in range(SIZE):
				var i: int = 0
				while i < SIZE:
					var idx: int = i + j * SIZE
					var c: int = mask[idx]
					if c == 0:
						i += 1
						continue

					# Width
					var w: int = 1
					while i + w < SIZE and mask[idx + w] == c:
						w += 1

					# Height
					var h: int = 1
					while j + h < SIZE:
						var row_start: int = i + (j + h) * SIZE
						var ok: bool = true
						for k in range(w):
							if mask[row_start + k] != c:
								ok = false
								break
						if not ok:
							break
						h += 1

					# Emit quad
					var x0 := Vector3i(0, 0, 0)
					x0[u] = i
					x0[v] = j
					x0[d] = slice + 1

					var du := Vector3i(0, 0, 0)
					var dv := Vector3i(0, 0, 0)
					du[u] = w
					dv[v] = h

					var backface: bool = (c < 0)
					var normal: Vector3 = _normal_for_axis(d, backface)

					_emit_quad(
						verts, norms, uvs, indices,
						Vector3(x0.x, x0.y, x0.z),
						Vector3(du.x, du.y, du.z),
						Vector3(dv.x, dv.y, dv.z),
						normal,
						backface
					)

					# Clear rectangle from mask
					for jj in range(h):
						for kk in range(w):
							mask[(i + kk) + (j + jj) * SIZE] = 0

					i += w

	# Build arrays
	if verts.is_empty():
		return {"opaque": {}, "transparent": {}}

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	return {
		"opaque": {"arrays": arrays},
		"transparent": {}
	}

static func _get_voxel(bytes: PackedByteArray, x: int, y: int, z: int) -> int:
	if x < 0 or x >= SIZE or y < 0 or y >= SIZE or z < 0 or z >= SIZE:
		return 0
	# MUST match ChunkWorld/WorldState indexing
	var idx: int = x + (z * SIZE) + (y * LAYER)
	return int(bytes[idx])

static func _normal_for_axis(d: int, backface: bool) -> Vector3:
	var s: float = -1.0 if backface else 1.0
	if d == 0:
		return Vector3(s, 0.0, 0.0)
	elif d == 1:
		return Vector3(0.0, s, 0.0)
	else:
		return Vector3(0.0, 0.0, s)

static func _emit_quad(
	verts: PackedVector3Array,
	norms: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	p: Vector3,
	du: Vector3,
	dv: Vector3,
	n: Vector3,
	backface: bool
) -> void:
	var v0: Vector3 = p
	var v1: Vector3 = p + du
	var v2: Vector3 = p + du + dv
	var v3: Vector3 = p + dv

	var base: int = verts.size()
	verts.append(v0)
	verts.append(v1)
	verts.append(v2)
	verts.append(v3)

	norms.append(n)
	norms.append(n)
	norms.append(n)
	norms.append(n)

	# Simple UVs (we’ll do atlas UVs later)
	uvs.append(Vector2(0, 0))
	uvs.append(Vector2(1, 0))
	uvs.append(Vector2(1, 1))
	uvs.append(Vector2(0, 1))

	if not backface:
		indices.append(base + 0)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 0)
		indices.append(base + 2)
		indices.append(base + 3)
	else:
		indices.append(base + 0)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 0)
		indices.append(base + 3)
		indices.append(base + 2)
