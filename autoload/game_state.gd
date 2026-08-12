extends Node

const DEFAULT_LEVEL_PATH := "res://data/levels/level_001.tres"

var selected_level_path: String = DEFAULT_LEVEL_PATH


func select_level(level_path: String) -> void:
	selected_level_path = level_path


func get_selected_level() -> LevelData:
	var level := load(selected_level_path) as LevelData
	if level != null:
		return level

	return load(DEFAULT_LEVEL_PATH) as LevelData
