extends Node
class_name LevelController

signal level_loaded(level_data: LevelData)
signal level_load_failed(message: String)
signal level_completed(result: LevelResult)
signal level_failed(message: String)
signal objectives_changed(summary: String)

var current_level: LevelData
var metrics := LevelMetrics.new()
var objectives: Array[Objective] = []


func load_level(level_data: LevelData, grid_manager: GridManager, buildings_root: Node) -> bool:
	if level_data == null:
		level_load_failed.emit("LevelData is null.")
		return false

	if grid_manager == null:
		level_load_failed.emit("GridManager is missing.")
		return false

	if buildings_root == null:
		level_load_failed.emit("Buildings root is missing.")
		return false

	current_level = level_data
	metrics.reset()
	objectives = _create_objectives(level_data.objectives)
	grid_manager.clear_all_pieces(true)
	grid_manager.grid_size = level_data.grid_size

	for initial_building in level_data.initial_buildings:
		if initial_building == null:
			level_load_failed.emit("Level contains an empty initial building entry.")
			return false

		if not _place_level_building(initial_building, grid_manager, buildings_root):
			level_load_failed.emit("Could not place initial building at %s." % initial_building.cell)
			return false

	level_loaded.emit(level_data)
	objectives_changed.emit(get_objectives_summary())
	return true


func get_available_buildings() -> Array[BuildingData]:
	if current_level == null:
		var empty_buildings: Array[BuildingData] = []
		return empty_buildings

	return current_level.allowed_buildings


func get_player_building_count(buildings_root: Node) -> int:
	if buildings_root == null:
		return 0

	var count := 0
	for child in buildings_root.get_children():
		var building := child as Building
		if building != null and not building.locked:
			count += 1

	return count


func refresh_layout_metrics(buildings_root: Node) -> void:
	if current_level == null:
		return

	metrics.refresh_layout(buildings_root)
	_update_objectives()


func record_tick(tick_index: int, tick_delta: float, buildings_root: Node) -> void:
	if current_level == null:
		return

	metrics.record_tick(tick_index, tick_delta)
	metrics.refresh_layout(buildings_root)
	_update_objectives()


func record_output_packet(packet: NumberPacket, matched_target: bool, buildings_root: Node) -> void:
	if current_level == null:
		return

	metrics.record_output_packet(packet, matched_target)
	metrics.refresh_layout(buildings_root)
	_update_objectives()


func get_objectives_summary() -> String:
	if objectives.is_empty():
		return "No objectives."

	var lines: Array[String] = []
	for objective in objectives:
		if objective == null:
			continue

		lines.append(objective.get_progress_text(metrics))

	return " | ".join(lines)


func calculate_stars() -> int:
	if current_level == null:
		return 0

	var earned_stars := 0

	for star_condition in current_level.star_conditions:
		if star_condition == null:
			continue

		match star_condition.condition_type:
			StarConditionData.ConditionType.COMPLETE_LEVEL:
				if _all_primary_objectives_complete():
					earned_stars = maxi(earned_stars, star_condition.stars)
			StarConditionData.ConditionType.MAX_BUILDINGS:
				if metrics.placed_buildings <= star_condition.limit:
					earned_stars = maxi(earned_stars, star_condition.stars)
			StarConditionData.ConditionType.MAX_TICKS:
				if metrics.tick_index <= star_condition.limit:
					earned_stars = maxi(earned_stars, star_condition.stars)
			StarConditionData.ConditionType.MAX_BUDGET:
				if metrics.spent_budget <= star_condition.limit:
					earned_stars = maxi(earned_stars, star_condition.stars)

	return earned_stars


func _place_level_building(level_building_data: LevelBuildingData, grid_manager: GridManager, buildings_root: Node) -> bool:
	if level_building_data == null or level_building_data.building_data == null:
		return false

	var scene := level_building_data.building_data.scene
	if scene == null:
		return false

	if not grid_manager.can_place_piece(level_building_data.cell):
		return false

	var piece := scene.instantiate() as Node2D
	if piece == null:
		return false

	_configure_level_piece(piece, level_building_data)
	return grid_manager.place_piece(piece, level_building_data.cell, buildings_root)


func _configure_level_piece(piece: Node2D, level_building_data: LevelBuildingData) -> void:
	var building := piece as Building
	if building == null:
		return

	building.building_data = level_building_data.building_data
	building.locked = level_building_data.locked
	building.set_rotation_steps(level_building_data.rotation_steps)

	if building.has_method("configure_from_level_data"):
		building.configure_from_level_data(level_building_data)


func _create_objectives(objective_data_list: Array[ObjectiveData]) -> Array[Objective]:
	var created_objectives: Array[Objective] = []

	for objective_data in objective_data_list:
		var objective := Objective.create_from_data(objective_data)
		if objective != null:
			created_objectives.append(objective)

	return created_objectives


func _update_objectives() -> void:
	for objective in objectives:
		if objective != null:
			objective.update(metrics)

	objectives_changed.emit(get_objectives_summary())

	var failed_constraint := _get_failed_constraint()
	if failed_constraint != null:
		level_failed.emit(failed_constraint.get_progress_text(metrics))
		return

	if _all_primary_objectives_complete():
		var result := LevelResult.new()
		result.completed = true
		result.stars = calculate_stars()
		result.tick_count = metrics.tick_index
		result.elapsed_seconds = metrics.elapsed_seconds
		result.placed_buildings = metrics.placed_buildings
		result.spent_budget = metrics.spent_budget
		level_completed.emit(result)


func _all_primary_objectives_complete() -> bool:
	var has_primary_objective := false

	for objective in objectives:
		if objective == null or objective.is_constraint():
			continue

		has_primary_objective = true
		if not objective.is_complete:
			return false

	return has_primary_objective


func _get_failed_constraint() -> Objective:
	for objective in objectives:
		if objective != null and objective.is_constraint() and objective.is_failed:
			return objective

	return null
