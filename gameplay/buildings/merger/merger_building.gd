extends BufferBuilding
class_name MergerBuilding


func _ready() -> void:
	max_buffer_size = maxi(max_buffer_size, 8)
	release_interval_ticks = maxi(release_interval_ticks, 1)
