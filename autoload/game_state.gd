extends Node

const DEFAULT_LEVEL_PATH := "res://data/levels/level_001.tres"
const LEVELS_DIR := "res://data/levels"

var selected_level_path: String = DEFAULT_LEVEL_PATH


func select_level(level_path: String) -> void:
	selected_level_path = level_path


func get_selected_level() -> LevelData:
	var level := load(selected_level_path) as LevelData
	if level != null:
		return level

	return load(DEFAULT_LEVEL_PATH) as LevelData


func has_next_level() -> bool:
	return _get_next_level_path() != ""


func select_next_level() -> bool:
	var next_level_path: String = _get_next_level_path()
	if next_level_path.is_empty():
		return false

	select_level(next_level_path)
	return true


func _get_next_level_path() -> String:
	var level_paths: Array[String] = _get_level_paths()
	var current_index: int = level_paths.find(selected_level_path)
	if current_index == -1 or current_index >= level_paths.size() - 1:
		return ""

	return level_paths[current_index + 1]


func _get_level_paths() -> Array[String]:
	var level_paths: Array[String] = []
	var directory: DirAccess = DirAccess.open(LEVELS_DIR)
	if directory == null:
		return level_paths

	directory.list_dir_begin()
	var file_name: String = directory.get_next()

	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			level_paths.append("%s/%s" % [LEVELS_DIR, file_name])

		file_name = directory.get_next()

	directory.list_dir_end()
	level_paths.sort()
	return level_paths
