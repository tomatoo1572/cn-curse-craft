extends Node

const WorldStateScript = preload("res://server/world/WorldState.gd")

var world_state: Node = null
var _clients: Array[Node] = []

var _autosave_timer: Timer = null

func _ready() -> void:
	world_state = WorldStateScript.new()
	world_state.name = "WorldState"
	add_child(world_state)

func start(_unused: Variant = null) -> void:
	world_state.call("setup_world", Config.world_id, Config.world_seed)

	if _autosave_timer == null:
		_autosave_timer = Timer.new()
		_autosave_timer.one_shot = false
		add_child(_autosave_timer)
		_autosave_timer.timeout.connect(_on_autosave_timeout)

	_autosave_timer.wait_time = float(Config.autosave_interval_sec)
	_autosave_timer.start()

func register_client(client: Node) -> void:
	if _clients.has(client):
		return
	_clients.append(client)

func unregister_client(client: Node) -> void:
	_clients.erase(client)

func request_chunk(cx: int, cz: int) -> Dictionary:
	return world_state.call("request_chunk", cx, cz)

func handle_break_request(_client: Node, cell: Vector3i, _player_pos: Vector3) -> void:
	var id: int = int(world_state.call("get_block_id_world", cell.x, cell.y, cell.z))
	if id == 0:
		return

	world_state.call("set_block_id_world", cell.x, cell.y, cell.z, 0)
	_broadcast_block_delta(cell.x, cell.y, cell.z, 0)

func handle_place_request(_client: Node, cell: Vector3i, block_id: int, _player_pos: Vector3) -> void:
	if block_id <= 0:
		return

	var existing: int = int(world_state.call("get_block_id_world", cell.x, cell.y, cell.z))
	if existing != 0:
		return

	world_state.call("set_block_id_world", cell.x, cell.y, cell.z, block_id)
	_broadcast_block_delta(cell.x, cell.y, cell.z, block_id)

func _broadcast_block_delta(x: int, y: int, z: int, id: int) -> void:
	for c in _clients:
		if is_instance_valid(c):
			c.call("receive_block_delta", x, y, z, id)

func _on_autosave_timeout() -> void:
	world_state.call("request_autosave_queue")

func _exit_tree() -> void:
	if world_state != null and is_instance_valid(world_state):
		world_state.call("flush_all_saves_sync")
