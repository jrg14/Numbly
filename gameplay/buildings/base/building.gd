extends Node2D
class_name Building

signal packet_output(packet: NumberPacket, from_building: Building)
signal packet_accepted(packet: NumberPacket, by_building: Building)
signal packet_rejected(packet: NumberPacket, by_building: Building)

@export var building_data: BuildingData
@export var grid_position: Vector2i = Vector2i.ZERO
@export var footprint_size: Vector2i = Vector2i(1, 1):
	set(value):
		footprint_size = Vector2i(maxi(value.x, 1), maxi(value.y, 1))
@export var facing: Vector2i = Vector2i.RIGHT
@export var locked: bool = false


func apply_building_data(data: BuildingData) -> void:
	building_data = data
	if building_data != null:
		footprint_size = building_data.footprint_size


func can_accept_packet(_packet: NumberPacket) -> bool:
	return false


func can_accept_packet_from(packet: NumberPacket, _from_building: Building) -> bool:
	return can_accept_packet(packet)


func can_accept_packet_from_cell(packet: NumberPacket, from_building: Building, _target_cell: Vector2i) -> bool:
	return can_accept_packet_from(packet, from_building)


func accept_packet(packet: NumberPacket) -> bool:
	if not can_accept_packet(packet):
		packet_rejected.emit(packet, self)
		return false

	packet_accepted.emit(packet, self)
	_on_packet_accepted(packet)
	return true


func accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if not can_accept_packet_from(packet, from_building):
		packet_rejected.emit(packet, self)
		return false

	packet_accepted.emit(packet, self)
	_on_packet_accepted_from(packet, from_building)
	return true


func accept_packet_from_cell(packet: NumberPacket, from_building: Building, target_cell: Vector2i) -> bool:
	if not can_accept_packet_from_cell(packet, from_building, target_cell):
		packet_rejected.emit(packet, self)
		return false

	packet_accepted.emit(packet, self)
	_on_packet_accepted_from_cell(packet, from_building, target_cell)
	return true


func simulation_tick(_delta: float) -> void:
	pass


func reset_simulation() -> void:
	pass


func set_rotation_steps(rotation_steps: int) -> void:
	var normalized_steps := rotation_steps % 4
	rotation_degrees = normalized_steps * 90.0
	facing = _get_facing_from_rotation_steps(normalized_steps)


func rotate_clockwise() -> void:
	set_rotation_steps(int(rotation_degrees / 90.0) + 1)


func emit_packet(packet: NumberPacket) -> void:
	packet_output.emit(packet, self)


func get_output_directions(_packet: NumberPacket = null) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	directions.append(facing)
	return directions


func get_output_target_groups(packet: NumberPacket = null) -> Array:
	var groups: Array = []
	for direction in get_output_directions(packet):
		var group: Array[Vector2i] = []
		group.append(grid_position + _get_single_cell_output_offset(direction))
		groups.append(group)

	return groups


func get_output_target_cells(packet: NumberPacket = null) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for group in get_output_target_groups(packet):
		for cell in group:
			var target_cell: Vector2i = cell
			if not cells.has(target_cell):
				cells.append(target_cell)

	return cells


func get_occupied_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(footprint_size.y):
		for x in range(footprint_size.x):
			cells.append(grid_position + Vector2i(x, y))

	return cells


func contains_grid_cell(cell: Vector2i) -> bool:
	return cell.x >= grid_position.x \
		and cell.y >= grid_position.y \
		and cell.x < grid_position.x + footprint_size.x \
		and cell.y < grid_position.y + footprint_size.y


func get_nearest_occupied_cell_to(cell: Vector2i) -> Vector2i:
	var nearest_cell := grid_position
	var nearest_distance := INF

	for occupied_cell in get_occupied_cells():
		var distance := Vector2(occupied_cell - cell).length_squared()
		if distance < nearest_distance:
			nearest_cell = occupied_cell
			nearest_distance = distance

	return nearest_cell


func get_edge_target_cells(direction: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	if direction == Vector2i.RIGHT:
		for y in range(footprint_size.y):
			cells.append(grid_position + Vector2i(footprint_size.x, y))
	elif direction == Vector2i.LEFT:
		for y in range(footprint_size.y):
			cells.append(grid_position + Vector2i(-1, y))
	elif direction == Vector2i.DOWN:
		for x in range(footprint_size.x):
			cells.append(grid_position + Vector2i(x, footprint_size.y))
	elif direction == Vector2i.UP:
		for x in range(footprint_size.x):
			cells.append(grid_position + Vector2i(x, -1))

	return cells


func get_perimeter_target_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []

	for cell in get_edge_target_cells(Vector2i.UP):
		cells.append(cell)
	for cell in get_edge_target_cells(Vector2i.RIGHT):
		cells.append(cell)
	for cell in get_edge_target_cells(Vector2i.DOWN):
		cells.append(cell)
	for cell in get_edge_target_cells(Vector2i.LEFT):
		cells.append(cell)

	return cells


func _on_packet_accepted(_packet: NumberPacket) -> void:
	pass


func _on_packet_accepted_from(packet: NumberPacket, _from_building: Building) -> void:
	_on_packet_accepted(packet)


func _on_packet_accepted_from_cell(packet: NumberPacket, from_building: Building, _target_cell: Vector2i) -> void:
	_on_packet_accepted_from(packet, from_building)


func _get_single_cell_output_offset(direction: Vector2i) -> Vector2i:
	if direction == Vector2i.RIGHT:
		return Vector2i(footprint_size.x, 0)
	if direction == Vector2i.LEFT:
		return Vector2i(-1, 0)
	if direction == Vector2i.DOWN:
		return Vector2i(0, footprint_size.y)
	if direction == Vector2i.UP:
		return Vector2i(0, -1)

	return direction


func _get_facing_from_rotation_steps(rotation_steps: int) -> Vector2i:
	match rotation_steps % 4:
		0:
			return Vector2i.RIGHT
		1:
			return Vector2i.DOWN
		2:
			return Vector2i.LEFT
		_:
			return Vector2i.UP
