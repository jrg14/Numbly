extends Resource
class_name LevelData

@export var id: StringName
@export var display_name: String = ""
@export_multiline var objective_text: String = ""
@export var grid_size: Vector2i = Vector2i(16, 16)
@export var initial_buildings: Array[LevelBuildingData] = []
@export var allowed_buildings: Array[BuildingData] = []
@export var objectives: Array[ObjectiveData] = []
@export var max_buildings: int = 0
@export var max_ticks: int = 0
@export var medal_conditions: Array[LevelMedalData] = []
@export var star_conditions: Array[StarConditionData] = []


func get_primary_target_value() -> int:
	for objective in objectives:
		if objective != null and objective.objective_type == ObjectiveData.ObjectiveType.TARGET_VALUE:
			return objective.target_value

	return 0
