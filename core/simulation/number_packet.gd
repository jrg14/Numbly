extends Resource
class_name NumberPacket

@export var value: int = 0
@export var source_id: StringName


func duplicate_packet() -> NumberPacket:
	var packet := NumberPacket.new()
	packet.value = value
	packet.source_id = source_id
	return packet
