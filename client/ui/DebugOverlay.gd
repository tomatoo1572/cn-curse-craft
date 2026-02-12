extends CanvasLayer

@onready var label: Label = $Panel/Margin/Label

func _process(_delta: float) -> void:
	if label == null:
		return

	var hb: String = "-"
	if Stats.hovered_block != Vector3.ZERO:
		hb = "%0.2f, %0.2f, %0.2f" % [Stats.hovered_block.x, Stats.hovered_block.y, Stats.hovered_block.z]

	label.text = (
		"CN CurseCraft — Voxel Core (M4)\n"
		+ "Mode: %s   Connected: %s   Ping: %dms\n" % [Stats.mode, str(Stats.connected), Stats.ping_ms]
		+ "FPS: %d\n\n" % [Stats.fps]
		+ "Chunks Loaded: %d\n" % [Stats.chunks_loaded]
		+ "Subchunks Loaded: %d\n" % [Stats.subchunks_loaded]
		+ "Chunk Gen Queue: %d\n" % [Stats.chunk_gen_jobs_in_queue]
		+ "Mesh Jobs In Flight: %d\n\n" % [Stats.mesh_jobs_in_flight]
		+ "Player Pos: %0.3f, %0.3f, %0.3f\n" % [Stats.player_pos.x, Stats.player_pos.y, Stats.player_pos.z]
		+ "Camera Pos: %0.3f, %0.3f, %0.3f\n" % [Stats.camera_pos.x, Stats.camera_pos.y, Stats.camera_pos.z]
		+ "Hover Block Center: %s\n" % hb
		+ "\nControls: WASD move, Mouse look, Space jump, Shift sprint"
	)
