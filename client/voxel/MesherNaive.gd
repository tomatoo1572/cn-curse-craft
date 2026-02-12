extends RefCounted
class_name MesherNaive

# Builds an ArrayMesh for one 16x16x16 subchunk.
# Naive meshing: one quad per exposed face.

const FACE_DIRS := [
	Vector3i( 1, 0, 0), # +X
	Vector3i(-1, 0, 0), # -X
	Vector3i( 0, 1, 0), # +Y
	Vector3i( 0,-1, 0), # -Y
	Vector3i( 0, 0, 1), # +Z
	Vector3i( 0, 0,-1)  # -Z
]

# For each face: 4 vertices (local cube positions)
const FACE_VERTS := [
	# +X
	[Vector3(1,0,0), Vector3(1,1,0), Vector3(1,1,1), Vector3(1,0,1)],
	# -X
	[Vector3(0,0,1), Vector3(0,1,1), Vector3(0,1,0), Vector3(0,0,0)],
	# +Y
	[Vector3(0,1,1), Vector3(1,1,1), Vector3(1,1,0), Vector3(0,1,0)],
	# -Y
	[Vector3(0,0,0), Vector3(1,0,0), Vector3(1,0,1), Vector3(0,0,1)],
	# +Z
	[Vector3(1,0,1), Vector3(1,1,1), Vector3(0,1,1), Vector3(0,0,1)],
	# -Z
	[Vector3(0,0,0), Vector3(0,1,0), Vector3(1,1,0), Vector3(1,0,0)]
]

const FACE_NORMALS := [
	Vector3( 1, 0, 0),
	Vector3(-1, 0, 0),
	Vector3( 0, 1, 0),
	Vector3( 0,-1, 0),
	Vector3( 0, 0, 1),
	Vector3( 0, 0,-1)
]

static func build_mesh_for_subchunk(sub, blocks: BlockRegistry, origin: Vector3) -> Dictionary:
	# returns { "opaque": ArrayMesh, "transparent": ArrayMesh }
	var opaque := _build(sub, blocks, origin, false)
	var trans := _build(sub, blocks, origin, true)
	return {"opaque": opaque, "transparent": trans}

static func _build(sub, blocks: BlockRegistry, origin: Vector3, want_transparent: bool) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	var index_cursor: int = 0

	for y in range(16):
		for z in range(16):
			for x in range(16):
				var id: int = sub.get_block(x, y, z)
				if blocks.is_air(id):
					continue

				var def := blocks.get_def(id)
				if def.is_transparent != want_transparent:
					continue

				for f in range(6):
					var d: Vector3i = FACE_DIRS[f]
					var nx: int = x + d.x
					var ny: int = y + d.y
					var nz: int = z + d.z

					var neighbor_id: int = 0
					var in_bounds: bool = (nx >= 0 and nx < 16 and ny >= 0 and ny < 16 and nz >= 0 and nz < 16)
					if in_bounds:
						neighbor_id = sub.get_block(nx, ny, nz)
					else:
						neighbor_id = 0 # treat outside as air (M1: single subchunk only)

					if not blocks.is_air(neighbor_id):
						continue

					# Add quad
					var fv = FACE_VERTS[f]
					var nrm: Vector3 = FACE_NORMALS[f]

					for i in range(4):
						verts.append(origin + Vector3(x, y, z) + fv[i])
						norms.append(nrm)

					# placeholder UVs (0..1)
					uvs.append(Vector2(0, 0))
					uvs.append(Vector2(0, 1))
					uvs.append(Vector2(1, 1))
					uvs.append(Vector2(1, 0))

					# two triangles: (0,1,2) and (0,2,3)
					indices.append(index_cursor + 0)
					indices.append(index_cursor + 1)
					indices.append(index_cursor + 2)
					indices.append(index_cursor + 0)
					indices.append(index_cursor + 2)
					indices.append(index_cursor + 3)
					index_cursor += 4

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	if verts.size() > 0:
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
