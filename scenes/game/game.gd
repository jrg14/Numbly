extends Node2D

@export var current_level: LevelData

@onready var grid_manager: GridManager = $GridManager
@onready var buildings_root: Node2D = $Buildings
@onready var packet_visualizer: PacketVisualizer = $PacketVisuals
@onready var level_controller: LevelController = $LevelController
@onready var placement_controller: PlacementController = $PlacementController
@onready var simulation_manager: SimulationManager = $SimulationManager
@onready var play_pause_button: Button = $UI/Controls/PlayPauseButton
@onready var menu_button: Button = $UI/Controls/MenuButton
@onready var undo_button: Button = $UI/Controls/UndoButton
@onready var redo_button: Button = $UI/Controls/RedoButton
@onready var reset_button: Button = $UI/Controls/ResetButton
@onready var tick_label: Label = $UI/Controls/TickLabel
@onready var selected_label: Label = $UI/Controls/SelectedLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var objective_label: Label = $UI/ObjectiveLabel
@onready var completion_overlay: Control = $UI/CompletionOverlay
@onready var completion_medal_label: Label = $UI/CompletionOverlay/Center/Card/Margin/Layout/MedalLabel
@onready var completion_stats_label: Label = $UI/CompletionOverlay/Center/Card/Margin/Layout/StatsLabel
@onready var retry_button: Button = $UI/CompletionOverlay/Center/Card/Margin/Layout/Buttons/RetryButton
@onready var main_menu_button: Button = $UI/CompletionOverlay/Center/Card/Margin/Layout/Buttons/MainMenuButton

var build_buttons: Array[Button] = []
var _level_completed: bool = false


func _ready() -> void:
	current_level = GameState.get_selected_level()

	build_buttons = [
		$UI/Controls/BuildButton1,
		$UI/Controls/BuildButton2,
		$UI/Controls/BuildButton3,
		$UI/Controls/BuildButton4,
		$UI/Controls/BuildButton5,
	]

	play_pause_button.pressed.connect(_on_play_pause_pressed)
	menu_button.pressed.connect(Callable(SceneRouter, "go_to_main_menu"))
	undo_button.pressed.connect(placement_controller.undo)
	redo_button.pressed.connect(placement_controller.redo)
	reset_button.pressed.connect(reset_level)
	retry_button.pressed.connect(reset_level)
	main_menu_button.pressed.connect(Callable(SceneRouter, "go_to_main_menu"))
	$UI/Controls/RotateButton.pressed.connect(placement_controller.rotate_clockwise)

	for i in range(build_buttons.size()):
		build_buttons[i].pressed.connect(_on_build_button_pressed.bind(i))

	level_controller.level_loaded.connect(_on_level_loaded)
	level_controller.level_load_failed.connect(_on_level_load_failed)
	level_controller.level_completed.connect(_on_level_completed)
	level_controller.level_failed.connect(_on_level_failed)
	level_controller.objectives_changed.connect(_on_objectives_changed)
	placement_controller.selected_building_changed.connect(_on_selected_building_changed)
	placement_controller.placement_failed.connect(_on_placement_failed)
	placement_controller.history_changed.connect(_on_history_changed)
	placement_controller.layout_changed.connect(_on_layout_changed)
	simulation_manager.simulation_started.connect(_refresh_play_pause_label)
	simulation_manager.simulation_paused.connect(_refresh_play_pause_label)
	simulation_manager.simulation_tick_completed.connect(_on_simulation_tick_completed)
	simulation_manager.packet_transferred.connect(_on_packet_transferred)
	simulation_manager.packet_blocked.connect(_on_packet_blocked)
	simulation_manager.output_packet_consumed.connect(_on_output_packet_consumed)
	simulation_manager.connection_error.connect(_on_connection_error)
	simulation_manager.addition_sum_created.connect(_on_addition_sum_created)

	reset_level()
	_refresh_play_pause_label()
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
	level_controller.record_tick(tick, _tick_delta, buildings_root)


func reset_level() -> void:
	_level_completed = false
	_hide_completion_overlay()
	packet_visualizer.clear_visuals()
	simulation_manager.reset()
	placement_controller.clear_history()

	if not level_controller.load_level(current_level, grid_manager, buildings_root):
		return

	level_controller.refresh_layout_metrics(buildings_root)
	simulation_manager.reset_simulation_state()
	placement_controller.refresh_conveyor_routes()
	var medal_summary := level_controller.get_medal_summary()
	if medal_summary.is_empty():
		status_label.text = "Coloca edificios y pulsa Play."
	else:
		status_label.text = "Coloca edificios y pulsa Play. Medallas: %s" % medal_summary


func _on_packet_transferred(packet: NumberPacket, from_building: Building, to_building: Building) -> void:
	packet_visualizer.show_transfer(packet, from_building, to_building)
	status_label.text = "Packet %d: %s -> %s" % [packet.value, from_building.name, to_building.name]


func _on_packet_blocked(packet: NumberPacket, from_building: Building, target_cell: Vector2i) -> void:
	packet_visualizer.show_blocked(packet, from_building, grid_manager.grid_to_world(target_cell))
	status_label.text = "Packet %d blocked from %s at %s" % [packet.value, from_building.name, target_cell]


func _on_output_packet_consumed(packet: NumberPacket, _output: OutputBuilding, matched_target: bool) -> void:
	packet_visualizer.show_output_received(packet, _output, matched_target)
	level_controller.record_output_packet(packet, matched_target, buildings_root)


func _on_addition_sum_created(addition: AdditionBuilding, input_values: Array[int], result: int) -> void:
	packet_visualizer.show_addition(addition, input_values, result)


func _on_level_completed(result: LevelResult) -> void:
	if _level_completed:
		return

	_level_completed = true
	SaveManager.record_level_result(current_level.id, result)
	status_label.text = "Nivel completado. Medalla: %s | Ticks: %d | Maquinas: %d" % [
		LevelMedalData.get_medal_name(result.medal),
		result.tick_count,
		result.placed_buildings,
	]
	simulation_manager.pause()
	_show_completion_overlay(result)


func _on_level_failed(message: String) -> void:
	if _level_completed:
		return

	simulation_manager.pause()
	status_label.text = "Objective failed: %s" % message


func _on_connection_error(message: String) -> void:
	status_label.text = message


func _on_placement_failed(cell: Vector2i) -> void:
	status_label.text = "Cannot place or remove at %s." % cell


func _on_layout_changed() -> void:
	_level_completed = false
	simulation_manager.reset()
	level_controller.refresh_layout_metrics(buildings_root)
	status_label.text = "Layout changed. Simulation reset."


func _on_level_loaded(level_data: LevelData) -> void:
	objective_label.text = level_data.objective_text
	placement_controller.max_placed_buildings = level_data.max_buildings
	placement_controller.set_available_buildings(level_data.allowed_buildings)
	_refresh_build_buttons(level_data.allowed_buildings)

	var medal_summary := level_controller.get_medal_summary()
	if not medal_summary.is_empty():
		status_label.text = "Medallas: %s" % medal_summary


func _on_level_load_failed(message: String) -> void:
	objective_label.text = "Level load failed"
	status_label.text = message


func _on_objectives_changed(summary: String) -> void:
	objective_label.text = summary


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


func _show_completion_overlay(result: LevelResult) -> void:
	placement_controller.input_enabled = false
	completion_medal_label.text = LevelMedalData.get_medal_name(result.medal)
	completion_stats_label.text = "Ticks: %d | Maquinas: %d" % [
		result.tick_count,
		result.placed_buildings,
	]
	completion_overlay.visible = true


func _hide_completion_overlay() -> void:
	completion_overlay.visible = false
	placement_controller.input_enabled = true
