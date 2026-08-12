extends Building
class_name SourceBuilding

@export var generated_value: int = 1
@export var packets_per_second: float = 1.0
@export var source_label: StringName

var _time_until_next_packet: float = 0.0


func _ready() -> void:
	_time_until_next_packet = _get_emit_interval()


func simulation_tick(delta: float) -> void:
	_time_until_next_packet -= delta

	while _time_until_next_packet <= 0.0:
		emit_packet(_create_packet())
		_time_until_next_packet += _get_emit_interval()


func can_accept_packet(_packet: NumberPacket) -> bool:
	return false


func _create_packet() -> NumberPacket:
	var packet := NumberPacket.new()
	packet.value = generated_value
	packet.source_id = source_label if not String(source_label).is_empty() else StringName("source_%d" % generated_value)
	return packet


func _get_emit_interval() -> float:
	if packets_per_second <= 0.0:
		return INF

	return 1.0 / packets_per_second
