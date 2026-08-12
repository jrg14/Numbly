extends Resource
class_name LevelData

@export var id: StringName
@export var display_name: String = ""
@export_multiline var objective_text: String = ""
@export var grid_size: Vector2i = Vector2i(8, 8)
@export var target_value: int = 0
@export var source_values: Array[int] = []
@export var allowed_buildings: Array[BuildingData] = []
