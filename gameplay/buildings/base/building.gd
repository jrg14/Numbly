extends Node2D
class_name Building

signal packet_output(packet: NumberPacket, from_building: Building)
signal packet_accepted(packet: NumberPacket, by_building: Building)
signal packet_rejected(packet: NumberPacket, by_building: Building)

@export var building_data: BuildingData
@export var grid_position: Vector2i = Vector2i.ZERO
@export var facing: Vector2i = Vector2i.RIGHT


func can_accept_packet(_packet: NumberPacket) -> bool:
	return false


func can_accept_packet_from(packet: NumberPacket, _from_building: Building) -> bool:
	return can_accept_packet(packet)


func accept_packet(packet: NumberPacket) -> bool:
	if not can_accept_packet(packet):
		packet_rejected.emit(packet, self)
		return false

	packet_accepted.emit(packet, self)
	_on_packet_accepted(packet)
	return true


func accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if not can_accept_packet_from(packet, from_building):
		packet_rejected.emit(packet, self)
		return false

	packet_accepted.emit(packet, self)
	_on_packet_accepted_from(packet, from_building)
	return true


func simulation_tick(_delta: float) -> void:
	pass


func rotate_clockwise() -> void:
	facing = Vector2i(-facing.y, facing.x)
	rotation_degrees += 90.0


func emit_packet(packet: NumberPacket) -> void:
	packet_output.emit(packet, self)


func _on_packet_accepted(_packet: NumberPacket) -> void:
	pass


func _on_packet_accepted_from(packet: NumberPacket, _from_building: Building) -> void:
	_on_packet_accepted(packet)
