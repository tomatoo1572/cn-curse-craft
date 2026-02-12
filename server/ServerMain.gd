extends Node

signal tick_happened(server_time_sec: float)

const WorldStateScript = preload("res://server/world/WorldState.gd")

var _tick_rate: int = 20
var _accum: float = 0.0
var _server_time_sec: float = 0.0

var world_state: Node = null

func _ready() -> void:
	# Create world state as a child so transport can find it
	world_state = WorldStateScript.new()
	world_state.name = "WorldState"
	add_child(world_state)

func start(tick_rate: int) -> void:
	_tick_rate = max(1, tick_rate)
	_accum = 0.0
	_server_time_sec = 0.0
	Log.info("[server] start tick_rate=%d" % _tick_rate)

func stop() -> void:
	Log.info("[server] stop")

func _process(delta: float) -> void:
	var step := 1.0 / float(_tick_rate)
	_accum += delta
	while _accum >= step:
		_accum -= step
		_server_time_sec += step
		_tick(step)

func _tick(_dt: float) -> void:
	emit_signal("tick_happened", _server_time_sec)
