extends RefCounted
class_name VoxelSubChunk

const SIZE: int = 16
const VOXELS: int = SIZE * SIZE * SIZE # 4096

# PackedByteArray is compact and fast enough for now (0..255 block IDs)
var blocks: PackedByteArray

func _init() -> void:
	blocks = PackedByteArray()
	blocks.resize(VOXELS)
	# default is 0 (air)

static func _index(x: int, y: int, z: int) -> int:
	# x + z*16 + y*256
	return x + (z * SIZE) + (y * SIZE * SIZE)

func get_block(x: int, y: int, z: int) -> int:
	return int(blocks[_index(x, y, z)])

func set_block(x: int, y: int, z: int, id: int) -> void:
	blocks[_index(x, y, z)] = id

func fill(id: int) -> void:
	for i in range(VOXELS):
		blocks[i] = id
