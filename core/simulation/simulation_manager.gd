extends Node
class_name SimulationManager

signal simulation_started
signal simulation_paused
signal simulation_tick_completed(tick_index: int, tick_delta: float)
signal packet_transferred(packet: NumberPacket, from_building: Building, to_building: Building)
signal packet_blocked(packet: NumberPacket, from_building: Building, target_cell: Vector2i)
signal output_packet_consumed(packet: NumberPacket, output: OutputBuilding, matched_target: bool)
signal output_target_reached(output: OutputBuilding, total_accepted: int)
signal addition_sum_created(addition: AdditionBuilding, input_values: Array[int], result: int)
signal arithmetic_operation_created(building: Building, input_values: Array[int], result: int, operator_symbol: String)
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
var _connected_additions: Dictionary = {}
var _connected_arithmetic_operators: Dictionary = {}


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
	_connected_additions.clear()
	_connected_arithmetic_operators.clear()

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
			var packet_consumed_callable := Callable(self, "_on_output_packet_consumed").bind(output)
			if not output.packet_consumed.is_connected(packet_consumed_callable):
				output.packet_consumed.connect(packet_consumed_callable)
			_connected_outputs[output] = true

		var addition := node as AdditionBuilding
		if addition != null and not _connected_additions.has(addition):
			var sum_callable := Callable(self, "_on_addition_sum_created")
			if not addition.sum_created.is_connected(sum_callable):
				addition.sum_created.connect(sum_callable)
			_connected_additions[addition] = true

		var arithmetic_operator := node as ArithmeticOperatorBuilding
		if arithmetic_operator != null and not _connected_arithmetic_operators.has(arithmetic_operator):
			if not (arithmetic_operator is AdditionBuilding):
				var operation_callable := Callable(self, "_on_arithmetic_operation_created")
				if not arithmetic_operator.operation_created.is_connected(operation_callable):
					arithmetic_operator.operation_created.connect(operation_callable)
			_connected_arithmetic_operators[arithmetic_operator] = true


func _on_building_packet_output(packet: NumberPacket, from_building: Building) -> void:
	if _grid_manager == null or packet == null or from_building == null:
		return

	if from_building is SourceBuilding:
		for target_group in from_building.get_output_target_groups(packet):
			_route_packet_to_target_group(packet.duplicate_packet(), from_building, target_group, true)
		return

	var output_target_groups := from_building.get_output_target_groups(packet)
	for i in range(output_target_groups.size()):
		var routed_packet := packet if i == output_target_groups.size() - 1 else packet.duplicate_packet()
		_route_packet_to_target_group(routed_packet, from_building, output_target_groups[i], false)


func _route_packet_to_target_group(packet: NumberPacket, from_building: Building, target_group: Array, skip_empty: bool) -> void:
	var first_target_cell := Vector2i.ZERO
	var has_target_cell := false
	var first_rejecting_building: Building

	for target in target_group:
		var target_cell: Vector2i = target
		if not has_target_cell:
			first_target_cell = target_cell
			has_target_cell = true

		var target_building := _grid_manager.get_occupant(target_cell) as Building
		if target_building == null:
			continue

		if target_building.can_accept_packet_from_cell(packet, from_building, target_cell) \
			and target_building.accept_packet_from_cell(packet, from_building, target_cell):
			packet_transferred.emit(packet, from_building, target_building)
			return

		if first_rejecting_building == null:
			first_rejecting_building = target_building

	if not has_target_cell:
		return

	if first_rejecting_building == null:
		if skip_empty:
			return

		connection_error.emit("No receiver at %s for packet %d from %s." % [first_target_cell, packet.value, from_building.name])
	else:
		connection_error.emit("%s rejected packet %d from %s." % [first_rejecting_building.name, packet.value, from_building.name])

	packet_blocked.emit(packet, from_building, first_target_cell)


func _on_output_target_reached(total_accepted: int, output: OutputBuilding) -> void:
	output_target_reached.emit(output, total_accepted)


func _on_output_packet_consumed(packet: NumberPacket, matched_target: bool, output: OutputBuilding) -> void:
	output_packet_consumed.emit(packet, output, matched_target)


func _on_addition_sum_created(addition: AdditionBuilding, input_values: Array[int], result: int) -> void:
	addition_sum_created.emit(addition, input_values, result)


func _on_arithmetic_operation_created(building: Building, input_values: Array[int], result: int, operator_symbol: String) -> void:
	arithmetic_operation_created.emit(building, input_values, result, operator_symbol)
