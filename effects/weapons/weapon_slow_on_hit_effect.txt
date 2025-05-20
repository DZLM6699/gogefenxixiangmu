class_name WeaponSlowOnHitEffect
extends NullEffect

export (String) var scaling_stat = "stat_engineering"


static func get_id() -> String:
	return "weapon_slow_on_hit"


func get_args(player_index: int) -> Array:
	var stat_per_value: = 1
	var total_modifier = abs(get_speed_percent_modifier(player_index)) as int
	return [str(value), str(stat_per_value), tr(scaling_stat.to_upper()), str(total_modifier)]


func get_speed_percent_modifier(player_index: int) -> int:
	return - max(Utils.get_stat(scaling_stat, player_index), 0) as int * value


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.scaling_stat = scaling_stat
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)
	scaling_stat = serialized.scaling_stat
