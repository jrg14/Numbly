extends Resource
class_name ObjectiveData

enum ObjectiveType {
	TARGET_VALUE,
	THROUGHPUT,
	MACHINE_LIMIT,
}

@export var objective_type: ObjectiveType = ObjectiveType.TARGET_VALUE
@export var target_value: int = 0
@export var required_count: int = 1
@export var duration_seconds: float = 0.0
