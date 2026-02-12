extends Node3D

var _opaque_mi: MeshInstance3D
var _trans_mi: MeshInstance3D

var _opaque_mat: StandardMaterial3D
var _trans_mat: StandardMaterial3D

func _ready() -> void:
	_ensure_children()
	_build_materials()

func set_chunk_coords(cx: int, cz: int) -> void:
	# Keep renderer at chunk origin. Mesh vertices are local (0..16).
	global_position = Vector3(float(cx * 16), 0.0, float(cz * 16))

func apply_mesh_arrays(opaque: Dictionary, transparent: Dictionary) -> void:
	# Build ArrayMesh on main thread only.
	_apply_one(_opaque_mi, _opaque_mat, opaque)
	_apply_one(_trans_mi, _trans_mat, transparent)

func _apply_one(mi: MeshInstance3D, mat: Material, data: Dictionary) -> void:
	if not data.has("arrays"):
		mi.mesh = null
		return

	var arrays_v: Variant = data["arrays"]
	if typeof(arrays_v) != TYPE_ARRAY:
		mi.mesh = null
		return

	var arrays: Array = arrays_v as Array
	var verts_v: Variant = arrays[Mesh.ARRAY_VERTEX]
	if typeof(verts_v) != TYPE_PACKED_VECTOR3_ARRAY:
		mi.mesh = null
		return

	var verts: PackedVector3Array = verts_v as PackedVector3Array
	if verts.size() == 0:
		mi.mesh = null
		return

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	mi.mesh = mesh
	mi.set_surface_override_material(0, mat)

func _ensure_children() -> void:
	_opaque_mi = get_node_or_null("Opaque") as MeshInstance3D
	if _opaque_mi == null:
		_opaque_mi = MeshInstance3D.new()
		_opaque_mi.name = "Opaque"
		add_child(_opaque_mi)

	_trans_mi = get_node_or_null("Transparent") as MeshInstance3D
	if _trans_mi == null:
		_trans_mi = MeshInstance3D.new()
		_trans_mi.name = "Transparent"
		add_child(_trans_mi)

func _build_materials() -> void:
	_opaque_mat = StandardMaterial3D.new()
	_opaque_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_opaque_mat.albedo_color = Color(0.65, 0.65, 0.70)

	_trans_mat = StandardMaterial3D.new()
	_trans_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trans_mat.albedo_color = Color(0.7, 0.9, 1.0, 0.35)
	_trans_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
