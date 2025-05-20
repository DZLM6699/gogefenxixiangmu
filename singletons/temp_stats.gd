extends Node



var player_stats = [{}, {}, {}, {}]
var are_player_stats_dirty = [false, false, false, false]


func reset() -> void :
	for player_index in player_stats.size():
		reset_player(player_index)


func reset_player(player_index: int) -> void :
	player_stats[player_index] = init_stats()
	Utils.reset_stat_cache(player_index)


func get_signal_name() -> String:
	return "temp_stats_updated"


func set_stat(stat_name: String, value: int, player_index: int) -> void :
	player_stats[player_index][stat_name] = value
	are_player_stats_dirty[player_index] = true
	Utils.reset_stat_cache(player_index)


func add_stat(stat_name: String, value: int, player_index: int) -> void :
	player_stats[player_index][stat_name] += value
	are_player_stats_dirty[player_index] = true
	Utils.reset_stat_cache(player_index)


func remove_stat(stat_name: String, value: int, player_index: int) -> void :
	player_stats[player_index][stat_name] -= value
	are_player_stats_dirty[player_index] = true
	Utils.reset_stat_cache(player_index)


func get_stat(stat_name: String, player_index: int) -> float:
	if player_index != RunData.DUMMY_PLAYER_INDEX and stat_name in player_stats[player_index]:
		return player_stats[player_index][stat_name] * RunData.get_stat_gain(stat_name, player_index)
	else:
		return 0.0


func init_stats() -> Dictionary:
	return PlayerRunData.init_stats(true)
