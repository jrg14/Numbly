extends Node2D

@export var current_level: LevelData

@onready var grid_manager: GridManager = $GridManager
@onready var buildings_root: Node2D = $Buildings
@onready var level_controller: LevelController = $LevelController
@onready var placement_controller: PlacementController = $PlacementController
@onready var simulation_manager: SimulationManager = $SimulationManager
@onready var play_pause_button: Button = $UI/Controls/PlayPauseButton
@onready var undo_button: Button = $UI/Controls/UndoButton
@onready var redo_button: Button = $UI/Controls/RedoButton
@onready var reset_button: Button = $UI/Controls/ResetButton
@onready var tick_label: Label = $UI/Controls/TickLabel
@onready var selected_label: Label = $UI/Controls/SelectedLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var objective_label: Label = $UI/ObjectiveLabel

var build_buttons: Array[Button] = []
var _level_completed: bool = false


func _ready() -> void:
	build_buttons = [
		$UI/Controls/BuildButton1,
		$UI/Controls/BuildButton2,
		$UI/Controls/BuildButton3,
		$UI/Controls/BuildButton4,
		$UI/Controls/BuildButton5,
	]

	play_pause_button.pressed.connect(_on_play_pause_pressed)
	undo_button.pressed.connect(placement_controller.undo)
	redo_button.pressed.connect(placement_controller.redo)
	reset_button.pressed.connect(reset_level)
	$UI/Controls/RotateButton.pressed.connect(placement_controller.rotate_clockwise)

	for i in range(build_buttons.size()):
		build_buttons[i].pressed.connect(_on_build_button_pressed.bind(i))

	level_controller.level_loaded.connect(_on_level_loaded)
	level_controller.level_load_failed.connect(_on_level_load_failed)
	placement_controller.selected_building_changed.connect(_on_selected_building_changed)
	placement_controller.placement_failed.connect(_on_placement_failed)
	placement_controller.history_changed.connect(_on_history_changed)
	placement_controller.layout_changed.connect(_on_layout_changed)
	simulation_manager.simulation_started.connect(_refresh_play_pause_label)
	simulation_manager.simulation_paused.connect(_refresh_play_pause_label)
	simulation_manager.simulation_tick_completed.connect(_on_simulation_tick_completed)
	simulation_manager.packet_transferred.connect(_on_packet_transferred)
	simulation_manager.packet_blocked.connect(_on_packet_blocked)
	simulation_manager.output_target_reached.connect(_on_output_target_reached)
	simulation_manager.connection_error.connect(_on_connection_error)

	reset_level()
	_refresh_play_pause_label()
	_on_simulation_tick_completed(simulation_manager.tick_index, 0.0)
	_on_history_changed(false, false)


func _on_play_pause_pressed() -> void:
	simulation_manager.toggle_play_pause()


func _on_build_button_pressed(index: int) -> void:
	placement_controller.select_building_index(index)


func _refresh_play_pause_label() -> void:
	play_pause_button.text = "Pause" if simulation_manager.is_running else "Play"


func _on_selected_building_changed(index: int, _scene: PackedScene) -> void:
	var available_buildings := level_controller.get_available_buildings()
	if index < 0 or index >= available_buildings.size():
		selected_label.text = "Selected: None"
		return

	selected_label.text = "Selected: %s" % available_buildings[index].display_name


func _on_simulation_tick_completed(tick: int, _tick_delta: float) -> void:
	tick_label.text = "Tick: %d" % tick

	if _level_completed or current_level == null or current_level.max_ticks <= 0:
		return

	if tick >= current_level.max_ticks:
		simulation_manager.pause()
		status_label.text = "Tick limit reached. Reset or improve the layout."


func reset_level() -> void:
	_level_completed = false
	simulation_manager.reset()
	placement_controller.clear_history()

	if not level_controller.load_level(current_level, grid_manager, buildings_root):
		return

	simulation_manager.reset_simulation_state()
	status_label.text = "Place buildings, then press Play."


func _on_packet_transferred(packet: NumberPacket, from_building: Building, to_building: Building) -> void:
	status_label.text = "Packet %d: %s -> %s" % [packet.value, from_building.name, to_building.name]


func _on_packet_blocked(packet: NumberPacket, from_building: Building, target_cell: Vector2i) -> void:
	status_label.text = "Packet %d blocked from %s at %s" % [packet.value, from_building.name, target_cell]


func _on_output_target_reached(_output: OutputBuilding, total_accepted: int) -> void:
	_level_completed = true
	status_label.text = "Objective complete: output received %d valid packet(s). Stars: %d" % [total_accepted, _calculate_stars()]
	simulation_manager.pause()


func _on_connection_error(message: String) -> void:
	status_label.text = message


func _on_placement_failed(cell: Vector2i) -> void:
	status_label.text = "Cannot place or remove at %s." % cell


func _on_layout_changed() -> void:
	_level_completed = false
	simulation_manager.reset()
	status_label.text = "Layout changed. Simulation reset."


func _on_level_loaded(level_data: LevelData) -> void:
	objective_label.text = level_data.objective_text
	placement_controller.max_placed_buildings = level_data.max_buildings
	placement_controller.set_available_buildings(level_data.allowed_buildings)
	_refresh_build_buttons(level_data.allowed_buildings)


func _on_level_load_failed(message: String) -> void:
	objective_label.text = "Level load failed"
	status_label.text = message


func _on_history_changed(can_undo: bool, can_redo: bool) -> void:
	undo_button.disabled = not can_undo
	redo_button.disabled = not can_redo


func _refresh_build_buttons(available_buildings: Array[BuildingData]) -> void:
	for i in range(build_buttons.size()):
		var button := build_buttons[i]
		var has_building := i < available_buildings.size() and available_buildings[i] != null
		button.visible = has_building
		button.disabled = not has_building

		if has_building:
			button.text = available_buildings[i].display_name


func _calculate_stars() -> int:
	if current_level == null:
		return 0

	var earned_stars := 0
	var placed_buildings := level_controller.get_player_building_count(buildings_root)

	for star_condition in current_level.star_conditions:
		if star_condition == null:
			continue

		match star_condition.condition_type:
			StarConditionData.ConditionType.COMPLETE_LEVEL:
				earned_stars = maxi(earned_stars, star_condition.stars)
			StarConditionData.ConditionType.MAX_BUILDINGS:
				if placed_buildings <= star_condition.limit:
					earned_stars = maxi(earned_stars, star_condition.stars)
			StarConditionData.ConditionType.MAX_TICKS:
				if simulation_manager.tick_index <= star_condition.limit:
					earned_stars = maxi(earned_stars, star_condition.stars)

	return earned_stars
