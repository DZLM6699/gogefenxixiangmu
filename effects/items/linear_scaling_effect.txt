class_name LinearScalingEffect
extends Effect

export var min_value: int
export var max_range: int
export var buffer: int
export var invert_scaling: bool

static func get_id() -> String:
	return "linear_scaling_effect"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[key] = [self]


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[key] = []


func get_args(_player_index: int) -> Array:
	return [str(value), str(min_value)]


func get_scaling_value(input: int) -> int:
	input -= buffer

	var total_scaling_percentage := float(abs(min_value) + abs(value))
	var function_slope := total_scaling_percentage / float(max_range)
	var function_result := function_slope * input

	var percentage := min_value + function_result
	if invert_scaling:
		percentage = value - function_result

	percentage = clamp(percentage, min_value, value)

	return percentage as int


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.min_value = min_value
	serialized.max_range = max_range
	serialized.buffer = buffer
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	min_value = serialized.min_value
	max_range = serialized.max_range
	buffer = serialized.buffer
