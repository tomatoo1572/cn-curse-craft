extends Node

var mode: String = "local"
var fps: int = 0

var chunks_loaded: int = 0
var subchunks_loaded: int = 0
var mesh_jobs_in_flight: int = 0
var chunk_gen_jobs_in_queue: int = 0

var connected: bool = true
var ping_ms: int = 0

func reset_placeholders() -> void:
	chunks_loaded = 0
	subchunks_loaded = 0
	mesh_jobs_in_flight = 0
	chunk_gen_jobs_in_queue = 0
	connected = true
	ping_ms = 0
