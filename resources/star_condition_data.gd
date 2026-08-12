extends Resource
class_name StarConditionData

enum ConditionType {
	COMPLETE_LEVEL,
	MAX_BUILDINGS,
	MAX_TICKS,
}

@export_range(1, 3, 1) var stars: int = 1
@export var condition_type: ConditionType = ConditionType.COMPLETE_LEVEL
@export var limit: int = 0
@export var description: String = ""
