extends Node

# Core overlay stats
var fps: int = 0
var mode: String = "local"
var connected: bool = false
var ping_ms: int = 0

var chunks_loaded: int = 0
var subchunks_loaded: int = 0
var chunk_gen_jobs_in_queue: int = 0
var mesh_jobs_in_flight: int = 0

# M4 debugging (to prove if position actually changes)
var player_pos: Vector3 = Vector3.ZERO
var camera_pos: Vector3 = Vector3.ZERO
var hovered_block: Vector3 = Vector3.ZERO  # stores block center (x+0.5,y+0.5,z+0.5) or ZERO if none

func reset_placeholders() -> void:
	fps = 0
	mode = "local"
	connected = false
	ping_ms = 0

	chunks_loaded = 0
	subchunks_loaded = 0
	chunk_gen_jobs_in_queue = 0
	mesh_jobs_in_flight = 0

	player_pos = Vector3.ZERO
	camera_pos = Vector3.ZERO
	hovered_block = Vector3.ZERO
