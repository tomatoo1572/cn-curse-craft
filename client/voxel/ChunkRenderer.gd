extends Node3D

const MesherNaiveScript = preload("res://client/voxel/MesherNaive.gd")

var _opaque_mi: MeshInstance3D
var _trans_mi: MeshInstance3D

var _opaque_mat: StandardMaterial3D
var _trans_mat: StandardMaterial3D

func _ready() -> void:
	_ensure_children()
	_build_materials()

func _ensure_children() -> void:
	_opaque_mi = get_node_or_null("Opaque")
	if _opaque_mi == null:
		_opaque_mi = MeshInstance3D.new()
		_opaque_mi.name = "Opaque"
		add_child(_opaque_mi)

	_trans_mi = get_node_or_null("Transparent")
	if _trans_mi == null:
		_trans_mi = MeshInstance3D.new()
		_trans_mi.name = "Transparent"
		add_child(_trans_mi)

func _build_materials() -> void:
	_opaque_mat = StandardMaterial3D.new()
	_opaque_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_opaque_mat.albedo_color = Color(0.65, 0.65, 0.70) # stone-ish placeholder

	_trans_mat = StandardMaterial3D.new()
	_trans_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trans_mat.albedo_color = Color(0.7, 0.9, 1.0, 0.35)
	_trans_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

func render_chunk_sub0(chunk, blocks) -> void:
	# M1: we only render subchunk y=0 at chunk origin
	var sub = chunk.get_sub(0)
	if sub == null:
		_opaque_mi.mesh = null
		_trans_mi.mesh = null
		return

	var origin := Vector3(chunk.cx * 16, 0, chunk.cz * 16)
	var result: Dictionary = MesherNaiveScript.build_mesh_for_subchunk(sub, blocks, origin)

	var opaque_mesh: ArrayMesh = result["opaque"]
	var trans_mesh: ArrayMesh = result["transparent"]

	_opaque_mi.mesh = opaque_mesh
	if _opaque_mi.mesh != null and _opaque_mi.mesh.get_surface_count() > 0:
		_opaque_mi.set_surface_override_material(0, _opaque_mat)

	_trans_mi.mesh = trans_mesh
	if _trans_mi.mesh != null and _trans_mi.mesh.get_surface_count() > 0:
		_trans_mi.set_surface_override_material(0, _trans_mat)
