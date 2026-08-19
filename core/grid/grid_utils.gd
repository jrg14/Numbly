extends RefCounted
class_name GridUtils


static func local_to_grid(local_position: Vector2, cell_size: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2i:
	var shifted_position := local_position - origin
	return Vector2i(
		floori(shifted_position.x / cell_size.x),
		floori(shifted_position.y / cell_size.y)
	)


static func grid_to_local_center(cell: Vector2i, cell_size: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2:
	return origin + Vector2(cell) * cell_size + cell_size * 0.5


static func grid_to_local_footprint_center(cell: Vector2i, footprint_size: Vector2i, cell_size: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2:
	return origin + Vector2(cell) * cell_size + Vector2(footprint_size) * cell_size * 0.5


static func grid_to_local_top_left(cell: Vector2i, cell_size: Vector2, origin: Vector2 = Vector2.ZERO) -> Vector2:
	return origin + Vector2(cell) * cell_size


static func cardinal_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i.RIGHT,
		cell + Vector2i.DOWN,
		cell + Vector2i.LEFT,
		cell + Vector2i.UP,
	]


static func all_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i(-1, -1),
		cell + Vector2i(0, -1),
		cell + Vector2i(1, -1),
		cell + Vector2i(-1, 0),
		cell + Vector2i(1, 0),
		cell + Vector2i(-1, 1),
		cell + Vector2i(0, 1),
		cell + Vector2i(1, 1),
	]
