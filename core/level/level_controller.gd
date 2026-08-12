extends Node
class_name LevelController

signal level_loaded(level_data: LevelData)
signal level_load_failed(message: String)

var current_level: LevelData


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
