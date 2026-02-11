extends Node3D

@onready var camera: Camera3D = $Player/Camera3D

var _transport: Node = null
var _server: Node = null

func boot_local_singleplayer(server: Node, transport: Node) -> void:
	_server = server
	_transport = transport

	Log.info("[client] boot local singleplayer")

	var join_variant: Variant = _transport.call("request_join_world")
	if typeof(join_variant) != TYPE_DICTIONARY:
		Log.error("[client] join_world returned non-dictionary")
		return

	var join: Dictionary = join_variant as Dictionary
	if not join.get("ok", false):
		Log.error("[client] failed to join world")
		return

	var spawn_variant: Variant = join.get("spawn_pos", Vector3(0, 2, 0))
	var spawn: Vector3 = Vector3(0, 2, 0)
	if typeof(spawn_variant) == TYPE_VECTOR3:
		spawn = spawn_variant as Vector3

	$Player.global_position = spawn
	Log.info("[client] joined world seed=%s spawn=%s" % [str(join.get("seed", 0)), str(spawn)])

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta: float) -> void:
	Stats.fps = int(Engine.get_frames_per_second())
