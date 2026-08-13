extends Node
class_name PlacementController

signal selected_building_changed(index: int, scene: PackedScene)
signal placement_succeeded(piece: Node2D, cell: Vector2i)
signal placement_failed(cell: Vector2i)
signal rotation_changed(rotation_steps: int)
signal history_changed(can_undo: bool, can_redo: bool)
signal layout_changed

@export var grid_manager_path: NodePath
@export var placement_preview_path: NodePath
@export var build_parent_path: NodePath
@export var available_building_scenes: Array[PackedScene] = []
@export var available_building_data: Array[BuildingData] = []
@export var delete_with_right_click: bool = true
@export var max_placed_buildings: int = 0
@export var input_enabled: bool = true

var selected_building_index: int = -1
var rotation_steps: int = 0

var _grid_manager: GridManager
var _placement_preview: PlacementPreview
var _build_parent: Node
var _last_hovered_cell: Vector2i = Vector2i(-9999, -9999)
var _undo_stack: Array[BuildCommand] = []
var _redo_stack: Array[BuildCommand] = []


func _ready() -> void:
	_grid_manager = get_node_or_null(grid_manager_path) as GridManager
	_placement_preview = get_node_or_null(placement_preview_path) as PlacementPreview
	_build_parent = get_node_or_null(build_parent_path)

	if _grid_manager != null and _placement_preview != null:
		_placement_preview.cell_size = _grid_manager.cell_size

	if available_building_data.is_empty():
		_migrate_scene_exports_to_building_data()

	if not available_building_data.is_empty():
		select_building_index(0)


func _process(_delta: float) -> void:
	if not input_enabled:
		if _placement_preview != null:
			_placement_preview.hide_preview()
		return

	_update_preview(get_viewport().get_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key_input(event)
		return

	if event is InputEventMouseButton and event.pressed:
		_handle_mouse_button(event)
		return

	if event is InputEventScreenTouch and event.pressed:
		_try_place_at_screen_position(event.position)


func select_building_index(index: int) -> void:
	if index < 0 or index >= available_building_data.size():
		return

	if selected_building_index != index:
		rotation_steps = 0
		rotation_changed.emit(rotation_steps)

	selected_building_index = index
	selected_building_changed.emit(index, available_building_data[index].scene)
	_update_preview(get_viewport().get_mouse_position())


func select_building_scene(scene: PackedScene) -> void:
	var scene_index := -1
	for i in range(available_building_data.size()):
		if available_building_data[i] != null and available_building_data[i].scene == scene:
			scene_index = i
			break

	if scene_index == -1:
		return

	select_building_index(scene_index)


func set_available_buildings(building_data_list: Array[BuildingData]) -> void:
	available_building_data = building_data_list.duplicate()
	available_building_scenes.clear()

	for building_data in available_building_data:
		if building_data != null:
			available_building_scenes.append(building_data.scene)

	selected_building_index = -1
	clear_history()

	if not available_building_data.is_empty():
		select_building_index(0)


func rotate_clockwise() -> void:
	rotation_steps = (rotation_steps + 1) % 4
	rotation_changed.emit(rotation_steps)
	_update_preview(get_viewport().get_mouse_position())


func place_selected_at(cell: Vector2i) -> bool:
	if not input_enabled or _grid_manager == null or selected_building_index == -1:
		return false

	if not _grid_manager.can_place_piece(cell):
		placement_failed.emit(cell)
		return false

	if max_placed_buildings > 0 and _get_placed_building_count() >= max_placed_buildings:
		placement_failed.emit(cell)
		return false

	var building_data := available_building_data[selected_building_index]
	if building_data == null or building_data.scene == null:
		placement_failed.emit(cell)
		return false

	var command := BuildCommand.new()
	command.command_type = BuildCommand.CommandType.PLACE
	command.grid_manager = _grid_manager
	command.build_parent = _get_build_parent()
	command.building_data = building_data
	command.cell = cell
	command.rotation_steps = rotation_steps

	var placed := _execute_command(command)
	if placed:
		placement_succeeded.emit(command.piece, cell)
		return true

	placement_failed.emit(cell)
	return false


func remove_piece_at(cell: Vector2i) -> Node2D:
	if not input_enabled or _grid_manager == null or not _grid_manager.is_in_bounds(cell):
		return null

	var occupant := _grid_manager.get_occupant(cell)
	if occupant == null:
		return null

	var building := occupant as Building
	if building != null and building.locked:
		placement_failed.emit(cell)
		return null

	var command := BuildCommand.new()
	command.command_type = BuildCommand.CommandType.REMOVE
	command.grid_manager = _grid_manager
	command.build_parent = _get_build_parent()
	command.cell = cell

	if _execute_command(command):
		return command.piece

	return null


func undo() -> bool:
	if _undo_stack.is_empty():
		return false

	var command := _undo_stack.pop_back() as BuildCommand
	if not command.undo():
		history_changed.emit(can_undo(), can_redo())
		return false

	_redo_stack.append(command)
	history_changed.emit(can_undo(), can_redo())
	layout_changed.emit()
	return true


func redo() -> bool:
	if _redo_stack.is_empty():
		return false

	var command := _redo_stack.pop_back() as BuildCommand
	if not command.execute():
		history_changed.emit(can_undo(), can_redo())
		return false

	_undo_stack.append(command)
	history_changed.emit(can_undo(), can_redo())
	layout_changed.emit()
	return true


func clear_history() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	history_changed.emit(false, false)


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func can_redo() -> bool:
	return not _redo_stack.is_empty()


func _handle_key_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_1:
			select_building_index(0)
		KEY_2:
			select_building_index(1)
		KEY_3:
			select_building_index(2)
		KEY_4:
			select_building_index(3)
		KEY_5:
			select_building_index(4)
		KEY_R:
			rotate_clockwise()
		KEY_Z:
			if event.ctrl_pressed:
				undo()
		KEY_Y:
			if event.ctrl_pressed:
				redo()
		KEY_DELETE, KEY_BACKSPACE:
			if _grid_manager != null:
				remove_piece_at(_last_hovered_cell)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_at_screen_position(event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT and delete_with_right_click:
		_try_remove_at_screen_position(event.position)


func _try_place_at_screen_position(screen_position: Vector2) -> void:
	if _grid_manager == null:
		return

	place_selected_at(_grid_manager.world_to_grid(_screen_to_world(screen_position)))


func _try_remove_at_screen_position(screen_position: Vector2) -> void:
	if _grid_manager == null:
		return

	remove_piece_at(_grid_manager.world_to_grid(_screen_to_world(screen_position)))


func _update_preview(screen_position: Vector2) -> void:
	if _grid_manager == null or _placement_preview == null or selected_building_index == -1:
		if _placement_preview != null:
			_placement_preview.hide_preview()
		return

	var cell := _grid_manager.world_to_grid(_screen_to_world(screen_position))
	_last_hovered_cell = cell

	if not _grid_manager.is_in_bounds(cell):
		_placement_preview.hide_preview()
		return

	_placement_preview.show_at(
		_grid_manager.grid_to_world(cell),
		_grid_manager.can_place_piece(cell),
		rotation_steps * 90.0
	)


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _get_build_parent() -> Node:
	return _build_parent if _build_parent != null else _grid_manager


func _get_facing_from_rotation() -> Vector2i:
	match rotation_steps:
		0:
			return Vector2i.RIGHT
		1:
			return Vector2i.DOWN
		2:
			return Vector2i.LEFT
		_:
			return Vector2i.UP


func _execute_command(command: BuildCommand) -> bool:
	if not command.execute():
		return false

	_undo_stack.append(command)
	_redo_stack.clear()
	history_changed.emit(can_undo(), can_redo())
	layout_changed.emit()
	return true


func _migrate_scene_exports_to_building_data() -> void:
	for scene in available_building_scenes:
		if scene == null:
			continue

		var building_data := BuildingData.new()
		building_data.scene = scene
		building_data.display_name = scene.resource_path.get_file().get_basename()
		available_building_data.append(building_data)


func _get_placed_building_count() -> int:
	var count := 0
	var build_parent := _get_build_parent()
	if build_parent == null:
		return count

	for child in build_parent.get_children():
		var building := child as Building
		if building != null and not building.locked:
			count += 1

	return count
