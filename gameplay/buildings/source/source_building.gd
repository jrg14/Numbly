extends Building
class_name SourceBuilding

@export var generated_value: int = 1
@export var packets_per_second: float = 1.0
@export var source_label: StringName

var _time_until_next_packet: float = 0.0


func _ready() -> void:
	_time_until_next_packet = _get_emit_interval()
	_update_value_label()


func simulation_tick(delta: float) -> void:
	_time_until_next_packet -= delta

	while _time_until_next_packet <= 0.0:
		emit_packet(_create_packet())
		_time_until_next_packet += _get_emit_interval()


func can_accept_packet(_packet: NumberPacket) -> bool:
	return false


func reset_simulation() -> void:
	_time_until_next_packet = _get_emit_interval()


func configure_from_level_data(level_building_data: LevelBuildingData) -> void:
	generated_value = level_building_data.generated_value
	packets_per_second = level_building_data.packets_per_second
	source_label = StringName("source_%d" % generated_value)
	_update_value_label()


func _create_packet() -> NumberPacket:
	var packet := NumberPacket.new()
	packet.value = generated_value
	packet.source_id = source_label if not String(source_label).is_empty() else StringName("source_%d" % generated_value)
	return packet


func _get_emit_interval() -> float:
	if packets_per_second <= 0.0:
		return INF

	return 1.0 / packets_per_second


func _update_value_label() -> void:
	var label := get_node_or_null("ValueLabel") as Label
	if label != null:
		label.text = str(generated_value)
