extends Node

var fps: int = 0
var mode: String = "local"
var connected: bool = false
var ping_ms: int = 0

var chunks_loaded: int = 0
var subchunks_loaded: int = 0
var chunk_gen_jobs_in_queue: int = 0
var mesh_jobs_in_flight: int = 0

var player_pos: Vector3 = Vector3.ZERO
var camera_pos: Vector3 = Vector3.ZERO

# Minecraft-style block targeting (INTEGER grid coords)
var has_hover: bool = false
var hovered_cell: Vector3i = Vector3i.ZERO          # block you would BREAK
var hovered_face_normal: Vector3i = Vector3i.ZERO   # face normal hit (one of +-X/Y/Z)
var hovered_place_cell: Vector3i = Vector3i.ZERO    # block you would PLACE (cell + normal)

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

	has_hover = false
	hovered_cell = Vector3i.ZERO
	hovered_face_normal = Vector3i.ZERO
	hovered_place_cell = Vector3i.ZERO
