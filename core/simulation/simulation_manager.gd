extends Node
class_name SimulationManager

signal simulation_started
signal simulation_paused
signal simulation_tick_completed(tick_index: int, tick_delta: float)
signal packet_transferred(packet: NumberPacket, from_building: Building, to_building: Building)
signal packet_blocked(packet: NumberPacket, from_building: Building, target_cell: Vector2i)
signal output_target_reached(output: OutputBuilding, total_accepted: int)
signal connection_error(message: String)

@export_range(1, 120, 1) var ticks_per_second: int = 10:
	set(value):
		ticks_per_second = max(value, 1)
		_tick_delta = 1.0 / float(ticks_per_second)

@export var auto_start: bool = false
@export var simulated_root_path: NodePath
@export var grid_manager_path: NodePath

var is_running: bool = false
var tick_index: int = 0

var _accumulator: float = 0.0
var _tick_delta: float = 0.1
var _simulated_root: Node
var _grid_manager: GridManager
var _connected_buildings: Dictionary = {}
var _connected_outputs: Dictionary = {}


func _ready() -> void:
	_tick_delta = 1.0 / float(ticks_per_second)
	_simulated_root = get_node_or_null(simulated_root_path)
	_grid_manager = get_node_or_null(grid_manager_path) as GridManager

	if auto_start:
		play()


func _process(delta: float) -> void:
	if not is_running:
		return

	_accumulator += delta

	while _accumulator >= _tick_delta:
		_accumulator -= _tick_delta
		_run_fixed_tick()


func play() -> void:
	if is_running:
		return

	_sync_building_connections()
	is_running = true
	simulation_started.emit()


func pause() -> void:
	if not is_running:
		return

	is_running = false
	simulation_paused.emit()


func toggle_play_pause() -> void:
	if is_running:
		pause()
	else:
		play()


func reset() -> void:
	pause()
	tick_index = 0
	_accumulator = 0.0
	reset_simulation_state()


func reset_simulation_state() -> void:
	_connected_buildings.clear()
	_connected_outputs.clear()

	for node in _get_simulated_nodes():
		if node.has_method("reset_simulation"):
			node.reset_simulation()


func _run_fixed_tick() -> void:
	tick_index += 1
	_sync_building_connections()

	for node in _get_simulated_nodes():
		if node.has_method("simulation_tick"):
			node.simulation_tick(_tick_delta)

	simulation_tick_completed.emit(tick_index, _tick_delta)


func _get_simulated_nodes() -> Array[Node]:
	var root := _simulated_root if _simulated_root != null else get_tree().current_scene
	var nodes: Array[Node] = []

	if root == null:
		return nodes

	_collect_simulated_nodes(root, nodes)
	return nodes


func _collect_simulated_nodes(node: Node, nodes: Array[Node]) -> void:
	if node.has_method("simulation_tick"):
		nodes.append(node)

	for child in node.get_children():
		_collect_simulated_nodes(child, nodes)


func _sync_building_connections() -> void:
	for node in _get_simulated_nodes():
		var building := node as Building
		if building == null:
			continue

		if not _connected_buildings.has(building):
			var packet_output_callable := Callable(self, "_on_building_packet_output")
			if not building.packet_output.is_connected(packet_output_callable):
				building.packet_output.connect(packet_output_callable)
			_connected_buildings[building] = true

		var output := node as OutputBuilding
		if output != null and not _connected_outputs.has(output):
			var output_callable := Callable(self, "_on_output_target_reached").bind(output)
			if not output.target_reached.is_connected(output_callable):
				output.target_reached.connect(output_callable)
			_connected_outputs[output] = true


func _on_building_packet_output(packet: NumberPacket, from_building: Building) -> void:
	if _grid_manager == null:
		return

	var target_cell := from_building.grid_position + from_building.facing
	var target_building := _grid_manager.get_occupant(target_cell) as Building

	if target_building != null and target_building.accept_packet_from(packet, from_building):
		packet_transferred.emit(packet, from_building, target_building)
		return

	if target_building == null:
		connection_error.emit("No receiver at %s for packet %d from %s." % [target_cell, packet.value, from_building.name])
	else:
		connection_error.emit("%s rejected packet %d from %s." % [target_building.name, packet.value, from_building.name])

	packet_blocked.emit(packet, from_building, target_cell)


func _on_output_target_reached(total_accepted: int, output: OutputBuilding) -> void:
	output_target_reached.emit(output, total_accepted)
