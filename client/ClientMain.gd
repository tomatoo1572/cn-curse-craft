extends Node3D

const BlockRegistryScript = preload("res://shared/voxel/BlockRegistry.gd")
const ChunkWorldScript = preload("res://client/voxel/ChunkWorld.gd")

@onready var player: Node = $Player

var _transport: Node = null
var _server: Node = null

var _blocks = null
var _chunk_world: Node3D = null

func _ready() -> void:
	_blocks = BlockRegistryScript.new()
	_ensure_chunk_world()

func _ensure_chunk_world() -> void:
	_chunk_world = get_node_or_null("ChunkWorld") as Node3D
	if _chunk_world == null:
		_chunk_world = Node3D.new()
		_chunk_world.name = "ChunkWorld"
		_chunk_world.set_script(ChunkWorldScript)
		add_child(_chunk_world)

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

	var spawn_v: Variant = join.get("spawn_pos", Vector3(8, 10, 8))
	var spawn: Vector3 = Vector3(8, 10, 8)
	if typeof(spawn_v) == TYPE_VECTOR3:
		spawn = spawn_v as Vector3

	(player as Node3D).global_position = spawn

	# Setup world streaming
	_chunk_world.call("setup", _transport, _blocks, player)

	# IMPORTANT: player controller script must be attached in the editor.
	# We only call setup(world) here.
	player.call("setup", _chunk_world)

	Stats.mode = "local"
	Stats.connected = true
	Stats.ping_ms = 0

	Log.info("[client] joined; M4 controller active")

func _process(_delta: float) -> void:
	Stats.fps = int(Engine.get_frames_per_second())
