extends Node

# ------------------------------------------------------------
# Streaming / perf
# ------------------------------------------------------------
var view_distance_chunks: int = 8
var target_tick_rate: int = 20

# ------------------------------------------------------------
# World identity (save/load)
# Keep BOTH names for compatibility with older scripts.
# ------------------------------------------------------------
var world_name: String = "dev_world"
var world_id: String = "dev_world"
var world_seed: int = 12345

# Autosave interval (seconds)
var autosave_interval_sec: float = 10.0

# ------------------------------------------------------------
# Logging (compat)
# Some versions use log_folder, others use log_dir, and Log.gd
# currently expects log_filename too.
# ------------------------------------------------------------
var log_to_file: bool = true
var log_folder: String = "user://logs"
var log_dir: String = "user://logs"
var log_filename: String = "latest.log"

# ------------------------------------------------------------
# Rendering: voxel atlas
# ------------------------------------------------------------
var atlas_texture_path: String = "res://client/assets/textures/voxel_atlas.png"
var atlas_tiles_x: int = 8
var atlas_tiles_y: int = 8
var atlas_padding_px: float = 2.0
