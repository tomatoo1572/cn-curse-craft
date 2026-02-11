extends Node

signal tick_happened(server_time_sec: float)

var _tick_rate: int = 20
var _accum: float = 0.0
var _server_time_sec: float = 0.0

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
