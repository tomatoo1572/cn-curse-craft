extends Node
class_name ClientMain

@export var default_place_block_id: int = 1

@onready var player: PlayerController = $Player
@onready var chunk_world: Node = $ChunkWorld

var _transport: Node = null

func bind_transport(transport: Node) -> void:
	_transport = transport

func _ready() -> void:
	if player != null:
		player.request_break.connect(_on_request_break)
		player.request_place.connect(_on_request_place)

func _on_request_break(cell: Vector3i) -> void:
	if _transport == null:
		Log.info("[CLIENT] break ignored: no transport")
		return
	Log.info("[CLIENT] sending break %s" % [str(cell)])
	_transport.call("client_request_break", cell, player.global_position)

func _on_request_place(place_cell: Vector3i) -> void:
	if _transport == null:
		Log.info("[CLIENT] place ignored: no transport")
		return
	Log.info("[CLIENT] sending place %s id=%d" % [str(place_cell), default_place_block_id])
	_transport.call("client_request_place", place_cell, default_place_block_id, player.global_position)

func receive_block_delta(x: int, y: int, z: int, id: int) -> void:
	Log.info("[CLIENT] delta (%d,%d,%d)=%d" % [x, y, z, id])
	if chunk_world == null:
		return
	chunk_world.call("apply_block_delta_world", x, y, z, id)
