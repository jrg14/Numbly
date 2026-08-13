extends Node2D
class_name PacketVisualizer

@export var transfer_duration: float = 0.18
@export var blocked_duration: float = 0.28
@export var popup_duration: float = 0.65
@export var number_size: Vector2 = Vector2(48, 34)


func clear_visuals() -> void:
	for child in get_children():
		child.queue_free()


func show_transfer(packet: NumberPacket, from_building: Building, to_building: Building) -> void:
	if packet == null or from_building == null or to_building == null:
		return

	var start_position: Vector2 = from_building.global_position + Vector2(from_building.facing) * 18.0
	var end_position: Vector2 = to_building.global_position
	var label := _create_number_label(str(packet.value), Color(0.96, 0.96, 0.78, 1.0), 26)
	_set_label_center(label, start_position)

	var tween := create_tween()
	tween.tween_property(label, "position", _center_to_label_position(label, end_position), transfer_duration)
	tween.parallel().tween_property(label, "scale", Vector2(1.08, 1.08), transfer_duration * 0.5)
	tween.tween_property(label, "scale", Vector2.ONE, transfer_duration * 0.5)
	tween.tween_callback(Callable(label, "queue_free"))


func show_blocked(packet: NumberPacket, from_building: Building, target_position: Vector2) -> void:
	if packet == null or from_building == null:
		return

	var label := _create_number_label(str(packet.value), Color(1.0, 0.36, 0.28, 1.0), 24)
	_set_label_center(label, from_building.global_position)

	var tween := create_tween()
	tween.tween_property(label, "position", _center_to_label_position(label, target_position), blocked_duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, blocked_duration)
	tween.tween_callback(Callable(label, "queue_free"))


func show_addition(addition: AdditionBuilding, input_values: Array[int], result: int) -> void:
	if addition == null:
		return

	var parts: Array[String] = []
	for value in input_values:
		parts.append(str(value))

	var expression := "%s = %d" % [" + ".join(parts), result]
	var label := _create_number_label(expression, Color(1.0, 0.86, 0.34, 1.0), 24)
	label.custom_minimum_size = Vector2(120, 34)
	_set_label_center(label, addition.global_position + Vector2(0, -42))

	var tween := create_tween()
	tween.tween_property(label, "position", label.position + Vector2(0, -20), popup_duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, popup_duration)
	tween.tween_callback(Callable(label, "queue_free"))


func show_output_received(packet: NumberPacket, output: OutputBuilding, matched_target: bool) -> void:
	if packet == null or output == null:
		return

	var color := Color(0.54, 1.0, 0.58, 1.0) if matched_target else Color(1.0, 0.3, 0.24, 1.0)
	var text := "OK %d" % packet.value if matched_target else "NO %d" % packet.value
	var label := _create_number_label(text, color, 22)
	label.custom_minimum_size = Vector2(76, 32)
	_set_label_center(label, output.global_position + Vector2(0, -38))

	var tween := create_tween()
	tween.tween_interval(transfer_duration)
	tween.tween_property(label, "scale", Vector2(1.18, 1.18), 0.08)
	tween.tween_property(label, "position", label.position + Vector2(0, -18), popup_duration)
	tween.parallel().tween_property(label, "modulate:a", 0.0, popup_duration)
	tween.tween_callback(Callable(label, "queue_free"))


func _create_number_label(text: String, color: Color, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = number_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 100
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.04, 0.05, 0.06, 1.0))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	return label


func _set_label_center(label: Label, center_position: Vector2) -> void:
	label.position = _center_to_label_position(label, center_position)


func _center_to_label_position(label: Label, center_position: Vector2) -> Vector2:
	return center_position - label.custom_minimum_size * 0.5
