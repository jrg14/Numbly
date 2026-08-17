extends Building
class_name FilterBuilding

enum FilterMode {
	EQUAL,
	NOT_EQUAL,
	GREATER_THAN,
	LESS_THAN,
	EVEN,
	ODD,
	MULTIPLE_OF,
}

@export var filter_mode: FilterMode = FilterMode.EQUAL
@export var compare_value: int = 0
@export var route_failed_packets: bool = true

var _pending_output_directions: Array[Vector2i] = []


func can_accept_packet(_packet: NumberPacket) -> bool:
	return true


func can_accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if from_building == null:
		return can_accept_packet(packet)

	var incoming_direction := from_building.grid_position - grid_position
	return can_accept_packet(packet) and not _get_filter_output_directions().has(incoming_direction)


func reset_simulation() -> void:
	_pending_output_directions.clear()


func configure_from_level_data(level_building_data: LevelBuildingData) -> void:
	compare_value = level_building_data.target_value


func get_output_directions(_packet: NumberPacket = null) -> Array[Vector2i]:
	return _pending_output_directions.duplicate()


func _on_packet_accepted(packet: NumberPacket) -> void:
	if _matches(packet.value):
		_pending_output_directions = [facing]
	elif route_failed_packets:
		_pending_output_directions = [_rotate_clockwise(facing)]
	else:
		_pending_output_directions.clear()

	if not _pending_output_directions.is_empty():
		emit_packet(packet)

	_pending_output_directions.clear()


func _matches(value: int) -> bool:
	match filter_mode:
		FilterMode.EQUAL:
			return value == compare_value
		FilterMode.NOT_EQUAL:
			return value != compare_value
		FilterMode.GREATER_THAN:
			return value > compare_value
		FilterMode.LESS_THAN:
			return value < compare_value
		FilterMode.EVEN:
			return value % 2 == 0
		FilterMode.ODD:
			return value % 2 != 0
		FilterMode.MULTIPLE_OF:
			return compare_value != 0 and value % compare_value == 0

	return false


func _rotate_clockwise(direction: Vector2i) -> Vector2i:
	return Vector2i(-direction.y, direction.x)


func _get_filter_output_directions() -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	directions.append(facing)
	directions.append(_rotate_clockwise(facing))
	return directions
