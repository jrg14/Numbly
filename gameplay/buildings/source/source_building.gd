extends Building
class_name SourceBuilding

@export var generated_value: int = 1
@export var packets_per_second: float = 1.0
@export var generation_interval_ticks: int = 10
@export var source_label: StringName

var _ticks_until_next_packet: int = 0


func _ready() -> void:
	_ticks_until_next_packet = _get_generation_interval_ticks()
	_update_value_label()


func simulation_tick(_delta: float) -> void:
	_ticks_until_next_packet -= 1

	if _ticks_until_next_packet <= 0:
		emit_packet(_create_packet())
		_ticks_until_next_packet += _get_generation_interval_ticks()


func can_accept_packet(_packet: NumberPacket) -> bool:
	return false


func reset_simulation() -> void:
	_ticks_until_next_packet = _get_generation_interval_ticks()


func configure_from_level_data(level_building_data: LevelBuildingData) -> void:
	generated_value = level_building_data.generated_value
	packets_per_second = level_building_data.packets_per_second
	generation_interval_ticks = level_building_data.generation_interval_ticks
	source_label = StringName("source_%d" % generated_value)
	_update_value_label()


func _create_packet() -> NumberPacket:
	var packet := NumberPacket.new()
	packet.value = generated_value
	packet.source_id = source_label if not String(source_label).is_empty() else StringName("source_%d" % generated_value)
	return packet


func _get_generation_interval_ticks() -> int:
	return maxi(generation_interval_ticks, 1)


func _update_value_label() -> void:
	var label := get_node_or_null("ValueLabel") as Label
	if label != null:
		label.text = str(generated_value)
