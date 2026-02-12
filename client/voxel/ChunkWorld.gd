extends Node3D

const ChunkRendererScript = preload("res://client/voxel/ChunkRenderer.gd")
const MesherGreedyScript = preload("res://client/voxel/MesherGreedy.gd")

var _transport: Node = null
var _player: Node3D = null

# key "cx,cz" -> ChunkRenderer node
var _renderers: Dictionary = {}

# key "cx,cz" -> PackedByteArray (subchunk 0)
var _chunk_bytes: Dictionary = {}

# desired requests waiting to be sent
var _request_queue: Array[Vector2i] = []

# key -> next_retry_msec
var _pending_until: Dictionary = {}

# Mesh jobs
var _mesh_pending: Dictionary = {}  # key -> true
var _mesh_jobs_in_flight: int = 0

const REQUESTS_PER_FRAME: int = 4
const PENDING_RETRY_MS: int = 200

func setup(transport: Node, _blocks_unused, player: Node3D) -> void:
	_transport = transport
	_player = player

func _process(_delta: float) -> void:
	if _transport == null or _player == null:
		return

	_update_stream_sets()
	_process_requests_budgeted()

	Stats.chunks_loaded = _renderers.size()
	Stats.subchunks_loaded = _renderers.size()
	Stats.chunk_gen_jobs_in_queue = _request_queue.size() + _pending_until.size()
	Stats.mesh_jobs_in_flight = _mesh_jobs_in_flight

func _player_chunk() -> Vector2i:
	var p: Vector3 = _player.global_position
	var cx: int = int(floor(p.x / 16.0))
	var cz: int = int(floor(p.z / 16.0))
	return Vector2i(cx, cz)

func _update_stream_sets() -> void:
	var center: Vector2i = _player_chunk()
	var vd: int = max(1, Config.view_distance_chunks)

	var desired: Dictionary = {}
	var ordered: Array[Vector2i] = []

	for dz in range(-vd, vd + 1):
		for dx in range(-vd, vd + 1):
			var c: Vector2i = Vector2i(center.x + dx, center.y + dz)
			var k: String = _key(c.x, c.y)
			desired[k] = true
			ordered.append(c)

	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da: int = (a.x - center.x) * (a.x - center.x) + (a.y - center.y) * (a.y - center.y)
		var db: int = (b.x - center.x) * (b.x - center.x) + (b.y - center.y) * (b.y - center.y)
		return da < db
	)

	var new_queue: Array[Vector2i] = []
	for c2 in ordered:
		var k2: String = _key(c2.x, c2.y)
		if _renderers.has(k2):
			continue
		if _pending_until.has(k2):
			continue
		new_queue.append(c2)
	_request_queue = new_queue

	var to_remove: Array[String] = []
	for k3_var in _renderers.keys():
		var k3: String = str(k3_var)
		if not desired.has(k3):
			to_remove.append(k3)

	for k4 in to_remove:
		var n: Node = _renderers[k4]
		if is_instance_valid(n):
			n.queue_free()
		_renderers.erase(k4)
		_chunk_bytes.erase(k4)
		_pending_until.erase(k4)
		_mesh_pending.erase(k4)

func _process_requests_budgeted() -> void:
	var now_ms: int = Time.get_ticks_msec()
	var budget: int = REQUESTS_PER_FRAME

	var due: Array[String] = []
	for k_var in _pending_until.keys():
		var k: String = str(k_var)
		var t: int = int(_pending_until[k])
		if now_ms >= t:
			due.append(k)

	for k2 in due:
		if budget <= 0:
			break
		var parts: PackedStringArray = k2.split(",")
		if parts.size() != 2:
			_pending_until.erase(k2)
			continue
		var cx: int = int(parts[0])
		var cz: int = int(parts[1])
		_try_request_chunk(cx, cz, now_ms)
		budget -= 1

	while budget > 0 and not _request_queue.is_empty():
		var c: Vector2i = _request_queue.pop_front()
		_try_request_chunk(c.x, c.y, now_ms)
		budget -= 1

func _try_request_chunk(cx: int, cz: int, now_ms: int) -> void:
	var k: String = _key(cx, cz)
	if _renderers.has(k):
		_pending_until.erase(k)
		return

	var resp_v: Variant = _transport.call("request_chunk", cx, cz)
	if typeof(resp_v) != TYPE_DICTIONARY:
		_pending_until[k] = now_ms + PENDING_RETRY_MS
		return

	var resp: Dictionary = resp_v as Dictionary

	if resp.get("pending", false):
		_pending_until[k] = now_ms + PENDING_RETRY_MS
		return

	_pending_until.erase(k)

	if not resp.get("ok", false):
		return

	var bytes_v: Variant = resp.get("bytes", PackedByteArray())
	if typeof(bytes_v) != TYPE_PACKED_BYTE_ARRAY:
		return

	var bytes: PackedByteArray = (bytes_v as PackedByteArray).duplicate()
	_on_chunk_bytes_ready(cx, cz, bytes)

func _on_chunk_bytes_ready(cx: int, cz: int, bytes: PackedByteArray) -> void:
	var k: String = _key(cx, cz)
	_chunk_bytes[k] = bytes
	var _r: Node = _ensure_renderer(cx, cz)
	_request_mesh_build(cx, cz, bytes)

func _ensure_renderer(cx: int, cz: int) -> Node:
	var k: String = _key(cx, cz)
	if _renderers.has(k):
		return _renderers[k]

	var r := Node3D.new()
	r.name = "Chunk_%d_%d" % [cx, cz]
	r.set_script(ChunkRendererScript)
	add_child(r)
	r.call("set_chunk_coords", cx, cz)

	_renderers[k] = r
	return r

func _request_mesh_build(cx: int, cz: int, bytes: PackedByteArray) -> void:
	var k: String = _key(cx, cz)
	if _mesh_pending.has(k):
		return
	_mesh_pending[k] = true
	_mesh_jobs_in_flight += 1

	# snapshot for worker thread
	var bytes_snapshot: PackedByteArray = bytes.duplicate()
	var task: Callable = Callable(self, "_mesh_task").bind(cx, cz, k, bytes_snapshot)
	WorkerThreadPool.add_task(task)

func _mesh_task(cx: int, cz: int, key: String, bytes: PackedByteArray) -> void:
	var result: Dictionary = MesherGreedyScript.build_mesh_arrays_from_bytes(bytes)
	Callable(self, "_on_mesh_ready").call_deferred(cx, cz, key, result)

func _on_mesh_ready(_cx: int, _cz: int, key: String, result: Dictionary) -> void:
	_mesh_jobs_in_flight = max(0, _mesh_jobs_in_flight - 1)
	_mesh_pending.erase(key)

	if not _renderers.has(key):
		return

	var r: Node = _renderers[key]
	if not is_instance_valid(r):
		return

	var opaque: Dictionary = (result.get("opaque", {}) as Dictionary)
	var transparent: Dictionary = (result.get("transparent", {}) as Dictionary)
	r.call("apply_mesh_arrays", opaque, transparent)

func _key(cx: int, cz: int) -> String:
	return "%d,%d" % [cx, cz]

# -------------------------------------------------------------------
# Block query for collision + raycast
# Only subchunk y=0 exists right now (y 0..15).
# -------------------------------------------------------------------
func get_block_id_world(x: int, y: int, z: int) -> int:
	if y < 0 or y >= 16:
		return 0

	var cx: int = int(floor(float(x) / 16.0))
	var cz: int = int(floor(float(z) / 16.0))
	var lx: int = x - (cx * 16)
	var lz: int = z - (cz * 16)
	if lx < 0:
		lx += 16
	if lz < 0:
		lz += 16

	var key: String = _key(cx, cz)
	if not _chunk_bytes.has(key):
		return 0

	var bytes: PackedByteArray = _chunk_bytes[key] as PackedByteArray
	var idx: int = lx + (lz * 16) + (y * 256)
	if idx < 0 or idx >= bytes.size():
		return 0
	return int(bytes[idx])

# -------------------------------------------------------------------
# M5: apply authoritative delta from server + remesh affected chunk(s)
# -------------------------------------------------------------------
func set_block_id_world(x: int, y: int, z: int, id: int) -> void:
	if y < 0 or y >= 16:
		return

	var cx: int = int(floor(float(x) / 16.0))
	var cz: int = int(floor(float(z) / 16.0))
	var lx: int = x - (cx * 16)
	var lz: int = z - (cz * 16)
	if lx < 0:
		lx += 16
	if lz < 0:
		lz += 16

	var key: String = _key(cx, cz)
	if not _chunk_bytes.has(key):
		return

	# IMPORTANT: write back to dictionary after mutation
	var bytes: PackedByteArray = _chunk_bytes[key] as PackedByteArray
	var idx: int = lx + (lz * 16) + (y * 256)
	if idx < 0 or idx >= bytes.size():
		return

	bytes[idx] = clamp(id, 0, 255)
	_chunk_bytes[key] = bytes

func apply_block_delta_world(x: int, y: int, z: int, id: int) -> void:
	set_block_id_world(x, y, z, id)

	var cx: int = int(floor(float(x) / 16.0))
	var cz: int = int(floor(float(z) / 16.0))

	_remesh_if_loaded(cx, cz)

	var lx: int = x - (cx * 16)
	var lz: int = z - (cz * 16)
	if lx < 0:
		lx += 16
	if lz < 0:
		lz += 16

	if lx == 0:
		_remesh_if_loaded(cx - 1, cz)
	elif lx == 15:
		_remesh_if_loaded(cx + 1, cz)

	if lz == 0:
		_remesh_if_loaded(cx, cz - 1)
	elif lz == 15:
		_remesh_if_loaded(cx, cz + 1)

func _remesh_if_loaded(cx: int, cz: int) -> void:
	var key: String = _key(cx, cz)
	if not _chunk_bytes.has(key):
		return
	if not _renderers.has(key):
		return
	var bytes: PackedByteArray = _chunk_bytes[key] as PackedByteArray
	_request_mesh_build(cx, cz, bytes)
