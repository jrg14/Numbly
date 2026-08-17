extends ArithmeticOperatorBuilding
class_name SubtractionBuilding


func _ready() -> void:
	operator_symbol = "-"


func _calculate_result(input_values: Array[int]) -> int:
	if input_values.is_empty():
		return 0

	var result := input_values[0]
	for i in range(1, input_values.size()):
		result -= input_values[i]
	return result


func _get_output_source_id() -> StringName:
	return &"subtraction"
