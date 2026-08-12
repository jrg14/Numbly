extends Objective
class_name MachineLimitObjective


func update(metrics: LevelMetrics) -> void:
	if data == null or metrics == null:
		return

	var limit := data.max_buildings
	if limit <= 0:
		is_complete = true
		return

	is_failed = metrics.placed_buildings > limit
	is_complete = not is_failed


func get_progress_text(metrics: LevelMetrics = null) -> String:
	if data == null:
		return "Machine limit"

	var current_count := metrics.placed_buildings if metrics != null else 0
	return "Machines: %d/%d" % [current_count, data.max_buildings]
