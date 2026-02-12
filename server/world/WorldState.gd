extends Node

const WorldStorageScript = preload("res://server/world/WorldStorage.gd")

const CHUNK_SIZE: int = 16
const CHUNK_LEN: int = CHUNK_SIZE * CHUNK_SIZE * CHUNK_SIZE # 4096

@export var world_seed: int = 12345

var _storage := WorldStorageScript.new()

# key "cx,cz" -> PackedByteArray
var _chunks: Dictionary = {}
var _pending_gen: Dictionary = {} # key -> true

# dirty keys waiting to be queued
var _dirty: Dictionary = {} # key -> true

# save queue contains keys to write to disk (incremental)
var _save_queue: Array[String] = []

const SAVE_CHUNKS_PER_FRAME: int = 2

func setup_world(world_id: String, desired_seed: int) -> void:
	_storage.setup(world_id)

	var meta: Dictionary = _storage.read_meta()
	if meta.is_empty():
		world_seed = desired_seed
		_storage.write_meta(world_seed)
	else:
		var s_v: Variant = meta.get("seed", desired_seed)
		if typeof(s_v) == TYPE_INT:
			world_seed = int(s_v)
		else:
			world_seed = desired_seed

func _process(_delta: float) -> void:
	# Incremental disk writes to avoid stutter
	var budget: int = SAVE_CHUNKS_PER_FRAME
	while budget > 0 and not _save_queue.is_empty():
		var k: String = _save_queue.pop_front()
		var parts: PackedStringArray = k.split(",")
		if parts.size() == 2 and _chunks.has(k):
			var cx: int = int(parts[0])
			var cz: int = int(parts[1])
			var bytes: PackedByteArray = _chunks[k] as PackedByteArray
			_storage.save_chunk_bytes(cx, cz, bytes)
		budget -= 1

	Stats.dirty_chunks = _dirty.size()
	Stats.save_queue = _save_queue.size()

func request_autosave_queue() -> void:
	# Move dirty keys into save queue (dedupe)
	for k_var in _dirty.keys():
		var k: String = str(k_var)
		if not _save_queue.has(k):
			_save_queue.append(k)
	_dirty.clear()

func flush_all_saves_sync() -> void:
	# queue dirty first
	request_autosave_queue()

	# save everything remaining right now
	while not _save_queue.is_empty():
		var k: String = _save_queue.pop_front()
		var parts: PackedStringArray = k.split(",")
		if parts.size() != 2:
			continue
		if not _chunks.has(k):
			continue
		var cx: int = int(parts[0])
		var cz: int = int(parts[1])
		var bytes: PackedByteArray = _chunks[k] as PackedByteArray
		_storage.save_chunk_bytes(cx, cz, bytes)

func request_chunk(cx: int, cz: int) -> Dictionary:
	var k: String = _key(cx, cz)

	if _chunks.has(k):
		return {"ok": true, "bytes": (_chunks[k] as PackedByteArray).duplicate()}

	# Try disk first (fast, authoritative)
	var loaded: PackedByteArray = _storage.load_chunk_bytes(cx, cz, CHUNK_LEN)
	if loaded.size() == CHUNK_LEN:
		_chunks[k] = loaded
		return {"ok": true, "bytes": loaded.duplicate()}

	# Otherwise generate (async)
	if _pending_gen.has(k):
		return {"pending": true}

	_pending_gen[k] = true
	var task := Callable(self, "_gen_task").bind(cx, cz, k)
	WorkerThreadPool.add_task(task)
	return {"pending": true}

func _gen_task(cx: int, cz: int, key: String) -> void:
	var bytes := _generate_flat_chunk_bytes(cx, cz)
	Callable(self, "_on_gen_done").call_deferred(key, bytes)

func _on_gen_done(key: String, bytes: PackedByteArray) -> void:
	_pending_gen.erase(key)
	_chunks[key] = bytes

func _generate_flat_chunk_bytes(_cx: int, _cz: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(CHUNK_LEN)

	for y in range(0, CHUNK_SIZE):
		for z in range(0, CHUNK_SIZE):
			for x in range(0, CHUNK_SIZE):
				var idx: int = x + (z * CHUNK_SIZE) + (y * CHUNK_SIZE * CHUNK_SIZE)
				var id: int = 0
				if y <= 2:
					id = 1 # stone
				elif y == 3:
					id = 2 # grass
				b[idx] = id
	return b

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
	if not _chunks.has(key):
		# If chunk not loaded, treat as air for now.
		return 0

	var bytes: PackedByteArray = _chunks[key] as PackedByteArray
	var idx: int = lx + (lz * 16) + (y * 256)
	if idx < 0 or idx >= bytes.size():
		return 0
	return int(bytes[idx])

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
	if not _chunks.has(key):
		# Ensure chunk exists in memory
		var loaded: PackedByteArray = _storage.load_chunk_bytes(cx, cz, CHUNK_LEN)
		if loaded.size() == CHUNK_LEN:
			_chunks[key] = loaded
		else:
			_chunks[key] = _generate_flat_chunk_bytes(cx, cz)

	var bytes: PackedByteArray = _chunks[key] as PackedByteArray
	var idx: int = lx + (lz * 16) + (y * 256)
	if idx < 0 or idx >= bytes.size():
		return

	var new_id: int = clamp(id, 0, 255)
	if int(bytes[idx]) == new_id:
		return

	bytes[idx] = new_id
	_chunks[key] = bytes # write-back (important)

	_dirty[key] = true

func _key(cx: int, cz: int) -> String:
	return "%d,%d" % [cx, cz]
