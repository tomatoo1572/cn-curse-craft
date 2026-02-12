extends RefCounted
class_name VoxelChunk

const SIZE_X: int = 16
const SIZE_Z: int = 16
const SUB_SIZE_Y: int = 16

var cx: int
var cz: int

# sub_y (int) -> VoxelSubChunk
var _subs: Dictionary = {} # Dictionary[int, VoxelSubChunk]

func _init(chunk_x: int, chunk_z: int) -> void:
	cx = chunk_x
	cz = chunk_z

func get_or_create_sub(sub_y: int) -> VoxelSubChunk:
	if _subs.has(sub_y):
		return _subs[sub_y] as VoxelSubChunk
	var s: VoxelSubChunk = VoxelSubChunk.new()
	_subs[sub_y] = s
	return s

func get_sub(sub_y: int) -> VoxelSubChunk:
	if _subs.has(sub_y):
		return _subs[sub_y] as VoxelSubChunk
	return null

func set_block_local(x: int, y: int, z: int, id: int, sub_y: int = 0) -> void:
	var s: VoxelSubChunk = get_or_create_sub(sub_y)
	s.set_block(x, y, z, id)

func get_block_local(x: int, y: int, z: int, sub_y: int = 0) -> int:
	var s: VoxelSubChunk = get_sub(sub_y)
	if s == null:
		return 0
	return s.get_block(x, y, z)

# --- Serialization (M1: only one subchunk "0") ---

func serialize_subchunk(sub_y: int = 0) -> PackedByteArray:
	var s: VoxelSubChunk = get_sub(sub_y)
	if s == null:
		var empty: PackedByteArray = PackedByteArray()
		empty.resize(VoxelSubChunk.VOXELS)
		return empty
	return s.blocks.duplicate()

static func from_serialized(chunk_x: int, chunk_z: int, bytes: PackedByteArray, sub_y: int = 0) -> VoxelChunk:
	var c: VoxelChunk = VoxelChunk.new(chunk_x, chunk_z)
	var s: VoxelSubChunk = c.get_or_create_sub(sub_y)

	# Expect 4096 bytes; if not, create empty and copy what we can.
	if bytes.size() != VoxelSubChunk.VOXELS:
		var fixed: PackedByteArray = PackedByteArray()
		fixed.resize(VoxelSubChunk.VOXELS)
		var n: int = min(bytes.size(), VoxelSubChunk.VOXELS)
		for i in range(n):
			fixed[i] = bytes[i]
		s.blocks = fixed
	else:
		s.blocks = bytes.duplicate()

	return c
