class_name SwapMaxMinStatEffect
extends Effect

var stats_swapped = []


static func get_id() -> String:
	return "swap_max_min_stat"


func apply(player_index: int) -> void:
	var min_max_stat_keys = stats_swapped

	if stats_swapped.size() == 0:
		stats_swapped = _find_min_max_stat_keys(player_index)

	var min_stat_key = min_max_stat_keys[0]
	var max_stat_key = min_max_stat_keys[1]

	var effects = RunData.get_player_effects(player_index)
	var min_stat_temp = TempStats.get_stat(min_stat_key, player_index)
	var max_stat_temp = TempStats.get_stat(max_stat_key, player_index)
	var min_stat_linked = LinkedStats.get_stat(min_stat_key, player_index)
	var max_stat_linked = LinkedStats.get_stat(max_stat_key, player_index)
	var min_stat_gain = RunData.get_stat_gain(min_stat_key, player_index)
	var max_stat_gain = RunData.get_stat_gain(max_stat_key, player_index)

	var min_stat_value = Utils.get_stat(min_stat_key, player_index)
	var max_stat_value = Utils.get_stat(max_stat_key, player_index)

	var new_min_permanent = (max_stat_value - min_stat_temp - min_stat_linked) / min_stat_gain
	var new_max_permanent = (min_stat_value - max_stat_temp - max_stat_linked) / max_stat_gain

	effects[min_stat_key] = new_min_permanent
	effects[max_stat_key] = new_max_permanent


func unapply(_player_index: int) -> void:
	pass


func get_args(player_index: int) -> Array:

	if stats_swapped.size() == 0:
		stats_swapped = _find_min_max_stat_keys(player_index)

	return [tr(stats_swapped[1].to_upper()), tr(stats_swapped[0].to_upper())]


func _find_min_max_stat_keys(player_index: int) -> Array:
	var min_stat_key = ""
	var max_stat_key = ""

	var stat_keys = Utils.get_primary_stat_keys()
	for stat_key in stat_keys:
		var current_stat = Utils.get_stat(stat_key, player_index)
		if current_stat <= 0:
			continue
		if min_stat_key.empty() or current_stat < Utils.get_stat(min_stat_key, player_index):
			min_stat_key = stat_key
		if max_stat_key.empty() or current_stat > Utils.get_stat(max_stat_key, player_index):
			max_stat_key = stat_key

	if min_stat_key.empty():
		min_stat_key = "stat_max_hp"
	if max_stat_key.empty():
		max_stat_key = "stat_max_hp"
	return [min_stat_key, max_stat_key]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.stats_swapped = stats_swapped

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	stats_swapped = serialized.stats_swapped if "stats_swapped" in serialized else []
