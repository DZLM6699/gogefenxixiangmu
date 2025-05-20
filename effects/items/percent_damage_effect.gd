class_name PercentDamageEffect
extends Effect

export(String) var source_id = ""
export(int) var duration_secs = 3
export(int) var max_stacks = 1
export(int) var max_procs = -1
export(Color) var outline_color = Color("bfebff")


static func get_id() -> String:
	return "percent_damage"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[custom_key].push_back(to_array())


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[custom_key].erase(to_array())


func to_array() -> Array:
	return [source_id, key, value, duration_secs, max_stacks, max_procs, outline_color.to_html()]


func get_args(_player_index: int) -> Array:
	return [str(value), tr(key.to_upper()), str(duration_secs), str(max_stacks * value)]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.source_id = source_id
	serialized.duration_secs = duration_secs
	serialized.max_stacks = max_stacks
	serialized.max_procs = max_procs
	serialized.outline_color = outline_color.to_html()

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	source_id = serialized.source_id
	duration_secs = serialized.duration_secs
	max_stacks = serialized.max_stacks
	max_procs = serialized.max_procs if "max_procs" in serialized else -1
	outline_color = Color(serialized.outline_color)
