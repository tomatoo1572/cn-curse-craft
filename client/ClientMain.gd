extends Node3D

const BlockRegistryScript = preload("res://shared/voxel/BlockRegistry.gd")
const ChunkWorldScript = preload("res://client/voxel/ChunkWorld.gd")
const DebugFlyControllerScript = preload("res://client/DebugFlyController.gd")

@onready var camera: Camera3D = $Player/Camera3D
@onready var player: Node3D = $Player

var _transport: Node = null
var _server: Node = null

var _blocks = null
var _chunk_world: Node3D = null

func _ready() -> void:
	_blocks = BlockRegistryScript.new()
	_ensure_chunk_world()
	_ensure_debug_fly_controller_node()

func _ensure_chunk_world() -> void:
	_chunk_world = get_node_or_null("ChunkWorld") as Node3D
	if _chunk_world == null:
		_chunk_world = Node3D.new()
		_chunk_world.name = "ChunkWorld"
		_chunk_world.set_script(ChunkWorldScript)
		add_child(_chunk_world)

func _ensure_debug_fly_controller_node() -> void:
	# Reliable: create a child node with the controller script.
	# This guarantees _ready/_process run.
	var existing := player.get_node_or_null("DebugFlyController")
	if existing != null:
		return

	var ctrl := Node.new()
	ctrl.name = "DebugFlyController"
	ctrl.set_script(DebugFlyControllerScript)
	player.add_child(ctrl)

func boot_local_singleplayer(server: Node, transport: Node) -> void:
	_server = server
	_transport = transport

	Log.info("[client] boot local singleplayer")

	var join_v: Variant = _transport.call("request_join_world")
	if typeof(join_v) != TYPE_DICTIONARY:
		Log.error("[client] join_world returned non-dictionary")
		return

	var join: Dictionary = join_v as Dictionary
	if not join.get("ok", false):
		Log.error("[client] failed to join world")
		return

	var spawn_v: Variant = join.get("spawn_pos", Vector3(0, 6, 0))
	var spawn: Vector3 = Vector3(0, 6, 0)
	if typeof(spawn_v) == TYPE_VECTOR3:
		spawn = spawn_v as Vector3

	player.global_position = spawn

	_chunk_world.call("setup", _transport, _blocks, player)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	Stats.mode = "local"
	Stats.connected = true
	Stats.ping_ms = 0

	Log.info("[client] joined; streaming enabled")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _process(_delta: float) -> void:
	Stats.fps = int(Engine.get_frames_per_second())
