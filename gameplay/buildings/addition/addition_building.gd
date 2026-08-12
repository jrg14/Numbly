extends Building
class_name AdditionBuilding

@export var input_count: int = 2
@export var max_buffer_size: int = 8

var _input_buffers: Dictionary = {}
var _lane_order: Array[Vector2i] = []


func can_accept_packet(_packet: NumberPacket) -> bool:
	return _get_total_buffered_packets() < max_buffer_size


func can_accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if not can_accept_packet(packet):
		return false

	var lane := _get_input_lane(from_building)
	return _input_buffers.has(lane) or _lane_order.size() < input_count


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
	_try_emit_sum()


func _try_emit_sum() -> void:
	while _has_ready_inputs():
		var result := 0

		for i in range(input_count):
			var lane := _lane_order[i]
			var lane_buffer := _input_buffers[lane] as Array
			var packet := lane_buffer.pop_front() as NumberPacket
			result += packet.value

		var output_packet := NumberPacket.new()
		output_packet.value = result
		output_packet.source_id = &"addition"
		emit_packet(output_packet)


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


func _get_total_buffered_packets() -> int:
	var total := 0

	for lane in _input_buffers:
		total += (_input_buffers[lane] as Array).size()

	return total
