extends Node2D
class_name GridManager

signal cell_occupied(cell: Vector2i, occupant: Node2D)
signal cell_cleared(cell: Vector2i)
signal piece_placed(piece: Node2D, cell: Vector2i)
signal piece_removed(piece: Node2D, cell: Vector2i)
signal grid_cleared

@export var grid_size: Vector2i = Vector2i(12, 8):
	set(value):
		grid_size = Vector2i(maxi(value.x, 1), maxi(value.y, 1))
		_initialize_cells()
		queue_redraw()

@export var cell_size: Vector2 = Vector2(64, 64):
	set(value):
		cell_size = Vector2(maxf(value.x, 1.0), maxf(value.y, 1.0))
		queue_redraw()

@export var origin: Vector2 = Vector2.ZERO:
	set(value):
		origin = value
		queue_redraw()

@export var draw_grid: bool = true
@export var grid_line_color: Color = Color(0.28, 0.31, 0.34, 0.45)
@export var occupied_cell_color: Color = Color(0.96, 0.72, 0.22, 0.18)

var _cells: Dictionary = {}


func _ready() -> void:
	_initialize_cells()


func world_to_grid(world_position: Vector2) -> Vector2i:
	return GridUtils.local_to_grid(to_local(world_position), cell_size, origin)


func grid_to_world(cell: Vector2i) -> Vector2:
	return to_global(GridUtils.grid_to_local_center(cell, cell_size, origin))


func grid_to_local_top_left(cell: Vector2i) -> Vector2:
	return GridUtils.grid_to_local_top_left(cell, cell_size, origin)


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < grid_size.x and cell.y < grid_size.y


func get_cell(cell: Vector2i) -> GridCell:
	if not is_in_bounds(cell):
		return null

	return _cells.get(cell)


func is_cell_occupied(cell: Vector2i) -> bool:
	var grid_cell := get_cell(cell)
	return grid_cell != null and grid_cell.is_occupied()


func get_occupant(cell: Vector2i) -> Node2D:
	var grid_cell := get_cell(cell)
	if grid_cell == null:
		return null

	return grid_cell.occupant if grid_cell.is_occupied() else null


func mark_cell_occupied(cell: Vector2i, occupant: Node2D) -> bool:
	var grid_cell := get_cell(cell)
	if grid_cell == null or grid_cell.is_occupied() or occupant == null:
		return false

	grid_cell.occupant = occupant
	cell_occupied.emit(cell, occupant)
	queue_redraw()
	return true


func clear_cell(cell: Vector2i) -> Node2D:
	var grid_cell := get_cell(cell)
	if grid_cell == null:
		return null

	var previous_occupant := get_occupant(cell)
	grid_cell.clear()
	cell_cleared.emit(cell)
	queue_redraw()
	return previous_occupant


func can_place_piece(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not is_cell_occupied(cell)


func place_piece(piece: Node2D, cell: Vector2i, piece_parent: Node = null) -> bool:
	if piece == null or not can_place_piece(cell):
		return false

	var parent := piece_parent if piece_parent != null else self
	if piece.get_parent() == null:
		parent.add_child(piece)
	elif piece.get_parent() != parent:
		piece.reparent(parent)

	piece.global_position = grid_to_world(cell)

	if piece is Building:
		piece.grid_position = cell

	mark_cell_occupied(cell, piece)
	piece_placed.emit(piece, cell)
	return true


func remove_piece_at(cell: Vector2i, free_piece: bool = true) -> Node2D:
	if not is_in_bounds(cell):
		return null

	var occupant := clear_cell(cell)
	if occupant == null:
		return null

	piece_removed.emit(occupant, cell)

	if is_instance_valid(occupant):
		var parent := occupant.get_parent()
		if parent != null:
			parent.remove_child(occupant)

		if free_piece:
			occupant.queue_free()

	return occupant


func clear_all_pieces(free_pieces: bool = true) -> void:
	for cell in _cells.keys():
		remove_piece_at(cell, free_pieces)

	grid_cleared.emit()
	queue_redraw()


func get_neighbors(cell: Vector2i, include_diagonals: bool = false) -> Array[Vector2i]:
	var raw_neighbors := GridUtils.all_neighbors(cell) if include_diagonals else GridUtils.cardinal_neighbors(cell)
	var valid_neighbors: Array[Vector2i] = []

	for neighbor in raw_neighbors:
		if is_in_bounds(neighbor):
			valid_neighbors.append(neighbor)

	return valid_neighbors


func _draw() -> void:
	if not draw_grid:
		return

	var grid_pixel_size := Vector2(grid_size) * cell_size

	for x in range(grid_size.x + 1):
		var line_x := origin.x + float(x) * cell_size.x
		draw_line(Vector2(line_x, origin.y), Vector2(line_x, origin.y + grid_pixel_size.y), grid_line_color)

	for y in range(grid_size.y + 1):
		var line_y := origin.y + float(y) * cell_size.y
		draw_line(Vector2(origin.x, line_y), Vector2(origin.x + grid_pixel_size.x, line_y), grid_line_color)

	for cell in _cells:
		if is_cell_occupied(cell):
			draw_rect(Rect2(grid_to_local_top_left(cell), cell_size), occupied_cell_color, true)


func _initialize_cells() -> void:
	_cells.clear()

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := Vector2i(x, y)
			_cells[cell] = GridCell.new(cell)
