extends Node2D
class_name PlacementPreview

@export var cell_size: Vector2 = Vector2(64, 64):
	set(value):
		cell_size = value
		queue_redraw()

var is_valid_position: bool = false:
	set(value):
		is_valid_position = value
		queue_redraw()


func show_at(world_position: Vector2, valid_position: bool, rotation_degrees_value: float) -> void:
	global_position = world_position
	rotation_degrees = rotation_degrees_value
	is_valid_position = valid_position
	visible = true


func hide_preview() -> void:
	visible = false


func _draw() -> void:
	var half_size := cell_size * 0.5
	var rect := Rect2(-half_size, cell_size)
	var fill_color := Color(0.2, 0.85, 0.45, 0.22) if is_valid_position else Color(0.95, 0.2, 0.18, 0.22)
	var outline_color := Color(0.2, 0.85, 0.45, 0.85) if is_valid_position else Color(0.95, 0.2, 0.18, 0.85)

	draw_rect(rect, fill_color, true)
	draw_rect(rect, outline_color, false, 3.0)
	draw_line(Vector2.ZERO, Vector2(cell_size.x * 0.32, 0.0), outline_color, 4.0)
