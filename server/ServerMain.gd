extends Node
class_name ServerMain

signal block_delta(x: int, y: int, z: int, id: int)

@export var max_reach: float = 6.5

var world: Node = null

func _ready() -> void:
	# WorldState is a sibling under ServerRoot, not a child of ServerMain
	var parent: Node = get_parent()
	if parent != null and parent.has_node("WorldState"):
		world = parent.get_node("WorldState")
	else:
		push_error("ServerMain: WorldState node not found under ServerRoot. Add ServerRoot/WorldState.")
		return

func request_chunk(cx: int, cz: int) -> Dictionary:
	if world == null:
		return {"ok": false}
	return world.call("request_chunk", cx, cz)

func handle_break_request(cell: Vector3i, player_pos: Vector3) -> void:
	if world == null:
		return
	if not _is_within_reach(cell, player_pos):
		return

	var id: int = int(world.call("get_block_id_world", cell.x, cell.y, cell.z))
	if id == 0:
		return

	world.call("set_block_id_world", cell.x, cell.y, cell.z, 0)
	emit_signal("block_delta", cell.x, cell.y, cell.z, 0)

func handle_place_request(place_cell: Vector3i, block_id: int, player_pos: Vector3) -> void:
	if world == null:
		return
	if not _is_within_reach(place_cell, player_pos):
		return
	if block_id <= 0:
		return

	var cur: int = int(world.call("get_block_id_world", place_cell.x, place_cell.y, place_cell.z))
	if cur != 0:
		return

	world.call("set_block_id_world", place_cell.x, place_cell.y, place_cell.z, block_id)
	emit_signal("block_delta", place_cell.x, place_cell.y, place_cell.z, block_id)

func _is_within_reach(cell: Vector3i, player_pos: Vector3) -> bool:
	var center := Vector3(float(cell.x) + 0.5, float(cell.y) + 0.5, float(cell.z) + 0.5)
	return player_pos.distance_to(center) <= max_reach
