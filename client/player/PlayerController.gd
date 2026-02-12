extends CharacterBody3D
class_name PlayerController

signal request_break(cell: Vector3i)
signal request_place(place_cell: Vector3i)

@export var mouse_sensitivity: float = 0.003
@export var walk_speed: float = 6.5
@export var sprint_multiplier: float = 1.6
@export var gravity: float = 24.0
@export var jump_velocity: float = 8.5

@export var half_width: float = 0.30
@export var height: float = 1.80
@export var step_height: float = 0.55

@export var reach: float = 6.0
@export var eye_height: float = 1.62

@onready var cam: Camera3D = $Camera3D

var _yaw: float = 0.0
var _pitch: float = 0.0

var _world: Node = null
var _on_ground: bool = false
var _wish_jump: bool = false

var _highlight: MeshInstance3D = null

func setup(world: Node) -> void:
	_world = world

func _ready() -> void:
	if cam == null:
		push_error("PlayerController: missing Camera3D child")
		return

	cam.position = Vector3(0.0, eye_height, 0.0)

	_yaw = rotation.y
	_pitch = cam.rotation.x

	_ensure_input_actions()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	_create_highlight()

func _ensure_input_actions() -> void:
	_add_key_action("move_forward", Key.KEY_W)
	_add_key_action("move_back", Key.KEY_S)
	_add_key_action("move_left", Key.KEY_A)
	_add_key_action("move_right", Key.KEY_D)
	_add_key_action("move_sprint", Key.KEY_SHIFT)
	_add_key_action("move_jump", Key.KEY_SPACE)
	_add_key_action("ui_cancel", Key.KEY_ESCAPE)

func _add_key_action(action: String, keycode: Key) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev: InputEventKey = InputEventKey.new()
	ev.keycode = keycode
	InputMap.action_add_event(action, ev)

# Escape/menu behavior can live in _input
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var e := event as InputEventKey
		if e.keycode == Key.KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Gameplay input MUST be in _unhandled_input so UI can't swallow it
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton

		# First left click captures mouse
		if mb.button_index == MOUSE_BUTTON_LEFT and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			return

		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				if Stats.has_hover:
					Log.info("[CLIENT] break request %s" % [str(Stats.hovered_cell)])
					request_break.emit(Stats.hovered_cell)
				else:
					Log.info("[CLIENT] break click but no hover")

			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				if Stats.has_hover:
					Log.info("[CLIENT] place request %s" % [str(Stats.hovered_place_cell)])
					request_place.emit(Stats.hovered_place_cell)
				else:
					Log.info("[CLIENT] place click but no hover")

	elif event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mm := event as InputEventMouseMotion
		_yaw -= mm.relative.x * mouse_sensitivity
		_pitch -= mm.relative.y * mouse_sensitivity
		_pitch = clamp(_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))

		rotation.y = _yaw
		cam.rotation.x = _pitch

func _process(_delta: float) -> void:
	_update_highlight()

func _physics_process(delta: float) -> void:
	if _world == null:
		return

	Stats.player_pos = global_position
	Stats.camera_pos = cam.global_position

	var input_x: float = 0.0
	var input_z: float = 0.0
	if Input.is_action_pressed("move_forward"):
		input_z += 1.0
	if Input.is_action_pressed("move_back"):
		input_z -= 1.0
	if Input.is_action_pressed("move_left"):
		input_x -= 1.0
	if Input.is_action_pressed("move_right"):
		input_x += 1.0

	var wish := Vector3(input_x, 0.0, input_z)
	var has_input: bool = wish.length_squared() > 0.0001
	if has_input:
		wish = wish.normalized()

	var speed: float = walk_speed
	if Input.is_action_pressed("move_sprint"):
		speed *= sprint_multiplier

	var yaw_basis: Basis = Basis(Vector3.UP, _yaw)
	var forward: Vector3 = -yaw_basis.z
	var right: Vector3 = yaw_basis.x

	if has_input:
		var desired: Vector3 = (right * wish.x + forward * wish.z) * speed
		velocity.x = desired.x
		velocity.z = desired.z
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y -= gravity * delta

	if Input.is_action_just_pressed("move_jump"):
		_wish_jump = true

	_move_with_voxel_collision(delta)

	if _wish_jump and _on_ground:
		velocity.y = jump_velocity
		_on_ground = false
	_wish_jump = false

# ---------------- Collision ----------------

func _move_with_voxel_collision(delta: float) -> void:
	var pos: Vector3 = global_position
	var attempted: Vector3 = velocity * delta

	_on_ground = false

	pos = _move_axis(pos, Vector3(attempted.x, 0.0, 0.0), 0)
	pos = _move_axis(pos, Vector3(0.0, 0.0, attempted.z), 2)

	var before_y: float = pos.y
	pos = _move_axis(pos, Vector3(0.0, attempted.y, 0.0), 1)

	if attempted.y < 0.0 and pos.y > before_y + attempted.y + 0.0001:
		_on_ground = true
		velocity.y = 0.0

	global_position = pos

func _move_axis(pos: Vector3, delta_move: Vector3, axis: int) -> Vector3:
	if delta_move == Vector3.ZERO:
		return pos

	var new_pos: Vector3 = pos + delta_move
	if not _aabb_hits_solid(new_pos):
		return new_pos

	if axis != 1 and abs(delta_move.y) < 0.00001 and (abs(delta_move.x) > 0.00001 or abs(delta_move.z) > 0.00001):
		var stepped: Vector3 = pos
		stepped.y += step_height
		if not _aabb_hits_solid(stepped):
			var stepped_move: Vector3 = stepped + delta_move
			if not _aabb_hits_solid(stepped_move):
				return stepped_move

	var lo: float = 0.0
	var hi: float = 1.0
	for _i in range(10):
		var mid: float = (lo + hi) * 0.5
		var test_pos: Vector3 = pos.lerp(new_pos, mid)
		if _aabb_hits_solid(test_pos):
			hi = mid
		else:
			lo = mid

	var resolved: Vector3 = pos.lerp(new_pos, lo)

	if axis == 0:
		velocity.x = 0.0
	elif axis == 1:
		velocity.y = 0.0
	else:
		velocity.z = 0.0

	return resolved

func _aabb_hits_solid(center_pos: Vector3) -> bool:
	var min_x: float = center_pos.x - half_width
	var max_x: float = center_pos.x + half_width
	var min_y: float = center_pos.y
	var max_y: float = center_pos.y + height
	var min_z: float = center_pos.z - half_width
	var max_z: float = center_pos.z + half_width

	var x0: int = int(floor(min_x))
	var x1: int = int(floor(max_x))
	var y0: int = int(floor(min_y))
	var y1: int = int(floor(max_y))
	var z0: int = int(floor(min_z))
	var z1: int = int(floor(max_z))

	for y in range(y0, y1 + 1):
		for z in range(z0, z1 + 1):
			for x in range(x0, x1 + 1):
				var id: int = int(_world.call("get_block_id_world", x, y, z))
				if id != 0:
					return true
	return false

# ---------------- Highlight + Minecraft DDA raycast ----------------

func _create_highlight() -> void:
	_highlight = MeshInstance3D.new()
	_highlight.name = "BlockHighlight"
	_highlight.top_level = true

	var bm := BoxMesh.new()
	bm.size = Vector3(1.02, 1.02, 1.02)
	_highlight.mesh = bm

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.12)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_highlight.set_surface_override_material(0, mat)

	add_child(_highlight)
	_highlight.visible = false

func _update_highlight() -> void:
	if _world == null or cam == null or _highlight == null:
		return

	var origin: Vector3 = cam.global_position
	var dir: Vector3 = (-cam.global_transform.basis.z).normalized()

	var hit := _minecraft_voxel_raycast(origin, dir, reach)

	if hit.is_empty():
		_highlight.visible = false
		Stats.has_hover = false
		Stats.hovered_cell = Vector3i.ZERO
		Stats.hovered_face_normal = Vector3i.ZERO
		Stats.hovered_place_cell = Vector3i.ZERO
		return

	var cell: Vector3i = hit["cell"]
	var normal: Vector3i = hit["normal"]
	var place: Vector3i = cell + normal

	var center: Vector3 = Vector3(float(cell.x) + 0.5, float(cell.y) + 0.5, float(cell.z) + 0.5)
	_highlight.visible = true
	_highlight.global_transform = Transform3D(Basis(), center)

	Stats.has_hover = true
	Stats.hovered_cell = cell
	Stats.hovered_face_normal = normal
	Stats.hovered_place_cell = place

func _minecraft_voxel_raycast(origin: Vector3, direction: Vector3, max_dist: float) -> Dictionary:
	var dir: Vector3 = direction.normalized()
	if dir.length_squared() < 0.000001:
		return {}

	var o: Vector3 = origin + dir * 0.0001

	var x: int = int(floor(o.x))
	var y: int = int(floor(o.y))
	var z: int = int(floor(o.z))

	var step_x: int = 1 if dir.x > 0.0 else -1
	var step_y: int = 1 if dir.y > 0.0 else -1
	var step_z: int = 1 if dir.z > 0.0 else -1

	var t_max_x: float = _intbound(o.x, dir.x)
	var t_max_y: float = _intbound(o.y, dir.y)
	var t_max_z: float = _intbound(o.z, dir.z)

	var t_delta_x: float = (1.0 / abs(dir.x)) if abs(dir.x) > 0.000001 else 1e30
	var t_delta_y: float = (1.0 / abs(dir.y)) if abs(dir.y) > 0.000001 else 1e30
	var t_delta_z: float = (1.0 / abs(dir.z)) if abs(dir.z) > 0.000001 else 1e30

	var dist: float = 0.0

	while dist <= max_dist:
		var hit_normal := Vector3i(0, 0, 0)

		if t_max_x < t_max_y:
			if t_max_x < t_max_z:
				x += step_x
				dist = t_max_x
				t_max_x += t_delta_x
				hit_normal = Vector3i(-step_x, 0, 0)
			else:
				z += step_z
				dist = t_max_z
				t_max_z += t_delta_z
				hit_normal = Vector3i(0, 0, -step_z)
		else:
			if t_max_y < t_max_z:
				y += step_y
				dist = t_max_y
				t_max_y += t_delta_y
				hit_normal = Vector3i(0, -step_y, 0)
			else:
				z += step_z
				dist = t_max_z
				t_max_z += t_delta_z
				hit_normal = Vector3i(0, 0, -step_z)

		var id: int = int(_world.call("get_block_id_world", x, y, z))
		if id != 0:
			return {"cell": Vector3i(x, y, z), "normal": hit_normal}

	return {}

func _intbound(s: float, ds: float) -> float:
	if ds > 0.0:
		return (ceil(s) - s) / ds
	elif ds < 0.0:
		return (s - floor(s)) / (-ds)
	else:
		return 1e30
