extends Node

@export var mouse_sensitivity: float = 0.003
@export var move_speed: float = 12.0
@export var fast_multiplier: float = 3.0
@export var up_down_speed: float = 10.0

var _yaw: float = 0.0
var _pitch: float = 0.0

var _player: Node3D = null
var _camera: Camera3D = null

func _ready() -> void:
	_player = get_parent() as Node3D
	if _player == null:
		push_error("DebugFlyController must be a child of a Node3D (Player).")
		return

	_camera = _player.get_node_or_null("Camera3D") as Camera3D
	if _camera == null:
		push_error("DebugFlyController: Expected Player/Camera3D.")
		return

	_ensure_input_actions()

	# Initialize yaw/pitch from current transforms
	_yaw = _player.rotation.y
	_pitch = _camera.rotation.x

func _ensure_input_actions() -> void:
	_add_key_action("move_forward", KEY_W)
	_add_key_action("move_back", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("move_up", KEY_E)
	_add_key_action("move_down", KEY_Q)
	_add_key_action("move_fast", KEY_SHIFT)

func _add_key_action(action: String, keycode: int) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)

func _unhandled_input(event: InputEvent) -> void:
	if _player == null or _camera == null:
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * mouse_sensitivity
		_pitch -= mm.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))

		_player.rotation.y = _yaw
		_camera.rotation.x = _pitch

func _process(delta: float) -> void:
	if _player == null or _camera == null:
		return

	var fast: float = fast_multiplier if Input.is_action_pressed("move_fast") else 1.0

	var dir := Vector3.ZERO
	if Input.is_action_pressed("move_forward"):
		dir.z -= 1.0
	if Input.is_action_pressed("move_back"):
		dir.z += 1.0
	if Input.is_action_pressed("move_left"):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right"):
		dir.x += 1.0

	if dir.length_squared() > 0.0:
		dir = dir.normalized()
		var forward := -_player.global_transform.basis.z
		var right := _player.global_transform.basis.x

		# FIX: W/S were inverted because dir.z is negative for forward.
		# Use -dir.z so forward movement goes forward.
		var move := (forward * (-dir.z) + right * dir.x) * move_speed * fast * delta
		_player.global_position += move

	if Input.is_action_pressed("move_up"):
		_player.global_position.y += up_down_speed * fast * delta
	if Input.is_action_pressed("move_down"):
		_player.global_position.y -= up_down_speed * fast * delta
