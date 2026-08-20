extends Building
class_name ArithmeticOperatorBuilding

signal operation_created(building: Building, input_values: Array[int], result: int, operator_symbol: String)

@export var input_count: int = 2
@export var max_buffer_size: int = 8
@export var operation_interval_ticks: int = 10
@export var operator_symbol: String = "?"

var _input_buffers: Dictionary = {}
var _ticks_until_next_operation: int = 0


func can_accept_packet(_packet: NumberPacket) -> bool:
	return _get_total_buffered_packets() < max_buffer_size


func can_accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if from_building == null:
		return can_accept_packet(packet)

	var target_cell := grid_position
	if from_building != null:
		target_cell = get_nearest_occupied_cell_to(from_building.grid_position)

	return can_accept_packet_from_cell(packet, from_building, target_cell)


func can_accept_packet_from_cell(packet: NumberPacket, _from_building: Building, target_cell: Vector2i) -> bool:
	if not can_accept_packet(packet):
		return false

	var lane_index := _get_input_lane_index_for_cell(target_cell)
	if lane_index == -1:
		return false

	return _can_accept_value_for_lane(packet.value, lane_index)


func reset_simulation() -> void:
	_input_buffers.clear()
	_ticks_until_next_operation = 0


func configure_from_level_data(level_building_data: LevelBuildingData) -> void:
	max_buffer_size = maxi(level_building_data.max_buffer_size, 1)
	operation_interval_ticks = maxi(level_building_data.operation_interval_ticks, 1)


func simulation_tick(_delta: float) -> void:
	if _ticks_until_next_operation > 0:
		_ticks_until_next_operation -= 1

	_try_emit_operation()


func set_rotation_steps(rotation_steps: int) -> void:
	var normalized_steps := rotation_steps % 4
	rotation_degrees = normalized_steps * 90.0
	facing = _get_facing_from_operation_rotation_steps(normalized_steps)
	_update_port_label_rotation()


func get_buffered_values() -> Array[int]:
	var values: Array[int] = []

	for lane_index in range(input_count):
		var lane_buffer := _get_lane_buffer(lane_index)
		for packet in lane_buffer:
			var number_packet := packet as NumberPacket
			values.append(number_packet.value)

	return values


func _on_packet_accepted_from(packet: NumberPacket, from_building: Building) -> void:
	var target_cell := grid_position
	if from_building != null:
		target_cell = get_nearest_occupied_cell_to(from_building.grid_position)
	_on_packet_accepted_from_cell(packet, from_building, target_cell)


func _on_packet_accepted_from_cell(packet: NumberPacket, _from_building: Building, target_cell: Vector2i) -> void:
	var lane_index := _get_input_lane_index_for_cell(target_cell)
	if lane_index == -1:
		return

	var lane_buffer := _get_lane_buffer(lane_index)
	lane_buffer.append(packet)
	_try_emit_operation()


func _try_emit_operation() -> void:
	if _ticks_until_next_operation > 0 or not _has_ready_inputs():
		return

	var input_values: Array[int] = []
	for i in range(input_count):
		var lane_buffer := _get_lane_buffer(i)
		var packet := lane_buffer.pop_front() as NumberPacket
		input_values.append(packet.value)

	var result := _calculate_result(input_values)
	var output_packet := NumberPacket.new()
	output_packet.value = result
	output_packet.source_id = _get_output_source_id()
	operation_created.emit(self, input_values, result, operator_symbol)
	_emit_specific_operation_signal(input_values, result)
	emit_packet(output_packet)
	_ticks_until_next_operation = maxi(operation_interval_ticks, 1)


func _calculate_result(input_values: Array[int]) -> int:
	if input_values.is_empty():
		return 0

	return input_values[0]


func _can_accept_value_for_lane(_value: int, _lane_index: int) -> bool:
	return true


func _emit_specific_operation_signal(_input_values: Array[int], _result: int) -> void:
	pass


func _get_output_source_id() -> StringName:
	return StringName(operator_symbol)


func get_output_target_groups(_packet: NumberPacket = null) -> Array:
	var groups: Array = []
	groups.append(get_edge_target_cells(facing))
	return groups


func get_input_cells() -> Array[Vector2i]:
	var input_cells: Array[Vector2i] = []

	if facing == Vector2i.RIGHT:
		input_cells.append(grid_position)
		input_cells.append(grid_position + Vector2i(0, footprint_size.y - 1))
	elif facing == Vector2i.LEFT:
		input_cells.append(grid_position + Vector2i(footprint_size.x - 1, footprint_size.y - 1))
		input_cells.append(grid_position + Vector2i(footprint_size.x - 1, 0))
	elif facing == Vector2i.DOWN:
		input_cells.append(grid_position + Vector2i(1, 0))
		input_cells.append(grid_position)
	elif facing == Vector2i.UP:
		input_cells.append(grid_position + Vector2i(0, footprint_size.y - 1))
		input_cells.append(grid_position + Vector2i(footprint_size.x - 1, footprint_size.y - 1))

	return input_cells


func _has_ready_inputs() -> bool:
	for i in range(input_count):
		var lane_buffer := _get_lane_buffer(i)
		if lane_buffer.is_empty():
			return false

	return true


func _get_input_lane_index_for_cell(target_cell: Vector2i) -> int:
	var input_cells := get_input_cells()
	for i in range(mini(input_count, input_cells.size())):
		if input_cells[i] == target_cell:
			return i

	return -1


func _get_lane_buffer(lane_index: int) -> Array:
	if not _input_buffers.has(lane_index):
		_input_buffers[lane_index] = []

	return _input_buffers[lane_index] as Array


func _get_total_buffered_packets() -> int:
	var total := 0

	for lane in _input_buffers:
		total += (_input_buffers[lane] as Array).size()

	return total


func _get_facing_from_operation_rotation_steps(rotation_steps: int) -> Vector2i:
	match rotation_steps % 4:
		0:
			return Vector2i.DOWN
		1:
			return Vector2i.LEFT
		2:
			return Vector2i.UP
		_:
			return Vector2i.RIGHT


func _update_port_label_rotation() -> void:
	for label_name in ["InputALabel", "InputBLabel", "OutputLabel"]:
		var label := get_node_or_null(NodePath(label_name)) as Label
		if label == null:
			continue

		label.pivot_offset = label.size * 0.5
		label.rotation_degrees = -rotation_degrees
