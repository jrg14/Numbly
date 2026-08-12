extends Objective
class_name TimeLimitObjective


func update(metrics: LevelMetrics) -> void:
	if data == null or metrics == null:
		return

	if data.max_ticks > 0:
		is_failed = metrics.tick_index > data.max_ticks
	elif data.duration_seconds > 0.0:
		is_failed = metrics.elapsed_seconds > data.duration_seconds
	else:
		is_failed = false

	is_complete = not is_failed


func get_progress_text(metrics: LevelMetrics = null) -> String:
	if data == null:
		return "Time limit"

	if data.max_ticks > 0:
		var tick_count := metrics.tick_index if metrics != null else 0
		return "Ticks: %d/%d" % [tick_count, data.max_ticks]

	var elapsed_seconds := metrics.elapsed_seconds if metrics != null else 0.0
	return "Time: %.1fs/%.1fs" % [elapsed_seconds, data.duration_seconds]
