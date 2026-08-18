extends Node

const DEFAULT_LEVEL_PATH := "res://data/levels/level_001.tres"
const LEVEL_PATHS: Array[String] = [
	"res://data/levels/level_001.tres",
	"res://data/levels/level_002.tres",
	"res://data/levels/level_003.tres",
	"res://data/levels/level_004.tres",
	"res://data/levels/level_005.tres",
	"res://data/levels/level_006.tres",
	"res://data/levels/level_007.tres",
	"res://data/levels/level_008.tres",
	"res://data/levels/level_009.tres",
	"res://data/levels/level_010.tres",
	"res://data/levels/level_011.tres",
	"res://data/levels/level_012.tres",
	"res://data/levels/level_013.tres",
	"res://data/levels/level_014.tres",
	"res://data/levels/level_015.tres",
	"res://data/levels/level_016.tres",
	"res://data/levels/level_017.tres",
	"res://data/levels/level_018.tres",
	"res://data/levels/level_019.tres",
	"res://data/levels/level_020.tres",
	"res://data/levels/level_021.tres",
	"res://data/levels/level_022.tres",
	"res://data/levels/level_023.tres",
	"res://data/levels/level_024.tres",
	"res://data/levels/level_025.tres",
]

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


func get_level_paths() -> Array[String]:
	return LEVEL_PATHS.duplicate()


func _get_next_level_path() -> String:
	var level_paths: Array[String] = get_level_paths()
	var current_index: int = level_paths.find(selected_level_path)
	if current_index == -1 or current_index >= level_paths.size() - 1:
		return ""

	return level_paths[current_index + 1]
