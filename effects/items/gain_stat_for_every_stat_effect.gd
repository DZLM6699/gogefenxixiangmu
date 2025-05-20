class_name GainStatForEveryStatEffect
extends Effect

export(int) var nb_stat_scaled = 0
export(String) var stat_scaled = ""
export(bool) var perm_stats_only = true


static func get_id() -> String:
	return "gain_stat_for_every_stat"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects["stat_links"].push_back([key, value, stat_scaled, nb_stat_scaled, perm_stats_only])


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects["stat_links"].erase([key, value, stat_scaled, nb_stat_scaled, perm_stats_only])


func get_args(player_index: int) -> Array:
	var key_arg = key
	var bonus = RunData.get_scaling_bonus(value, stat_scaled, nb_stat_scaled, perm_stats_only, player_index)

	if key_arg == "number_of_enemies":
		key_arg = "pct_number_of_enemies"

	var stat_scaled_text = tr(stat_scaled.to_upper())

	if stat_scaled == "different_item":
		stat_scaled_text = tr("ITEM")

	return [str(value), tr(key_arg.to_upper()), str(nb_stat_scaled), stat_scaled_text, str(bonus)]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.nb_stat_scaled = nb_stat_scaled
	serialized.stat_scaled = stat_scaled
	serialized.perm_stats_only = perm_stats_only

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	nb_stat_scaled = serialized.nb_stat_scaled as int
	stat_scaled = serialized.stat_scaled
	perm_stats_only = serialized.perm_stats_only if "perm_stats_only" in serialized else true
