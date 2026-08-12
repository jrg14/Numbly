extends RefCounted
class_name Objective

var data: ObjectiveData
var is_complete: bool = false
var is_failed: bool = false


static func create_from_data(objective_data: ObjectiveData) -> Objective:
	if objective_data == null:
		return null

	match objective_data.objective_type:
		ObjectiveData.ObjectiveType.TARGET_VALUE:
			return TargetValueObjective.new(objective_data)
		ObjectiveData.ObjectiveType.THROUGHPUT:
			return ThroughputObjective.new(objective_data)
		ObjectiveData.ObjectiveType.MACHINE_LIMIT:
			return MachineLimitObjective.new(objective_data)
		ObjectiveData.ObjectiveType.TIME_LIMIT:
			return TimeLimitObjective.new(objective_data)
		ObjectiveData.ObjectiveType.BUDGET_LIMIT:
			return BudgetLimitObjective.new(objective_data)

	return Objective.new(objective_data)


func _init(objective_data: ObjectiveData = null) -> void:
	data = objective_data


func reset() -> void:
	is_complete = false
	is_failed = false


func update(_metrics: LevelMetrics) -> void:
	pass


func is_constraint() -> bool:
	return data != null and data.is_constraint


func get_progress_text(_metrics: LevelMetrics = null) -> String:
	return "Objective"
