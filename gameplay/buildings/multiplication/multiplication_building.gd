extends ArithmeticOperatorBuilding
class_name MultiplicationBuilding


func _ready() -> void:
	operator_symbol = "x"


func _calculate_result(input_values: Array[int]) -> int:
	if input_values.is_empty():
		return 0

	var result := 1
	for value in input_values:
		result *= value
	return result


func _get_output_source_id() -> StringName:
	return &"multiplication"
