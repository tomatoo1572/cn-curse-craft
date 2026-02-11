extends CanvasLayer

@onready var label: Label = $Panel/Margin/Label

func _ready() -> void:
	visible = Config.show_debug_overlay

func _process(_delta: float) -> void:
	if not visible:
		return

	var lines: Array[String] = []
	lines.append("CN CurseCraft — Voxel Core (M0)")
	lines.append("Mode: %s   Connected: %s   Ping: %dms" % [Stats.mode, str(Stats.connected), Stats.ping_ms])
	lines.append("FPS: %d" % Stats.fps)
	lines.append("")
	lines.append("Chunks Loaded: %d (placeholder)" % Stats.chunks_loaded)
	lines.append("Subchunks Loaded: %d (placeholder)" % Stats.subchunks_loaded)
	lines.append("Chunk Gen Queue: %d (placeholder)" % Stats.chunk_gen_jobs_in_queue)
	lines.append("Mesh Jobs In Flight: %d (placeholder)" % Stats.mesh_jobs_in_flight)

	label.text = "\n".join(lines)
