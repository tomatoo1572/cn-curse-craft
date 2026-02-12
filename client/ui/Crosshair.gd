extends CanvasLayer

@export var thickness: int = 1
@export var size: int = 7

@onready var line_h: ColorRect = $Center/LineH
@onready var line_v: ColorRect = $Center/LineV

func _ready() -> void:
	# Make sure UI never steals input
	($Center as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line_v.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply()

func _process(_delta: float) -> void:
	_apply()

func _apply() -> void:
	var rect := get_viewport().get_visible_rect()
	var cx: float = rect.size.x * 0.5
	var cy: float = rect.size.y * 0.5

	# Horizontal line (simple plus)
	line_h.size = Vector2(float(size), float(thickness))
	line_h.global_position = Vector2(cx - float(size) * 0.5, cy - float(thickness) * 0.5)

	# Vertical line (simple plus)
	line_v.size = Vector2(float(thickness), float(size))
	line_v.global_position = Vector2(cx - float(thickness) * 0.5, cy - float(size) * 0.5)
