extends Node
class_name PlacementController

signal selected_building_changed(index: int, scene: PackedScene)
signal placement_succeeded(piece: Node2D, cell: Vector2i)
signal placement_failed(cell: Vector2i)
signal rotation_changed(rotation_steps: int)
signal erase_mode_changed(enabled: bool)
signal history_changed(can_undo: bool, can_redo: bool)
signal layout_changed

@export var grid_manager_path: NodePath
@export var placement_preview_path: NodePath
@export var route_overlay_path: NodePath
@export var build_parent_path: NodePath
@export var available_building_scenes: Array[PackedScene] = []
@export var available_building_data: Array[BuildingData] = []
@export var delete_with_right_click: bool = true
@export var max_placed_buildings: int = 0
@export var input_enabled: bool = true
@export var drag_place_conveyors: bool = true

var selected_building_index: int = -1
var rotation_steps: int = 0
var erase_mode: bool = false

var _grid_manager: GridManager
var _placement_preview: PlacementPreview
var _route_overlay: RouteOverlay
var _build_parent: Node
var _last_hovered_cell: Vector2i = Vector2i(-9999, -9999)
var _is_drag_placing: bool = false
var _is_drag_removing: bool = false
var _last_drag_cell: Vector2i = Vector2i(-9999, -9999)
var _drag_placed_cells: Dictionary = {}
var _undo_stack: Array[BuildCommand] = []
var _redo_stack: Array[BuildCommand] = []


func _ready() -> void:
	_grid_manager = get_node_or_null(grid_manager_path) as GridManager
	_placement_preview = get_node_or_null(placement_preview_path) as PlacementPreview
	_route_overlay = get_node_or_null(route_overlay_path) as RouteOverlay
	_build_parent = get_node_or_null(build_parent_path)

	if _grid_manager != null and _placement_preview != null:
		_placement_preview.cell_size = _grid_manager.cell_size

	if available_building_data.is_empty():
		_migrate_scene_exports_to_building_data()

	if not available_building_data.is_empty():
		select_building_index(0)


func _process(_delta: float) -> void:
	if not input_enabled:
		_stop_drag_placing()
		_stop_drag_removing()
		if _placement_preview != null:
			_placement_preview.hide_preview()
		if _route_overlay != null:
			_route_overlay.hide_routes()
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

	if event is InputEventMouseButton and not event.pressed:
		_handle_mouse_release(event)
		return

	if event is InputEventMouseMotion:
		_handle_pointer_drag(event.position)
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
		return

	if event is InputEventScreenDrag:
		_handle_pointer_drag(event.position)


func select_building_index(index: int) -> void:
	if index < 0 or index >= available_building_data.size():
		return

	if selected_building_index != index:
		rotation_steps = 0
		rotation_changed.emit(rotation_steps)

	selected_building_index = index
	set_erase_mode(false)
	selected_building_changed.emit(index, available_building_data[index].scene)
	_stop_drag_placing()
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
	_stop_drag_placing()
	_update_preview(get_viewport().get_mouse_position())


func place_selected_at(cell: Vector2i) -> bool:
	return _place_selected_at(cell, rotation_steps)


func _place_selected_at(cell: Vector2i, placement_rotation_steps: int) -> bool:
	if not input_enabled or _grid_manager == null or selected_building_index == -1:
		return false

	if max_placed_buildings > 0 and _get_placed_building_count() >= max_placed_buildings:
		placement_failed.emit(cell)
		return false

	var building_data := available_building_data[selected_building_index]
	if building_data == null or building_data.scene == null:
		placement_failed.emit(cell)
		return false

	if not _grid_manager.can_place_piece(cell, building_data.footprint_size):
		placement_failed.emit(cell)
		return false

	var command := BuildCommand.new()
	command.command_type = BuildCommand.CommandType.PLACE
	command.grid_manager = _grid_manager
	command.build_parent = _get_build_parent()
	command.building_data = building_data
	command.cell = cell
	command.rotation_steps = placement_rotation_steps

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
	command.cell = building.grid_position if building != null else cell

	if _execute_command(command):
		return command.piece

	return null


func set_erase_mode(enabled: bool) -> void:
	if erase_mode == enabled:
		return

	erase_mode = enabled
	_stop_drag_placing()
	_stop_drag_removing()
	erase_mode_changed.emit(erase_mode)

	if _placement_preview != null:
		_placement_preview.hide_preview()
	if _route_overlay != null:
		_route_overlay.hide_routes()

	if not erase_mode:
		_update_preview(get_viewport().get_mouse_position())


func toggle_erase_mode() -> void:
	set_erase_mode(not erase_mode)


func undo() -> bool:
	if _undo_stack.is_empty():
		return false

	var command := _undo_stack.pop_back() as BuildCommand
	if not command.undo():
		history_changed.emit(can_undo(), can_redo())
		return false

	_redo_stack.append(command)
	_update_all_conveyor_routes()
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
	_update_all_conveyor_routes()
	history_changed.emit(can_undo(), can_redo())
	layout_changed.emit()
	return true


func clear_history() -> void:
	_undo_stack.clear()
	_redo_stack.clear()
	history_changed.emit(false, false)


func refresh_conveyor_routes() -> void:
	_update_all_conveyor_routes()


func can_undo() -> bool:
	return not _undo_stack.is_empty()


func can_redo() -> bool:
	return not _redo_stack.is_empty()


func _handle_key_input(event: InputEventKey) -> void:
	if event.keycode >= KEY_1 and event.keycode <= KEY_9:
		select_building_index(event.keycode - KEY_1)
		return

	if event.keycode == KEY_0:
		select_building_index(9)
		return

	match event.keycode:
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
		_begin_or_place_at_screen_position(event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT and delete_with_right_click:
		_try_remove_at_screen_position(event.position)


func _handle_mouse_release(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_stop_drag_placing()
		_stop_drag_removing()


func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		_begin_or_place_at_screen_position(event.position)
	else:
		_stop_drag_placing()
		_stop_drag_removing()


func _handle_pointer_drag(screen_position: Vector2) -> void:
	if _is_drag_removing:
		_try_remove_at_screen_position(screen_position)
		return

	if not _is_drag_placing:
		return

	_drag_place_at_screen_position(screen_position)


func _begin_or_place_at_screen_position(screen_position: Vector2) -> void:
	if erase_mode:
		_start_drag_removing()
		_try_remove_at_screen_position(screen_position)
		return

	if _can_drag_place_selected_building():
		_start_drag_placing()
		_drag_place_at_screen_position(screen_position)
		return

	_try_place_at_screen_position(screen_position)


func _try_place_at_screen_position(screen_position: Vector2) -> void:
	if _grid_manager == null:
		return

	place_selected_at(_grid_manager.world_to_grid(_screen_to_world(screen_position)))


func _drag_place_at_screen_position(screen_position: Vector2) -> void:
	if _grid_manager == null:
		return

	var cell: Vector2i = _grid_manager.world_to_grid(_screen_to_world(screen_position))
	if not _grid_manager.is_in_bounds(cell):
		return

	for path_cell in _get_drag_cells_between(_last_drag_cell, cell):
		var previous_cell: Vector2i = _last_drag_cell
		var direction: Vector2i = _get_primary_direction(_last_drag_cell, path_cell)
		_try_drag_place_at_cell(path_cell, direction)
		_configure_drag_route(previous_cell, path_cell, direction)
		_last_drag_cell = path_cell


func _try_remove_at_screen_position(screen_position: Vector2) -> void:
	if _grid_manager == null:
		return

	remove_piece_at(_grid_manager.world_to_grid(_screen_to_world(screen_position)))


func _update_preview(screen_position: Vector2) -> void:
	if erase_mode or _grid_manager == null or _placement_preview == null or selected_building_index == -1:
		if _placement_preview != null:
			_placement_preview.hide_preview()
		if _route_overlay != null:
			_route_overlay.hide_routes()
		return

	var cell := _grid_manager.world_to_grid(_screen_to_world(screen_position))
	_last_hovered_cell = cell

	if not _grid_manager.is_in_bounds(cell):
		_placement_preview.hide_preview()
		if _route_overlay != null:
			_route_overlay.hide_routes()
		return

	var occupant := _grid_manager.get_occupant(cell) as Building
	if occupant != null:
		_placement_preview.hide_preview()
		if _route_overlay != null:
			_route_overlay.show_focus(
				occupant.grid_position,
				occupant,
				occupant.building_data,
				rotation_steps,
				false,
				true
			)
		return

	var building_data := available_building_data[selected_building_index]
	var footprint_size := building_data.footprint_size if building_data != null else Vector2i(1, 1)
	var can_place := _grid_manager.can_place_piece(cell, footprint_size)

	_placement_preview.show_at(
		_grid_manager.grid_to_world_for_footprint(cell, footprint_size),
		can_place,
		rotation_steps,
		building_data
	)

	if _route_overlay != null:
		_route_overlay.show_focus(cell, null, building_data, rotation_steps, true, can_place)


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _start_drag_placing() -> void:
	_is_drag_placing = true
	_last_drag_cell = Vector2i(-9999, -9999)
	_drag_placed_cells.clear()


func _stop_drag_placing() -> void:
	var was_drag_placing: bool = _is_drag_placing
	_is_drag_placing = false
	_last_drag_cell = Vector2i(-9999, -9999)
	_drag_placed_cells.clear()

	if was_drag_placing:
		_update_all_conveyor_routes()


func _start_drag_removing() -> void:
	_is_drag_removing = true


func _stop_drag_removing() -> void:
	_is_drag_removing = false


func _can_drag_place_selected_building() -> bool:
	if not drag_place_conveyors or selected_building_index < 0 or selected_building_index >= available_building_data.size():
		return false

	var building_data := available_building_data[selected_building_index]
	return building_data != null and building_data.building_type == BuildingData.BuildingType.CONVEYOR


func _try_drag_place_at_cell(cell: Vector2i, direction: Vector2i) -> void:
	if _drag_placed_cells.has(cell):
		return

	_drag_placed_cells[cell] = true

	var building_data := available_building_data[selected_building_index]
	var footprint_size := building_data.footprint_size if building_data != null else Vector2i(1, 1)
	if _grid_manager == null or not _grid_manager.can_place_piece(cell, footprint_size):
		return

	_place_selected_at(cell, _get_rotation_steps_for_direction(direction))


func _configure_drag_route(previous_cell: Vector2i, current_cell: Vector2i, direction: Vector2i) -> void:
	var current_conveyor := _get_conveyor_at(current_cell)
	if current_conveyor != null:
		current_conveyor.configure_route(-direction, direction)
		current_conveyor.set_connection_state(previous_cell.x >= -9000, false)

	var previous_conveyor := _get_conveyor_at(previous_cell)
	if previous_conveyor != null:
		previous_conveyor.configure_route(previous_conveyor.input_direction, direction)
		previous_conveyor.set_connection_state(true, true)
		_update_conveyor_route_at(previous_cell)

	if current_conveyor != null:
		_update_conveyor_route_at(current_cell)


func _get_drag_cells_between(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if from_cell.x < -9000:
		cells.append(to_cell)
		return cells

	var delta: Vector2i = to_cell - from_cell
	if delta == Vector2i.ZERO:
		cells.append(to_cell)
		return cells

	var cursor := from_cell
	if absi(delta.x) >= absi(delta.y):
		_append_axis_drag_cells(cells, cursor, to_cell.x, true)
		cursor = cells.back() if not cells.is_empty() else cursor
		_append_axis_drag_cells(cells, cursor, to_cell.y, false)
	else:
		_append_axis_drag_cells(cells, cursor, to_cell.y, false)
		cursor = cells.back() if not cells.is_empty() else cursor
		_append_axis_drag_cells(cells, cursor, to_cell.x, true)

	return cells


func _append_axis_drag_cells(cells: Array[Vector2i], from_cell: Vector2i, target_axis_value: int, horizontal: bool) -> void:
	var current_value := from_cell.x if horizontal else from_cell.y
	var step := 1 if target_axis_value > current_value else -1

	var cursor := from_cell
	while current_value != target_axis_value:
		current_value += step
		if horizontal:
			cursor.x = current_value
		else:
			cursor.y = current_value

		if cells.is_empty() or cells.back() != cursor:
			cells.append(cursor)


func _get_primary_direction(from_cell: Vector2i, to_cell: Vector2i) -> Vector2i:
	if from_cell.x < -9000:
		return _get_facing_from_rotation()

	var delta: Vector2i = to_cell - from_cell
	if delta == Vector2i.ZERO:
		return _get_facing_from_rotation()

	if absi(delta.x) >= absi(delta.y):
		return Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT

	return Vector2i.DOWN if delta.y > 0 else Vector2i.UP


func _get_rotation_steps_for_direction(direction: Vector2i) -> int:
	if direction == Vector2i.RIGHT:
		return 0
	if direction == Vector2i.DOWN:
		return 1
	if direction == Vector2i.LEFT:
		return 2
	if direction == Vector2i.UP:
		return 3

	return rotation_steps


func _get_conveyor_at(cell: Vector2i) -> ConveyorBuilding:
	if _grid_manager == null or not _grid_manager.is_in_bounds(cell):
		return null

	return _grid_manager.get_occupant(cell) as ConveyorBuilding


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
	var footprint_size := Vector2i(1, 1)
	var building := command.piece as Building
	if building != null:
		footprint_size = building.footprint_size

	_update_conveyor_routes_around(command.cell, footprint_size)
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


func _update_conveyor_routes_around(center_cell: Vector2i, footprint_size: Vector2i = Vector2i(1, 1)) -> void:
	if _grid_manager == null:
		return

	for y in range(-1, footprint_size.y + 1):
		for x in range(-1, footprint_size.x + 1):
			_update_conveyor_route_at(center_cell + Vector2i(x, y))


func _update_all_conveyor_routes() -> void:
	if _grid_manager == null:
		return

	for _pass_index in range(4):
		for y in range(_grid_manager.grid_size.y):
			for x in range(_grid_manager.grid_size.x):
				_update_conveyor_route_at(Vector2i(x, y))


func _update_conveyor_route_at(cell: Vector2i) -> void:
	var conveyor := _get_conveyor_at(cell)
	if conveyor == null:
		return

	var input_options: Array[Vector2i] = []
	var output_options: Array[Vector2i] = []

	for direction in [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]:
		var neighbor := _get_building_at(cell + direction)
		if neighbor == null:
			continue

		if _neighbor_can_feed_conveyor(neighbor, cell, cell + direction):
			input_options.append(direction)

		if _conveyor_can_feed_neighbor(conveyor, neighbor, cell + direction):
			output_options.append(direction)

	var output_direction := _choose_output_direction(conveyor, output_options, input_options)
	var input_direction := _choose_input_direction(conveyor, input_options, output_direction)
	conveyor.configure_route(input_direction, output_direction)
	conveyor.set_connection_state(input_options.has(input_direction), output_options.has(output_direction))


func _choose_output_direction(conveyor: ConveyorBuilding, output_options: Array[Vector2i], input_options: Array[Vector2i]) -> Vector2i:
	var current_output_neighbor := _get_building_at(conveyor.grid_position + conveyor.facing)
	var has_operation_output := _has_operation_output_option(conveyor, output_options)
	if output_options.has(conveyor.facing) \
			and (not has_operation_output or not (current_output_neighbor is ConveyorBuilding)):
		return conveyor.facing

	for direction in output_options:
		if direction != conveyor.input_direction and _is_operation_building(_get_building_at(conveyor.grid_position + direction)):
			return direction

	for direction in output_options:
		if direction != conveyor.input_direction:
			return direction

	for direction in output_options:
		if _is_operation_building(_get_building_at(conveyor.grid_position + direction)):
			return direction

	if output_options.size() > 0:
		return output_options[0]

	var fallback: Vector2i = conveyor.facing
	if input_options.size() > 0:
		fallback = -input_options[0]

	return fallback


func _has_operation_output_option(conveyor: ConveyorBuilding, output_options: Array[Vector2i]) -> bool:
	for direction in output_options:
		if _is_operation_building(_get_building_at(conveyor.grid_position + direction)):
			return true

	return false


func _is_operation_building(building: Building) -> bool:
	return building is ArithmeticOperatorBuilding


func _choose_input_direction(conveyor: ConveyorBuilding, input_options: Array[Vector2i], output_direction: Vector2i) -> Vector2i:
	if input_options.has(conveyor.input_direction) and conveyor.input_direction != output_direction:
		return conveyor.input_direction

	for direction in input_options:
		if direction != output_direction:
			return direction

	return -output_direction


func _neighbor_can_feed_conveyor(neighbor: Building, conveyor_cell: Vector2i, neighbor_cell: Vector2i) -> bool:
	if neighbor is SourceBuilding:
		return true

	if neighbor is OutputBuilding:
		return false

	if neighbor is ConveyorBuilding:
		var direction_to_neighbor := neighbor_cell - conveyor_cell
		return neighbor.facing == -direction_to_neighbor

	return neighbor.get_output_target_cells(NumberPacket.new()).has(conveyor_cell)


func _conveyor_can_feed_neighbor(conveyor: ConveyorBuilding, neighbor: Building, neighbor_cell: Vector2i) -> bool:
	if neighbor is SourceBuilding:
		return false

	if neighbor is OutputBuilding:
		return true

	if neighbor is ArithmeticOperatorBuilding:
		return neighbor.can_accept_packet_from_cell(NumberPacket.new(), conveyor, neighbor_cell)

	if neighbor is ConveyorBuilding:
		var direction_to_neighbor := neighbor_cell - conveyor.grid_position
		return (neighbor as ConveyorBuilding).facing != -direction_to_neighbor

	if neighbor is SplitterBuilding or neighbor is FilterBuilding:
		return neighbor.can_accept_packet_from_cell(NumberPacket.new(), conveyor, neighbor_cell)

	if neighbor is BufferBuilding or neighbor is GateBuilding:
		return neighbor.can_accept_packet_from_cell(NumberPacket.new(), conveyor, neighbor_cell)

	return neighbor.can_accept_packet_from_cell(NumberPacket.new(), conveyor, neighbor_cell)


func _get_route_output_directions(building: Building) -> Array[Vector2i]:
	if building is SplitterBuilding or building is FilterBuilding:
		var directions: Array[Vector2i] = []
		directions.append(building.facing)
		directions.append(Vector2i(-building.facing.y, building.facing.x))
		return directions

	if building is GateBuilding:
		var directions: Array[Vector2i] = []
		directions.append(building.facing)
		return directions

	return building.get_output_directions(NumberPacket.new())


func _get_building_at(cell: Vector2i) -> Building:
	if _grid_manager == null or not _grid_manager.is_in_bounds(cell):
		return null

	return _grid_manager.get_occupant(cell) as Building
