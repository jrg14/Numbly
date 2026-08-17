extends Resource
class_name BuildingData

enum BuildingType {
	SOURCE,
	CONVEYOR,
	OUTPUT,
	ADDITION,
	MULTIPLICATION,
	SUBTRACTION,
	DIVISION,
	MODULO,
	SPLITTER,
	BUFFER,
	MERGER,
	FILTER,
	GATE,
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var building_type: BuildingType = BuildingType.SOURCE
@export var scene: PackedScene
@export var icon: Texture2D
@export var cost: int = 0
@export var input_count: int = 0
@export var output_count: int = 0
@export var tick_interval: float = 1.0
@export var placeable: bool = true
