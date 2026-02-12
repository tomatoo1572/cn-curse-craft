extends CanvasLayer

@onready var _label: Label = _find_label()

func _find_label() -> Label:
	var a: Node = get_node_or_null("Panel/Margin/Label")
	if a != null and a is Label:
		return a as Label

	var b: Node = get_node_or_null("Panel/MarginContainer/Label")
	if b != null and b is Label:
		return b as Label

	return null

func _ready() -> void:
	# UI must never steal clicks
	for child in get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _label == null:
		return

	# Godot returns float FPS -> cast explicitly to avoid narrowing warning
	var fps_i: int = int(round(Engine.get_frames_per_second()))
	if fps_i <= 0:
		fps_i = int(round(1.0 / max(delta, 0.000001)))

	var vd: int = int(Config.view_distance_chunks)

	var hover_lines: String
	if Stats.has_hover:
		hover_lines = "\n\nHit Block (int): %s\nHit Face Normal: %s\nPlace Block (int): %s" % [
			str(Stats.hovered_cell),
			str(Stats.hovered_face_normal),
			str(Stats.hovered_place_cell),
		]
	else:
		hover_lines = "\n\nHit Block (int): -\nHit Face Normal: -\nPlace Block (int): -"

	var p: Vector3 = Stats.player_pos
	var c: Vector3 = Stats.camera_pos

	_label.text = (
		"CN CurseCraft — Voxel Core (M6)\n"
		+ "Mode: %s   Connected: true   Ping: 0ms\n"
		+ "FPS: %d\n"
		+ "View Dist (chunks): %d\n\n"
		+ "Chunks Loaded: %d\n"
		+ "Subchunks Loaded: %d\n"
		+ "Chunk Gen Queue: %d\n"
		+ "Mesh Jobs In Flight: %d\n\n"
		+ "Dirty Chunks: %d\n"
		+ "Save Queue: %d\n\n"
		+ "Player Pos: %.3f, %.3f, %.3f\n"
		+ "Camera Pos: %.3f, %.3f, %.3f"
		+ "%s\n\n"
		+ "Controls: WASD move, Mouse look, Space jump, Shift sprint"
	) % [
		Stats.mode,
		fps_i,
		vd,
		Stats.chunks_loaded,
		Stats.subchunks_loaded,
		Stats.chunk_gen_jobs_in_queue,
		Stats.mesh_jobs_in_flight,
		Stats.dirty_chunks,
		Stats.save_queue,
		p.x, p.y, p.z,
		c.x, c.y, c.z,
		hover_lines
	]
