extends Control

const LEVELS_DIR := "res://data/levels"

@onready var levels_list: VBoxContainer = $Margin/Layout/Scroll/LevelsList
@onready var back_button: Button = $Margin/Layout/Header/BackButton
@onready var status_label: Label = $Margin/Layout/StatusLabel


func _ready() -> void:
	back_button.pressed.connect(Callable(SceneRouter, "go_to_main_menu"))
	_populate_levels()


func _populate_levels() -> void:
	var level_paths := _get_level_paths()

	if level_paths.is_empty():
		status_label.text = "No hay niveles disponibles."
		return

	status_label.text = "%d niveles disponibles" % level_paths.size()

	for level_path in level_paths:
		var level_data := load(level_path) as LevelData
		if level_data == null:
			continue

		var button := Button.new()
		var medal := SaveManager.get_level_medal(level_data.id)
		button.custom_minimum_size = Vector2(0, 48)
		button.text = "%s  %s - %s" % [
			LevelMedalData.get_medal_badge(medal),
			level_data.id,
			level_data.display_name,
		]
		button.tooltip_text = "%s\n%s" % [level_data.objective_text, SaveManager.get_level_summary(level_data.id)]
		button.pressed.connect(_on_level_pressed.bind(level_path))
		levels_list.add_child(button)


func _get_level_paths() -> Array[String]:
	var level_paths: Array[String] = []
	var directory := DirAccess.open(LEVELS_DIR)
	if directory == null:
		return level_paths

	directory.list_dir_begin()
	var file_name := directory.get_next()

	while not file_name.is_empty():
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			level_paths.append("%s/%s" % [LEVELS_DIR, file_name])

		file_name = directory.get_next()

	directory.list_dir_end()
	level_paths.sort()
	return level_paths


func _on_level_pressed(level_path: String) -> void:
	GameState.select_level(level_path)
	SceneRouter.go_to_game()
