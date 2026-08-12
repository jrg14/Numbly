extends Node2D

const SOURCE_2_SCENE := preload("res://gameplay/buildings/source/source_2_building.tscn")
const SOURCE_3_SCENE := preload("res://gameplay/buildings/source/source_3_building.tscn")
const OUTPUT_5_SCENE := preload("res://gameplay/buildings/output/output_5_building.tscn")

@onready var grid_manager: GridManager = $GridManager
@onready var buildings_root: Node2D = $Buildings
@onready var placement_controller: PlacementController = $PlacementController
@onready var simulation_manager: SimulationManager = $SimulationManager
@onready var play_pause_button: Button = $UI/Controls/PlayPauseButton
@onready var tick_label: Label = $UI/Controls/TickLabel
@onready var selected_label: Label = $UI/Controls/SelectedLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var objective_label: Label = $UI/ObjectiveLabel


func _ready() -> void:
	_setup_level_001()

	play_pause_button.pressed.connect(_on_play_pause_pressed)
	$UI/Controls/Source2Button.pressed.connect(func() -> void: placement_controller.select_building_index(0))
	$UI/Controls/Source3Button.pressed.connect(func() -> void: placement_controller.select_building_index(1))
	$UI/Controls/ConveyorButton.pressed.connect(func() -> void: placement_controller.select_building_index(2))
	$UI/Controls/AdditionButton.pressed.connect(func() -> void: placement_controller.select_building_index(3))
	$UI/Controls/OutputButton.pressed.connect(func() -> void: placement_controller.select_building_index(4))
	$UI/Controls/RotateButton.pressed.connect(placement_controller.rotate_clockwise)

	placement_controller.selected_building_changed.connect(_on_selected_building_changed)
	simulation_manager.simulation_started.connect(_refresh_play_pause_label)
	simulation_manager.simulation_paused.connect(_refresh_play_pause_label)
	simulation_manager.simulation_tick_completed.connect(_on_simulation_tick_completed)
	simulation_manager.packet_transferred.connect(_on_packet_transferred)
	simulation_manager.packet_blocked.connect(_on_packet_blocked)
	simulation_manager.output_target_reached.connect(_on_output_target_reached)

	objective_label.text = "Objective: produce 5 from sources 2 and 3"
	status_label.text = "Place conveyors and Addition, then press Play."
	_refresh_play_pause_label()
	_on_selected_building_changed(placement_controller.selected_building_index, null)
	_on_simulation_tick_completed(simulation_manager.tick_index, 0.0)


func _on_play_pause_pressed() -> void:
	simulation_manager.toggle_play_pause()


func _refresh_play_pause_label() -> void:
	play_pause_button.text = "Pause" if simulation_manager.is_running else "Play"


func _on_selected_building_changed(index: int, _scene: PackedScene) -> void:
	var names := ["Source 2", "Source 3", "Conveyor", "Addition", "Output 5"]
	selected_label.text = "Selected: %s" % names[index] if index >= 0 and index < names.size() else "Selected: None"


func _on_simulation_tick_completed(tick: int, _tick_delta: float) -> void:
	tick_label.text = "Tick: %d" % tick


func _setup_level_001() -> void:
	_place_fixed_piece(SOURCE_2_SCENE, Vector2i(0, 2))
	_place_fixed_piece(SOURCE_3_SCENE, Vector2i(0, 4))
	_place_fixed_piece(OUTPUT_5_SCENE, Vector2i(7, 3))


func _place_fixed_piece(scene: PackedScene, cell: Vector2i) -> void:
	if not grid_manager.can_place_piece(cell):
		return

	var piece := scene.instantiate() as Node2D
	grid_manager.place_piece(piece, cell, buildings_root)


func _on_packet_transferred(packet: NumberPacket, from_building: Building, to_building: Building) -> void:
	status_label.text = "Packet %d: %s -> %s" % [packet.value, from_building.name, to_building.name]


func _on_packet_blocked(packet: NumberPacket, from_building: Building, target_cell: Vector2i) -> void:
	status_label.text = "Packet %d blocked from %s at %s" % [packet.value, from_building.name, target_cell]


func _on_output_target_reached(_output: OutputBuilding, total_accepted: int) -> void:
	status_label.text = "Objective complete: output received %d valid packet(s)." % total_accepted
	simulation_manager.pause()
