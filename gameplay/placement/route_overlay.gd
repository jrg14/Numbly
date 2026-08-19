extends Node2D
class_name RouteOverlay

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.DOWN,
	Vector2i.LEFT,
	Vector2i.UP,
]

@export var grid_manager_path: NodePath
@export var active_cell_color: Color = Color(1.0, 0.88, 0.28, 0.42)
@export var invalid_cell_color: Color = Color(1.0, 0.26, 0.22, 0.55)
@export var output_color: Color = Color(0.26, 0.95, 0.48, 0.95)
@export var input_color: Color = Color(0.22, 0.68, 1.0, 0.95)
@export var potential_color: Color = Color(0.82, 0.88, 0.94, 0.35)
@export var blocked_color: Color = Color(1.0, 0.26, 0.22, 0.88)

var _grid_manager: GridManager
var _cell: Vector2i = Vector2i.ZERO
var _building: Building
var _building_data: BuildingData
var _rotation_steps: int = 0
var _is_preview: bool = false
var _is_valid: bool = false
var _has_focus: bool = false


func _ready() -> void:
	_grid_manager = get_node_or_null(grid_manager_path) as GridManager
	visible = false


func show_focus(cell: Vector2i, building: Building, building_data: BuildingData, rotation_steps: int, is_preview: bool, is_valid: bool) -> void:
	_cell = cell
	_building = building
	_building_data = building_data
	_rotation_steps = rotation_steps
	_is_preview = is_preview
	_is_valid = is_valid
	_has_focus = building != null or building_data != null
	visible = _has_focus
	queue_redraw()


func hide_routes() -> void:
	_has_focus = false
	_building = null
	_building_data = null
	visible = false
	queue_redraw()


func _draw() -> void:
	if not _has_focus or _grid_manager == null:
		return

	_draw_active_cell()
	_draw_input_routes()
	_draw_output_routes()


func _draw_active_cell() -> void:
	var footprint_size := _get_footprint_size()
	var footprint_pixel_size := _grid_manager.cell_size * Vector2(footprint_size)
	var center := to_local(_grid_manager.grid_to_world_for_footprint(_cell, footprint_size))
	var rect := Rect2(center - footprint_pixel_size * 0.5, footprint_pixel_size)
	var color := invalid_cell_color if _is_preview and not _is_valid else active_cell_color
	draw_rect(rect, color, false, 3.0)


func _draw_input_routes() -> void:
	if _is_arithmetic_focus():
		_draw_arithmetic_input_routes()
		return

	for direction in _get_input_directions():
		if not _grid_manager.is_in_bounds(_cell + direction):
			continue

		var state := _get_input_state(direction)
		var color := _get_route_color(state, input_color)
		var center := to_local(_grid_manager.grid_to_world(_cell))
		var edge := center + Vector2(direction) * _grid_manager.cell_size * 0.35
		_draw_arrow(edge, center, color, 3.0)
		_draw_connection_dot(edge, color)


func _draw_arithmetic_input_routes() -> void:
	var feeder_direction := -_get_facing_for_focus()
	for input_cell in _get_arithmetic_input_cells():
		var feeder_cell := input_cell + feeder_direction
		if not _grid_manager.is_in_bounds(input_cell):
			continue

		var state := _get_input_state_for_cell(input_cell, feeder_cell)
		var color := _get_route_color(state, input_color)
		var input_center := to_local(_grid_manager.grid_to_world(input_cell))

		if _grid_manager.is_in_bounds(feeder_cell):
			var feeder_center := to_local(_grid_manager.grid_to_world(feeder_cell))
			_draw_arrow(feeder_center, input_center, color, 3.0)

		_draw_connection_dot(input_center, color)


func _draw_output_routes() -> void:
	var center := to_local(_grid_manager.grid_to_world_for_footprint(_cell, _get_footprint_size()))
	for target_cell in _get_output_target_cells():
		if not _grid_manager.is_in_bounds(target_cell):
			continue

		var state := _get_output_state_for_cell(target_cell)
		var color := _get_route_color(state, output_color)
		var target_center := to_local(_grid_manager.grid_to_world(target_cell))
		_draw_arrow(center, target_center, color, 4.0)
		_draw_connection_dot(target_center, color)


func _draw_arrow(start: Vector2, end: Vector2, color: Color, width: float) -> void:
	var delta := end - start
	if delta.length_squared() <= 0.01:
		return

	var direction := delta.normalized()
	var side := Vector2(-direction.y, direction.x)
	var tip := end
	var arrow_points := PackedVector2Array([
		tip,
		tip - direction * 10.0 + side * 6.0,
		tip - direction * 10.0 - side * 6.0,
	])

	draw_line(start, end - direction * 7.0, color, width, true)
	draw_colored_polygon(arrow_points, color)


func _draw_connection_dot(position: Vector2, color: Color) -> void:
	draw_circle(position, 5.0, color)


func _get_route_color(state: StringName, base_color: Color) -> Color:
	match state:
		&"connected":
			return base_color
		&"blocked":
			return blocked_color
		_:
			return potential_color


func _get_output_directions() -> Array[Vector2i]:
	if _building != null:
		if _building is SourceBuilding:
			return _all_directions()
		if _building is OutputBuilding:
			return _empty_directions()
		if _building is SplitterBuilding or _building is FilterBuilding:
			var dynamic_directions: Array[Vector2i] = []
			dynamic_directions.append(_building.facing)
			dynamic_directions.append(_rotate_clockwise(_building.facing))
			return dynamic_directions
		if _building is GateBuilding:
			return _single_direction(_building.facing)
		return _building.get_output_directions(NumberPacket.new())

	if _building_data == null:
		return _empty_directions()

	match _building_data.building_type:
		BuildingData.BuildingType.SOURCE:
			return _all_directions()
		BuildingData.BuildingType.OUTPUT:
			return _empty_directions()
		BuildingData.BuildingType.SPLITTER, BuildingData.BuildingType.FILTER:
			var directions: Array[Vector2i] = []
			directions.append(_get_facing_from_rotation(_rotation_steps))
			directions.append(_rotate_clockwise(_get_facing_from_rotation(_rotation_steps)))
			return directions
		_:
			return _single_direction(_get_facing_from_rotation(_rotation_steps))

	return _empty_directions()


func _get_output_target_cells() -> Array[Vector2i]:
	if _building != null:
		return _building.get_output_target_cells(NumberPacket.new())

	if _building_data == null:
		return _empty_cells()

	var facing := _get_facing_from_rotation(_rotation_steps)
	var footprint_size := _get_footprint_size()

	match _building_data.building_type:
		BuildingData.BuildingType.SOURCE:
			return _get_perimeter_target_cells(_cell, footprint_size)
		BuildingData.BuildingType.OUTPUT:
			return _empty_cells()
		BuildingData.BuildingType.SPLITTER, BuildingData.BuildingType.FILTER:
			var target_cells: Array[Vector2i] = []
			target_cells.append(_cell + facing)
			target_cells.append(_cell + _rotate_clockwise(facing))
			return target_cells
		_:
			return _get_edge_target_cells(_cell, footprint_size, facing)

	return _empty_cells()


func _get_input_directions() -> Array[Vector2i]:
	if _building != null:
		if _building is SourceBuilding:
			return _empty_directions()
		if _building is ConveyorBuilding:
			return _single_direction((_building as ConveyorBuilding).input_direction)
		if _building is ArithmeticOperatorBuilding:
			return _get_operator_input_directions(_building.facing)
		if _building is OutputBuilding:
			return _all_directions()
		if _building is SplitterBuilding or _building is FilterBuilding:
			var routed_input_directions: Array[Vector2i] = []
			routed_input_directions.append(-_building.facing)
			routed_input_directions.append(-_rotate_clockwise(_building.facing))
			return routed_input_directions
		if _building is BufferBuilding or _building is GateBuilding:
			return _get_operator_input_directions(_building.facing)
		return _get_operator_input_directions(_building.facing)

	if _building_data == null:
		return _empty_directions()

	var facing := _get_facing_from_rotation(_rotation_steps)
	match _building_data.building_type:
		BuildingData.BuildingType.SOURCE:
			return _empty_directions()
		BuildingData.BuildingType.CONVEYOR:
			return _single_direction(-facing)
		BuildingData.BuildingType.OUTPUT:
			return _all_directions()
		BuildingData.BuildingType.SPLITTER, BuildingData.BuildingType.FILTER:
			var routed_input_directions: Array[Vector2i] = []
			routed_input_directions.append(-facing)
			routed_input_directions.append(-_rotate_clockwise(facing))
			return routed_input_directions
		BuildingData.BuildingType.BUFFER, BuildingData.BuildingType.MERGER, BuildingData.BuildingType.GATE:
			return _get_operator_input_directions(facing)
		_:
			return _get_operator_input_directions(facing)

	return _empty_directions()


func _single_direction(direction: Vector2i) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	directions.append(direction)
	return directions


func _empty_directions() -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	return directions


func _empty_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	return cells


func _all_directions() -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	for direction in DIRECTIONS:
		directions.append(direction)
	return directions


func _get_operator_input_directions(facing: Vector2i) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	for direction in DIRECTIONS:
		if direction != facing:
			directions.append(direction)
	return directions


func _get_output_state(direction: Vector2i) -> StringName:
	var target := _get_building_at(_cell + direction)
	if target == null:
		return &"potential"

	if _can_focused_building_feed(target, direction):
		return &"connected"

	return &"blocked"


func _get_output_state_for_cell(target_cell: Vector2i) -> StringName:
	var target := _get_building_at(target_cell)
	if target == null:
		return &"potential"

	if _building != null:
		if _building is SourceBuilding and not (target is SourceBuilding):
			return &"connected"

		var packet := NumberPacket.new()
		if target.can_accept_packet_from_cell(packet, _building, target_cell):
			return &"connected"

		return &"blocked"

	if target is SourceBuilding:
		return &"blocked"

	if target.can_accept_packet(NumberPacket.new()):
		return &"connected"

	return &"blocked"


func _get_input_state(direction: Vector2i) -> StringName:
	var neighbor := _get_building_at(_cell + direction)
	if neighbor == null:
		return &"potential"

	if _can_neighbor_feed_focus(neighbor, direction):
		return &"connected"

	return &"blocked"


func _get_input_state_for_cell(input_cell: Vector2i, feeder_cell: Vector2i) -> StringName:
	var neighbor := _get_building_at(feeder_cell)
	if neighbor == null:
		return &"potential"

	if neighbor is OutputBuilding:
		return &"blocked"

	if neighbor.get_output_target_cells(NumberPacket.new()).has(input_cell):
		return &"connected"

	return &"blocked"


func _can_focused_building_feed(target: Building, direction_to_target: Vector2i) -> bool:
	if target is SourceBuilding:
		return false

	if target is OutputBuilding or target is ArithmeticOperatorBuilding:
		return true

	if target is ConveyorBuilding:
		return (target as ConveyorBuilding).facing != -direction_to_target

	if target is SplitterBuilding or target is FilterBuilding:
		return not _get_route_output_directions(target).has(-direction_to_target)

	if target is BufferBuilding or target is GateBuilding:
		return -direction_to_target != target.facing

	return target.can_accept_packet(NumberPacket.new())


func _can_neighbor_feed_focus(neighbor: Building, direction_to_neighbor: Vector2i) -> bool:
	if neighbor is SourceBuilding:
		return true

	if neighbor is OutputBuilding:
		return false

	return _get_route_output_directions(neighbor).has(-direction_to_neighbor)


func _get_building_at(cell: Vector2i) -> Building:
	if _grid_manager == null or not _grid_manager.is_in_bounds(cell):
		return null

	return _grid_manager.get_occupant(cell) as Building


func _get_facing_from_rotation(rotation_steps: int) -> Vector2i:
	match rotation_steps % 4:
		0:
			return Vector2i.RIGHT
		1:
			return Vector2i.DOWN
		2:
			return Vector2i.LEFT
		_:
			return Vector2i.UP


func _rotate_clockwise(direction: Vector2i) -> Vector2i:
	return Vector2i(-direction.y, direction.x)


func _get_route_output_directions(building: Building) -> Array[Vector2i]:
	if building is SplitterBuilding or building is FilterBuilding:
		var directions: Array[Vector2i] = []
		directions.append(building.facing)
		directions.append(_rotate_clockwise(building.facing))
		return directions

	if building is GateBuilding:
		return _single_direction(building.facing)

	return building.get_output_directions(NumberPacket.new())


func _get_footprint_size() -> Vector2i:
	if _building != null:
		return _building.footprint_size

	if _building_data != null:
		return _building_data.footprint_size

	return Vector2i(1, 1)


func _get_facing_for_focus() -> Vector2i:
	if _building != null:
		return _building.facing

	return _get_facing_from_rotation(_rotation_steps)


func _is_arithmetic_focus() -> bool:
	if _building != null:
		return _building is ArithmeticOperatorBuilding

	if _building_data == null:
		return false

	return _building_data.building_type == BuildingData.BuildingType.ADDITION \
		or _building_data.building_type == BuildingData.BuildingType.MULTIPLICATION \
		or _building_data.building_type == BuildingData.BuildingType.SUBTRACTION \
		or _building_data.building_type == BuildingData.BuildingType.DIVISION \
		or _building_data.building_type == BuildingData.BuildingType.MODULO


func _get_arithmetic_input_cells() -> Array[Vector2i]:
	if _building is ArithmeticOperatorBuilding:
		return (_building as ArithmeticOperatorBuilding).get_input_cells()

	var cells: Array[Vector2i] = []
	var footprint_size := _get_footprint_size()
	var facing := _get_facing_for_focus()

	if facing == Vector2i.RIGHT:
		cells.append(_cell)
		cells.append(_cell + Vector2i(0, 1))
	elif facing == Vector2i.LEFT:
		cells.append(_cell + Vector2i(footprint_size.x - 1, 0))
		cells.append(_cell + Vector2i(footprint_size.x - 1, 1))
	elif facing == Vector2i.DOWN:
		cells.append(_cell)
		cells.append(_cell + Vector2i(1, 0))
	elif facing == Vector2i.UP:
		cells.append(_cell + Vector2i(0, footprint_size.y - 1))
		cells.append(_cell + Vector2i(1, footprint_size.y - 1))

	return cells


func _get_edge_target_cells(cell: Vector2i, footprint_size: Vector2i, direction: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	if direction == Vector2i.RIGHT:
		for y in range(footprint_size.y):
			cells.append(cell + Vector2i(footprint_size.x, y))
	elif direction == Vector2i.LEFT:
		for y in range(footprint_size.y):
			cells.append(cell + Vector2i(-1, y))
	elif direction == Vector2i.DOWN:
		for x in range(footprint_size.x):
			cells.append(cell + Vector2i(x, footprint_size.y))
	elif direction == Vector2i.UP:
		for x in range(footprint_size.x):
			cells.append(cell + Vector2i(x, -1))

	return cells


func _get_perimeter_target_cells(cell: Vector2i, footprint_size: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for target_cell in _get_edge_target_cells(cell, footprint_size, Vector2i.UP):
		cells.append(target_cell)
	for target_cell in _get_edge_target_cells(cell, footprint_size, Vector2i.RIGHT):
		cells.append(target_cell)
	for target_cell in _get_edge_target_cells(cell, footprint_size, Vector2i.DOWN):
		cells.append(target_cell)
	for target_cell in _get_edge_target_cells(cell, footprint_size, Vector2i.LEFT):
		cells.append(target_cell)

	return cells
