extends Node


var factor_cache: = {}


func reset_cache() -> void :
	factor_cache.clear()


func get_final_enemy_damage(from_value: float, percent_modifier: int = 0) -> int:
	var cache_key: = "enemy_damage"
	var factor = factor_cache.get(cache_key)
	if factor == null:
		var effects_factor = max(0.01, 1.0 + Utils.sum_all_player_stats("enemy_damage") / 100.0)
		var danger_factor = max(0.01, 1.0 + RunData.get_player_effect("danger_enemy_damage", 0) / 100.0)
		var coop_factor = max(0.01, 1.0 + ((RunData.get_player_count() - 1) * CoopService.additional_enemy_damage_per_coop_player))
		var accessibility_factor = RunData.current_run_accessibility_settings.damage

		var curse_factor = 0
		if "stat_curse" in RunData.get_player_effects(0):
			curse_factor = sqrt(Utils.average_all_player_stats("stat_curse")) / 25.0

		var endless_factor = max(0.01, 1.0 + (RunData.get_endless_factor() * (1.0 + curse_factor)))

		factor = danger_factor * accessibility_factor * coop_factor * effects_factor * endless_factor
		factor_cache[cache_key] = factor

	var boost_factor = max(0.01, 1.0 + percent_modifier / 100.0)
	return round(from_value * factor * boost_factor) as int


func get_final_enemy_health(from_value: int, percent_modifier: int = 0) -> int:
	var cache_key: = "enemy_health"
	var factor = factor_cache.get(cache_key)
	if factor == null:
		var effects_factor = max(0.01, 1.0 + Utils.sum_all_player_stats("enemy_health") / 100.0)
		var danger_factor = max(0.01, 1.0 + RunData.get_player_effect("danger_enemy_health", 0) / 100.0)
		var coop_factor = max(0.01, 1.0 + ((RunData.get_player_count() - 1) * CoopService.additional_enemy_health_per_coop_player))
		var accessibility_factor = RunData.current_run_accessibility_settings.health

		var curse_factor = 0
		if "stat_curse" in RunData.get_player_effects(0):
			curse_factor = sqrt(Utils.average_all_player_stats("stat_curse")) / 10.0

		var endless_factor = max(0.01, 1.0 + (RunData.get_endless_factor() * 2.25) * (1.0 + curse_factor))

		factor = danger_factor * accessibility_factor * coop_factor * effects_factor * endless_factor
		factor_cache[cache_key] = factor

	var boost_factor = max(0.01, 1.0 + percent_modifier / 100.0)
	return round(from_value * factor * boost_factor) as int


func get_final_enemy_speed(from_value: int, effects_factor: float, percent_modifier: int = 0) -> int:
	var cache_key: = "enemy_speed"
	var factor = factor_cache.get(cache_key)
	if factor == null:
		var accessibility_factor = RunData.current_run_accessibility_settings.speed
		var endless_factor = 1.0 + (min(1.75, RunData.get_endless_factor() / 13.33))
		factor = effects_factor * accessibility_factor * endless_factor
		factor_cache[cache_key] = factor

	var boost_factor = 1.0 + percent_modifier / 100.0
	return round(from_value * factor * boost_factor) as int


func is_considered_turret(structure_effect: StructureEffect) -> bool:
	return (structure_effect is TurretEffect
		and structure_effect.text_key != "effect_garden"
		and structure_effect.text_key != "effect_wandering_bot"
	)


func is_offensive(structure: Structure) -> bool:
	return (structure is Turret
		and not structure is Garden
		and not structure is WanderingBot
		and not structure.stats.is_healing
	)


func sort_turrets_by_strength(a: TurretEffect, b: TurretEffect) -> bool:
	var ordering: = ["effect_builder_turret_alt", "effect_turret_rocket", "effect_turret_laser", "effect_tyler", 
		"effect_turret_flame", "effect_turret", "effect_turret_healing"]

	var a_index: = ordering.find(a.text_key)
	var b_index: = ordering.find(b.text_key)
	assert (a_index != - 1, "turret ordering is missing key %s" % a.text_key)
	assert (b_index != - 1, "turret ordering is missing key %s" % b.text_key)
	return a_index <= b_index


func is_weapon_spawning_structure(weapon: WeaponData) -> bool:
	return (weapon.weapon_id == "weapon_screwdriver"
		or weapon.weapon_id == "weapon_wrench"
		or weapon.weapon_id == "weapon_pruner")
