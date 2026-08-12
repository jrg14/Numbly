extends RefCounted
class_name BuildCommand

enum CommandType {
	PLACE,
	REMOVE,
}

var command_type: CommandType = CommandType.PLACE
var grid_manager: GridManager
var build_parent: Node
var building_data: BuildingData
var scene: PackedScene
var cell: Vector2i = Vector2i.ZERO
var rotation_steps: int = 0
var piece: Node2D


func execute() -> bool:
	match command_type:
		CommandType.PLACE:
			return _execute_place()
		CommandType.REMOVE:
			return _execute_remove()

	return false


func undo() -> bool:
	match command_type:
		CommandType.PLACE:
			return _undo_place()
		CommandType.REMOVE:
			return _undo_remove()

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


func _apply_piece_setup(target_piece: Node2D) -> void:
	target_piece.rotation_degrees = rotation_steps * 90.0

	var building := target_piece as Building
	if building == null:
		return

	building.building_data = building_data
	building.locked = false
	building.set_rotation_steps(rotation_steps)
