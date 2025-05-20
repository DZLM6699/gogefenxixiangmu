class_name PlayerRunData
extends Reference

const DEFAULT_MAX_HP: = 10

var current_character: CharacterData = null
var current_health: = 10
var current_level: int = 0

var current_xp: float = 0.0
var gold: int = 0
var selected_weapon: WeaponData
var weapons: = []
var items: = []
var appearances: = []
var effects: Dictionary


var active_sets = {}

var active_set_effects: = []



var unique_effects: = []

var additional_weapon_effects: = []

var tier_iv_weapon_effects: = []

var tier_i_weapon_effects: = []

var chal_recycling_current: = 0
var consumables_picked_up_this_run: = 0
var curse_locked_shop_items_pity: = 0


func _init() -> void :
	effects = init_effects()


func duplicate() -> PlayerRunData:
	var copy: PlayerRunData = get_script().new()
	copy.current_character = current_character
	copy.current_health = current_health
	copy.current_level = current_level
	copy.current_xp = current_xp
	copy.gold = gold
	copy.selected_weapon = selected_weapon
	copy.weapons = weapons.duplicate()
	copy.items = items.duplicate()
	copy.appearances = appearances.duplicate()
	copy.effects = effects.duplicate(true)
	copy.active_sets = active_sets.duplicate()
	copy.active_set_effects = active_set_effects.duplicate()
	copy.unique_effects = unique_effects.duplicate()
	copy.additional_weapon_effects = additional_weapon_effects.duplicate()
	copy.tier_iv_weapon_effects = tier_iv_weapon_effects.duplicate()
	copy.tier_i_weapon_effects = tier_i_weapon_effects.duplicate()
	copy.chal_recycling_current = chal_recycling_current
	copy.consumables_picked_up_this_run = consumables_picked_up_this_run
	copy.curse_locked_shop_items_pity = curse_locked_shop_items_pity
	return copy


func serialize() -> Dictionary:
	var serialized_weapons: = []
	for weapon in weapons:
		serialized_weapons.push_back(weapon.serialize())

	var serialized_items: = []
	var serialize_cache = {}
	for item in items:
		if item.is_cursed:
			serialized_items.push_back(item.serialize())
		else:
			var serialized_item = serialize_cache.get(item.my_id)
			if not serialized_item:
				serialized_item = item.serialize()
				serialize_cache[item.my_id] = serialized_item
			serialized_items.push_back(serialized_item)

	var serialized_appearances: = []
	for appearance in appearances:
		serialized_appearances.push_back(appearance.serialize())

	var serialized_active_set_effects: = []
	for active_set_effect in active_set_effects:
		var serialized_effect = active_set_effect[1].serialize()
		serialized_active_set_effects.push_back([active_set_effect[0], serialized_effect])

	return {
		"current_character": current_character.my_id if current_character else null, 
		"current_health": current_health, 
		"current_level": current_level, 
		"current_xp": current_xp, 
		"gold": gold, 
		"selected_weapon": selected_weapon.my_id if selected_weapon else null, 
		"weapons": serialized_weapons, 
		"items": serialized_items, 
		"appearances": serialized_appearances, 
		"effects": _serialize_effects(effects), 
		"active_sets": active_sets.duplicate(), 
		"active_set_effects": serialized_active_set_effects, 
		"unique_effects": unique_effects.duplicate(), 
		"additional_weapon_effects": additional_weapon_effects.duplicate(), 
		"tier_iv_weapon_effects": tier_iv_weapon_effects.duplicate(), 
		"tier_i_weapon_effects": tier_i_weapon_effects.duplicate(), 
		"chal_recycling_current": chal_recycling_current, 
		"consumables_picked_up_this_run": consumables_picked_up_this_run, 
		"curse_locked_shop_items_pity": curse_locked_shop_items_pity
	}


func deserialize(data: Dictionary) -> PlayerRunData:
	current_character = (
		ItemService.get_element(ItemService.characters, data.current_character)
		if data.current_character
		else null
	)

	
	current_health = int(data.current_health)
	current_level = int(data.current_level)
	current_xp = data.current_xp
	gold = int(data.gold)

	if data.selected_weapon != null:
		var weapon_data = ItemService.get_element(ItemService.weapons, data.selected_weapon)

		if weapon_data:
			weapon_data = weapon_data.duplicate()
			selected_weapon = weapon_data

	for weapon in data.weapons:

		if weapon is String:
			continue

		var weapon_data = ItemService.get_element(ItemService.weapons, weapon.my_id)

		if weapon_data:
			weapon_data = weapon_data.duplicate()
			weapon_data.deserialize_and_merge(weapon)
			weapons.push_back(weapon_data)

	for item in data.items:

		if item is String:
			continue

		var item_data = ItemService.get_element(ItemService.items, item.my_id)
		var character_data = ItemService.get_element(ItemService.characters, item.my_id)
		if item_data != null:
			item_data = item_data.duplicate()
			item_data.deserialize_and_merge(item)
			items.push_back(item_data)
		elif character_data != null:
			character_data = character_data.duplicate()
			character_data.deserialize_and_merge(item)
			items.push_back(character_data)

	for appearance in data.appearances:
		var deserialized = ItemAppearanceData.new()
		deserialized.deserialize_and_merge(appearance)
		appearances.push_back(deserialized)

	
	
	
	var weapon_effect_hashes = {}
	_cache_effect_hashes(weapons, weapon_effect_hashes)
	effects = _deserialize_effects(data.effects, weapon_effect_hashes)

	active_sets = data.active_sets.duplicate()
	for k in active_sets.keys():
		
		active_sets[k] = int(active_sets[k])

	for active_set_effect in data.active_set_effects:
		for effect in ItemService.effects:
			if effect.get_id() == active_set_effect[1].effect_id:
				var deserialized_effect = effect.new()
				deserialized_effect.deserialize_and_merge(active_set_effect[1])
				active_set_effects.push_back(
					[active_set_effect[0], deserialized_effect]
				)
				break

	unique_effects = data.unique_effects.duplicate()
	additional_weapon_effects = data.additional_weapon_effects.duplicate()
	tier_iv_weapon_effects = data.tier_iv_weapon_effects.duplicate()
	tier_i_weapon_effects = data.tier_i_weapon_effects.duplicate()

	chal_recycling_current = data.chal_recycling_current
	consumables_picked_up_this_run = data.consumables_picked_up_this_run
	curse_locked_shop_items_pity = data.curse_locked_shop_items_pity if "curse_locked_shop_items_pity" in data else 0

	return self


func _serialize_effects(p_effects: Dictionary):
	var result = {}
	for key in p_effects:
		if RunData.effect_keys_full_serialization.has(key):
			if p_effects[key] is Array:
				result[key] = []
				for element in p_effects[key]:
					result[key].push_back(element.serialize())
			elif p_effects[key] != null:
				result[key] = p_effects[key].serialize()

		elif RunData.effect_keys_with_weapon_stats.has(key):
			if not p_effects[key] is Array:
				return

			result[key] = []
			for element in p_effects[key]:
				
				if element is Array:
					var array = []
					for effect in element:
						if effect is WeaponStats:
							array.push_back(effect.serialize())
						else:
							array.push_back(effect)
					result[key].push_back(array)
				else:
					if element is WeaponStats:
						result[key].push_back(element.serialize())
					else:
						result[key].push_back(element)

		else:
			result[key] = p_effects[key]
	return result


func _deserialize_effects(p_effects: Dictionary, weapon_effect_hashes: Dictionary) -> Dictionary:
	var result = {}
	for key in p_effects:
		if RunData.effect_keys_full_serialization.has(key):
			if p_effects[key] is Array:
				result[key] = []
				for serialized_effect in p_effects[key]:
					var instance = _get_or_deserialize_effect(serialized_effect, weapon_effect_hashes)
					if instance: result[key].push_back(instance)
			elif p_effects[key] != null:
				if key == "burn_chance":
					var instance = BurningData.new()
					instance.deserialize_and_merge(p_effects[key])
					result[key] = instance
				else:
					var instance = _get_or_deserialize_effect(p_effects[key], weapon_effect_hashes)
					if instance: result[key] = instance
		elif RunData.effect_keys_with_weapon_stats.has(key):
			if p_effects[key] is Array:
				result[key] = []
				for serialized_element in p_effects[key]:
					if serialized_element is Array:
						var array = []
						for serialized_effect in serialized_element:
							if serialized_effect is Dictionary:
								var instance = RangedWeaponStats.new()
								instance.deserialize_and_merge(serialized_effect)
								array.push_back(instance)
							else:
								array.push_back(serialized_effect)
						result[key].push_back(array)
					else:
						if serialized_element is Dictionary:
							var instance = RangedWeaponStats.new()
							instance.deserialize_and_merge(serialized_element)
							result[key].push_back(instance)
						else:
							result[key].push_back(serialized_element)

		else:
			result[key] = p_effects[key]

	return result


func _get_or_deserialize_effect(serialized_effect: Dictionary, weapon_effect_hashes: Dictionary):
	var effect_hash = _unsorted_dictionary_hash(serialized_effect)
	var weapon_effects = weapon_effect_hashes.get(effect_hash)
	if weapon_effects and weapon_effects.size() > 0 and weapon_effects.back().get_id() == serialized_effect.effect_id:
		
		
		
		
		var effect = weapon_effects.pop_back()
		if weapon_effects.size() == 0:
			var _removed = weapon_effect_hashes.erase(effect_hash)
		return effect
	
	for effect in ItemService.effects:
		if effect.get_id() == serialized_effect.effect_id:
			var instance = effect.new()
			instance.deserialize_and_merge(serialized_effect)
			return instance
	return null


func _cache_effect_hashes(elements: Array, weapon_effect_hashes: Dictionary) -> void :
		for element in elements:
			for effect in element.effects:
				var effect_hash = _unsorted_dictionary_hash(effect.serialize())
				var existing_effects = weapon_effect_hashes.get(effect_hash)
				if existing_effects == null:
					weapon_effect_hashes[effect_hash] = [effect]
				else:
					existing_effects.push_back(effect)


func _unsorted_dictionary_hash(dictionary: Dictionary) -> int:
	
	
	
	var sort_keys = true
	return JSON.print(dictionary, "", sort_keys).hash()


static func init_stats(all_null_values: bool = false) -> Dictionary:
	var stats: = {
		"stat_max_hp": DEFAULT_MAX_HP if not all_null_values else 0, 
		"stat_armor": 0, 
		"stat_crit_chance": 0, 
		"stat_luck": 0, 
		"stat_attack_speed": 0, 
		"stat_elemental_damage": 0, 
		"stat_hp_regeneration": 0, 
		"stat_lifesteal": 0, 
		"stat_melee_damage": 0, 
		"stat_percent_damage": 0, 
		"stat_dodge": 0, 
		"stat_engineering": 0, 
		"stat_range": 0, 
		"stat_ranged_damage": 0, 
		"stat_speed": 0, 
		"stat_harvesting": 0, 
		"xp_gain": 0, 
		"number_of_enemies": 0, 
		"consumable_heal": 0, 
		"burning_cooldown_reduction": 0, 
		"burning_cooldown_increase": 0, 
		"burning_spread": 0, 
		"piercing": 0, 
		"piercing_damage": 0, 
		"pickup_range": 0, 
		"chance_double_gold": 0, 
		"bounce": 0, 
		"bounce_damage": 0, 
		"heal_when_pickup_gold": 0, 
		"item_box_gold": 0, 
		"knockback": 0, 
		"hp_cap": Utils.LARGE_NUMBER if not all_null_values else 0, 
		"speed_cap": Utils.LARGE_NUMBER if not all_null_values else 0, 
		"lose_hp_per_second": 0, 
		"map_size": 0, 
		"dodge_cap": 60, 
		"crit_chance_cap": Utils.LARGE_NUMBER if not all_null_values else 0, 
		"gold_drops": 0, 
		"enemy_health": 0, 
		"enemy_damage": 0, 
		"enemy_speed": 0, 
		"boss_strength": 0, 
		"explosion_size": 0, 
		"explosion_damage": 0, 
		"damage_against_bosses": 0, 
		"weapon_slot": 6 if not all_null_values else 0, 
		"items_price": 0, 
		"reroll_price": 0, 
		"harvesting_growth": 5 if not all_null_values else 0, 
		"hit_protection": 0, 
		"weapons_price": 0, 
		"structure_attack_speed": 0, 
		"structure_percent_damage": 0, 
		"structure_range": 0, 
	}
	for stat in ItemService.stats:
		if stat.is_dlc_stat:
			stats[stat.stat_name] = 0
	return stats


static func init_effects() -> Dictionary:
	var all_stats = init_stats()
	var all_effects = {
		"gain_stat_max_hp": 0, 
		"gain_stat_armor": 0, 
		"gain_stat_crit_chance": 0, 
		"gain_stat_luck": 0, 
		"gain_stat_attack_speed": 0, 
		"gain_stat_elemental_damage": 0, 
		"gain_stat_hp_regeneration": 0, 
		"gain_stat_lifesteal": 0, 
		"gain_stat_melee_damage": 0, 
		"gain_stat_percent_damage": 0, 
		"gain_stat_dodge": 0, 
		"gain_stat_engineering": 0, 
		"gain_stat_range": 0, 
		"gain_stat_ranged_damage": 0, 
		"gain_stat_speed": 0, 
		"gain_stat_harvesting": 0, 
		"gain_stat_curse": 0, 
		"no_melee_weapons": 0, 
		"no_ranged_weapons": 0, 
		"no_duplicate_weapons": 0, 
		"hp_start_wave": 100, 
		"hp_start_next_wave": 100, 
		"pacifist": 0, 
		"cryptid": 0, 
		"gain_pct_gold_start_wave": 0, 
		"torture": 0, 
		"recycling_gains": 0, 
		"one_shot_trees": 0, 
		"max_ranged_weapons": 999, 
		"max_melee_weapons": 999, 
		"group_structures": 0, 
		"can_attack_while_moving": 1, 
		"trees": 0, 
		"trees_start_wave": 0, 
		"min_weapon_tier": 0, 
		"max_weapon_tier": 99, 
		"hp_shop": 0, 
		"free_rerolls": 0, 
		"instant_gold_attracting": 0, 
		"double_boss": 0, 
		"gain_explosion_damage": 0, 
		"gain_piercing_damage": 0, 
		"gain_bounce_damage": 0, 
		"gain_damage_against_bosses": 0, 
		"neutral_gold_drops": 0, 
		"enemy_gold_drops": 0, 
		"wandering_bots": 0, 
		"can_burn_enemies": 1, 
		"danger_enemy_health": 0, 
		"danger_enemy_damage": 0, 
		"dmg_when_pickup_gold": [], 
		"dmg_when_death": [], 
		"dmg_when_heal": [], 
		"dmg_on_dodge": [], 
		"heal_on_dodge": [], 
		"remove_speed": [], 
		"starting_item": [], 
		"cursed_starting_item": [], 
		"starting_weapon": [], 
		"cursed_starting_weapon": [], 
		"projectiles_on_death": [], 
		"burn_chance": BurningData.new(), 
		"burning_enemy_hp_percent_damage": [], 
		"weapon_class_bonus": [], 
		"unique_weapon_effects": [], 
		"additional_weapon_effects": [], 
		"tier_iv_weapon_effects": [], 
		"tier_i_weapon_effects": [], 
		"gold_on_crit_kill": [], 
		"heal_on_crit_kill": 0, 
		"temp_stats_while_not_moving": [], 
		"temp_stats_while_moving": [], 
		"temp_stats_on_hit": [], 
		"stats_end_of_wave": [], 
		"stat_links": [], 
		"structures": [], 
		"explode_on_hit": [], 
		"explode_when_below_hp": [], 
		"convert_stats_end_of_wave": [], 
		"explode_on_death": [], 
		"alien_eyes": [], 
		"upgrade_random_weapon": [], 
		"minimum_weapons_in_shop": 0, 
		"destroy_weapons": 0, 
		"extra_enemies_next_wave": [], 
		"extra_loot_aliens_next_wave": 0, 
		"extra_loot_aliens": 0, 
		"stats_next_wave": [], 
		"consumable_stats_while_max": [], 
		"temp_consumable_stats_while_max": [], 
		"explode_on_consumable": [], 
		"explode_on_consumable_burning": [], 
		"structures_cooldown_reduction": [], 
		"convert_stats_half_wave": [], 
		"stats_on_level_up": [], 
		"temp_stats_on_dodge": [], 
		"no_heal": 0, 
		"tree_turrets": 0, 
		"stats_below_half_health": [], 
		"guaranteed_shop_items": [], 
		"special_enemies_last_wave": 0, 
		"specific_items_price": [], 
		"accuracy": 0, 
		"projectiles": 0, 
		"upgraded_baits": 0, 
		"minimum_weapon_cooldowns": [], 
		"maximum_weapon_cooldowns": [], 
		"burning_enemy_speed": 0, 
		"weapon_scaling_stats": [], 
		"slow_on_hit": [], 
		"enemy_percent_damage_taken": [], 
		"gain_stat_for_equipped_item_with_stat": [], 
		"weapon_slot_upgrades": 0, 
		"next_level_xp_needed": 0, 
		"all_weapons_count_for_sets": 0, 
		"structures_can_crit": 0, 
		"landmines_on_death_chance": [], 
		"temp_stats_on_structure_crit": [], 
		"gain_stat_for_every_step_after_equip": [], 
		"decaying_stats_on_consumable": [], 
		"decaying_stats_on_hit": [], 
		"temp_stats_per_interval": [], 
		"pierce_on_crit": 0, 
		"bounce_on_crit": 0, 
		"consumable_heal_over_time": 0, 
		"lock_current_weapons": 0, 
		"knockback_aura": 0, 
		"level_upgrades_modifications": 0, 
		"enemy_fruit_drops": 0, 
		"stats_on_fruit": [], 
		"duplicate_item": [], 
		"poisoned_fruit": 0, 
		"gain_stat_when_attack_killed_enemies": [], 
		"extra_item_in_crate": [], 
		"bonus_damage_against_targets_above_hp": [], 
		"bonus_damage_against_targets_below_hp": [], 
		"heal_on_kill": 0, 
		"modify_every_x_projectile": [], 
		"gold_on_cursed_enemy_kill": 0, 
		"giant_crit_damage": [], 
		"loot_alien_speed": 0, 
		"bonus_non_elemental_damage_against_burning_targets": 0, 
		"bonus_weapon_class_damage_against_cursed_enemies": [], 
		"item_steals": 0, 
		"item_steals_spawns_enemy": [], 
		"item_steals_spawns_random_elite": 0, 
		"disable_item_locking": 0, 
		"explode_on_overkill": [], 
		"crate_chance": 0, 
		"loot_alien_chance": 0, 
		"gain_stat_for_duplicate_items": [], 
		"max_turret_count": Utils.LARGE_NUMBER, 
		"convert_bonus_gold": [], 
		"remove_shop_items": [], 
		"charm_on_hit": [], 
		"materials_per_living_enemy": 0, 
		"negative_knockback": 0, 
		"weapon_type_bonus": [], 
		"scale_materials_with_distance": [], 
		"curse_locked_items": 0, 
		"increase_tier_on_reroll": [], 
		"reload_when_pickup_gold": 0, 
		"increase_material_value": 0, 
		"gain_stats_on_reroll": [], 
		"stronger_elites_on_kill": 0, 
		"stronger_loot_aliens_on_kill": 0, 
		"hp_regen_bonus": []
	}

	all_effects.merge(all_stats)

	return all_effects
