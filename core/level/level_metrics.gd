extends RefCounted
class_name LevelMetrics

var tick_index: int = 0
var elapsed_seconds: float = 0.0
var placed_buildings: int = 0
var spent_budget: int = 0
var matched_output_counts_by_value: Dictionary = {}
var consumed_output_counts_by_value: Dictionary = {}
var output_events: Array[Dictionary] = []


func reset() -> void:
	tick_index = 0
	elapsed_seconds = 0.0
	placed_buildings = 0
	spent_budget = 0
	matched_output_counts_by_value.clear()
	consumed_output_counts_by_value.clear()
	output_events.clear()


func record_tick(new_tick_index: int, tick_delta: float) -> void:
	tick_index = new_tick_index
	elapsed_seconds += tick_delta


func record_output_packet(packet: NumberPacket, matched_target: bool) -> void:
	if packet == null:
		return

	consumed_output_counts_by_value[packet.value] = get_consumed_output_count(packet.value) + 1
	if matched_target:
		matched_output_counts_by_value[packet.value] = get_matched_output_count(packet.value) + 1

	output_events.append({
		"value": packet.value,
		"matched_target": matched_target,
		"time": elapsed_seconds,
		"tick": tick_index,
	})


func refresh_layout(buildings_root: Node) -> void:
	placed_buildings = 0
	spent_budget = 0

	if buildings_root == null:
		return

	for child in buildings_root.get_children():
		var building := child as Building
		if building == null or building.locked:
			continue

		placed_buildings += 1
		if building.building_data != null:
			spent_budget += building.building_data.cost


func get_matched_output_count(value: int) -> int:
	return matched_output_counts_by_value.get(value, 0)


func get_consumed_output_count(value: int) -> int:
	return consumed_output_counts_by_value.get(value, 0)


func get_recent_output_count(value: int, window_seconds: float) -> int:
	var count := 0
	var min_time := elapsed_seconds - maxf(window_seconds, 0.0)

	for event in output_events:
		if event["value"] == value and event["matched_target"] and event["time"] >= min_time:
			count += 1

	return count
