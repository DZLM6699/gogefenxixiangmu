class_name TempStatsPerIntervalEffect
extends Effect

export var interval := 1
export var reset_on_hit := false


static func get_id() -> String:
	return "temp_stats_per_interval"


func apply(player_index: int) -> void:
	var gain_stat_effects = RunData.get_player_effect(custom_key, player_index)
	for existing_effect in gain_stat_effects:
		if existing_effect[0] == key and existing_effect[2] == interval and existing_effect[3] == reset_on_hit:
			existing_effect[1] += value
			return
	gain_stat_effects.push_back([key, value, interval, reset_on_hit])


func unapply(player_index: int) -> void:
	var gain_stat_effects = RunData.get_player_effect(custom_key, player_index)
	for i in gain_stat_effects.size():
		var existing_effect = gain_stat_effects[i]
		if existing_effect[0] == key and existing_effect[2] == interval and existing_effect[3] == reset_on_hit:
			existing_effect[1] -= value
			if existing_effect[1] == 0:
				gain_stat_effects.remove(i)
			return


func _add_custom_args() -> void:
	var interval_as_neutral := CustomArg.new()
	interval_as_neutral.arg_index = 2
	interval_as_neutral.arg_sign = Sign.NEUTRAL
	custom_args.append(interval_as_neutral)


func get_text(player_index: int, colored: bool = true) -> String:
	if interval == 1:
		text_key = "EFFECT_TEMP_STATS_PER_INTERVAL_SINGULAR"
	return .get_text(player_index, colored)


func get_args(_player_index: int) -> Array:
	return [str(value), tr(key.to_upper()), str(interval)]


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.interval = interval
	serialized.reset_on_hit = reset_on_hit
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	interval = serialized.interval as int
	reset_on_hit = serialized.reset_on_hit as bool
