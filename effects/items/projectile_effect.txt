class_name ProjectileEffect
extends Effect

export(Resource) var weapon_stats
export(bool) var auto_target_enemy = false
export(int) var cooldown = -1


static func get_id() -> String:
	return "projectile"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[key].push_back([value, weapon_stats, auto_target_enemy, cooldown])


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[key].erase([value, weapon_stats, auto_target_enemy, cooldown])


func get_args(player_index: int) -> Array:
	var current_stats = WeaponService.init_ranged_stats(weapon_stats, player_index, true)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(weapon_stats.scaling_stats)
	return [str(value), str(current_stats.damage), str(current_stats.bounce + 1), scaling_text, str(cooldown)]


func serialize() -> Dictionary:
	var serialized = .serialize()

	if weapon_stats != null:
		serialized.weapon_stats = weapon_stats.serialize()

	serialized.auto_target_enemy = auto_target_enemy
	serialized.cooldown = cooldown

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	if serialized.has("weapon_stats"):
		var data = RangedWeaponStats.new()
		data.deserialize_and_merge(serialized.weapon_stats)
		weapon_stats = data

	auto_target_enemy = serialized.auto_target_enemy
	cooldown = serialized.cooldown
