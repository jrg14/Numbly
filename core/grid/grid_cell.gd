extends RefCounted
class_name GridCell

var coordinate: Vector2i
var occupant: Node2D


func _init(initial_coordinate: Vector2i = Vector2i.ZERO) -> void:
	coordinate = initial_coordinate


func is_occupied() -> bool:
	return occupant != null and is_instance_valid(occupant)


func clear() -> void:
	occupant = null
