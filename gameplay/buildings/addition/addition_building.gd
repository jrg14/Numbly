extends ArithmeticOperatorBuilding
class_name AdditionBuilding

signal sum_created(addition: AdditionBuilding, input_values: Array[int], result: int)

func _ready() -> void:
	operator_symbol = "+"


func _calculate_result(input_values: Array[int]) -> int:
	var result := 0
	for value in input_values:
		result += value
	return result


func _emit_specific_operation_signal(input_values: Array[int], result: int) -> void:
	sum_created.emit(self, input_values, result)


func _get_output_source_id() -> StringName:
	return &"addition"
