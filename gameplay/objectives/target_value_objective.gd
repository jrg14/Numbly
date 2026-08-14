extends Objective
class_name TargetValueObjective


func update(metrics: LevelMetrics) -> void:
	if data == null or metrics == null:
		return

	is_complete = metrics.get_matched_output_count(data.target_value) >= data.required_count


func get_progress_text(metrics: LevelMetrics = null) -> String:
	if data == null:
		return "Target value"

	var current_count := metrics.get_matched_output_count(data.target_value) if metrics != null else 0
	return "Numero %d conseguido: %d/%d" % [
		data.target_value,
		current_count,
		data.required_count,
	]
