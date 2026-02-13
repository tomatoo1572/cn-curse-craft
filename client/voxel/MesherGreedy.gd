extends RefCounted

const BlockRegistryScript := preload("res://shared/voxel/BlockRegistry.gd")

const SIZE: int = 16
const AREA: int = SIZE * SIZE

static func _idx(x: int, y: int, z: int) -> int:
	# x + z*16 + y*256
	return x + (z * SIZE) + (y * SIZE * SIZE)

static func _get_id(bytes: PackedByteArray, x: int, y: int, z: int) -> int:
	if x < 0 or x >= SIZE:
		return 0
	if y < 0 or y >= SIZE:
		return 0
	if z < 0 or z >= SIZE:
		return 0
	var i: int = _idx(x, y, z)
	if i < 0 or i >= bytes.size():
		return 0
	return int(bytes[i])

static func build_mesh_arrays_from_bytes(bytes: PackedByteArray) -> Dictionary:
	var o_verts: PackedVector3Array = PackedVector3Array()
	var o_norms: PackedVector3Array = PackedVector3Array()
	var o_uv: PackedVector2Array = PackedVector2Array()
	var o_uv2: PackedVector2Array = PackedVector2Array()
	var o_idx: PackedInt32Array = PackedInt32Array()

	var t_verts: PackedVector3Array = PackedVector3Array()
	var t_norms: PackedVector3Array = PackedVector3Array()
	var t_uv: PackedVector2Array = PackedVector2Array()
	var t_uv2: PackedVector2Array = PackedVector2Array()
	var t_idx: PackedInt32Array = PackedInt32Array()

	var mask_id: PackedInt32Array = PackedInt32Array()
	var mask_sign: PackedInt32Array = PackedInt32Array()
	mask_id.resize(AREA)
	mask_sign.resize(AREA)

	for d in [0, 1, 2]:
		for slice in range(-1, SIZE):
			# Build mask
			var n: int = 0
			for vv in range(0, SIZE):
				for uu in range(0, SIZE):
					var x: int = 0
					var y: int = 0
					var z: int = 0

					if d == 0:
						x = slice
						y = vv
						z = uu
					elif d == 1:
						x = uu
						y = slice
						z = vv
					else:
						x = uu
						y = vv
						z = slice

					var a: int = _get_id(bytes, x, y, z)

					if d == 0:
						x = slice + 1
					elif d == 1:
						y = slice + 1
					else:
						z = slice + 1

					var b: int = _get_id(bytes, x, y, z)

					var id_out: int = 0
					var sign_out: int = 0

					if a != 0 and b == 0:
						id_out = a
						sign_out = 1
					elif a == 0 and b != 0:
						id_out = b
						sign_out = -1

					mask_id[n] = id_out
					mask_sign[n] = sign_out
					n += 1

			# Greedy merge rectangles on the mask
			var j: int = 0
			for vv0 in range(0, SIZE):
				for uu0 in range(0, SIZE):
					var id0: int = int(mask_id[j])
					var s0: int = int(mask_sign[j])

					if id0 == 0:
						j += 1
						continue

					# width
					var w: int = 1
					while uu0 + w < SIZE:
						var jj: int = j + w
						if int(mask_id[jj]) != id0 or int(mask_sign[jj]) != s0:
							break
						w += 1

					# height
					var h: int = 1
					var done: bool = false
					while vv0 + h < SIZE and not done:
						for k in range(0, w):
							var jj2: int = (uu0 + k) + (vv0 + h) * SIZE
							if int(mask_id[jj2]) != id0 or int(mask_sign[jj2]) != s0:
								done = true
								break
						if not done:
							h += 1

					_emit_quad(
						id0, d, s0,
						slice, uu0, vv0,
						w, h,
						o_verts, o_norms, o_uv, o_uv2, o_idx
					)

					# Clear rectangle
					for dv in range(0, h):
						for du in range(0, w):
							var jj3: int = (uu0 + du) + (vv0 + dv) * SIZE
							mask_id[jj3] = 0
							mask_sign[jj3] = 0

					j += 1

	return {
		"opaque": {
			"verts": o_verts,
			"normals": o_norms,
			"uv": o_uv,
			"uv2": o_uv2,
			"indices": o_idx,
		},
		"transparent": {
			"verts": t_verts,
			"normals": t_norms,
			"uv": t_uv,
			"uv2": t_uv2,
			"indices": t_idx,
		}
	}

static func _emit_quad(
	id0: int,
	d: int,
	face_sign: int, # renamed from "sign" to avoid built-in warning
	slice: int,
	uu0: int,
	vv0: int,
	w: int,
	h: int,
	verts: PackedVector3Array,
	norms: PackedVector3Array,
	uv: PackedVector2Array,
	uv2: PackedVector2Array,
	indices: PackedInt32Array
) -> void:
	var x0: int = 0
	var y0: int = 0
	var z0: int = 0

	if d == 0:
		x0 = slice + 1
		y0 = vv0
		z0 = uu0
	elif d == 1:
		x0 = uu0
		y0 = slice + 1
		z0 = vv0
	else:
		x0 = uu0
		y0 = vv0
		z0 = slice + 1

	var du: Vector3 = Vector3.ZERO
	var dv: Vector3 = Vector3.ZERO

	if d == 0:
		du = Vector3(0.0, 0.0, float(w))
		dv = Vector3(0.0, float(h), 0.0)
	elif d == 1:
		du = Vector3(float(w), 0.0, 0.0)
		dv = Vector3(0.0, 0.0, float(h))
	else:
		du = Vector3(float(w), 0.0, 0.0)
		dv = Vector3(0.0, float(h), 0.0)

	var p0: Vector3 = Vector3(float(x0), float(y0), float(z0))
	var p1: Vector3 = p0 + du
	var p2: Vector3 = p0 + du + dv
	var p3: Vector3 = p0 + dv

	var n: Vector3 = Vector3.ZERO
	if d == 0:
		n.x = float(face_sign)
	elif d == 1:
		n.y = float(face_sign)
	else:
		n.z = float(face_sign)

	# UV repeats in block-units, shader will tile using fract(UV)
	var uv0: Vector2 = Vector2(0.0, 0.0)
	var uv1: Vector2 = Vector2(float(w), 0.0)
	var uv2v: Vector2 = Vector2(float(w), float(h))
	var uv3: Vector2 = Vector2(0.0, float(h))

	# UV2 stores atlas tile coordinate (tx, ty)
	var tile: Vector2i = BlockRegistryScript.tile_for_face(id0, d, face_sign)
	var tile_v: Vector2 = Vector2(float(tile.x), float(tile.y))

	var base: int = verts.size()

	if face_sign > 0:
		verts.append(p0); verts.append(p1); verts.append(p2); verts.append(p3)
		uv.append(uv0); uv.append(uv1); uv.append(uv2v); uv.append(uv3)
	else:
		verts.append(p0); verts.append(p3); verts.append(p2); verts.append(p1)
		uv.append(uv0); uv.append(uv3); uv.append(uv2v); uv.append(uv1)

	for _i in range(4):
		norms.append(n)
		uv2.append(tile_v)

	indices.append(base + 0)
	indices.append(base + 1)
	indices.append(base + 2)
	indices.append(base + 0)
	indices.append(base + 2)
	indices.append(base + 3)
