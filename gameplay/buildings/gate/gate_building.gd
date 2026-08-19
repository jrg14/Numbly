extends Building
class_name GateBuilding

enum GateMode {
	EVERY_N,
	MATCH_VALUE,
	BLOCK_VALUE,
}

@export var gate_mode: GateMode = GateMode.EVERY_N
@export var interval: int = 2
@export var compare_value: int = 0

var _seen_packets: int = 0
var _should_emit_current_packet: bool = false


func can_accept_packet(_packet: NumberPacket) -> bool:
	return true


func can_accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if from_building == null:
		return can_accept_packet(packet)

	var incoming_direction := _get_incoming_direction(from_building)
	return can_accept_packet(packet) and incoming_direction != facing


func can_accept_packet_from_cell(packet: NumberPacket, from_building: Building, target_cell: Vector2i) -> bool:
	if from_building == null:
		return can_accept_packet(packet)

	var incoming_direction := _get_incoming_direction(from_building, target_cell)
	return can_accept_packet(packet) and incoming_direction != facing


func reset_simulation() -> void:
	_seen_packets = 0
	_should_emit_current_packet = false


func configure_from_level_data(level_building_data: LevelBuildingData) -> void:
	interval = maxi(level_building_data.operation_interval_ticks, 1)
	compare_value = level_building_data.target_value


func get_output_directions(_packet: NumberPacket = null) -> Array[Vector2i]:
	if not _should_emit_current_packet:
		return []

	var directions: Array[Vector2i] = []
	directions.append(facing)
	return directions


func _on_packet_accepted(packet: NumberPacket) -> void:
	_seen_packets += 1
	_should_emit_current_packet = _passes(packet.value)
	if _should_emit_current_packet:
		emit_packet(packet)

	_should_emit_current_packet = false


func _passes(value: int) -> bool:
	match gate_mode:
		GateMode.EVERY_N:
			return _seen_packets % maxi(interval, 1) == 0
		GateMode.MATCH_VALUE:
			return value == compare_value
		GateMode.BLOCK_VALUE:
			return value != compare_value

	return false


func _get_incoming_direction(from_building: Building, target_cell: Vector2i = Vector2i(-9999, -9999)) -> Vector2i:
	if target_cell.x < -9000:
		target_cell = grid_position

	var origin_cell := from_building.get_nearest_occupied_cell_to(target_cell)
	var delta := origin_cell - target_cell
	if absi(delta.x) >= absi(delta.y):
		return Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT

	return Vector2i.DOWN if delta.y > 0 else Vector2i.UP
