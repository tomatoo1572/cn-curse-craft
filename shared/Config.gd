extends Node

# ---------------------------
# Streaming
# ---------------------------
var view_distance_chunks: int = 8

# ---------------------------
# World Save/Load
# ---------------------------
var world_id: String = "dev_world"
var world_seed: int = 12345

# ---------------------------
# Autosave
# ---------------------------
var autosave_interval_sec: float = 10.0

# ---------------------------
# Logging (compat)
# Different versions of Log.gd may reference different names,
# so we provide BOTH.
# ---------------------------
var log_to_file: bool = true

# Preferred name (some Log.gd uses this)
var log_folder: String = "user://logs"

# Alternate name (some code uses this)
var log_dir: String = "user://logs"

var log_filename: String = "latest.log"
