extends Building
class_name ConveyorBuilding

@export var travel_time: float = 0.25
@export var input_direction: Vector2i = Vector2i.LEFT:
	set(value):
		input_direction = _normalize_cardinal(value, Vector2i.LEFT)
		queue_redraw()

@export var belt_color: Color = Color(0.16, 0.17, 0.16, 1.0)
@export var belt_edge_color: Color = Color(0.92, 0.36, 0.05, 1.0)
@export var belt_shadow_color: Color = Color(0.05, 0.06, 0.06, 1.0)
@export var arrow_color: Color = Color(0.25, 0.26, 0.25, 0.75)

var _queued_packets: Array[Dictionary] = []


func can_accept_packet(_packet: NumberPacket) -> bool:
	return true


func can_accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if from_building == null:
		return can_accept_packet(packet)

	var incoming_direction: Vector2i = from_building.grid_position - grid_position
	return can_accept_packet(packet) and incoming_direction != facing


func reset_simulation() -> void:
	_queued_packets.clear()


func set_rotation_steps(rotation_steps: int) -> void:
	var normalized_steps: int = rotation_steps % 4
	facing = _get_facing_from_rotation_steps(normalized_steps)
	input_direction = -facing
	rotation_degrees = 0.0
	queue_redraw()


func configure_route(new_input_direction: Vector2i, new_output_direction: Vector2i) -> void:
	input_direction = _normalize_cardinal(new_input_direction, -facing)
	facing = _normalize_cardinal(new_output_direction, facing)
	rotation_degrees = 0.0
	queue_redraw()


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


func _draw() -> void:
	var path_points: Array[Vector2] = _get_path_points()

	for i in range(path_points.size() - 1):
		draw_line(path_points[i], path_points[i + 1], belt_shadow_color, 44.0, true)

	if path_points.size() == 3:
		draw_circle(Vector2.ZERO, 22.0, belt_shadow_color)

	for i in range(path_points.size() - 1):
		draw_line(path_points[i], path_points[i + 1], belt_edge_color, 36.0, true)

	if path_points.size() == 3:
		draw_circle(Vector2.ZERO, 18.0, belt_edge_color)

	for i in range(path_points.size() - 1):
		draw_line(path_points[i], path_points[i + 1], belt_color, 26.0, true)

	if path_points.size() == 3:
		draw_circle(Vector2.ZERO, 13.0, belt_color)

	_draw_motion_arrows(path_points)
	_draw_edge_clips(path_points)


func _get_path_points() -> Array[Vector2]:
	var input_point: Vector2 = _direction_to_edge(input_direction)
	var output_point: Vector2 = _direction_to_edge(facing)

	if input_direction == -facing:
		return [input_point, output_point]

	return [input_point, Vector2.ZERO, output_point]


func _draw_motion_arrows(path_points: Array[Vector2]) -> void:
	if path_points.size() < 2:
		return

	for i in range(path_points.size() - 1):
		var start: Vector2 = path_points[i]
		var end: Vector2 = path_points[i + 1]
		var direction: Vector2 = (end - start).normalized()
		var center: Vector2 = start.lerp(end, 0.58)
		var side: Vector2 = Vector2(-direction.y, direction.x)
		var arrow := PackedVector2Array([
			center + direction * 9.0,
			center - direction * 8.0 + side * 7.0,
			center - direction * 8.0 - side * 7.0,
		])
		draw_colored_polygon(arrow, arrow_color)


func _draw_edge_clips(path_points: Array[Vector2]) -> void:
	if path_points.is_empty():
		return

	var clip_color := Color(0.78, 0.82, 0.86, 1.0)
	for point in path_points:
		if point == Vector2.ZERO:
			continue

		var outward: Vector2 = point.normalized()
		var tangent: Vector2 = Vector2(-outward.y, outward.x)
		var clip_center: Vector2 = point - outward * 7.0
		var clip_points := PackedVector2Array([
			clip_center - tangent * 8.0 - outward * 3.0,
			clip_center + tangent * 8.0 - outward * 3.0,
			clip_center + tangent * 8.0 + outward * 3.0,
			clip_center - tangent * 8.0 + outward * 3.0,
		])
		draw_colored_polygon(clip_points, clip_color)


func _direction_to_edge(direction: Vector2i) -> Vector2:
	return Vector2(direction) * 32.0


func _normalize_cardinal(direction: Vector2i, fallback: Vector2i) -> Vector2i:
	if direction == Vector2i.ZERO:
		return fallback

	if absi(direction.x) >= absi(direction.y):
		return Vector2i.RIGHT if direction.x > 0 else Vector2i.LEFT

	return Vector2i.DOWN if direction.y > 0 else Vector2i.UP
