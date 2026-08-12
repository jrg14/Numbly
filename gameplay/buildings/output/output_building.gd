extends Building
class_name OutputBuilding

signal target_reached(total_accepted: int)
signal wrong_value_received(packet: NumberPacket)

@export var target_value: int = 1
@export var required_count: int = 1

var accepted_count: int = 0
var rejected_count: int = 0


func can_accept_packet(_packet: NumberPacket) -> bool:
	return true


func reset_output() -> void:
	accepted_count = 0
	rejected_count = 0


func _on_packet_accepted(packet: NumberPacket) -> void:
	if packet.value != target_value:
		rejected_count += 1
		wrong_value_received.emit(packet)
		return

	accepted_count += 1

	if accepted_count >= required_count:
		target_reached.emit(accepted_count)
