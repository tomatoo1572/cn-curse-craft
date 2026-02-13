extends Node3D

const ShaderRes := preload("res://client/shaders/voxel_atlas.gdshader")

var _cx: int = 0
var _cz: int = 0

var _opaque_mi: MeshInstance3D
var _trans_mi: MeshInstance3D

static var _opaque_mat: ShaderMaterial = null
static var _trans_mat: ShaderMaterial = null

func set_chunk_coords(cx: int, cz: int) -> void:
	_cx = cx
	_cz = cz
	global_position = Vector3(float(cx * 16), 0.0, float(cz * 16))

func _ready() -> void:
	_opaque_mi = MeshInstance3D.new()
	_opaque_mi.name = "Opaque"
	add_child(_opaque_mi)

	_trans_mi = MeshInstance3D.new()
	_trans_mi.name = "Transparent"
	add_child(_trans_mi)

	_opaque_mi.material_override = _get_opaque_mat()
	_trans_mi.material_override = _get_trans_mat()

static func _make_mat(_is_transparent: bool) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = ShaderRes

	var path := str(Config.atlas_texture_path)
	var tex: Texture2D = load(path) as Texture2D

	if tex == null:
		Log.err("[RENDER] Failed to load atlas texture at: %s" % path)
	else:
		var sz: Vector2 = Vector2(tex.get_size())
		Log.info("[RENDER] Atlas loaded: %s size=%s" % [path, str(sz)])

		mat.set_shader_parameter("atlas_tex", tex)
		mat.set_shader_parameter("atlas_size_px", sz)

	mat.set_shader_parameter("atlas_tiles", Vector2(float(Config.atlas_tiles_x), float(Config.atlas_tiles_y)))
	mat.set_shader_parameter("padding_px", float(Config.atlas_padding_px))

	return mat

static func _get_opaque_mat() -> ShaderMaterial:
	if _opaque_mat == null:
		_opaque_mat = _make_mat(false)
	return _opaque_mat

static func _get_trans_mat() -> ShaderMaterial:
	if _trans_mat == null:
		_trans_mat = _make_mat(true)
	return _trans_mat

func apply_mesh_arrays(opaque: Dictionary, transparent: Dictionary) -> void:
	_opaque_mi.mesh = _mesh_from(opaque)
	_trans_mi.mesh = _mesh_from(transparent)

func _mesh_from(d: Dictionary) -> Mesh:
	if d.is_empty():
		return null

	var verts: PackedVector3Array = d.get("verts", PackedVector3Array()) as PackedVector3Array
	if verts.is_empty():
		return null

	var norms: PackedVector3Array = d.get("normals", PackedVector3Array()) as PackedVector3Array
	var uv: PackedVector2Array = d.get("uv", PackedVector2Array()) as PackedVector2Array
	var uv2: PackedVector2Array = d.get("uv2", PackedVector2Array()) as PackedVector2Array
	var idx: PackedInt32Array = d.get("indices", PackedInt32Array()) as PackedInt32Array

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_TEX_UV2] = uv2
	arrays[Mesh.ARRAY_INDEX] = idx

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
