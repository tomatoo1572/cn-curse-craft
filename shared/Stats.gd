extends Node

var mode: String = "local"

var chunks_loaded: int = 0
var subchunks_loaded: int = 0
var chunk_gen_jobs_in_queue: int = 0
var mesh_jobs_in_flight: int = 0

var player_pos: Vector3 = Vector3.ZERO
var camera_pos: Vector3 = Vector3.ZERO

var has_hover: bool = false
var hovered_cell: Vector3i = Vector3i.ZERO
var hovered_face_normal: Vector3i = Vector3i.ZERO
var hovered_place_cell: Vector3i = Vector3i.ZERO

# M6 save stats
var dirty_chunks: int = 0
var save_queue: int = 0

func reset_placeholders() -> void:
	mode = "local"
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
	dirty_chunks = 0
	save_queue = 0
