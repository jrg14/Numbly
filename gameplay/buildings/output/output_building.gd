extends Building
class_name OutputBuilding

signal target_reached(total_accepted: int)
signal packet_consumed(packet: NumberPacket, matched_target: bool)
signal wrong_value_received(packet: NumberPacket)

@export var target_value: int = 1
@export var required_count: int = 1

var accepted_count: int = 0
var rejected_count: int = 0
var is_complete: bool = false


func can_accept_packet(_packet: NumberPacket) -> bool:
	return true


func _ready() -> void:
	_update_value_label()


func reset_output() -> void:
	accepted_count = 0
	rejected_count = 0
	is_complete = false
	_update_value_label()


func reset_simulation() -> void:
	reset_output()


func configure_from_level_data(level_building_data: LevelBuildingData) -> void:
	target_value = level_building_data.target_value
	if level_building_data.required_count > 0:
		required_count = level_building_data.required_count
	_update_value_label()


func configure_requirements(new_target_value: int, new_required_count: int) -> void:
	target_value = new_target_value
	required_count = maxi(new_required_count, 1)
	_update_value_label()


func _on_packet_accepted(packet: NumberPacket) -> void:
	if packet.value != target_value:
		rejected_count += 1
		packet_consumed.emit(packet, false)
		wrong_value_received.emit(packet)
		return

	accepted_count += 1
	packet_consumed.emit(packet, true)
	_update_value_label()

	if not is_complete and accepted_count >= required_count:
		is_complete = true
		target_reached.emit(accepted_count)


func _update_value_label() -> void:
	var label := get_node_or_null("ValueLabel") as Label
	if label != null:
		label.text = str(target_value)

	var count_label := get_node_or_null("CountLabel") as Label
	if count_label != null:
		count_label.text = "%d/%d" % [accepted_count, required_count]
