extends Node2D

@export var current_level: LevelData

@onready var grid_manager: GridManager = $GridManager
@onready var buildings_root: Node2D = $Buildings
@onready var packet_visualizer: PacketVisualizer = $PacketVisuals
@onready var level_controller: LevelController = $LevelController
@onready var placement_controller: PlacementController = $PlacementController
@onready var simulation_manager: SimulationManager = $SimulationManager
@onready var controls: HBoxContainer = $UI/Controls
@onready var play_pause_button: Button = $UI/Controls/PlayPauseButton
@onready var menu_button: Button = $UI/Controls/MenuButton
@onready var undo_button: Button = $UI/Controls/UndoButton
@onready var redo_button: Button = $UI/Controls/RedoButton
@onready var reset_button: Button = $UI/Controls/ResetButton
@onready var rotate_button: Button = $UI/Controls/RotateButton
@onready var medal_progress_label: Label = $UI/MedalProgressLabel
@onready var status_label: Label = $UI/StatusLabel
@onready var completion_overlay: Control = $UI/CompletionOverlay
@onready var completion_title_label: Label = $UI/CompletionOverlay/Center/Card/Margin/Layout/TitleLabel
@onready var completion_medal_label: Label = $UI/CompletionOverlay/Center/Card/Margin/Layout/MedalLabel
@onready var completion_stats_label: Label = $UI/CompletionOverlay/Center/Card/Margin/Layout/StatsLabel
@onready var retry_button: Button = $UI/CompletionOverlay/Center/Card/Margin/Layout/Buttons/RetryButton
@onready var next_level_button: Button = $UI/CompletionOverlay/Center/Card/Margin/Layout/Buttons/NextLevelButton
@onready var main_menu_button: Button = $UI/CompletionOverlay/Center/Card/Margin/Layout/Buttons/MainMenuButton

var build_buttons: Array[Button] = []
var _level_completed: bool = false
var _build_palette_panel: PanelContainer
var _build_palette: HBoxContainer
var erase_button: Button


func _ready() -> void:
	current_level = GameState.get_selected_level()

	build_buttons = [
		$UI/Controls/BuildButton1,
		$UI/Controls/BuildButton2,
		$UI/Controls/BuildButton3,
		$UI/Controls/BuildButton4,
		$UI/Controls/BuildButton5,
	]
	_create_erase_button()
	_create_build_palette()
	$UI.move_child(completion_overlay, $UI.get_child_count() - 1)
	_configure_mobile_hud()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

	play_pause_button.pressed.connect(_on_play_pause_pressed)
	menu_button.pressed.connect(Callable(SceneRouter, "go_to_main_menu"))
	undo_button.pressed.connect(placement_controller.undo)
	redo_button.pressed.connect(placement_controller.redo)
	reset_button.pressed.connect(reset_level)
	retry_button.pressed.connect(retry_level_attempt)
	next_level_button.pressed.connect(_on_next_level_pressed)
	main_menu_button.pressed.connect(Callable(SceneRouter, "go_to_main_menu"))
	rotate_button.pressed.connect(placement_controller.rotate_clockwise)
	erase_button.toggled.connect(_on_erase_button_toggled)

	for i in range(build_buttons.size()):
		build_buttons[i].pressed.connect(_on_build_button_pressed.bind(i))

	level_controller.level_loaded.connect(_on_level_loaded)
	level_controller.level_load_failed.connect(_on_level_load_failed)
	level_controller.level_completed.connect(_on_level_completed)
	level_controller.level_failed.connect(_on_level_failed)
	placement_controller.placement_failed.connect(_on_placement_failed)
	placement_controller.erase_mode_changed.connect(_on_erase_mode_changed)
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
	simulation_manager.arithmetic_operation_created.connect(_on_arithmetic_operation_created)

	reset_level()
	_refresh_play_pause_label()
	_on_history_changed(false, false)


func _on_play_pause_pressed() -> void:
	simulation_manager.toggle_play_pause()


func _on_build_button_pressed(index: int) -> void:
	placement_controller.select_building_index(index)


func _refresh_play_pause_label() -> void:
	play_pause_button.text = "Pause" if simulation_manager.is_running else "Play"


func _on_simulation_tick_completed(tick: int, tick_delta: float) -> void:
	level_controller.record_tick(tick, tick_delta, buildings_root)
	_refresh_medal_progress()


func reset_level() -> void:
	_level_completed = false
	_hide_completion_overlay()
	packet_visualizer.clear_visuals()
	simulation_manager.reset()
	placement_controller.clear_history()
	placement_controller.set_erase_mode(false)
	if current_level != null:
		_fit_board_to_viewport(current_level.grid_size)

	if not level_controller.load_level(current_level, grid_manager, buildings_root):
		return

	level_controller.refresh_layout_metrics(buildings_root)
	simulation_manager.reset_simulation_state()
	placement_controller.refresh_conveyor_routes()
	_refresh_medal_progress()
	var medal_summary := level_controller.get_medal_summary()
	if medal_summary.is_empty():
		status_label.text = "Coloca edificios y pulsa Play."
	else:
		status_label.text = "Coloca edificios y pulsa Play. Medallas: %s" % medal_summary


func retry_level_attempt() -> void:
	_level_completed = false
	_hide_completion_overlay()
	packet_visualizer.clear_visuals()
	simulation_manager.reset()
	level_controller.reset_attempt_metrics(buildings_root)
	placement_controller.set_erase_mode(false)
	placement_controller.refresh_conveyor_routes()
	_refresh_medal_progress()
	status_label.text = "Intento reiniciado. Tu construccion se mantiene."


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


func _on_arithmetic_operation_created(building: Building, input_values: Array[int], result: int, operator_symbol: String) -> void:
	packet_visualizer.show_operation(building, input_values, result, operator_symbol)


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
	_show_result_overlay("Nivel completado", LevelMedalData.get_medal_name(result.medal), result)


func _on_level_failed(message: String) -> void:
	if _level_completed:
		return

	_level_completed = true
	simulation_manager.pause()
	status_label.text = "Objective failed: %s" % message
	_show_result_overlay("Nivel fallido", "Sin completar", null)


func _on_connection_error(message: String) -> void:
	status_label.text = message


func _on_placement_failed(cell: Vector2i) -> void:
	status_label.text = "Cannot place or remove at %s." % cell


func _on_layout_changed() -> void:
	_level_completed = false
	simulation_manager.reset()
	level_controller.refresh_layout_metrics(buildings_root)
	_refresh_medal_progress()
	status_label.text = "Layout changed. Simulation reset."


func _on_level_loaded(level_data: LevelData) -> void:
	_fit_board_to_viewport(level_data.grid_size)
	_refresh_building_positions()
	placement_controller.max_placed_buildings = level_data.max_buildings
	placement_controller.set_available_buildings(level_data.allowed_buildings)
	_refresh_build_buttons(level_data.allowed_buildings)
	_refresh_medal_progress()

	var medal_summary := level_controller.get_medal_summary()
	if not medal_summary.is_empty():
		status_label.text = "Medallas: %s" % medal_summary


func _on_level_load_failed(message: String) -> void:
	status_label.text = message


func _on_history_changed(can_undo: bool, can_redo: bool) -> void:
	undo_button.disabled = not can_undo
	redo_button.disabled = not can_redo


func _refresh_build_buttons(available_buildings: Array[BuildingData]) -> void:
	_ensure_build_button_count(available_buildings.size())

	for i in range(build_buttons.size()):
		var button := build_buttons[i]
		_apply_mobile_button_style(button, Vector2(168, 60), 19)
		var has_building := i < available_buildings.size() and available_buildings[i] != null
		button.visible = has_building
		button.disabled = not has_building

		if has_building:
			button.text = "%d %s" % [i + 1, available_buildings[i].display_name]
			button.tooltip_text = available_buildings[i].description


func _ensure_build_button_count(count: int) -> void:
	while build_buttons.size() < count:
		var button := Button.new()
		button.name = "BuildButton%d" % (build_buttons.size() + 1)
		_apply_mobile_button_style(button, Vector2(168, 60), 19)
		button.layout_mode = 2
		_build_palette.add_child(button)
		button.pressed.connect(_on_build_button_pressed.bind(build_buttons.size()))
		build_buttons.append(button)


func _create_build_palette() -> void:
	_build_palette_panel = PanelContainer.new()
	_build_palette_panel.name = "BuildPalettePanel"
	_build_palette_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	$UI.add_child(_build_palette_panel)

	var margin := MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_build_palette_panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.horizontal_scroll_mode = 1
	scroll.vertical_scroll_mode = 0
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)

	_build_palette = HBoxContainer.new()
	_build_palette.name = "BuildPalette"
	_build_palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_palette.alignment = BoxContainer.ALIGNMENT_CENTER
	_build_palette.add_theme_constant_override("h_separation", 8)
	scroll.add_child(_build_palette)

	for button in build_buttons:
		_apply_mobile_button_style(button, Vector2(168, 60), 19)
		button.reparent(_build_palette)


func _create_erase_button() -> void:
	erase_button = Button.new()
	erase_button.name = "EraseButton"
	_apply_mobile_button_style(erase_button, Vector2(92, 56), 18)
	erase_button.toggle_mode = true
	erase_button.text = "Borrar"
	controls.add_child(erase_button)
	controls.move_child(erase_button, rotate_button.get_index())


func _configure_mobile_hud() -> void:
	var viewport_size := get_viewport_rect().size
	var side_margin := 10.0
	var top_margin := 10.0
	var control_height := 56.0
	var palette_height := 96.0

	controls.offset_left = side_margin
	controls.offset_top = top_margin
	controls.offset_right = viewport_size.x - side_margin
	controls.offset_bottom = top_margin + control_height
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 8)

	for button in [play_pause_button, menu_button, undo_button, redo_button, reset_button, erase_button, rotate_button]:
		if button != null:
			_apply_mobile_button_style(button, Vector2(92, control_height), 18)

	for button in build_buttons:
		_apply_mobile_button_style(button, Vector2(168, 60), 19)

	medal_progress_label.offset_left = side_margin
	medal_progress_label.offset_top = top_margin + control_height + 8.0
	medal_progress_label.offset_right = viewport_size.x - side_margin
	medal_progress_label.offset_bottom = top_margin + control_height + 36.0
	medal_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	medal_progress_label.add_theme_font_size_override("font_size", 21)
	_refresh_medal_progress()

	status_label.visible = false

	if _build_palette_panel != null:
		_build_palette_panel.offset_left = side_margin
		_build_palette_panel.offset_top = viewport_size.y - palette_height
		_build_palette_panel.offset_right = viewport_size.x - side_margin
		_build_palette_panel.offset_bottom = viewport_size.y - 8.0

	if current_level != null:
		_fit_board_to_viewport(current_level.grid_size)
		_refresh_building_positions()


func _fit_board_to_viewport(level_grid_size: Vector2i) -> void:
	if level_grid_size.x <= 0 or level_grid_size.y <= 0:
		return

	var viewport_size := get_viewport_rect().size
	var board_top := 128.0
	var bottom_reserved := 112.0
	var side_margin := 16.0
	var available_width := maxf(viewport_size.x - side_margin * 2.0, 1.0)
	var available_height := maxf(viewport_size.y - board_top - bottom_reserved, 1.0)
	var max_cell_size := minf(
		available_width / float(level_grid_size.x),
		available_height / float(level_grid_size.y)
	)
	var cell_size_value := floorf(minf(max_cell_size, 64.0))
	cell_size_value = maxf(cell_size_value, 28.0)

	grid_manager.cell_size = Vector2(cell_size_value, cell_size_value)

	var board_size := Vector2(float(level_grid_size.x), float(level_grid_size.y)) * cell_size_value
	grid_manager.position = Vector2(
		maxf(side_margin, (viewport_size.x - board_size.x) * 0.5),
		board_top
	)

	if placement_controller != null:
		var preview := get_node_or_null("PlacementPreview") as PlacementPreview
		if preview != null:
			preview.cell_size = grid_manager.cell_size


func _apply_mobile_button_style(button: Button, minimum_size: Vector2, font_size: int) -> void:
	button.custom_minimum_size = minimum_size
	button.add_theme_font_size_override("font_size", font_size)


func _refresh_building_positions() -> void:
	for child in buildings_root.get_children():
		var building := child as Building
		if building != null:
			grid_manager.refresh_piece_transform(building)


func _refresh_medal_progress() -> void:
	var summary := level_controller.get_medal_progress_summary(simulation_manager.ticks_per_second)
	medal_progress_label.visible = not summary.is_empty()
	medal_progress_label.text = summary
	medal_progress_label.add_theme_color_override(
		"font_color",
		_get_medal_progress_color(level_controller.get_current_medal_target())
	)


func _get_medal_progress_color(medal: int) -> Color:
	match medal:
		LevelMedalData.Medal.GOLD:
			return Color(1.0, 0.78, 0.18, 1.0)
		LevelMedalData.Medal.SILVER:
			return Color(0.78, 0.84, 0.9, 1.0)
		LevelMedalData.Medal.BRONZE:
			return Color(0.95, 0.48, 0.18, 1.0)
		_:
			return Color(1.0, 0.32, 0.28, 1.0)


func _show_result_overlay(title: String, medal_text: String, result: LevelResult) -> void:
	placement_controller.input_enabled = false
	completion_title_label.text = title
	completion_medal_label.text = medal_text
	next_level_button.disabled = not GameState.has_next_level()

	if result == null:
		completion_stats_label.text = "No se han alcanzado los requisitos minimos."
	else:
		completion_stats_label.text = "Tiempo: %.1fs | Maquinas: %d" % [
			result.elapsed_seconds,
			result.placed_buildings,
		]

	completion_overlay.visible = true


func _hide_completion_overlay() -> void:
	completion_overlay.visible = false
	placement_controller.input_enabled = true


func _on_erase_button_toggled(enabled: bool) -> void:
	placement_controller.set_erase_mode(enabled)


func _on_erase_mode_changed(enabled: bool) -> void:
	if erase_button != null:
		erase_button.set_pressed_no_signal(enabled)

	if enabled:
		status_label.text = "Toca o arrastra sobre piezas para borrarlas."
	else:
		status_label.text = "Coloca edificios y pulsa Play."


func _on_viewport_size_changed() -> void:
	_configure_mobile_hud()


func _on_next_level_pressed() -> void:
	if GameState.select_next_level():
		SceneRouter.go_to_game()
