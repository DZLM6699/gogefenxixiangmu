class_name StatGainsModificationEffect
extends Effect

export(String) var stat_displayed = ""
export(Array, String) var stats_modified


static func get_id() -> String:
	return "stat_gains_modifications"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	for stat in stats_modified:
		effects["gain_" + stat] += value


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	for stat in stats_modified:
		effects["gain_" + stat] -= value


func get_args(_player_index: int) -> Array:
	return [tr(stat_displayed.to_upper()), str(abs(value))]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.stat_displayed = stat_displayed
	serialized.stats_modified = stats_modified

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	stat_displayed = serialized.stat_displayed
	stats_modified = serialized.stats_modified
