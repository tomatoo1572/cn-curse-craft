extends Node3D
class_name ChunkRenderer

var _cx: int = 0
var _cz: int = 0

var _opaque_mi: MeshInstance3D
var _transparent_mi: MeshInstance3D

var _opaque_mat: StandardMaterial3D
var _transparent_mat: StandardMaterial3D

func _ready() -> void:
	# Children are created in code so the scene stays minimal.
	_opaque_mi = MeshInstance3D.new()
	_opaque_mi.name = "Opaque"
	add_child(_opaque_mi)

	_transparent_mi = MeshInstance3D.new()
	_transparent_mi.name = "Transparent"
	add_child(_transparent_mi)

	# Simple placeholder materials (we'll swap to atlas textures later)
	_opaque_mat = StandardMaterial3D.new()
	_opaque_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_opaque_mat.albedo_color = Color(0.45, 0.45, 0.48, 1.0)
	_opaque_mat.cull_mode = BaseMaterial3D.CULL_BACK

	_transparent_mat = StandardMaterial3D.new()
	_transparent_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_transparent_mat.albedo_color = Color(0.75, 0.75, 0.80, 0.35)
	_transparent_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_transparent_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_transparent_mat.no_depth_test = false

func set_chunk_coords(cx: int, cz: int) -> void:
	_cx = cx
	_cz = cz
	position = Vector3(float(cx * 16), 0.0, float(cz * 16))

# opaque_data and transparent_data are dictionaries produced by MesherGreedy
# They can be either:
# - {"arrays": <Array sized Mesh.ARRAY_MAX>}
# OR
# - {"verts": PackedVector3Array, "normals": PackedVector3Array, "uvs": PackedVector2Array, "indices": PackedInt32Array}
func apply_mesh_arrays(opaque_data: Dictionary, transparent_data: Dictionary) -> void:
	_apply_one(_opaque_mi, opaque_data, _opaque_mat)
	_apply_one(_transparent_mi, transparent_data, _transparent_mat)

func _apply_one(mi: MeshInstance3D, data: Dictionary, mat: Material) -> void:
	if data.is_empty():
		mi.mesh = null
		return

	var arrays: Array = _extract_arrays(data)
	if arrays.is_empty():
		mi.mesh = null
		return

	# IMPORTANT: replace mesh entirely every time (no accumulating surfaces)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, mat)
	mi.mesh = mesh

func _extract_arrays(data: Dictionary) -> Array:
	# Case A: caller already provided Godot arrays format
	if data.has("arrays") and typeof(data["arrays"]) == TYPE_ARRAY:
		var a: Array = data["arrays"]
		return a

	# Case B: build arrays from component fields
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)

	var verts_v: Variant = data.get("verts", PackedVector3Array())
	var norms_v: Variant = data.get("normals", PackedVector3Array())
	var uvs_v: Variant = data.get("uvs", PackedVector2Array())
	var cols_v: Variant = data.get("colors", PackedColorArray())
	var idx_v: Variant = data.get("indices", PackedInt32Array())

	var verts: PackedVector3Array = (verts_v as PackedVector3Array) if typeof(verts_v) == TYPE_PACKED_VECTOR3_ARRAY else PackedVector3Array()
	var norms: PackedVector3Array = (norms_v as PackedVector3Array) if typeof(norms_v) == TYPE_PACKED_VECTOR3_ARRAY else PackedVector3Array()
	var uvs: PackedVector2Array = (uvs_v as PackedVector2Array) if typeof(uvs_v) == TYPE_PACKED_VECTOR2_ARRAY else PackedVector2Array()
	var cols: PackedColorArray = (cols_v as PackedColorArray) if typeof(cols_v) == TYPE_PACKED_COLOR_ARRAY else PackedColorArray()
	var idx: PackedInt32Array = (idx_v as PackedInt32Array) if typeof(idx_v) == TYPE_PACKED_INT32_ARRAY else PackedInt32Array()

	if verts.is_empty():
		return []

	arrays[Mesh.ARRAY_VERTEX] = verts
	if not norms.is_empty():
		arrays[Mesh.ARRAY_NORMAL] = norms
	if not uvs.is_empty():
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	if not cols.is_empty():
		arrays[Mesh.ARRAY_COLOR] = cols
	if not idx.is_empty():
		arrays[Mesh.ARRAY_INDEX] = idx

	return arrays
