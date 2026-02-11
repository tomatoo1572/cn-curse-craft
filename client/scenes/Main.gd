extends Node3D

const ServerMainScript = preload("res://server/ServerMain.gd")
const LocalServerTransportScript = preload("res://server/LocalServerTransport.gd")

@onready var server_root: Node = get_node_or_null("ServerRoot")
@onready var client_main: Node = get_node_or_null("ClientRoot/ClientMain")

var _server: Node = null
var _transport: Node = null

func _ready() -> void:
	if server_root == null:
		push_error("Main.tscn is missing 'ServerRoot' under the root node.")
		return
	if client_main == null:
		push_error("Main.tscn is missing 'ClientRoot/ClientMain' (check names/hierarchy).")
		return

	Stats.reset_placeholders()
	Stats.mode = "local"

	_server = ServerMainScript.new()
	server_root.add_child(_server)
	_server.call("start", Config.target_tick_rate)

	_transport = LocalServerTransportScript.new()
	server_root.add_child(_transport)
	_transport.call("bind_to_server", _server)

	client_main.call("boot_local_singleplayer", _server, _transport)

	Log.info("[main] boot complete")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
