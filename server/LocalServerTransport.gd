extends Node
class_name LocalServerTransport

var _server: Node = null
var _client: Node = null

func bind_to_server(server: Node) -> void:
	_server = server
	if _server != null and _server.has_signal("block_delta"):
		_server.block_delta.connect(_on_server_block_delta)

func connect_client(client: Node) -> void:
	_client = client
	Stats.connected = true
	Stats.ping_ms = 0

# ---------------- Existing streaming API ----------------
func request_chunk(cx: int, cz: int) -> Dictionary:
	if _server == null:
		return {"ok": false}
	return _server.call("request_chunk", cx, cz)

# ---------------- M5 edit requests ----------------
func client_request_break(cell: Vector3i, player_pos: Vector3) -> void:
	if _server == null:
		return
	_server.call("handle_break_request", cell, player_pos)

func client_request_place(place_cell: Vector3i, block_id: int, player_pos: Vector3) -> void:
	if _server == null:
		return
	_server.call("handle_place_request", place_cell, block_id, player_pos)

func _on_server_block_delta(x: int, y: int, z: int, id: int) -> void:
	if _client == null:
		return
	_client.call("receive_block_delta", x, y, z, id)
