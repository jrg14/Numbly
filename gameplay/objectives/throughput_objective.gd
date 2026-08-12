extends Objective
class_name ThroughputObjective


func update(metrics: LevelMetrics) -> void:
	if data == null or metrics == null:
		return

	var window := maxf(data.duration_seconds, 1.0)
	var required_outputs := data.required_count
	if data.throughput_per_second > 0.0:
		required_outputs = ceili(data.throughput_per_second * window)

	is_complete = metrics.get_recent_output_count(data.target_value, window) >= required_outputs


func get_progress_text(metrics: LevelMetrics = null) -> String:
	if data == null:
		return "Throughput"

	var window := maxf(data.duration_seconds, 1.0)
	var required_outputs := data.required_count
	if data.throughput_per_second > 0.0:
		required_outputs = ceili(data.throughput_per_second * window)

	var current_count := metrics.get_recent_output_count(data.target_value, window) if metrics != null else 0
	return "Throughput %d over %.1fs: %d/%d" % [data.target_value, window, current_count, required_outputs]
