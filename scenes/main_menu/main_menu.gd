extends Control

@onready var play_button: Button = $Center/Panel/Menu/PlayButton


func _ready() -> void:
	play_button.pressed.connect(Callable(SceneRouter, "go_to_level_select"))
