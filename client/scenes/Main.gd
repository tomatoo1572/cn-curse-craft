extends Node

const ServerMainScript = preload("res://server/ServerMain.gd")
const LocalServerTransportScript = preload("res://server/LocalServerTransport.gd")

@onready var server_root: Node = $ServerRoot
@onready var client_main: Node = $ClientRoot/ClientMain
@onready var player: Node3D = $ClientRoot/ClientMain/Player
@onready var chunk_world: Node = $ClientRoot/ClientMain/ChunkWorld

var _server: Node = null
var _transport: Node = null

func _ready() -> void:
	Stats.reset_placeholders()
	Stats.mode = "local"

	_server = ServerMainScript.new()
	server_root.add_child(_server)

	_transport = LocalServerTransportScript.new()
	server_root.add_child(_transport)
	_transport.call("bind_to_server", _server)

	client_main.call("bind_transport", _transport)
	_transport.call("connect_client", client_main)

	# Give player world queries for collision/raycast
	player.call("setup", chunk_world)

	# ✅ Spawn above the flat terrain (terrain top is y=3)
	# Player is a CharacterBody3D with feet at its origin, so set y safely above.
	player.global_position = Vector3(8.0, 6.0, 8.0)

	# Chunk streaming
	chunk_world.call("setup", _transport, null, player)
