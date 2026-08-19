extends Node2D
class_name PlacementPreview

@export var cell_size: Vector2 = Vector2(64, 64):
	set(value):
		cell_size = value
		_refresh_preview_transform()

var is_valid_position: bool = false

var footprint_size: Vector2i = Vector2i(1, 1):
	set(value):
		footprint_size = Vector2i(maxi(value.x, 1), maxi(value.y, 1))
		_refresh_preview_transform()

var _preview_building_data: BuildingData
var _preview_piece: Node2D


func show_at(world_position: Vector2, valid_position: bool, rotation_steps: int, building_data: BuildingData) -> void:
	global_position = world_position
	rotation_degrees = 0.0
	_set_preview_building_data(building_data)
	footprint_size = building_data.footprint_size if building_data != null else Vector2i(1, 1)
	is_valid_position = valid_position
	_apply_preview_rotation(rotation_steps)
	_refresh_preview_transform()
	visible = true


func hide_preview() -> void:
	visible = false


func _set_preview_building_data(building_data: BuildingData) -> void:
	if _preview_building_data == building_data:
		return

	_preview_building_data = building_data

	if _preview_piece != null and is_instance_valid(_preview_piece):
		_preview_piece.queue_free()
		_preview_piece = null

	if _preview_building_data == null or _preview_building_data.scene == null:
		return

	_preview_piece = _preview_building_data.scene.instantiate() as Node2D
	if _preview_piece == null:
		return

	add_child(_preview_piece)
	var building := _preview_piece as Building
	if building != null:
		building.apply_building_data(_preview_building_data)
		building.locked = true


func _apply_preview_rotation(rotation_steps: int) -> void:
	if _preview_piece == null:
		return

	var building := _preview_piece as Building
	if building != null:
		building.set_rotation_steps(rotation_steps)
	else:
		_preview_piece.rotation_degrees = rotation_steps * 90.0


func _refresh_preview_transform() -> void:
	if _preview_piece == null:
		return

	var base_cell_size := 64.0
	_preview_piece.position = Vector2.ZERO
	_preview_piece.scale = Vector2(
		cell_size.x / base_cell_size * float(footprint_size.x),
		cell_size.y / base_cell_size * float(footprint_size.y)
	)
	_preview_piece.modulate = Color(1.0, 1.0, 1.0, 0.68) if is_valid_position else Color(1.0, 0.3, 0.25, 0.58)
