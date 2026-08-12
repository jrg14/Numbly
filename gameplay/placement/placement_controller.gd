extends Node
class_name PlacementController

signal selected_building_changed(index: int, scene: PackedScene)
signal placement_succeeded(piece: Node2D, cell: Vector2i)
signal placement_failed(cell: Vector2i)
signal rotation_changed(rotation_steps: int)

@export var grid_manager_path: NodePath
@export var placement_preview_path: NodePath
@export var build_parent_path: NodePath
@export var available_building_scenes: Array[PackedScene] = []
@export var delete_with_right_click: bool = true

var selected_building_index: int = -1
var rotation_steps: int = 0

var _grid_manager: GridManager
var _placement_preview: PlacementPreview
var _build_parent: Node
var _last_hovered_cell: Vector2i = Vector2i(-9999, -9999)


func _ready() -> void:
	_grid_manager = get_node_or_null(grid_manager_path) as GridManager
	_placement_preview = get_node_or_null(placement_preview_path) as PlacementPreview
	_build_parent = get_node_or_null(build_parent_path)

	if _grid_manager != null and _placement_preview != null:
		_placement_preview.cell_size = _grid_manager.cell_size

	if not available_building_scenes.is_empty():
		select_building_index(0)


func _process(_delta: float) -> void:
	_update_preview(get_viewport().get_mouse_position())


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key_input(event)
		return

	if event is InputEventMouseButton and event.pressed:
		_handle_mouse_button(event)
		return

	if event is InputEventScreenTouch and event.pressed:
		_try_place_at_screen_position(event.position)


func select_building_index(index: int) -> void:
	if index < 0 or index >= available_building_scenes.size():
		return

	if selected_building_index != index:
		rotation_steps = 0
		rotation_changed.emit(rotation_steps)

	selected_building_index = index
	selected_building_changed.emit(index, available_building_scenes[index])
	_update_preview(get_viewport().get_mouse_position())


func select_building_scene(scene: PackedScene) -> void:
	var scene_index := available_building_scenes.find(scene)
	if scene_index == -1:
		available_building_scenes.append(scene)
		scene_index = available_building_scenes.size() - 1

	select_building_index(scene_index)


func rotate_clockwise() -> void:
	rotation_steps = (rotation_steps + 1) % 4
	rotation_changed.emit(rotation_steps)
	_update_preview(get_viewport().get_mouse_position())


func place_selected_at(cell: Vector2i) -> bool:
	if _grid_manager == null or selected_building_index == -1:
		return false

	if not _grid_manager.can_place_piece(cell):
		placement_failed.emit(cell)
		return false

	var scene := available_building_scenes[selected_building_index]
	var piece := scene.instantiate() as Node2D
	if piece == null:
		placement_failed.emit(cell)
		return false

	piece.rotation_degrees = rotation_steps * 90.0

	if piece is Building:
		piece.facing = _get_facing_from_rotation()

	var placed := _grid_manager.place_piece(piece, cell, _get_build_parent())
	if placed:
		placement_succeeded.emit(piece, cell)
	else:
		piece.queue_free()
		placement_failed.emit(cell)

	return placed


func remove_piece_at(cell: Vector2i) -> Node2D:
	if _grid_manager == null:
		return null

	return _grid_manager.remove_piece_at(cell, true)


func _handle_key_input(event: InputEventKey) -> void:
	match event.keycode:
		KEY_1:
			select_building_index(0)
		KEY_2:
			select_building_index(1)
		KEY_3:
			select_building_index(2)
		KEY_4:
			select_building_index(3)
		KEY_5:
			select_building_index(4)
		KEY_R:
			rotate_clockwise()
		KEY_DELETE, KEY_BACKSPACE:
			if _grid_manager != null:
				remove_piece_at(_last_hovered_cell)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		_try_place_at_screen_position(event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT and delete_with_right_click:
		_try_remove_at_screen_position(event.position)


func _try_place_at_screen_position(screen_position: Vector2) -> void:
	if _grid_manager == null:
		return

	place_selected_at(_grid_manager.world_to_grid(_screen_to_world(screen_position)))


func _try_remove_at_screen_position(screen_position: Vector2) -> void:
	if _grid_manager == null:
		return

	remove_piece_at(_grid_manager.world_to_grid(_screen_to_world(screen_position)))


func _update_preview(screen_position: Vector2) -> void:
	if _grid_manager == null or _placement_preview == null or selected_building_index == -1:
		if _placement_preview != null:
			_placement_preview.hide_preview()
		return

	var cell := _grid_manager.world_to_grid(_screen_to_world(screen_position))
	_last_hovered_cell = cell

	if not _grid_manager.is_in_bounds(cell):
		_placement_preview.hide_preview()
		return

	_placement_preview.show_at(
		_grid_manager.grid_to_world(cell),
		_grid_manager.can_place_piece(cell),
		rotation_steps * 90.0
	)


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _get_build_parent() -> Node:
	return _build_parent if _build_parent != null else _grid_manager


func _get_facing_from_rotation() -> Vector2i:
	match rotation_steps:
		0:
			return Vector2i.RIGHT
		1:
			return Vector2i.DOWN
		2:
			return Vector2i.LEFT
		_:
			return Vector2i.UP
