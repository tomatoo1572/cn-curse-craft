extends RefCounted

# Render layers:
# 0 = opaque
# 1 = cutout (alpha test)  [later]
# 2 = transparent (alpha blend) [later]
var id: int
var name: String
var solid: bool
var render_layer: int

var tile_top: Vector2i
var tile_bottom: Vector2i
var tile_side: Vector2i

func _init(
	p_id: int,
	p_name: String,
	p_solid: bool,
	p_render_layer: int,
	p_tile_top: Vector2i,
	p_tile_bottom: Vector2i,
	p_tile_side: Vector2i
) -> void:
	id = p_id
	name = p_name
	solid = p_solid
	render_layer = p_render_layer
	tile_top = p_tile_top
	tile_bottom = p_tile_bottom
	tile_side = p_tile_side
