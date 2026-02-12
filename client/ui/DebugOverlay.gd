extends CanvasLayer

@onready var panel: Control = $Panel
@onready var label: Label = $Panel/Margin/Label

func _ready() -> void:
	# IMPORTANT: UI must not steal mouse input
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if $Panel/Margin is Control:
		($Panel/Margin as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	var hit_block_str := "-"
	var hit_face_str := "-"
	var place_block_str := "-"

	if Stats.has_hover:
		hit_block_str = "%d, %d, %d" % [Stats.hovered_cell.x, Stats.hovered_cell.y, Stats.hovered_cell.z]
		hit_face_str = "%d, %d, %d" % [Stats.hovered_face_normal.x, Stats.hovered_face_normal.y, Stats.hovered_face_normal.z]
		place_block_str = "%d, %d, %d" % [Stats.hovered_place_cell.x, Stats.hovered_place_cell.y, Stats.hovered_place_cell.z]

	label.text = (
		"CN CurseCraft — Voxel Core (M4)\n"
		+ "Mode: %s   Connected: %s   Ping: %dms\n" % [Stats.mode, str(Stats.connected), Stats.ping_ms]
		+ "FPS: %d\n\n" % [Stats.fps]
		+ "Chunks Loaded: %d\n" % [Stats.chunks_loaded]
		+ "Subchunks Loaded: %d\n"
		% [Stats.subchunks_loaded]
		+ "Chunk Gen Queue: %d\n" % [Stats.chunk_gen_jobs_in_queue]
		+ "Mesh Jobs In Flight: %d\n\n" % [Stats.mesh_jobs_in_flight]
		+ "Player Pos: %0.3f, %0.3f, %0.3f\n" % [Stats.player_pos.x, Stats.player_pos.y, Stats.player_pos.z]
		+ "Camera Pos: %0.3f, %0.3f, %0.3f\n\n" % [Stats.camera_pos.x, Stats.camera_pos.y, Stats.camera_pos.z]
		+ "Hit Block (int): %s\n" % hit_block_str
		+ "Hit Face Normal: %s\n" % hit_face_str
		+ "Place Block (int): %s\n\n" % place_block_str
		+ "Controls: WASD move, Mouse look, Space jump, Shift sprint"
	)
