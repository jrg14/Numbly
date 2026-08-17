extends Building
class_name BufferBuilding

@export var max_buffer_size: int = 8
@export var release_interval_ticks: int = 10

var _buffer: Array[NumberPacket] = []
var _ticks_until_release: int = 0


func can_accept_packet(_packet: NumberPacket) -> bool:
	return _buffer.size() < max_buffer_size


func can_accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if from_building == null:
		return can_accept_packet(packet)

	var incoming_direction := from_building.grid_position - grid_position
	return can_accept_packet(packet) and incoming_direction != facing


func reset_simulation() -> void:
	_buffer.clear()
	_ticks_until_release = 0


func configure_from_level_data(level_building_data: LevelBuildingData) -> void:
	max_buffer_size = maxi(level_building_data.max_buffer_size, 1)
	release_interval_ticks = maxi(level_building_data.operation_interval_ticks, 1)


func simulation_tick(_delta: float) -> void:
	if _ticks_until_release > 0:
		_ticks_until_release -= 1

	if _ticks_until_release > 0 or _buffer.is_empty():
		return

	var packet := _buffer.pop_front() as NumberPacket
	emit_packet(packet)
	_ticks_until_release = maxi(release_interval_ticks, 1)


func _on_packet_accepted(packet: NumberPacket) -> void:
	_buffer.append(packet)
