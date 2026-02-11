extends Node

var server: Node = null

func bind_to_server(s: Node) -> void:
	server = s
	Log.info("[transport] bound to local server")

func request_join_world() -> Dictionary:
	return {
		"ok": true,
		"seed": 12345,
		"spawn_pos": Vector3(0, 2, 0)
	}

func request_player_move(_desired: Vector3) -> void:
	pass
