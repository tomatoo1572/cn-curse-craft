extends Node

var _server: Node = null
var _client: Node = null

func bind_to_server(server: Node) -> void:
	_server = server
	_server.call("start")

func connect_client(client: Node) -> void:
	_client = client
	if _server != null:
		_server.call("register_client", client)

func request_chunk(cx: int, cz: int) -> Dictionary:
	if _server == null:
		return {"ok": false}
	return _server.call("request_chunk", cx, cz)

func client_request_break(cell: Vector3i, player_pos: Vector3) -> void:
	if _server == null:
		return
	_server.call("handle_break_request", _client, cell, player_pos)

func client_request_place(cell: Vector3i, block_id: int, player_pos: Vector3) -> void:
	if _server == null:
		return
	_server.call("handle_place_request", _client, cell, block_id, player_pos)
