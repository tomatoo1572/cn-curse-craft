extends RefCounted
class_name WorldStorage

const MAGIC: int = 0x434E4343 # "CNCC"
const VERSION: int = 1

var world_id: String = "dev_world"
var base_dir: String = ""
var chunks_dir: String = ""

func setup(p_world_id: String) -> void:
	world_id = p_world_id
	base_dir = "user://worlds/%s" % world_id
	chunks_dir = "%s/chunks" % base_dir
	_ensure_dir(base_dir)
	_ensure_dir(chunks_dir)

func meta_path() -> String:
	return "%s/meta.json" % base_dir

func chunk_path(cx: int, cz: int) -> String:
	return "%s/c.%d.%d.bin" % [chunks_dir, cx, cz]

func write_meta(p_seed: int) -> void:
	var obj: Dictionary = {
		"version": VERSION,
		"seed": p_seed,
	}
	var json_text: String = JSON.stringify(obj, "\t")
	var f: FileAccess = FileAccess.open(meta_path(), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(json_text)
	f.flush()

func read_meta() -> Dictionary:
	var p: String = meta_path()
	if not FileAccess.file_exists(p):
		return {}

	var f: FileAccess = FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}

	var txt: String = f.get_as_text()
	var j := JSON.new()
	if j.parse(txt) != OK:
		return {}

	if typeof(j.data) != TYPE_DICTIONARY:
		return {}

	return j.data as Dictionary

func load_chunk_bytes(cx: int, cz: int, expected_len: int) -> PackedByteArray:
	var p: String = chunk_path(cx, cz)
	if not FileAccess.file_exists(p):
		return PackedByteArray()

	var f: FileAccess = FileAccess.open(p, FileAccess.READ)
	if f == null:
		return PackedByteArray()

	if f.get_length() < 12:
		return PackedByteArray()

	var magic: int = int(f.get_32())
	if magic != MAGIC:
		return PackedByteArray()

	var ver: int = int(f.get_16())
	f.get_16() # reserved
	var length: int = int(f.get_32())

	if ver != VERSION:
		return PackedByteArray()
	if length != expected_len:
		return PackedByteArray()

	var buf: PackedByteArray = f.get_buffer(length)
	if buf.size() != expected_len:
		return PackedByteArray()

	return buf

func save_chunk_bytes(cx: int, cz: int, bytes: PackedByteArray) -> void:
	_ensure_dir(chunks_dir)

	var p: String = chunk_path(cx, cz)
	var f: FileAccess = FileAccess.open(p, FileAccess.WRITE)
	if f == null:
		return

	f.store_32(MAGIC)
	f.store_16(VERSION)
	f.store_16(0) # reserved
	f.store_32(bytes.size())
	f.store_buffer(bytes)
	f.flush()

static func _ensure_dir(path: String) -> void:
	var da: DirAccess = DirAccess.open(path)
	if da != null:
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))
