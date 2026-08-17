extends Building
class_name SplitterBuilding

enum SplitMode {
	ALTERNATE,
	DUPLICATE,
	PRIORITY,
}

@export var split_mode: SplitMode = SplitMode.ALTERNATE

var _next_output_index: int = 0
var _pending_output_directions: Array[Vector2i] = []


func can_accept_packet(_packet: NumberPacket) -> bool:
	return true


func can_accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if from_building == null:
		return can_accept_packet(packet)

	var incoming_direction := from_building.grid_position - grid_position
	return can_accept_packet(packet) and not _get_split_output_directions().has(incoming_direction)


func reset_simulation() -> void:
	_next_output_index = 0
	_pending_output_directions.clear()


func get_output_directions(_packet: NumberPacket = null) -> Array[Vector2i]:
	return _pending_output_directions.duplicate()


func _on_packet_accepted(_packet: NumberPacket) -> void:
	_emit_split_packet(_packet)


func _on_packet_accepted_from(packet: NumberPacket, _from_building: Building) -> void:
	_emit_split_packet(packet)


func _emit_split_packet(packet: NumberPacket) -> void:
	var outputs := _get_split_output_directions()
	if split_mode == SplitMode.DUPLICATE:
		_pending_output_directions = outputs
	elif split_mode == SplitMode.PRIORITY:
		_pending_output_directions = [outputs[0]]
	else:
		_pending_output_directions = [outputs[_next_output_index % outputs.size()]]
		_next_output_index += 1

	emit_packet(packet)
	_pending_output_directions.clear()


func _get_split_output_directions() -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	directions.append(facing)
	directions.append(_rotate_clockwise(facing))
	return directions


func _rotate_clockwise(direction: Vector2i) -> Vector2i:
	return Vector2i(-direction.y, direction.x)
