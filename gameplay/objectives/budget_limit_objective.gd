extends Objective
class_name BudgetLimitObjective


func update(metrics: LevelMetrics) -> void:
	if data == null or metrics == null:
		return

	if data.max_budget <= 0:
		is_complete = true
		return

	is_failed = metrics.spent_budget > data.max_budget
	is_complete = not is_failed


func get_progress_text(metrics: LevelMetrics = null) -> String:
	if data == null:
		return "Budget"

	var spent_budget := metrics.spent_budget if metrics != null else 0
	return "Budget: %d/%d" % [spent_budget, data.max_budget]
