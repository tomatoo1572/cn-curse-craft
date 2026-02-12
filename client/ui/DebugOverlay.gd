extends CanvasLayer

@onready var label: Label = $Panel/Margin/Label

func _ready() -> void:
	visible = Config.show_debug_overlay

func _process(_delta: float) -> void:
	if not visible:
		return

	var lines: Array[String] = []
	lines.append("CN CurseCraft — Voxel Core (M2)")
	lines.append("Mode: %s   Connected: %s   Ping: %dms" % [Stats.mode, str(Stats.connected), Stats.ping_ms])
	lines.append("FPS: %d" % Stats.fps)
	lines.append("View Dist (chunks): %d" % Config.view_distance_chunks)
	lines.append("")
	lines.append("Chunks Loaded: %d" % Stats.chunks_loaded)
	lines.append("Subchunks Loaded: %d" % Stats.subchunks_loaded)
	lines.append("Chunk Gen Queue: %d" % Stats.chunk_gen_jobs_in_queue)
	lines.append("Mesh Jobs In Flight: %d" % Stats.mesh_jobs_in_flight)
	lines.append("")
	lines.append("Controls (debug): WASD move, Mouse look, Q/E down/up, Shift fast")

	label.text = "\n".join(lines)
