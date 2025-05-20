class_name TurretEffect
extends StructureEffect

export (float) var shooting_animation_speed = 1.0
export (bool) var is_burning = false
export (bool) var is_spawning = false
export (String) var tracking_key


static func get_id() -> String:
	return "turret"


func get_args(player_index: int) -> Array:
	if is_spawning:
		var spawn_cd = WeaponService.apply_structure_attack_speed_effects(stats.cooldown, player_index)
		return [str(stepify(spawn_cd / 60.0, 0.1))]

	var args: = WeaponServiceInitStatsArgs.new()
	args.effects = effects
	var init_stats = WeaponService.init_structure_stats(stats, player_index, args)

	if is_burning:
		var scaling_stats_text = WeaponService.get_scaling_stats_icon_text(init_stats.burning_data.scaling_stats)
		return [str(init_stats.burning_data.duration), str(init_stats.burning_data.damage), scaling_stats_text, tr(key.to_upper())]
	else:
		var scaling_stats_text = WeaponService.get_scaling_stats_icon_text(stats.scaling_stats)
		return [str(init_stats.damage), scaling_stats_text, str(init_stats.nb_projectiles), str(init_stats.bounce), tr(key.to_upper())]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.shooting_animation_speed = shooting_animation_speed
	serialized.is_burning = is_burning
	serialized.is_spawning = is_spawning
	serialized.tracking_key = tracking_key

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	is_burning = serialized.is_burning
	is_spawning = serialized.is_spawning if "is_spawning" in serialized else false
	tracking_key = serialized.get("tracking_key", "")


func _add_custom_args() -> void :
	if is_burning:
		var duration_as_neutral: = CustomArg.new()
		duration_as_neutral.arg_sign = Sign.NEUTRAL
		custom_args.append(duration_as_neutral)
