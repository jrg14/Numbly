extends Building
class_name ConveyorBuilding

@export var travel_time: float = 0.25

var _queued_packets: Array[Dictionary] = []


func can_accept_packet(_packet: NumberPacket) -> bool:
	return true


func simulation_tick(delta: float) -> void:
	for queued_packet in _queued_packets:
		var remaining_time: float = queued_packet["remaining_time"]
		queued_packet["remaining_time"] = remaining_time - delta

	var ready_packets: Array[NumberPacket] = []
	_queued_packets = _queued_packets.filter(
		func(queued_packet: Dictionary) -> bool:
			if queued_packet["remaining_time"] <= 0.0:
				ready_packets.append(queued_packet["packet"])
				return false

			return true
	)

	for packet in ready_packets:
		emit_packet(packet)


func _on_packet_accepted(packet: NumberPacket) -> void:
	_queued_packets.append({
		"packet": packet,
		"remaining_time": maxf(travel_time, 0.0),
	})
