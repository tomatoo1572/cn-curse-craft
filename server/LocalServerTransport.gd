extends Node

var server: Node = null

func bind_to_server(s: Node) -> void:
	server = s
	Log.info("[transport] bound to local server")

func request_join_world() -> Dictionary:
	return {
		"ok": true,
		"seed": 12345,
		"spawn_pos": Vector3(8, 6, 8)
	}

func request_chunk(cx: int, cz: int) -> Dictionary:
	if server == null:
		return {"ok": false, "pending": false, "error": "no_server"}

	var ws: Node = server.get_node_or_null("WorldState")
	if ws == null:
		return {"ok": false, "pending": false, "error": "no_world_state"}

	var resp_v: Variant = ws.call("request_subchunk0_bytes", cx, cz)
	if typeof(resp_v) != TYPE_DICTIONARY:
		return {"ok": false, "pending": false, "error": "bad_world_state_resp"}

	var resp: Dictionary = resp_v as Dictionary

	# Pass through pending/ok
	if resp.get("pending", false):
		return {"ok": false, "pending": true}

	if not resp.get("ok", false):
		return {"ok": false, "pending": false, "error": "gen_failed"}

	var bytes_v: Variant = resp.get("bytes", PackedByteArray())
	if typeof(bytes_v) != TYPE_PACKED_BYTE_ARRAY:
		return {"ok": false, "pending": false, "error": "bad_bytes"}

	return {"ok": true, "pending": false, "cx": cx, "cz": cz, "sub_y": 0, "bytes": (bytes_v as PackedByteArray)}
