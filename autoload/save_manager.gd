extends Node

const SAVE_PATH := "user://progress.cfg"
const LEVELS_SECTION := "levels"

var _progress: Dictionary = {}


func _ready() -> void:
	load_progress()


func load_progress() -> void:
	_progress.clear()

	var config := ConfigFile.new()
	var error: Error = config.load(SAVE_PATH)
	if error != OK:
		return

	for level_id: String in config.get_section_keys(LEVELS_SECTION):
		var stored_value: Variant = config.get_value(LEVELS_SECTION, level_id, {})
		if stored_value is Dictionary:
			_progress[level_id] = stored_value


func save_progress() -> void:
	var config := ConfigFile.new()

	for level_id in _progress:
		config.set_value(LEVELS_SECTION, level_id, _progress[level_id])

	config.save(SAVE_PATH)


func record_level_result(level_id: StringName, result: LevelResult) -> void:
	if result == null or not result.completed or result.medal <= LevelMedalData.Medal.NONE:
		return

	var id_text: String = String(level_id)
	var previous: Dictionary = get_level_progress(level_id)
	var previous_medal: int = int(previous.get("best_medal", LevelMedalData.Medal.NONE))
	var should_update: bool = result.medal > previous_medal

	if result.medal == previous_medal:
		var previous_ticks: int = int(previous.get("best_ticks", 2147483647))
		var previous_buildings: int = int(previous.get("best_buildings", 2147483647))
		should_update = result.tick_count < previous_ticks

		if result.tick_count == previous_ticks:
			should_update = result.placed_buildings < previous_buildings

	if not should_update:
		return

	_progress[id_text] = {
		"completed": true,
		"best_medal": result.medal,
		"best_ticks": result.tick_count,
		"best_seconds": result.elapsed_seconds,
		"best_buildings": result.placed_buildings,
		"best_budget": result.spent_budget,
		"updated_at": Time.get_datetime_string_from_system(),
	}
	save_progress()


func get_level_progress(level_id: StringName) -> Dictionary:
	return _progress.get(String(level_id), {}).duplicate()


func get_level_medal(level_id: StringName) -> int:
	var progress: Dictionary = get_level_progress(level_id)
	return int(progress.get("best_medal", LevelMedalData.Medal.NONE))


func get_level_summary(level_id: StringName) -> String:
	var progress: Dictionary = get_level_progress(level_id)
	var medal: int = int(progress.get("best_medal", LevelMedalData.Medal.NONE))
	if medal == LevelMedalData.Medal.NONE:
		return "Sin completar"

	return "%s | %d ticks | %d maquinas" % [
		LevelMedalData.get_medal_name(medal),
		int(progress.get("best_ticks", 0)),
		int(progress.get("best_buildings", 0)),
	]
