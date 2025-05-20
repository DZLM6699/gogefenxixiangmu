class_name PlayerHealthStatEffect
extends NullEffect

export (int) var for_every_health_percent: = 1


static func get_id() -> String:
	return "weapon_player_health_stat"


func get_args(player_index: int) -> Array:
	return [str(value), tr(key.to_upper()), str(for_every_health_percent), str(get_bonus_damage(player_index))]


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.for_every_health_percent = for_every_health_percent
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)
	for_every_health_percent = serialized.for_every_health_percent


func get_bonus_damage(player_index: int) -> int:
	var current_health = RunData.get_player_current_health(player_index)
	var max_health = RunData.get_player_max_health(player_index)
	return WeaponService.apply_inverted_health_bonus(value, for_every_health_percent, current_health, max_health)
