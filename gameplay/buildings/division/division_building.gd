extends ArithmeticOperatorBuilding
class_name DivisionBuilding


func _ready() -> void:
	operator_symbol = "/"


func _calculate_result(input_values: Array[int]) -> int:
	if input_values.is_empty():
		return 0

	var result := input_values[0]
	for i in range(1, input_values.size()):
		result = int(result / input_values[i])
	return result


func _can_accept_value_for_lane(value: int, lane_index: int) -> bool:
	return lane_index == 0 or value != 0


func _get_output_source_id() -> StringName:
	return &"division"
