extends Control

@onready var levels_list: VBoxContainer = $Margin/Layout/Scroll/LevelsList
@onready var back_button: Button = $Margin/Layout/Header/BackButton
@onready var status_label: Label = $Margin/Layout/StatusLabel


func _ready() -> void:
	back_button.pressed.connect(Callable(SceneRouter, "go_to_main_menu"))
	_populate_levels()


func _populate_levels() -> void:
	var level_paths := GameState.get_level_paths()

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
		button.custom_minimum_size = Vector2(0, 60)
		button.add_theme_font_size_override("font_size", 19)
		button.text = "%s  %s - %s" % [
			LevelMedalData.get_medal_badge(medal),
			level_data.id,
			level_data.display_name,
		]
		button.tooltip_text = "%s\n%s" % [level_data.objective_text, SaveManager.get_level_summary(level_data.id)]
		button.pressed.connect(_on_level_pressed.bind(level_path))
		levels_list.add_child(button)


func _on_level_pressed(level_path: String) -> void:
	GameState.select_level(level_path)
	SceneRouter.go_to_game()
