extends Node3D

const VoxelChunkScript = preload("res://shared/voxel/VoxelChunk.gd")
const ChunkRendererScript = preload("res://client/voxel/ChunkRenderer.gd")

var _transport: Node = null
var _blocks = null
var _player: Node3D = null

# key "cx,cz" -> ChunkRenderer node
var _renderers: Dictionary = {}

# Desired requests waiting to be sent (Vector2i)
var _request_queue: Array[Vector2i] = []

# key -> next_retry_msec (int). If key exists, we are pending and should retry after that time.
var _pending_until: Dictionary = {}

# Tuning
const REQUESTS_PER_FRAME: int = 4
const PENDING_RETRY_MS: int = 200

func setup(transport: Node, blocks, player: Node3D) -> void:
	_transport = transport
	_blocks = blocks
	_player = player

func _process(_delta: float) -> void:
	if _transport == null or _blocks == null or _player == null:
		return

	_update_stream_sets()
	_process_requests_budgeted()

	# Stats
	Stats.chunks_loaded = _renderers.size()
	Stats.subchunks_loaded = _renderers.size()
	Stats.chunk_gen_jobs_in_queue = _request_queue.size() + _pending_until.size()
	Stats.mesh_jobs_in_flight = 0

func _player_chunk() -> Vector2i:
	var p: Vector3 = _player.global_position
	var cx: int = int(floor(p.x / 16.0))
	var cz: int = int(floor(p.z / 16.0))
	return Vector2i(cx, cz)

func _update_stream_sets() -> void:
	var center: Vector2i = _player_chunk()
	var vd: int = max(1, Config.view_distance_chunks)

	# Build desired set and a sorted list by distance (near first)
	var desired: Dictionary = {}
	var ordered: Array[Vector2i] = []

	for dz in range(-vd, vd + 1):
		for dx in range(-vd, vd + 1):
			var c := Vector2i(center.x + dx, center.y + dz)
			var k := _key(c.x, c.y)
			desired[k] = true
			ordered.append(c)

	# Sort by squared distance to center so near chunks load first
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var da := (a.x - center.x) * (a.x - center.x) + (a.y - center.y) * (a.y - center.y)
		var db := (b.x - center.x) * (b.x - center.x) + (b.y - center.y) * (b.y - center.y)
		return da < db
	)

	# Enqueue missing (but never duplicate)
	# We rebuild the queue each frame based on desired set to avoid stale duplicates.
	var new_queue: Array[Vector2i] = []
	for c in ordered:
		var k2 := _key(c.x, c.y)
		if _renderers.has(k2):
			continue
		# if pending, don't enqueue; pending will be retried by timer logic
		if _pending_until.has(k2):
			continue
		new_queue.append(c)

	_request_queue = new_queue

	# Unload chunks no longer desired
	var to_remove: Array[String] = []
	for k3 in _renderers.keys():
		if not desired.has(k3):
			to_remove.append(k3)

	for k4 in to_remove:
		var n: Node = _renderers[k4]
		if is_instance_valid(n):
			n.queue_free()
		_renderers.erase(k4)
		_pending_until.erase(k4)

func _process_requests_budgeted() -> void:
	var now_ms: int = Time.get_ticks_msec()

	# First, retry pending chunks that are due (limited by budget)
	var budget: int = REQUESTS_PER_FRAME

	# Collect due pending keys
	var due: Array[String] = []
	for k in _pending_until.keys():
		var t: int = int(_pending_until[k])
		if now_ms >= t:
			due.append(k)

	# Retry due pending (closest first if possible)
	# We'll just retry in dictionary order for simplicity; good enough for M2.
	for k in due:
		if budget <= 0:
			break
		var parts := k.split(",")
		if parts.size() != 2:
			_pending_until.erase(k)
			continue
		var cx: int = int(parts[0])
		var cz: int = int(parts[1])
		_try_request_chunk(cx, cz, now_ms)
		budget -= 1

	# Then request new chunks from the queue
	while budget > 0 and not _request_queue.is_empty():
		var c: Vector2i = _request_queue.pop_front()
		_try_request_chunk(c.x, c.y, now_ms)
		budget -= 1

func _try_request_chunk(cx: int, cz: int, now_ms: int) -> void:
	var k := _key(cx, cz)
	if _renderers.has(k):
		_pending_until.erase(k)
		return

	var resp_v: Variant = _transport.call("request_chunk", cx, cz)
	if typeof(resp_v) != TYPE_DICTIONARY:
		_pending_until[k] = now_ms + PENDING_RETRY_MS
		return

	var resp: Dictionary = resp_v as Dictionary

	# Pending: set next retry time
	if resp.get("pending", false):
		_pending_until[k] = now_ms + PENDING_RETRY_MS
		return

	_pending_until.erase(k)

	if not resp.get("ok", false):
		return

	var bytes_v: Variant = resp.get("bytes", PackedByteArray())
	if typeof(bytes_v) != TYPE_PACKED_BYTE_ARRAY:
		return

	var bytes: PackedByteArray = bytes_v as PackedByteArray
	var chunk = VoxelChunkScript.from_serialized(cx, cz, bytes, 0)
	_spawn_renderer_for_chunk(chunk)

func _spawn_renderer_for_chunk(chunk) -> void:
	var k := _key(chunk.cx, chunk.cz)
	if _renderers.has(k):
		return

	var r := Node3D.new()
	r.name = "Chunk_%d_%d" % [chunk.cx, chunk.cz]
	r.set_script(ChunkRendererScript)
	add_child(r)

	r.call("render_chunk_sub0", chunk, _blocks)
	_renderers[k] = r

func _key(cx: int, cz: int) -> String:
	return "%d,%d" % [cx, cz]
