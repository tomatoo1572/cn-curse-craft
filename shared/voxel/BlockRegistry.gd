extends RefCounted

const BlockDefScript := preload("res://shared/voxel/BlockDef.gd")

static var _inited: bool = false
static var _defs: Dictionary = {} # int -> RefCounted (BlockDef)

static func _init_defaults() -> void:
	if _inited:
		return
	_inited = true
	_defs.clear()

	# Atlas: 256x256, tiles are 32x32 => 8x8 tiles.
	# Your current atlas top row:
	# (0,0) dirt, (1,0) grass, (2,0) stone

	# id 1 = stone
	_defs[1] = BlockDefScript.new(
		1, "stone", true, 0,
		Vector2i(2, 0), Vector2i(2, 0), Vector2i(2, 0)
	)

	# id 2 = dirt
	_defs[2] = BlockDefScript.new(
		2, "dirt", true, 0,
		Vector2i(0, 0), Vector2i(0, 0), Vector2i(0, 0)
	)

	# id 3 = grass
	# You only have ONE grass tile right now, so we use it for top+side,
	# and use dirt for the bottom (Minecraft-ish).
	_defs[3] = BlockDefScript.new(
		3, "grass", true, 0,
		Vector2i(1, 0), Vector2i(0, 0), Vector2i(1, 0)
	)

static func has(id: int) -> bool:
	_init_defaults()
	return _defs.has(id)

static func is_solid(id: int) -> bool:
	if id == 0:
		return false
	_init_defaults()
	var d: Variant = _defs.get(id, null)
	if d == null:
		return true
	return bool((d as RefCounted).get("solid"))

static func render_layer(id: int) -> int:
	if id == 0:
		return 0
	_init_defaults()
	var d: Variant = _defs.get(id, null)
	if d == null:
		return 0
	return int((d as RefCounted).get("render_layer"))

# d_axis: 0=X, 1=Y, 2=Z
# face_sign: +1 or -1
static func tile_for_face(id: int, d_axis: int, face_sign: int) -> Vector2i:
	_init_defaults()
	var d: Variant = _defs.get(id, null)
	if d == null:
		return Vector2i(0, 0)

	var def: RefCounted = d as RefCounted

	if d_axis == 1:
		if face_sign > 0:
			return def.get("tile_top") as Vector2i
		return def.get("tile_bottom") as Vector2i

	return def.get("tile_side") as Vector2i
