extends Node

const WorldGenFlatScript = preload("res://server/world/WorldGenFlat.gd")

# key "cx,cz" -> PackedByteArray (subchunk 0 only for now)
var _chunk_bytes: Dictionary = {}
var _pending: Dictionary = {}

func request_subchunk0_bytes(cx: int, cz: int) -> Dictionary:
	var key := "%d,%d" % [cx, cz]

	if _chunk_bytes.has(key):
		return {"ok": true, "pending": false, "bytes": _chunk_bytes[key]}

	if _pending.has(key):
		return {"ok": false, "pending": true}

	# Not generated yet: enqueue async job
	_pending[key] = true

	# Skeleton async generation
	var callable := Callable(self, "_gen_task").bind(cx, cz, key)
	WorkerThreadPool.add_task(callable)

	return {"ok": false, "pending": true}

func _gen_task(cx: int, cz: int, key: String) -> void:
	# This runs on a worker thread.
	# Generate bytes (pure data), then hand off storing to main thread.
	var bytes: PackedByteArray = WorldGenFlatScript.generate_subchunk_0_bytes()
	Callable(self, "_finish_gen").call_deferred(key, bytes)

func _finish_gen(key: String, bytes: PackedByteArray) -> void:
	# Main thread
	_chunk_bytes[key] = bytes
	_pending.erase(key)
