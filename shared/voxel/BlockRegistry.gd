extends RefCounted
class_name BlockRegistry

var _by_id: Dictionary = {} # int -> BlockDef
var _air: BlockDef

func _init() -> void:
	_register_core()

func _register_core() -> void:
	# Air (0)
	var air := BlockDef.new()
	air.id = 0
	air.name = "air"
	air.is_solid = false
	air.is_transparent = true
	air.uv_index = 0
	register_block(air)
	_air = air

	# Stone (1)
	var stone := BlockDef.new()
	stone.id = 1
	stone.name = "stone"
	stone.is_solid = true
	stone.is_transparent = false
	stone.uv_index = 1
	register_block(stone)

func register_block(def: BlockDef) -> void:
	_by_id[def.id] = def

func get_def(id: int) -> BlockDef:
	if _by_id.has(id):
		return _by_id[id]
	return _air

func is_air(id: int) -> bool:
	return id == 0
