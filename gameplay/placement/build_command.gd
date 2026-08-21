extends RefCounted
class_name BuildCommand

enum CommandType {
	PLACE,
	REMOVE,
	ROTATE,
	MOVE,
}

var command_type: CommandType = CommandType.PLACE
var grid_manager: GridManager
var build_parent: Node
var building_data: BuildingData
var scene: PackedScene
var cell: Vector2i = Vector2i.ZERO
var previous_cell: Vector2i = Vector2i.ZERO
var rotation_steps: int = 0
var previous_rotation_steps: int = 0
var piece: Node2D


func execute() -> bool:
	match command_type:
		CommandType.PLACE:
			return _execute_place()
		CommandType.REMOVE:
			return _execute_remove()
		CommandType.ROTATE:
			return _execute_rotate()
		CommandType.MOVE:
			return _execute_move()

	return false


func undo() -> bool:
	match command_type:
		CommandType.PLACE:
			return _undo_place()
		CommandType.REMOVE:
			return _undo_remove()
		CommandType.ROTATE:
			return _undo_rotate()
		CommandType.MOVE:
			return _undo_move()

	return false


func _execute_place() -> bool:
	if grid_manager == null or building_data == null or building_data.scene == null:
		return false

	if piece == null or not is_instance_valid(piece):
		piece = building_data.scene.instantiate() as Node2D

	if piece == null:
		return false

	_apply_piece_setup(piece)
	return grid_manager.place_piece(piece, cell, build_parent)


func _execute_remove() -> bool:
	if grid_manager == null:
		return false

	var target_piece := grid_manager.get_occupant(cell) as Building
	if target_piece != null and target_piece.locked:
		return false

	if target_piece != null:
		cell = target_piece.grid_position

	piece = grid_manager.remove_piece_at(cell, false)
	return piece != null


func _undo_place() -> bool:
	if grid_manager == null:
		return false

	var removed_piece := grid_manager.remove_piece_at(cell, false)
	return removed_piece != null


func _undo_remove() -> bool:
	if grid_manager == null or piece == null or not is_instance_valid(piece):
		return false

	return grid_manager.place_piece(piece, cell, build_parent)


func _execute_rotate() -> bool:
	var building := piece as Building
	if building == null or building.locked:
		return false

	previous_rotation_steps = _get_piece_rotation_steps(building)
	building.set_rotation_steps(rotation_steps)
	return true


func _undo_rotate() -> bool:
	var building := piece as Building
	if building == null or not is_instance_valid(building):
		return false

	building.set_rotation_steps(previous_rotation_steps)
	return true


func _execute_move() -> bool:
	var building := piece as Building
	if grid_manager == null or building == null or not is_instance_valid(building) or building.locked:
		return false

	var original_cell := previous_cell
	if original_cell == cell:
		return false

	var removed_piece := grid_manager.remove_piece_at(original_cell, false)
	if removed_piece == null:
		return false

	if grid_manager.place_piece(piece, cell, build_parent):
		return true

	grid_manager.place_piece(piece, original_cell, build_parent)
	return false


func _undo_move() -> bool:
	if grid_manager == null or piece == null or not is_instance_valid(piece):
		return false

	var removed_piece := grid_manager.remove_piece_at(cell, false)
	if removed_piece == null:
		return false

	if grid_manager.place_piece(piece, previous_cell, build_parent):
		return true

	grid_manager.place_piece(piece, cell, build_parent)
	return false


func _apply_piece_setup(target_piece: Node2D) -> void:
	target_piece.rotation_degrees = rotation_steps * 90.0

	var building := target_piece as Building
	if building == null:
		return

	building.apply_building_data(building_data)
	building.locked = false
	building.set_rotation_steps(rotation_steps)


func _get_piece_rotation_steps(building: Building) -> int:
	if building is ConveyorBuilding:
		return _get_conveyor_rotation_steps(building.facing)

	return posmod(roundi(building.rotation_degrees / 90.0), 4)


func _get_conveyor_rotation_steps(facing: Vector2i) -> int:
	if facing == Vector2i.RIGHT:
		return 0
	if facing == Vector2i.DOWN:
		return 1
	if facing == Vector2i.LEFT:
		return 2
	if facing == Vector2i.UP:
		return 3

	return 0
