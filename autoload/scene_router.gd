extends Node

const MAIN_MENU_SCENE := "res://scenes/main_menu/main_menu.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/level_select/level_select.tscn"
const GAME_SCENE := "res://scenes/game/game.tscn"


func go_to_main_menu() -> void:
	_change_scene(MAIN_MENU_SCENE)


func go_to_level_select() -> void:
	_change_scene(LEVEL_SELECT_SCENE)


func go_to_game() -> void:
	_change_scene(GAME_SCENE)


func _change_scene(scene_path: String) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("Could not change scene to %s. Error: %s" % [scene_path, error])
