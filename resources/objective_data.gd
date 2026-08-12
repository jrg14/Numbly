extends Resource
class_name ObjectiveData

enum ObjectiveType {
	TARGET_VALUE,
	THROUGHPUT,
	MACHINE_LIMIT,
	TIME_LIMIT,
	BUDGET_LIMIT,
}

@export var objective_type: ObjectiveType = ObjectiveType.TARGET_VALUE
@export var is_constraint: bool = false
@export var target_value: int = 0
@export var required_count: int = 1
@export var duration_seconds: float = 0.0
@export var throughput_per_second: float = 0.0
@export var max_buildings: int = 0
@export var max_ticks: int = 0
@export var max_budget: int = 0
