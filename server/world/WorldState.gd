extends Node
class_name WorldState

const CHUNK_BYTES_LEN: int = 16 * 16 * 16

@export var world_seed: int = 12345

# key "cx,cz" -> PackedByteArray (y 0..15 only)
var _chunks: Dictionary = {}

# key -> true while generating
var _pending: Dictionary = {}

func request_chunk(cx: int, cz: int) -> Dictionary:
	var k: String = _key(cx, cz)
	if _chunks.has(k):
		return {"ok": true, "bytes": (_chunks[k] as PackedByteArray).duplicate()}

	if _pending.has(k):
		return {"pending": true}

	_pending[k] = true
	var task := Callable(self, "_gen_task").bind(cx, cz, k)
	WorkerThreadPool.add_task(task)
	return {"pending": true}

func _gen_task(cx: int, cz: int, key: String) -> void:
	var bytes := _generate_flat_chunk_bytes(cx, cz)
	Callable(self, "_on_gen_done").call_deferred(key, bytes)

func _on_gen_done(key: String, bytes: PackedByteArray) -> void:
	_pending.erase(key)
	_chunks[key] = bytes

func _generate_flat_chunk_bytes(_cx: int, _cz: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(CHUNK_BYTES_LEN)

	for y in range(0, 16):
		for z in range(0, 16):
			for x in range(0, 16):
				var idx: int = x + (z * 16) + (y * 256)
				var id: int = 0
				if y <= 2:
					id = 1
				elif y == 3:
					id = 2
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
		_chunks[key] = _generate_flat_chunk_bytes(cx, cz)
		_pending.erase(key)

	# IMPORTANT: write back after mutation
	var bytes: PackedByteArray = _chunks[key] as PackedByteArray
	var idx: int = lx + (lz * 16) + (y * 256)
	if idx < 0 or idx >= bytes.size():
		return

	bytes[idx] = clamp(id, 0, 255)
	_chunks[key] = bytes

func _key(cx: int, cz: int) -> String:
	return "%d,%d" % [cx, cz]
