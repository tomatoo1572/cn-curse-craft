extends Node

var _file: FileAccess = null
var _enabled: bool = true

func _ready() -> void:
	_enabled = Config.log_to_file
	if not _enabled:
		return

	DirAccess.make_dir_recursive_absolute(Config.log_folder)
	var path: String = Config.log_folder.path_join(Config.log_filename)

	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		_enabled = false
		push_warning("Failed to open log file: %s" % path)
		return

	info("Log started: %s" % path)

func _exit_tree() -> void:
	if _file != null:
		info("Log closed.")
		_file.flush()
		_file.close()
		_file = null

func _stamp() -> String:
	var t := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d %02d:%02d:%02d" % [t.year, t.month, t.day, t.hour, t.minute, t.second]

func _write(level: String, msg: String) -> void:
	var line: String = "[%s] [%s] %s" % [_stamp(), level, msg]
	print(line)
	if _enabled and _file != null:
		_file.store_line(line)
		_file.flush()

func info(msg: String) -> void:
	_write("INFO", msg)

func warn(msg: String) -> void:
	_write("WARN", msg)

func error(msg: String) -> void:
	_write("ERROR", msg)
