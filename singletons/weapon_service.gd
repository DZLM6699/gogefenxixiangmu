extends Node

const MIN_RANGE = 25
const DEFAULT_PROJECTILE_SCENE = preload("res://projectiles/bullet/bullet_projectile.tscn")
const MIN_COOLDOWN: = 2

var breaking_sounds: Array = [
	preload("res://weapons/melee_sounds/glass_smashable_small_break_01.wav"), 
	preload("res://weapons/melee_sounds/glass_smashable_small_break_02.wav"), 
	preload("res://weapons/melee_sounds/glass_smashable_small_break_03.wav"), 
]


func init_melee_stats(from_stats: MeleeWeaponStats, player_index: int, args: = WeaponServiceInitStatsArgs.new()) -> MeleeWeaponStats:
	var new_stats = init_base_stats(from_stats, player_index, args) as MeleeWeaponStats
	new_stats.alternate_attack_type = from_stats.alternate_attack_type

	var min_range = MIN_RANGE

	if new_stats.min_range != 0:
		min_range = new_stats.min_range + MIN_RANGE

	new_stats.max_range = max(min_range, new_stats.max_range + (Utils.get_stat("stat_range", player_index) / 2.0)) as int

	return new_stats


func init_ranged_stats(from_stats: RangedWeaponStats, player_index: int, is_special_spawn: = false, args: = WeaponServiceInitStatsArgs.new()) -> RangedWeaponStats:
	var new_stats = init_base_stats(from_stats, player_index, args, false, is_special_spawn) as RangedWeaponStats

	var min_range = MIN_RANGE

	if new_stats.min_range != 0:
		min_range = new_stats.min_range + MIN_RANGE

	new_stats.max_range = max(min_range, new_stats.max_range + Utils.get_stat("stat_range", player_index)) as int
	_set_common_ranged_stats(new_stats, from_stats, player_index)
	return new_stats


func init_structure_stats(from_stats: RangedWeaponStats, player_index: int, args: = WeaponServiceInitStatsArgs.new()) -> RangedWeaponStats:
	var is_structure: = true
	var new_stats = init_base_stats(from_stats, player_index, args, is_structure) as RangedWeaponStats

	new_stats.max_range = max(MIN_RANGE, new_stats.max_range + Utils.get_stat("structure_range", player_index))

	_set_common_ranged_stats(new_stats, from_stats, player_index)

	return new_stats



func _set_common_ranged_stats(new_stats: RangedWeaponStats, from_stats: RangedWeaponStats, player_index: int):
	var projectiles_effect = RunData.get_player_effect("projectiles", player_index)
	new_stats.projectile_spread = from_stats.projectile_spread + (projectiles_effect * 0.1)

	if from_stats.nb_projectiles > 0:
		new_stats.nb_projectiles = from_stats.nb_projectiles + projectiles_effect

	var piercing_dmg_bonus = (Utils.get_stat("piercing_damage", player_index) / 100.0)
	var bounce_dmg_bonus = (Utils.get_stat("bounce_damage", player_index) / 100.0)

	new_stats.piercing = from_stats.piercing + RunData.get_player_effect("piercing", player_index)
	new_stats.piercing_dmg_reduction = clamp(from_stats.piercing_dmg_reduction - piercing_dmg_bonus, 0, 1)

	if from_stats.can_bounce:
		new_stats.bounce = from_stats.bounce + RunData.get_player_effect("bounce", player_index)
	else:
		new_stats.bounce = 0

	new_stats.bounce_dmg_reduction = clamp(from_stats.bounce_dmg_reduction - bounce_dmg_bonus, 0, 1)
	new_stats.projectile_scene = from_stats.projectile_scene

	if from_stats.increase_projectile_speed_with_range:
		var stat_range = Utils.get_stat("stat_range", player_index)
		new_stats.projectile_speed = clamp(from_stats.projectile_speed + (from_stats.projectile_speed / 300.0) * stat_range, 50, 6000) as int
	else:
		new_stats.projectile_speed = from_stats.projectile_speed


func init_base_stats(from_stats: WeaponStats, player_index: int, args: = WeaponServiceInitStatsArgs.new(), is_structure: = false, is_special_spawn: = false) -> WeaponStats:
	var new_stats: WeaponStats
	if from_stats is MeleeWeaponStats:
		new_stats = MeleeWeaponStats.new()
	else:
		new_stats = RangedWeaponStats.new()

	
	new_stats.cooldown = from_stats.cooldown
	new_stats.damage = from_stats.damage
	new_stats.accuracy = from_stats.accuracy
	new_stats.crit_chance = from_stats.crit_chance
	new_stats.crit_damage = from_stats.crit_damage
	new_stats.min_range = from_stats.min_range
	new_stats.max_range = from_stats.max_range
	new_stats.knockback = from_stats.knockback
	new_stats.knockback_piercing = from_stats.knockback_piercing
	new_stats.can_have_positive_knockback = from_stats.can_have_positive_knockback
	new_stats.can_have_negative_knockback = from_stats.can_have_negative_knockback
	new_stats.effect_scale = from_stats.effect_scale
	new_stats.scaling_stats = from_stats.scaling_stats
	new_stats.lifesteal = from_stats.lifesteal
	new_stats.shooting_sounds = from_stats.shooting_sounds
	new_stats.sound_db_mod = from_stats.sound_db_mod
	new_stats.is_healing = from_stats.is_healing
	new_stats.recoil = from_stats.recoil
	new_stats.recoil_duration = from_stats.recoil_duration
	new_stats.additional_cooldown_every_x_shots = from_stats.additional_cooldown_every_x_shots
	new_stats.additional_cooldown_multiplier = from_stats.additional_cooldown_multiplier
	new_stats.speed_percent_modifier = from_stats.speed_percent_modifier

	new_stats.burning_data = from_stats.burning_data
	new_stats.attack_speed_mod = from_stats.attack_speed_mod

	
	for weapon_type_bonus in RunData.get_player_effect("weapon_type_bonus", player_index):
		var weapon_type = weapon_type_bonus[0]
		var stat_name = weapon_type_bonus[1]
		var effect_value = weapon_type_bonus[2]

		if new_stats is RangedWeaponStats and weapon_type == WeaponType.RANGED:
			var value = new_stats.get(stat_name) + effect_value
			new_stats.set(stat_name, value)
		if new_stats is MeleeWeaponStats and weapon_type == WeaponType.MELEE:
			var value = new_stats.get(stat_name) + effect_value
			new_stats.set(stat_name, value)

	var set_bonus_dmg: = 0.0
	for class_bonus in RunData.get_player_effect("weapon_class_bonus", player_index):
		var set_id = class_bonus[0]
		var stat_name = class_bonus[1]
		var effect_value = class_bonus[2]
		for set in args.sets:
			if set.my_id == set_id:
				if stat_name == "stat_percent_damage":
					set_bonus_dmg += effect_value / 100.0
				else:
					var value = new_stats.get(stat_name) + effect_value
					if stat_name == "lifesteal" or stat_name == "crit_damage":
						value = new_stats.get(stat_name) + (effect_value / 100.0)
					new_stats.set(stat_name, value)

	var is_exploding: = false
	for effect in args.effects:
		if effect is BurningEffect:
			new_stats.burning_data = effect.burning_data
		elif effect is ExplodingEffect:
			is_exploding = true
		elif effect is WeaponSlowOnHitEffect:
			new_stats.speed_percent_modifier += effect.get_speed_percent_modifier(player_index)
		elif effect is WeaponStackEffect:
			var nb_same_weapon = 0
			for checked_weapon in RunData.get_player_weapons(player_index):
				if checked_weapon.weapon_id == effect.weapon_stacked_id:
					nb_same_weapon += 1
			new_stats.set(effect.stat_name, new_stats.get(effect.stat_name) + (effect.value * max(0.0, nb_same_weapon - 1)))

		elif effect is WeaponGainStatForEveryStatEffect:
			var perm_stats_only = true
			var bonus = RunData.get_scaling_bonus(effect.value, effect.stat_scaled, effect.nb_stat_scaled, perm_stats_only, player_index)
			new_stats.set(effect.increased_stat_name, new_stats.get(effect.increased_stat_name) + bonus)

	if not is_structure and not is_special_spawn:
		new_stats.scaling_stats = _apply_weapon_scaling_stat_effects(new_stats.scaling_stats, player_index)

	var slow_on_hit_effects = RunData.get_player_effect("slow_on_hit", player_index)
	for slow_on_hit_effect in slow_on_hit_effects:
		if find_scaling_stat(slow_on_hit_effect[0], new_stats.scaling_stats) != null:
			new_stats.speed_percent_modifier -= slow_on_hit_effect[1]
			break

	
	new_stats.burning_data = init_burning_data(new_stats.burning_data, player_index, is_structure)

	
	var atk_spd = (Utils.get_stat("stat_attack_speed", player_index) + new_stats.attack_speed_mod) / 100.0
	if is_structure:
		atk_spd = 0
	
	
	assert (new_stats.cooldown >= MIN_COOLDOWN)
	new_stats.cooldown = apply_attack_speed_mod_to_cooldown(new_stats.cooldown, atk_spd)
	if atk_spd > 0:
		new_stats.recoil /= 1 + atk_spd
		new_stats.recoil_duration /= 1 + atk_spd
	_apply_min_cooldown_effect(new_stats, player_index)
	_apply_max_cooldown_effect(new_stats, player_index)

	
	new_stats.damage = apply_scaling_stats_to_damage(new_stats.damage, new_stats.scaling_stats, player_index)

	var percent_dmg_bonus = (1 + (Utils.get_stat("stat_percent_damage", player_index) / 100.0))
	if is_structure:
		percent_dmg_bonus = (1 + (Utils.get_stat("structure_percent_damage", player_index) / 100.0))

	var exploding_dmg_bonus = 0
	if is_exploding:
		exploding_dmg_bonus = (Utils.get_stat("explosion_damage", player_index) / 100.0)

	new_stats.damage = max(1, round(new_stats.damage * (set_bonus_dmg + percent_dmg_bonus + exploding_dmg_bonus))) as int

	
	if not is_structure or RunData.get_player_effect_bool("structures_can_crit", player_index):
		new_stats.crit_chance += Utils.get_capped_stat("stat_crit_chance", player_index) / 100.0

	
	new_stats.accuracy += RunData.get_player_effect("accuracy", player_index) / 100.0

	
	if not is_structure:
		new_stats.lifesteal += Utils.get_stat("stat_lifesteal", player_index) / 100.0

	
	var min_knockback = - Utils.LARGE_NUMBER if new_stats.can_have_negative_knockback else 0
	var max_knockback = Utils.LARGE_NUMBER if new_stats.can_have_positive_knockback else 0
	var player_knockback = RunData.get_player_effect("knockback", player_index)

	if new_stats.can_have_negative_knockback and not new_stats.can_have_positive_knockback:
		player_knockback = - player_knockback

	new_stats.knockback = clamp(new_stats.knockback + player_knockback, min_knockback, max_knockback) as int
	if RunData.get_player_effect_bool("negative_knockback", player_index):
		if from_stats.knockback < 0:
			new_stats.knockback -= player_knockback
		elif new_stats.knockback >= 0:
			new_stats.knockback *= - 1

	return new_stats



func get_explosion_damage(from_stats: WeaponStats, player_index: int) -> int:
	var scaling_stats = _apply_weapon_scaling_stat_effects(from_stats.scaling_stats, player_index)
	var damage = apply_scaling_stats_to_damage(from_stats.damage, scaling_stats, player_index)
	var percent_dmg_bonus = (1 + (Utils.get_stat("stat_percent_damage", player_index) / 100.0))
	var exploding_dmg_bonus = (Utils.get_stat("explosion_damage", player_index) / 100.0)
	return max(1, round(damage * (percent_dmg_bonus + exploding_dmg_bonus))) as int



func init_burning_data(base_burning_data: BurningData, player_index: int, is_structure: bool = false) -> BurningData:
	var global_burning = RunData.get_player_effect("burn_chance", player_index)
	var no_global_burning = global_burning.is_not_burning()
	var base_weapon_has_no_burning = base_burning_data.is_not_burning()

	var new_burning_data: = BurningData.new()

	if no_global_burning and base_weapon_has_no_burning:
		return new_burning_data

	new_burning_data.chance = base_burning_data.chance
	new_burning_data.damage = base_burning_data.damage
	new_burning_data.duration = base_burning_data.duration
	new_burning_data.spread = base_burning_data.spread
	new_burning_data.scaling_stats = base_burning_data.scaling_stats
	
	new_burning_data.spread += RunData.get_player_effect("burning_spread", player_index)

	if base_burning_data.is_global_burn:
		new_burning_data.damage = apply_scaling_stats_to_damage(new_burning_data.damage, new_burning_data.scaling_stats, player_index)
		new_burning_data.damage = apply_damage_bonus(new_burning_data.damage, player_index)
		return new_burning_data

	
	if base_weapon_has_no_burning:
		
		new_burning_data.chance = global_burning.chance
		new_burning_data.duration = global_burning.duration
		new_burning_data.scaling_stats = global_burning.scaling_stats
		new_burning_data.spread = global_burning.spread
		new_burning_data.damage = global_burning.damage
		new_burning_data.is_global_burn = true

	else:
		new_burning_data.damage += global_burning.damage

	new_burning_data.damage = apply_scaling_stats_to_damage(new_burning_data.damage, new_burning_data.scaling_stats, player_index)
	if is_structure and not base_weapon_has_no_burning:
		new_burning_data.damage = apply_structure_damage_bonus(new_burning_data.damage, player_index)
	else:
		new_burning_data.damage = apply_damage_bonus(new_burning_data.damage, player_index)

	return new_burning_data


func manage_special_spawn_projectile(
	entity_from, 
	weapon_stats: RangedWeaponStats, 
	direction: float, 
	auto_target_enemy: bool, 
	entity_spawner_ref: EntitySpawner, 
	from: Node, 
	args: = WeaponServiceSpawnProjectileArgs.new()
) -> Node:
	var pos = entity_from.global_position

	if weapon_stats.shooting_sounds.size() > 0:
		SoundManager2D.play(Utils.get_rand_element(weapon_stats.shooting_sounds), pos, 0, 0.2)

	if auto_target_enemy:
		var target = entity_spawner_ref.get_rand_enemy(entity_from)

		if target != null and is_instance_valid(target):
			direction = (target.global_position - pos).angle()

	args.deferred = true
	args.knockback_direction = Vector2(cos(direction), sin(direction))
	var projectile = spawn_projectile(pos, weapon_stats, direction, from, args)

	return projectile


func spawn_projectile(
	pos: Vector2, 
	weapon_stats: RangedWeaponStats, 
	direction: float, 
	from: Node, 
	args: WeaponServiceSpawnProjectileArgs
) -> Node:
	var knockback_direction = args.knockback_direction
	var deferred = args.deferred
	var effects = args.effects
	var damage_tracking_key = args.damage_tracking_key

	var hitbox_args = Hitbox.HitboxArgs.new().set_from_weapon_stats(weapon_stats)

	var duplicated_effects = []
	for effect in effects:
		duplicated_effects.push_back(effect.duplicate())
	duplicated_effects = set_projectile_effects(duplicated_effects, args.from_player_index)

	var main = Utils.get_scene_node()
	var projectile_scene = weapon_stats.projectile_scene if weapon_stats.projectile_scene != null else DEFAULT_PROJECTILE_SCENE

	var projectile = main.get_node_from_pool(projectile_scene.resource_path)
	if projectile == null:
		projectile = projectile_scene.instance()
		if deferred:
			main.call_deferred("add_player_projectile", projectile)
		else:
			main.add_player_projectile(projectile)

	if deferred:
		
		projectile.call_deferred("set_from", from)
		projectile.set_deferred("spawn_position", pos)
		projectile.set_deferred("velocity", Vector2.RIGHT.rotated(direction) * weapon_stats.projectile_speed)
		projectile.set_deferred("rotation", (Vector2.RIGHT.rotated(direction) * weapon_stats.projectile_speed).angle())
		projectile.call_deferred("set_weapon_stats", weapon_stats)
		projectile.call_deferred("set_damage_tracking_key", damage_tracking_key)
		projectile.call_deferred("set_effects", duplicated_effects)
		projectile.call_deferred("set_damage", weapon_stats.damage, hitbox_args)
		projectile.call_deferred("set_knockback_vector", knockback_direction, weapon_stats.knockback, weapon_stats.knockback_piercing)
		projectile.call_deferred("set_effect_scale", weapon_stats.effect_scale)
		projectile.call_deferred("set_speed_percent_modifier", weapon_stats.speed_percent_modifier)
		projectile.call_deferred("shoot")
	else:
		
		projectile.set_from(from)
		projectile.spawn_position = pos
		projectile.set_effects(duplicated_effects)
		projectile.velocity = Vector2.RIGHT.rotated(direction) * weapon_stats.projectile_speed
		projectile.rotation = projectile.velocity.angle()
		projectile.set_damage_tracking_key(damage_tracking_key)
		projectile.set_weapon_stats(weapon_stats)
		projectile.set_damage(weapon_stats.damage, hitbox_args)
		projectile.set_knockback_vector(knockback_direction, weapon_stats.knockback, weapon_stats.knockback_piercing)
		projectile.set_effect_scale(weapon_stats.effect_scale)
		projectile.set_speed_percent_modifier(weapon_stats.speed_percent_modifier)
		projectile.shoot()

	return projectile


func set_projectile_effects(base_effects: Array, player_index: int = - 1) -> Array:
	var all_effects = base_effects.duplicate()

	if player_index >= 0:
		all_effects = _add_player_effect_to_effects(all_effects, "pierce_on_crit", player_index)
		all_effects = _add_player_effect_to_effects(all_effects, "bounce_on_crit", player_index)

	return all_effects


func _add_player_effect_to_effects(effects: Array, key: String, player_index: int) -> Array:
	var player_effect: int = RunData.get_player_effect(key, player_index)
	if player_effect <= 0:
		return effects
	var found: = false
	for effect in effects:
		if effect.key == key:
			effect.value += player_effect
			found = true
	if not found:
		var effect: = NullEffect.new()
		effect.key = key
		effect.value = player_effect
		effects.append(effect)

	return effects



func get_scaling_stats_icon_text(p_scaling_stats: Array) -> String:
	var stat_icon_text: = ""
	for i in p_scaling_stats.size():
		stat_icon_text += Utils.get_scaling_stat_icon_text(p_scaling_stats[i][0], p_scaling_stats[i][1])
	return stat_icon_text


func sum_scaling_stat_values(p_scaling_stats: Array, player_index: int) -> float:
	var value = 0
	for scaling_stat in p_scaling_stats:
		if scaling_stat[0] == "stat_levels":
			value += RunData.get_player_level(player_index) * scaling_stat[1]
		else:
			value += Utils.get_stat(scaling_stat[0], player_index) * scaling_stat[1]

	return value


func find_scaling_stat(stat_name: String, scaling_stats: Array):
	for scaling_stat in scaling_stats:
		if scaling_stat[0] == stat_name:
			return scaling_stat
	return null


func apply_scaling_stats_to_damage(damage: int, p_scaling_stats: Array, player_index: int) -> int:
	return max(1.0, damage + sum_scaling_stat_values(p_scaling_stats, player_index)) as int


func apply_damage_bonus(value: int, player_index: int) -> int:
	var percent_dmg_bonus = 1 + Utils.get_stat("stat_percent_damage", player_index) / 100.0
	return max(1, round(max(1, value) * percent_dmg_bonus)) as int


func apply_structure_damage_bonus(value: int, player_index: int) -> int:
	var percent_dmg_bonus = 1 + Utils.get_stat("structure_percent_damage", player_index) / 100.0
	return max(1, round(max(1, value) * percent_dmg_bonus)) as int



func apply_inverted_health_bonus(value: int, per_health_percent_amount: int, current_health: int, max_health: int) -> int:
	if max_health == 0:
		return 0
	var percent_missing_health: = max(0.0, 1.0 - float(current_health) / float(max_health)) * 100.0
	return round(value * (percent_missing_health / per_health_percent_amount)) as int


func explode(effect: Effect, args: WeaponServiceExplodeArgs) -> Node:
	var main: Main = Utils.get_scene_node()
	var instance = main.get_node_from_pool(effect.explosion_scene.resource_path)
	if instance == null:
		instance = effect.explosion_scene.instance()
		main.call_deferred("add_explosion", instance)

	
	
	
	instance.player_index = args.from_player_index
	instance.set_deferred("global_position", args.pos)
	instance.set_deferred("sound_db_mod", effect.sound_db_mod)
	instance.call_deferred("set_damage_tracking_key", args.damage_tracking_key)
	instance.call_deferred("set_damage", args)
	instance.call_deferred("set_smoke_amount", round(effect.scale * effect.base_smoke_amount))
	instance.call_deferred("set_area", effect.scale)
	if args.from != null:
		instance.call_deferred("set_from", args.from)

	instance.call_deferred("start_explosion")

	return instance


func should_spawn_landmines_on_enemy_death(hitbox: Hitbox, was_burning: bool, player_index: int) -> bool:
	var from = hitbox.from if hitbox != null else null
	var landmines_on_death_effects = RunData.get_player_effect("landmines_on_death_chance", player_index)
	for landmines_on_death_effect in landmines_on_death_effects:
		var effect_stat = landmines_on_death_effect[0]
		var chance = landmines_on_death_effect[1] / 100.0
		if not Utils.get_chance_success(chance):
			continue
		var weapon_did_stat_damage = from is Weapon and find_scaling_stat(effect_stat, from.current_stats.scaling_stats) != null
		var burning_did_stat_damage = effect_stat == "stat_elemental_damage" and was_burning
		if weapon_did_stat_damage or burning_did_stat_damage:
			return true
	return false


func get_structure_attack_speed(player_index: int) -> float:
	var structure_attack_speed = Utils.get_stat("structure_attack_speed", player_index)
	var effect_scaling_stats = RunData.get_player_effect("structures_cooldown_reduction", player_index)
	var scaling_stats = []
	for effect_scaling_stat in effect_scaling_stats:
		scaling_stats.push_back([effect_scaling_stat[0], effect_scaling_stat[1] / 100.0])
	return sum_scaling_stat_values(scaling_stats, player_index) + structure_attack_speed


func apply_structure_attack_speed_effects(base_cooldown: int, player_index: int) -> int:
	if base_cooldown <= 0:
		return base_cooldown
	var total_attack_speed_percent = get_structure_attack_speed(player_index) / 100.0
	base_cooldown = apply_attack_speed_mod_to_cooldown(base_cooldown, total_attack_speed_percent)
	return base_cooldown


func apply_attack_speed_mod_to_cooldown(base_cooldown: int, attack_speed_mod: float) -> int:
	if attack_speed_mod < 0:
		return max(MIN_COOLDOWN, base_cooldown * (1 + abs(attack_speed_mod))) as int
	return max(MIN_COOLDOWN, base_cooldown / (1 + attack_speed_mod)) as int


func _apply_min_cooldown_effect(stats: WeaponStats, player_index: int) -> void :
	var min_cooldown_effects = RunData.get_player_effect("minimum_weapon_cooldowns", player_index)
	if min_cooldown_effects.empty():
		return
	
	var min_cooldown_effect_value: int = min_cooldown_effects.back()
	assert (min_cooldown_effect_value >= MIN_COOLDOWN)
	
	
	var total_cooldown_seconds: = stats.get_cooldown_value(player_index, 1.0)
	var total_cooldown: = total_cooldown_seconds * 60.0
	var cooldown_below_min: = min_cooldown_effect_value - total_cooldown
	if cooldown_below_min <= 0:
		return

	
	
	
	var new_cooldown = stats.cooldown + ceil(cooldown_below_min) as int

	
	
	if stats.additional_cooldown_every_x_shots != - 1:
		stats.additional_cooldown_multiplier = max(1, (stats.additional_cooldown_multiplier * stats.cooldown) / new_cooldown)

	stats.cooldown = new_cooldown


func _apply_max_cooldown_effect(stats: WeaponStats, player_index: int) -> void :
	var max_cooldown_effects = RunData.get_player_effect("maximum_weapon_cooldowns", player_index)
	if max_cooldown_effects.empty():
		return

	var max_cooldown_value: int = max_cooldown_effects[0]
	var total_cooldown_seconds: = stats.get_cooldown_value(player_index, 1.0)
	var total_cooldown: = total_cooldown_seconds * 60.0

	var cooldown_above_max: = total_cooldown - max_cooldown_value
	if cooldown_above_max <= 0:
		return

	stats.cooldown -= ceil(cooldown_above_max) as int


func _apply_weapon_scaling_stat_effects(scaling_stats: Array, player_index: int) -> Array:
	var weapon_scaling_stat_effects = RunData.get_player_effect("weapon_scaling_stats", player_index)
	if weapon_scaling_stat_effects.empty():
		return scaling_stats
	var new_scaling_stats = scaling_stats.duplicate(true)
	for scaling_stat_effect in weapon_scaling_stat_effects:
		var scaling_stat_name = scaling_stat_effect[0]
		var scaling_stat_value = scaling_stat_effect[1] / 100.0
		var existing_scaling_stat = find_scaling_stat(scaling_stat_name, new_scaling_stats)
		if existing_scaling_stat != null:
			existing_scaling_stat[1] += scaling_stat_value
		else:
			new_scaling_stats.push_back([scaling_stat_name, scaling_stat_value])
	return new_scaling_stats


func init_stats_every_x_projectiles(base_stats: WeaponStats, player_index: int, args: WeaponServiceInitStatsArgs) -> Dictionary:
	
	var modify_projectile_effects = []
	var nb_projectile_effect = 0
	var item_effects = RunData.get_player_effect("modify_every_x_projectile", player_index)
	modify_projectile_effects.append_array(item_effects)

	for effect in args.effects:
		if effect is WeaponEffectWithSubEffects:
			modify_projectile_effects.push_back(effect)

	var stats_every_x_shots = {}

	for effect in modify_projectile_effects:
		for sub_effect in effect.sub_effects:
			sub_effect.apply(player_index)
			if sub_effect.key == "projectiles":
				nb_projectile_effect += sub_effect.value

		var modified_stats: RangedWeaponStats = init_ranged_stats(base_stats, player_index, false, args)

		modified_stats.projectile_spread += nb_projectile_effect * 0.15
		stats_every_x_shots[effect.value] = modified_stats

		for sub_effect in effect.sub_effects:
			sub_effect.unapply(player_index)

	return stats_every_x_shots
