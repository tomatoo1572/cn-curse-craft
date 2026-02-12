extends CanvasLayer
class_name DebugOverlay

@onready var _label: Label = _find_label()

func _find_label() -> Label:
	# Your scene might be Panel/Margin/Label (your screenshot)
	var a: Node = get_node_or_null("Panel/Margin/Label")
	if a != null and a is Label:
		return a as Label

	# Some people use Panel/MarginContainer/Label
	var b: Node = get_node_or_null("Panel/MarginContainer/Label")
	if b != null and b is Label:
		return b as Label

	# Fallback: try to find any Label under this overlay
	for child in get_children():
		if child is Label:
			return child as Label

	return null

func _ready() -> void:
	# Make sure UI never steals clicks
	if self is CanvasLayer:
		for n in get_children():
			if n is Control:
				(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if _label == null:
		return

	var fps: int = Engine.get_frames_per_second()
	if fps <= 0:
		# fallback estimate (rare)
		fps = int(round(1.0 / max(delta, 0.000001)))

	var mode: String = str(Stats.mode) if Stats != null else "?"
	var connected: String = "true"
	var ping: int = 0

	var vd_line: String = ""
	if "view_distance_chunks" in Config:
		vd_line = "\nView Dist (chunks): %d" % int(Config.view_distance_chunks)

	var hover_lines: String = ""
	if "has_hover" in Stats and Stats.has_hover:
		hover_lines = "\n\nHit Block (int): %s\nHit Face Normal: %s\nPlace Block (int): %s" % [
			str(Stats.hovered_cell),
			str(Stats.hovered_face_normal),
			str(Stats.hovered_place_cell),
		]
	else:
		hover_lines = "\n\nHit Block (int): -\nHit Face Normal: -\nPlace Block (int): -"

	var player_pos_line: String = ""
	if "player_pos" in Stats:
		var p = Stats.player_pos
		player_pos_line = "\n\nPlayer Pos: %.3f, %.3f, %.3f" % [p.x, p.y, p.z]

	var cam_pos_line: String = ""
	if "camera_pos" in Stats:
		var c = Stats.camera_pos
		cam_pos_line = "\nCamera Pos: %.3f, %.3f, %.3f" % [c.x, c.y, c.z]

	_label.text = (
		"CN CurseCraft — Voxel Core (M5)\n"
		+ "Mode: %s   Connected: %s   Ping: %dms\n"
		+ "FPS: %d"
		+ vd_line
		+ "\n\nChunks Loaded: %d\nSubchunks Loaded: %d\nChunk Gen Queue: %d\nMesh Jobs In Flight: %d"
		+ player_pos_line
		+ cam_pos_line
		+ hover_lines
		+ "\n\nControls: WASD move, Mouse look, Space jump, Shift sprint"
	) % [
		mode, connected, ping,
		fps,
		int(Stats.chunks_loaded),
		int(Stats.subchunks_loaded),
		int(Stats.chunk_gen_jobs_in_queue),
		int(Stats.mesh_jobs_in_flight),
	]
