extends Building
class_name ArithmeticOperatorBuilding

signal operation_created(building: Building, input_values: Array[int], result: int, operator_symbol: String)

@export var input_count: int = 2
@export var max_buffer_size: int = 8
@export var operation_interval_ticks: int = 10
@export var operator_symbol: String = "?"

var _input_buffers: Dictionary = {}
var _lane_order: Array[Vector2i] = []
var _ticks_until_next_operation: int = 0


func can_accept_packet(_packet: NumberPacket) -> bool:
	return _get_total_buffered_packets() < max_buffer_size


func can_accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if not can_accept_packet(packet):
		return false

	var lane := _get_input_lane(from_building)
	var lane_index := _get_lane_index_for_acceptance(lane)
	if lane_index == -1:
		return false

	return _can_accept_value_for_lane(packet.value, lane_index)


func reset_simulation() -> void:
	_input_buffers.clear()
	_lane_order.clear()
	_ticks_until_next_operation = 0


func configure_from_level_data(level_building_data: LevelBuildingData) -> void:
	max_buffer_size = maxi(level_building_data.max_buffer_size, 1)
	operation_interval_ticks = maxi(level_building_data.operation_interval_ticks, 1)


func simulation_tick(_delta: float) -> void:
	if _ticks_until_next_operation > 0:
		_ticks_until_next_operation -= 1

	_try_emit_operation()


func get_buffered_values() -> Array[int]:
	var values: Array[int] = []

	for lane in _lane_order:
		var lane_buffer := _input_buffers[lane] as Array
		for packet in lane_buffer:
			var number_packet := packet as NumberPacket
			values.append(number_packet.value)

	return values


func _on_packet_accepted_from(packet: NumberPacket, from_building: Building) -> void:
	var lane := _get_input_lane(from_building)
	if not _input_buffers.has(lane):
		_input_buffers[lane] = []
		_lane_order.append(lane)

	var lane_buffer := _input_buffers[lane] as Array
	lane_buffer.append(packet)
	_try_emit_operation()


func _try_emit_operation() -> void:
	if _ticks_until_next_operation > 0 or not _has_ready_inputs():
		return

	var input_values: Array[int] = []
	for i in range(input_count):
		var lane := _lane_order[i]
		var lane_buffer := _input_buffers[lane] as Array
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


func _has_ready_inputs() -> bool:
	if _lane_order.size() < input_count:
		return false

	for i in range(input_count):
		var lane := _lane_order[i]
		var lane_buffer := _input_buffers[lane] as Array
		if lane_buffer.is_empty():
			return false

	return true


func _get_input_lane(from_building: Building) -> Vector2i:
	if from_building == null:
		return Vector2i.ZERO

	return from_building.grid_position - grid_position


func _get_lane_index_for_acceptance(lane: Vector2i) -> int:
	var existing_index := _lane_order.find(lane)
	if existing_index != -1:
		return existing_index

	if _lane_order.size() >= input_count:
		return -1

	return _lane_order.size()


func _get_total_buffered_packets() -> int:
	var total := 0

	for lane in _input_buffers:
		total += (_input_buffers[lane] as Array).size()

	return total
