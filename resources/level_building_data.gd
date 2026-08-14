extends Resource
class_name LevelBuildingData

@export var building_data: BuildingData
@export var cell: Vector2i = Vector2i.ZERO
@export_range(0, 3, 1) var rotation_steps: int = 0
@export var locked: bool = false
@export var generated_value: int = 0
@export var packets_per_second: float = 1.0
@export var generation_interval_ticks: int = 10
@export var target_value: int = 0
@export var required_count: int = 0
@export var max_buffer_size: int = 8
@export var operation_interval_ticks: int = 10


func get_facing() -> Vector2i:
	match rotation_steps % 4:
		0:
			return Vector2i.RIGHT
		1:
			return Vector2i.DOWN
		2:
			return Vector2i.LEFT
		_:
			return Vector2i.UP
