extends Building
class_name ConveyorBuilding

@export var travel_time: float = 0.25
@export_range(1, 12, 1) var max_packet_capacity: int = 4
@export var input_direction: Vector2i = Vector2i.LEFT:
	set(value):
		input_direction = _normalize_cardinal(value, Vector2i.LEFT)
		queue_redraw()

@export var belt_color: Color = Color(0.13, 0.15, 0.15, 1.0)
@export var belt_edge_color: Color = Color(0.98, 0.58, 0.12, 1.0)
@export var belt_shadow_color: Color = Color(0.05, 0.06, 0.06, 1.0)
@export var flow_mark_color: Color = Color(1.0, 0.84, 0.34, 0.9)
@export var packet_color: Color = Color(0.95, 0.96, 0.78, 1.0)
@export var connected_input_color: Color = Color(0.2, 0.72, 1.0, 0.95)
@export var connected_output_color: Color = Color(0.24, 0.94, 0.48, 0.95)
@export var open_port_color: Color = Color(0.78, 0.82, 0.86, 0.72)
@export var blocked_color: Color = Color(1.0, 0.27, 0.2, 0.95)

var _queued_packets: Array[Dictionary] = []
var _flow_phase: float = 0.0
var _has_connected_input: bool = false
var _has_connected_output: bool = false


func apply_building_data(data: BuildingData) -> void:
	super.apply_building_data(data)
	if building_data != null:
		travel_time = maxf(building_data.tick_interval, 0.0)


func _process(delta: float) -> void:
	_flow_phase = fmod(_flow_phase + delta * 58.0, 18.0)
	queue_redraw()


func can_accept_packet(_packet: NumberPacket) -> bool:
	return _queued_packets.size() < max_packet_capacity


func can_accept_packet_from(packet: NumberPacket, from_building: Building) -> bool:
	if from_building == null:
		return can_accept_packet(packet)

	var incoming_direction := _get_incoming_direction(from_building)
	return can_accept_packet(packet) and incoming_direction != facing


func can_accept_packet_from_cell(packet: NumberPacket, from_building: Building, target_cell: Vector2i) -> bool:
	if from_building == null:
		return can_accept_packet(packet)

	var incoming_direction := _get_incoming_direction(from_building, target_cell)
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


func set_connection_state(has_input: bool, has_output: bool) -> void:
	_has_connected_input = has_input
	_has_connected_output = has_output
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

	_draw_flow_marks(path_points)
	_draw_capacity_meter()
	_draw_queued_packets(path_points)
	_draw_port_markers(path_points)


func _get_path_points() -> Array[Vector2]:
	var input_point: Vector2 = _direction_to_edge(input_direction)
	var output_point: Vector2 = _direction_to_edge(facing)

	if input_direction == -facing:
		return [input_point, output_point]

	return [input_point, Vector2.ZERO, output_point]


func _draw_flow_marks(path_points: Array[Vector2]) -> void:
	for i in range(path_points.size() - 1):
		var start: Vector2 = path_points[i]
		var end: Vector2 = path_points[i + 1]
		var segment := end - start
		var segment_length := segment.length()
		if segment_length <= 0.01:
			continue

		var direction := segment / segment_length
		var side := Vector2(-direction.y, direction.x)
		var distance := 8.0 + _flow_phase
		while distance < segment_length - 5.0:
			var center := start + direction * distance
			var mark := PackedVector2Array([
				center + direction * 5.5,
				center + side * 4.0,
				center - direction * 5.5,
				center - side * 4.0,
			])
			draw_colored_polygon(mark, flow_mark_color)
			distance += 18.0


func _draw_capacity_meter() -> void:
	if max_packet_capacity <= 1:
		return

	var fill_ratio := clampf(float(_queued_packets.size()) / float(max_packet_capacity), 0.0, 1.0)
	var track := Rect2(Vector2(-24.0, 23.0), Vector2(48.0, 4.0))
	var fill := Rect2(track.position, Vector2(track.size.x * fill_ratio, track.size.y))
	var color := blocked_color if _queued_packets.size() >= max_packet_capacity else connected_output_color
	draw_rect(track, Color(0.02, 0.025, 0.03, 0.5), true)
	draw_rect(fill, color, true)


func _draw_queued_packets(path_points: Array[Vector2]) -> void:
	var safe_travel_time := maxf(travel_time, 0.001)
	for queued_packet in _queued_packets:
		var packet := queued_packet.get("packet") as NumberPacket
		if packet == null:
			continue

		var remaining_time: float = queued_packet.get("remaining_time", safe_travel_time)
		var progress := clampf(1.0 - remaining_time / safe_travel_time, 0.06, 0.94)
		var position := _sample_path(path_points, progress)
		_draw_packet_badge(position, str(packet.value))


func _draw_packet_badge(position: Vector2, text: String) -> void:
	draw_circle(position + Vector2(1.5, 2.0), 12.0, Color(0.02, 0.025, 0.03, 0.72))
	draw_circle(position, 12.0, packet_color)
	draw_arc(position, 12.0, 0.0, TAU, 18, Color(0.05, 0.06, 0.06, 0.9), 2.0)

	var font := ThemeDB.fallback_font
	if font == null:
		return

	var font_size := 13
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := position + Vector2(-text_width * 0.5, 4.5)
	draw_string(font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, Color(0.06, 0.07, 0.08, 1.0))


func _draw_port_markers(path_points: Array[Vector2]) -> void:
	if path_points.is_empty():
		return

	_draw_port_marker(path_points.front(), input_direction, _has_connected_input, true)
	_draw_port_marker(path_points.back(), facing, _has_connected_output, false)


func _draw_port_marker(point: Vector2, direction: Vector2i, connected: bool, is_input: bool) -> void:
	if point == Vector2.ZERO:
		return

	var outward: Vector2 = Vector2(direction).normalized()
	var tangent := Vector2(-outward.y, outward.x)
	var center := point - outward * 7.0
	var color := connected_input_color if is_input else connected_output_color
	if not connected:
		color = open_port_color
	if _queued_packets.size() >= max_packet_capacity and is_input:
		color = blocked_color

	var points := PackedVector2Array([
		center - tangent * 8.0 - outward * 3.0,
		center + tangent * 8.0 - outward * 3.0,
		center + tangent * 8.0 + outward * 3.0,
		center - tangent * 8.0 + outward * 3.0,
	])
	draw_colored_polygon(points, color)


func _sample_path(path_points: Array[Vector2], progress: float) -> Vector2:
	if path_points.size() == 0:
		return Vector2.ZERO
	if path_points.size() == 1:
		return path_points[0]

	var total_length := 0.0
	for i in range(path_points.size() - 1):
		total_length += path_points[i].distance_to(path_points[i + 1])

	if total_length <= 0.01:
		return path_points.back()

	var target_distance := clampf(progress, 0.0, 1.0) * total_length
	for i in range(path_points.size() - 1):
		var start: Vector2 = path_points[i]
		var end: Vector2 = path_points[i + 1]
		var segment_length := start.distance_to(end)
		if target_distance <= segment_length:
			return start.lerp(end, target_distance / segment_length)

		target_distance -= segment_length

	return path_points.back()


func _direction_to_edge(direction: Vector2i) -> Vector2:
	return Vector2(direction) * 32.0


func _normalize_cardinal(direction: Vector2i, fallback: Vector2i) -> Vector2i:
	if direction == Vector2i.ZERO:
		return fallback

	if absi(direction.x) >= absi(direction.y):
		return Vector2i.RIGHT if direction.x > 0 else Vector2i.LEFT

	return Vector2i.DOWN if direction.y > 0 else Vector2i.UP


func _get_incoming_direction(from_building: Building, target_cell: Vector2i = Vector2i(-9999, -9999)) -> Vector2i:
	if target_cell.x < -9000:
		target_cell = grid_position

	var origin_cell := from_building.get_nearest_occupied_cell_to(target_cell)
	return _normalize_cardinal(origin_cell - target_cell, input_direction)
