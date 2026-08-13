extends Resource
class_name LevelMedalData

enum Medal {
	NONE,
	BRONZE,
	SILVER,
	GOLD,
}

@export var medal: Medal = Medal.BRONZE
@export var max_ticks: int = 0
@export var max_buildings: int = 0
@export var description: String = ""


func is_earned(metrics: LevelMetrics) -> bool:
	if metrics == null:
		return false

	if max_ticks > 0 and metrics.tick_index > max_ticks:
		return false

	if max_buildings > 0 and metrics.placed_buildings > max_buildings:
		return false

	return true


static func get_medal_name(value: int) -> String:
	match value:
		Medal.BRONZE:
			return "Bronce"
		Medal.SILVER:
			return "Plata"
		Medal.GOLD:
			return "Oro"
		_:
			return "Sin completar"


static func get_medal_badge(value: int) -> String:
	match value:
		Medal.BRONZE:
			return "[Bronce]"
		Medal.SILVER:
			return "[Plata]"
		Medal.GOLD:
			return "[Oro]"
		_:
			return "[--]"
