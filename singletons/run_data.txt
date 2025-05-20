extends Node

signal levelled_up(player_index)
signal gold_changed(new_value, player_index)
signal bonus_gold_changed(new_value)
signal xp_added(current_xp, max_xp, player_index)
signal stat_added(stat_name, value, db_mod, player_index)
signal stat_removed(stat_name, value, db_mod, player_index)
signal stats_updated(player_index)
signal enemy_charmed(enemy)
signal bonus_gold_converted(total_bonus_gold, nb_materials_per_conversion, nb_stats_added_per_conversion)

signal damage_effect(value, player_index, armor_applied, dodgeable)
signal lifesteal_effect(value, player_index)
signal healing_effect(value, player_index, tracking_key)
signal heal_over_time_effect(total_healing, duration, player_index)

const ENDLESS_HARVESTING_DECREASE: = 20


const DUMMY_PLAYER_INDEX: = 123


var players_data: = []
var dummy_player_effects: Dictionary
var dummy_player_remove_speed_data: Dictionary

var effect_keys_full_serialization = [
	"burn_chance", "structures", "explode_on_hit", "explode_when_below_hp", "explode_on_death", "explode_on_consumable", 
		"convert_stats_end_of_wave", "convert_stats_half_wave", "modify_every_x_projectile", "explode_on_overkill", 
		"explode_on_consumable_burning", "convert_bonus_gold", "scale_materials_with_distance", 
]

var effect_keys_with_weapon_stats = [
	"projectiles_on_death", "alien_eyes"
]

var init_tracked_items: = {
	"item_vigilante_ring": 0, 
	"item_alien_eyes": 0, 
	"item_baby_elephant": 0, 
	"item_cyberball": 0, 
	"item_baby_with_a_beard": 0, 
	"item_bag": 0, 
	"item_crown": 0, 
	"item_cute_monkey": 0, 
	"item_dangerous_bunny": 0, 
	"item_hunting_trophy": 0, 
	"item_metal_detector": 0, 
	"item_piggy_bank": 0, 
	"item_rip_and_tear": 0, 
	"item_tree": 0, 
	"item_anvil": 0, 
	"item_grinds_magical_leaf": 0, 
	"item_scared_sausage": 0, 
	"item_recycling_machine": 0, 
	"item_coupon": 0, 
	"character_lich": 0, 
	"item_riposte": 0, 
	"item_adrenaline": 0, 
	"item_spicy_sauce": 0, 
	"item_tentacle": 0, 
	"item_giant_belt": 0, 
	"item_extra_stomach": 0, 
	"character_glutton": 0, 
	"item_greek_fire": 0, 
	"item_snowball": 0, 
	"item_goblet": 0, 
	"item_black_flag": 0, 
	"item_decomposing_flesh": 0, 
	"item_celery_tea": 0, 
	"item_robot_arm": 0, 
	"item_bone_dice": [0, 0], 
	"item_sunken_bell": 0, 
	"item_krakens_eye": 0, 
	"character_lucky": 0, 
	"item_turret": 0, 
	"item_turret_flame": 0, 
	"item_turret_healing": 0, 
	"item_tyler": 0, 
	"item_turret_laser": 0, 
	"item_turret_rocket": 0, 
	"item_landmines": 0, 
	"character_bull": 0, 
	"character_ogre": 0, 
	"character_hiker": [0, 0], 
	"character_builder": 0, 
	"item_builder_turret_0": 0, 
	"item_builder_turret_1": 0, 
	"item_builder_turret_2": 0, 
	"item_builder_turret_3": 0, 
	"character_druid": 0, 
	"item_barnacle": 0, 
	"item_baby_squid": 0, 
	"item_ashes": 0, 
	"character_chef": 0, 
	"item_treasure_map": 0, 
	"character_dwarf": 0, 
	"item_fish_hook": 0
}

var remove_speed_effect_cache: = [{}, {}, {}, {}]
var items_nb_cache: = [{}, {}, {}, {}]
var different_items_nb_cache: = [{}, {}, {}, {}]
var duplicate_items_cache: = [null, null, null, null]
var max_consumable_stats_gained_this_wave: = [[], [], [], []]
var tracked_item_effects: = [{}, {}, {}, {}]
var _are_player_stats_dirty: = [false, false, false, false]


var current_run_accessibility_settings: Dictionary

var current_living_enemies: = 0
var current_living_trees: = 0
var current_burning_enemies: = 0
var current_charmed_enemies: = [0, 0, 0, 0]
var steps_taken_this_wave: = [0, 0, 0, 0]

var start_wave_state: = {}
var last_saved_run_state: = {}
var wave_in_progress: = false
var resumed_from_state_in_shop: = false
var nb_of_waves: = 20

var elites_spawn: = []
var bosses_spawn: = []
var elites_killed_this_run: = []
var bosses_killed_this_run: = []
var loot_aliens_killed_this_run: = 0
var current_zone: = 0
var current_wave: int
var current_difficulty: int
var bonus_gold: int
var total_bonus_gold: int
var run_won: bool
var challenges_completed_this_run: = []
var reload_music = true
var retries: = 0
var all_last_wave_bosses_killed = false

var locked_shop_items: = [[], [], [], []]
var current_background = null

var shop_effects_checked = false

var instant_waves = false
var invulnerable = false

var difficulty_unlocked = - 1
var max_endless_wave_record_beaten = - 1
var is_endless_run = false
var is_coop_run = false
var enabled_dlcs = []


func _ready() -> void :
	if DebugService.unlock_all_challenges:
		for chal in ChallengeService.challenges:
			ChallengeService.complete_challenge(chal.my_id)

	if DebugService.reinitialize_store_data:
		Platform.reinitialize_store_data()

	dummy_player_effects = PlayerRunData.init_effects()
	dummy_player_remove_speed_data = init_remove_speed_data(DUMMY_PLAYER_INDEX)


func on_wave_start() -> void :
	_reset_per_wave_properties()
	start_wave_state = get_state()
	wave_in_progress = true
	shop_effects_checked = false


func on_wave_end() -> void :
	var max_steps_taken: = 0.0
	for steps_taken in steps_taken_this_wave:
		max_steps_taken = max(max_steps_taken, steps_taken)
	ProgressData.data["steps_taken"] += int(max_steps_taken)
	_reset_per_wave_properties()


func _reset_per_wave_properties() -> void :
	start_wave_state.clear()
	current_living_enemies = 0
	current_living_trees = 0
	current_burning_enemies = 0
	current_charmed_enemies = [0, 0, 0, 0]
	steps_taken_this_wave = [0, 0, 0, 0]
	wave_in_progress = false


func get_player_count() -> int:
	return players_data.size()


func reset_players_data_stats_and_effects() -> void :
	for player_data in players_data:
		player_data.effects = PlayerRunData.init_effects()


func set_player_count(count: int, reset: = false) -> void :
	if reset:
		players_data.clear()
	while players_data.size() < count:
		var player_data: PlayerRunData = PlayerRunData.new()
		player_data.gold = DebugService.starting_gold
		if DebugService.randomize_equipment:
			player_data.gold = Utils.randi_range(10, 500)
			player_data.current_level = Utils.randi_range(10, 26)
		players_data.push_back(player_data)
	players_data.resize(count)


func get_player_character(player_index: int) -> CharacterData:
	assert (player_index >= 0)
	return players_data[player_index].current_character


func get_player_current_health(player_index: int) -> int:
	assert (player_index >= 0)
	
	return players_data[player_index].current_health if wave_in_progress else get_player_max_health(player_index)


func get_player_max_health(player_index: int) -> int:
	return max(1, Utils.get_capped_stat("stat_max_hp", player_index)) as int


func get_player_missing_health(player_index: int) -> int:
	return get_player_max_health(player_index) - get_player_current_health(player_index)


func get_player_level(player_index: int) -> int:
	assert (player_index >= 0)
	if player_index == DUMMY_PLAYER_INDEX:
		return 0
	return players_data[player_index].current_level


func get_player_xp(player_index: int) -> float:
	assert (player_index >= 0)
	return players_data[player_index].current_xp


func get_player_gold(player_index: int) -> int:
	assert (player_index >= 0)
	if player_index == DUMMY_PLAYER_INDEX:
		return 0
	return players_data[player_index].gold


func get_player_weapons(player_index: int) -> Array:
	assert (player_index >= 0)
	if player_index == DUMMY_PLAYER_INDEX:
		return []
	return players_data[player_index].weapons.duplicate()


func get_player_item(item_id: String, player_index: int) -> ItemData:
	for player_item in get_player_items(player_index):
		if player_item.my_id == item_id:
			return player_item

	return null


func existing_weapon_has_effect(effect_key: String) -> bool:
	for i in players_data.size():
		var player_weapons = get_player_weapons(i)
		for weapon in player_weapons:
			for effect in weapon.effects:
				if effect.key == effect_key or effect.custom_key == effect_key:
					return true

	return false


func get_player_sets(player_index: int) -> Array:
	assert (player_index >= 0)
	if player_index == DUMMY_PLAYER_INDEX:
		return []
	return players_data[player_index].active_sets.keys()


func get_player_appearances(player_index: int) -> Array:
	assert (player_index >= 0)
	return players_data[player_index].appearances.duplicate()


func get_player_items(player_index: int) -> Array:
	assert (player_index >= 0)
	if player_index == DUMMY_PLAYER_INDEX:
		return []
	return players_data[player_index].items.duplicate()


func get_player_effects(player_index: int) -> Dictionary:
	assert (player_index >= 0)
	if player_index == DUMMY_PLAYER_INDEX:
		return dummy_player_effects
	return players_data[player_index].effects


func get_player_effect(key: String, player_index: int):
	assert (player_index >= 0, key)
	return get_player_effects(player_index)[key]


func get_player_effect_bool(key: String, player_index: int) -> bool:
	assert (player_index >= 0, key)
	return get_player_effect(key, player_index) > 0


func sum_all_player_effects(key: String) -> int:
	var sum: = 0
	for player_data in players_data:
		sum += player_data.effects[key]
	return sum


func concat_all_player_effects(key: String) -> Array:
	var result: = []
	for player_data in players_data:
		result.append_array(player_data.effects.get(key, []))
	return result


func get_player_selected_weapon(player_index: int) -> WeaponData:
	assert (player_index >= 0)
	return players_data[player_index].selected_weapon


func get_player_locked_shop_items(player_index: int) -> Array:
	assert (player_index >= 0)
	return locked_shop_items[player_index].duplicate()


func lock_player_shop_item(item_data: ItemParentData, wave_value: int, player_index: int) -> void :
	locked_shop_items[player_index].push_back([item_data, wave_value])


func unlock_player_shop_item(item_data: ItemParentData, player_index: int) -> void :
	var player_locked_items = locked_shop_items[player_index]
	for locked_item in player_locked_items:
		if locked_item[0].my_id == item_data.my_id:
			player_locked_items.erase(locked_item)
			break


func reset(restart: bool = false) -> void :
	current_run_accessibility_settings = ProgressData.settings.enemy_scaling.duplicate()

	reset_background()
	reset_weapons_dmg_dealt()
	reset_weapons_tracked_value_this_wave()
	reset_wave_caches()
	reset_run_caches()

	for player_index in tracked_item_effects.size():
		tracked_item_effects[player_index] = init_tracked_effects()

	if not restart:
		set_player_count(1, true)
		is_coop_run = false
		is_endless_run = false
		enabled_dlcs = []
		current_difficulty = 0
		ProgressData.reset_dlc_resources_to_active_dlcs()
	else:
		var characters: = []
		for player_data in players_data:
			characters.push_back(player_data.current_character)

		var selected_weapons: = []
		for player_data in players_data:
			selected_weapons.push_back(player_data.selected_weapon)

		set_player_count(get_player_count(), true)
		for i in characters.size():
			var character = characters[i]
			add_character(character, i)

		for i in selected_weapons.size():
			var selected_weapon = selected_weapons[i]
			if selected_weapon:
				var _weapon = add_weapon(selected_weapon, i, true)

		add_starting_items_and_weapons()

		var difficulty = ItemService.get_element(ItemService.difficulties, "", current_difficulty)

		
		for effect in difficulty.effects:
			effect.apply(0)

	_reset_per_wave_properties()
	DebugService.reset_for_new_run()

	init_elites_spawn()
	init_bosses_spawn()

	resumed_from_state_in_shop = false
	shop_effects_checked = false
	bonus_gold = 0
	total_bonus_gold = 0
	retries = 0
	elites_killed_this_run = []
	bosses_killed_this_run = []
	loot_aliens_killed_this_run = 0
	challenges_completed_this_run = []
	run_won = false
	all_last_wave_bosses_killed = false
	locked_shop_items = [[], [], [], []]
	difficulty_unlocked = - 1
	max_endless_wave_record_beaten = - 1
	current_wave = DebugService.starting_wave

	if DebugService.randomize_waves:
		current_wave = Utils.randi_range(9, 20)

	
	instant_waves = DebugService.instant_waves
	invulnerable = DebugService.invulnerable

	TempStats.reset()
	LinkedStats.reset()
	ItemService.init_unlocked_pool()

	InputService.hide_mouse = true





func reset_wave_caches() -> void :
	for player_index in remove_speed_effect_cache.size():
		if player_index >= get_player_count():
			remove_speed_effect_cache[player_index].clear()
			continue
		remove_speed_effect_cache[player_index] = init_remove_speed_data(player_index)

	for player_index in max_consumable_stats_gained_this_wave.size():
		if player_index >= get_player_count():
			max_consumable_stats_gained_this_wave[player_index].clear()
			continue
		var consumable_stats_while_max = get_player_effect("consumable_stats_while_max", player_index)
		var copied_array: = []
		for stat in consumable_stats_while_max:
			var copied_stat = stat.duplicate()
			if copied_stat.size() > 2:
				
				copied_stat[2] = 0
			copied_array.push_back(copied_stat)
		max_consumable_stats_gained_this_wave[player_index] = copied_array


func reset_run_caches() -> void :
	for cache in items_nb_cache:
		cache.clear()

	for cache in different_items_nb_cache:
		cache.clear()

	duplicate_items_cache = [null, null, null, null]


func init_bosses_spawn() -> void :
	bosses_spawn = get_bosses_to_spawn(sum_all_player_effects("double_boss") > 0)


func get_bosses_to_spawn(double_boss: bool) -> Array:
	var new_bosses_spawn = []
	var possible_bosses = ItemService.get_bosses_from_zone(current_zone)
	var nb_bosses = 1

	if double_boss:
		nb_bosses = 2

	for i in nb_bosses:
		var boss_id = Utils.get_rand_element(possible_bosses).my_id

		for boss in possible_bosses:
			if boss.my_id == boss_id:
				possible_bosses.erase(boss)
				break

		new_bosses_spawn.push_back(boss_id)

	return new_bosses_spawn


func init_elites_spawn(base_wave: int = 10, horde_chance: float = 0.4) -> void :
	elites_spawn = []
	var diff = current_difficulty
	var nb_elites = 0
	var possible_elites = ItemService.get_elites_from_zone(current_zone)

	for player_index in get_player_count():
		var current_character = get_player_character(player_index)
		if current_character != null:
			if current_character.my_id == "character_jack" or current_character.my_id == "character_gangster":
				horde_chance = 0.0
			elif get_player_count() == 1 and current_character.my_id == "character_ogre":
				horde_chance = 1.0

	if diff < 2:
		return
	elif diff < 4:
		nb_elites = 1
	else:
		nb_elites = 3

	var wave = Utils.randi_range(base_wave + 1, base_wave + 2)

	for i in nb_elites:

		var type = EliteType.HORDE if Utils.get_chance_success(horde_chance) else EliteType.ELITE

		if DebugService.spawn_specific_elite != "":
			type = EliteType.ELITE
			wave = DebugService.starting_wave
		elif DebugService.spawn_horde:
			type = EliteType.HORDE
			wave = DebugService.starting_wave

		if i == 1:
			wave = Utils.randi_range(base_wave + 4, base_wave + 5)
		elif i == 2:
			wave = Utils.randi_range(base_wave + 7, base_wave + 8)
			type = EliteType.ELITE

		var elite_id = Utils.get_rand_element(possible_elites).my_id if type == EliteType.ELITE else ""

		for elite in possible_elites:
			if elite.my_id == elite_id:
				possible_elites.erase(elite)
				break

		elites_spawn.push_back([wave, type, elite_id])


func is_elite_wave(type: int = - 1) -> bool:
	var is_elite = false

	for elite_spawn in elites_spawn:
		if elite_spawn[0] == current_wave and (type == - 1 or elite_spawn[1] == type):
			is_elite = true
			break

	return is_elite


func is_in_last_waves() -> bool:
	return current_wave >= nb_of_waves - 1


func remove_bonus_gold(value: int) -> void :
	set_bonus_gold(bonus_gold - value)


func add_bonus_gold(value: int, check_conversions: bool = true) -> void :
	var old_total: = total_bonus_gold
	var new_total: = old_total + value
	total_bonus_gold = new_total

	var is_bonus_gold_converted: = false

	if not check_conversions:
		set_bonus_gold(bonus_gold + value)
		return

	
	var nb_materials_per_conversion = 0
	var nb_stats_added_per_conversion = 0

	for player_index in range(get_player_count()):
		for effect in get_player_effect("convert_bonus_gold", player_index):
			is_bonus_gold_converted = true

			nb_stats_added_per_conversion = 0
			nb_materials_per_conversion = effect.value

			for sub_effect in effect.sub_effects:
				nb_stats_added_per_conversion += sub_effect.value

			var already_converted_before = floor(old_total / get_player_count() / effect.value) as int
			var to_convert = new_total / get_player_count() - (already_converted_before * effect.value)

			while to_convert >= effect.value:
				to_convert -= effect.value
				var value_added = 0
				for sub_effect in effect.sub_effects:
					sub_effect.apply(player_index)
					value_added += sub_effect.value
				add_tracked_value(player_index, "character_builder", value_added, 1)

	emit_signal("bonus_gold_converted", total_bonus_gold, nb_materials_per_conversion, nb_stats_added_per_conversion)


	if not is_bonus_gold_converted:
		set_bonus_gold(bonus_gold + value)


func set_bonus_gold(value: int) -> void :
	bonus_gold = max(0, value) as int
	emit_signal("bonus_gold_changed", bonus_gold)


func add_xp(value: int, player_index: int) -> void :

	if value <= 0:
		return

	var player_data = players_data[player_index]
	player_data.current_xp += value * (1 + (Utils.get_stat("xp_gain", player_index) / 100.0))

	var next_level_xp = get_next_level_xp_needed(player_index)
	emit_signal("xp_added", player_data.current_xp, next_level_xp, player_index)

	while player_data.current_xp >= next_level_xp:
		level_up(player_index)
		
		emit_signal("xp_added", player_data.current_xp, next_level_xp, player_index)
		next_level_xp = get_next_level_xp_needed(player_index)


func get_next_level_xp_needed(player_index) -> float:
	return get_xp_needed(get_player_level(player_index) + 1) * (1.0 + get_player_effect("next_level_xp_needed", player_index) / 100.0)


func get_xp_needed(level: int) -> float:
	return pow(3 + level, 2)


func get_endless_factor(p_wave: int = - 1) -> float:

	var wave = p_wave if p_wave != - 1 else current_wave
	var endless_wave = max(0, wave - 20)
	var endless_mult = 2.0 + max(0.0, (wave - 35) * 0.2)
	var endless_factor = max(0.0, ((endless_wave * (endless_wave + 1)) / 2) / 100.0) * endless_mult

	return endless_factor


func get_additional_elites_endless() -> Array:
	var new_elites = []
	if current_wave > nb_of_waves:
		var nb_of_additional_elites = ceil((current_wave - 20.0) / 10.0)
		for i in nb_of_additional_elites:
			new_elites.push_back(ItemService.get_random_elite_id_from_zone(ZoneService.current_zone.my_id))

	return new_elites


func level_up(player_index: int) -> void :
	var player_data = players_data[player_index]
	player_data.current_xp = max(0, player_data.current_xp - get_next_level_xp_needed(player_index))
	player_data.current_level += 1
	emit_signal("levelled_up", player_index)

	var chal_student = ChallengeService.get_chal("chal_student")
	if player_data.current_level >= chal_student.value:
		ChallengeService.complete_challenge("chal_student")

	var chal_fast_learner = ChallengeService.get_chal("chal_fast_learner")
	if player_data.current_level >= chal_fast_learner.value and current_wave < chal_fast_learner.additional_args[0]:
		ChallengeService.complete_challenge("chal_fast_learner")


func add_gold(value: int, player_index: int) -> void :
	if value == 0:
		return

	var player_data = players_data[player_index]
	var old_value = player_data.gold
	player_data.gold += value
	var new_value = player_data.gold
	if LinkedStats.should_update_on_gold_change(player_index, old_value, new_value):
		LinkedStats.reset_player(player_index)

	ChallengeService.try_complete_challenge("chal_hoarder", player_data.gold)

	emit_signal("gold_changed", player_data.gold, player_index)


func remove_gold(value: int, player_index: int) -> void :
	var player_data = players_data[player_index]
	var old_value = player_data.gold
	player_data.gold = max(0, player_data.gold - value) as int
	var new_value = player_data.gold
	if LinkedStats.should_update_on_gold_change(player_index, old_value, new_value):
		LinkedStats.reset_player(player_index)

	emit_signal("gold_changed", player_data.gold, player_index)




func apply_common_gold_pickup_effects(value: int, player_index: int) -> int:
	var boost: = 1
	if Utils.get_chance_success(get_player_effect("chance_double_gold", player_index) / 100.0):
		add_tracked_value(player_index, "item_metal_detector", value)
		boost = 2
	return boost


func add_character(character: CharacterData, player_index: int) -> void :
	players_data[player_index].current_character = character
	add_item(character, player_index)


func add_item(item: ItemData, player_index: int) -> void :
	players_data[player_index].items.push_back(item)
	_update_item_caches(item, player_index)
	apply_item_effects(item, player_index)
	add_item_displayed(item, player_index)
	update_item_related_effects(player_index)
	LinkedStats.reset_player(player_index)
	_check_bait_chal(item.my_id, player_index)
	check_scavenger_chal()


func remove_item(item: ItemData, player_index: int, by_id: bool = false) -> void :
	for i in players_data[player_index].items.size():
		var cond = ItemService.is_same_item(item, players_data[player_index].items[i])

		if by_id:
			cond = item.my_id == players_data[player_index].items[i].my_id

		if cond:
			players_data[player_index].items.erase(players_data[player_index].items[i])
			break

	_update_item_caches(item, player_index)
	unapply_item_effects(item, player_index)
	remove_item_displayed(item, player_index)
	update_item_related_effects(player_index)
	LinkedStats.reset_player(player_index)

	if item.replaced_by:
		add_item(item.replaced_by, player_index)


func check_scavenger_chal() -> void :
	for player_data in players_data:
		var parsed_items = {}
		var nb_unique_commons = 0

		for item in player_data.items:
			if item.tier <= Tier.COMMON and not parsed_items.has(item.my_id):
				parsed_items[item.my_id] = true
				nb_unique_commons += 1

		if nb_unique_commons >= ChallengeService.get_chal("chal_scavenger").value:
			ChallengeService.complete_challenge("chal_scavenger")
			break


func _check_bait_chal(item_id: String, player_index: int) -> void :
	if item_id == "item_bait":
		var nb_baits = 0

		for player_item in get_player_items(player_index):
			if player_item.my_id == "item_bait":
				nb_baits += 1

		if nb_baits >= ChallengeService.get_chal("chal_baited").value:
			ChallengeService.complete_challenge("chal_baited")


func add_weapon(weapon: WeaponData, player_index: int, is_selection: bool = false) -> WeaponData:
	var new_weapon = weapon.duplicate()
	if is_selection:
		players_data[player_index].selected_weapon = new_weapon

	players_data[player_index].weapons.push_back(new_weapon)
	_update_item_caches(weapon, player_index)
	apply_item_effects(new_weapon, player_index)
	update_sets(player_index)
	update_item_related_effects(player_index)
	LinkedStats.reset_player(player_index)

	check_bourgeoisie_chal()
	check_experimentation_chal()

	return new_weapon


func check_bourgeoisie_chal() -> void :
	for player_data in players_data:
		var legendaries = 0

		for weapon in player_data.weapons:
			if weapon.tier >= Tier.LEGENDARY:
				legendaries += 1

		if legendaries >= ChallengeService.get_chal("chal_bourgeoisie").value:
			ChallengeService.complete_challenge("chal_bourgeoisie")
			break


func check_experimentation_chal() -> void :
	for player_data in players_data:
		if player_data.weapons.size() >= ChallengeService.get_chal("chal_experimentation").value:
			var checked_weapons = {}
			for weapon in player_data.weapons:
				if not checked_weapons.has(weapon.weapon_id):
					checked_weapons[weapon.weapon_id] = 1
				else:
					checked_weapons[weapon.weapon_id] += 1
			if checked_weapons.size() >= ChallengeService.get_chal("chal_experimentation").value:
				ChallengeService.complete_challenge("chal_experimentation")
				break


func remove_weapon_by_index(index: int, player_index: int) -> int:
	var removed_weapon_tracked_value = 0
	var weapon = players_data[player_index].weapons[index]
	removed_weapon_tracked_value = weapon.tracked_value
	players_data[player_index].weapons.remove(index)
	after_weapon_removed(weapon, player_index)
	return removed_weapon_tracked_value


func remove_weapon(weapon: WeaponData, player_index: int) -> int:
	var removed_weapon_tracked_value = 0
	var weapons: Array = players_data[player_index].weapons
	for current_weapon in weapons:
		if ItemService.is_same_weapon(current_weapon, weapon):
			removed_weapon_tracked_value = current_weapon.tracked_value
			weapons.erase(current_weapon)
			break
	after_weapon_removed(weapon, player_index)
	return removed_weapon_tracked_value


func after_weapon_removed(weapon: WeaponData, player_index: int) -> void :
	unapply_item_effects(weapon, player_index)
	update_sets(player_index)
	update_item_related_effects(player_index)
	LinkedStats.reset_player(player_index)
	ChallengeService.check_stat_challenges(player_index)


func remove_all_weapons(player_index: int) -> void :
	var player_data = players_data[player_index]
	var weapons = player_data.weapons
	for weapon in player_data.weapons:
		unapply_item_effects(weapon, player_index)
	weapons.clear()

	_update_item_caches(WeaponData.new(), player_index)
	update_sets(player_index)
	update_item_related_effects(player_index)
	LinkedStats.reset_player(player_index)
	ChallengeService.check_stat_challenges(player_index)


func add_weapon_dmg_dealt(pos: int, dmg_dealt: int, player_index: int) -> void :
	var weapons: = get_player_weapons(player_index)
	if pos < weapons.size():
		weapons[pos].dmg_dealt_last_wave += dmg_dealt


func reset_weapons_dmg_dealt() -> void :
	for player_data in players_data:
		for weapon in player_data.weapons:
			weapon.dmg_dealt_last_wave = 0


func reset_weapons_tracked_value_this_wave() -> void :
	for player_data in players_data:
		for weapon in player_data.weapons:
			weapon.tracked_value_added_this_wave = 0


func update_sets(player_index: int) -> void :
	var player_data = players_data[player_index]
	var active_set_effects = player_data.active_set_effects
	var active_sets = player_data.active_sets

	for effect in active_set_effects:
		effect[1].unapply(player_index)

	active_sets.clear()
	active_set_effects.clear()

	var weapons: = get_player_weapons(player_index)
	for weapon in weapons:
		for set in weapon.sets:
			if get_player_effect_bool("all_weapons_count_for_sets", player_index):
				active_sets[set.my_id] = weapons.size()
			elif active_sets.has(set.my_id):
				active_sets[set.my_id] += 1
			else:
				active_sets[set.my_id] = 1

	for key in active_sets:
		if active_sets[key] >= 2:
			var set = ItemService.get_set(key)
			var set_effects = set.set_bonuses[min(active_sets[key] - 2, set.set_bonuses.size() - 1)]

			for effect in set_effects:
				effect.apply(player_index)
				active_set_effects.push_back([key, effect])


func get_unique_weapon_ids(player_index: int) -> Dictionary:
	var unique_weapon_ids = {}

	var weapons: = get_player_weapons(player_index)
	for weapon in weapons:
		unique_weapon_ids[weapon.weapon_id] = weapon

	return unique_weapon_ids


func update_item_related_effects(player_index: int) -> void :
	update_unique_bonuses(player_index)
	update_additional_weapon_bonuses(player_index)
	update_tier_iv_weapon_bonuses(player_index)
	update_tier_i_weapon_bonuses(player_index)


func update_unique_bonuses(player_index: int) -> void :
	var effects: = get_player_effects(player_index)
	var unique_effects = players_data[player_index].unique_effects

	for effect in unique_effects:
		effects[effect[0]] -= effect[1]

	unique_effects.clear()
	var unique_weapon_ids = get_unique_weapon_ids(player_index)

	for i in unique_weapon_ids.size():
		for effect in effects["unique_weapon_effects"]:
			effects[effect[0]] += effect[1]
			unique_effects.push_back([effect[0], effect[1]])


func update_additional_weapon_bonuses(player_index: int) -> void :
	var effects: = get_player_effects(player_index)
	for effect in players_data[player_index].additional_weapon_effects:
		effects[effect[0]] -= effect[1]

	players_data[player_index].additional_weapon_effects = []

	var weapons: = get_player_weapons(player_index)
	for weapon in weapons:
		for effect in effects["additional_weapon_effects"]:
			effects[effect[0]] += effect[1]
			players_data[player_index].additional_weapon_effects.push_back([effect[0], effect[1]])


func update_tier_iv_weapon_bonuses(player_index: int) -> void :
	var effects: = get_player_effects(player_index)
	var tier_iv_weapon_effects = players_data[player_index].tier_iv_weapon_effects

	for effect in tier_iv_weapon_effects:
		effects[effect[0]] -= effect[1]

	tier_iv_weapon_effects.clear()

	var weapons: = get_player_weapons(player_index)
	for weapon in weapons:
		if weapon.tier >= Tier.LEGENDARY:
			for effect in effects["tier_iv_weapon_effects"]:
				effects[effect[0]] += effect[1]
				tier_iv_weapon_effects.push_back([effect[0], effect[1]])


func update_tier_i_weapon_bonuses(player_index: int) -> void :
	var effects: = get_player_effects(player_index)
	var tier_i_weapon_effects = players_data[player_index].tier_i_weapon_effects

	for effect in tier_i_weapon_effects:
		effects[effect[0]] -= effect[1]

	tier_i_weapon_effects.clear()

	var weapons: = get_player_weapons(player_index)
	for weapon in weapons:
		if weapon.tier <= Tier.COMMON:
			for effect in effects["tier_i_weapon_effects"]:
				effects[effect[0]] += effect[1]
				tier_i_weapon_effects.push_back([effect[0], effect[1]])


func apply_item_effects(item_data: ItemParentData, player_index: int) -> void :
	Utils.reset_stat_cache(player_index)
	var effects = get_player_effects(player_index)
	for effect in item_data.effects:
		if item_data is ItemData and not item_data is UpgradeData and Utils.is_stat_key(effect.key):
			var value_before = effects[effect.key]
			effect.apply(player_index)
			var value_after = effects[effect.key]
			var value_change = value_after - value_before
			if value_change > 0:
				_apply_gain_stat_for_equipped_item_with_stat_effects(effect.key, player_index)
		else:
			effect.apply(player_index)
	ChallengeService.check_stat_challenges(player_index)


func unapply_item_effects(item_data: ItemParentData, player_index: int) -> void :
	Utils.reset_stat_cache(player_index)
	for effect in item_data.effects:
		effect.unapply(player_index)
	ChallengeService.check_stat_challenges(player_index)


func add_item_displayed(new_item: ItemData, player_index: int) -> void :
	if get_nb_item(new_item.my_id, player_index) > 1:
		return

	var player_appearances: Array = players_data[player_index].appearances
	for new_appearance in new_item.item_appearances:
		if new_appearance == null:
			continue

		var display_appearance: = true

		if new_appearance.position != 0:
			var appearance_to_erase = null

			for appearance in player_appearances:
				if appearance.position != new_appearance.position or new_appearance.position == 0:
					continue

				if new_appearance.display_priority >= appearance.display_priority:
					appearance_to_erase = appearance
				else:
					display_appearance = false

				break

			if appearance_to_erase:
				player_appearances.erase(appearance_to_erase)

		if display_appearance:
			player_appearances.push_back(new_appearance)

		player_appearances.sort_custom(Sorter, "sort_depth_ascending")


func remove_item_displayed(removed_item: ItemData, player_index: int) -> void :
	var player_appearances: Array = players_data[player_index].appearances
	for appearance in removed_item.item_appearances:
		player_appearances.erase(appearance)


func get_free_weapon_slots(player_index: int) -> int:
	var effects: = get_player_effects(player_index)
	var weapons: = get_player_weapons(player_index)
	return effects["weapon_slot"] - weapons.size()


func has_weapon_slot_available(shop_weapon: WeaponData, player_index: int) -> bool:
	var effects: = get_player_effects(player_index)
	var weapons: = get_player_weapons(player_index)

	if get_player_effect_bool("no_duplicate_weapons", player_index):
		if shop_weapon.weapon_id in get_unique_weapon_ids(player_index):
			return false

	if shop_weapon.type == - 1:
		return weapons.size() < effects["weapon_slot"]
	else:
		var nb = 0
		for weapon in weapons:
			if weapon.type == shop_weapon.type:
				nb += 1

		var max_slots = effects["max_melee_weapons"] if shop_weapon.type == WeaponType.MELEE else effects["max_ranged_weapons"]
		return weapons.size() < effects["weapon_slot"] and nb < min(effects["weapon_slot"], max_slots)


func some_player_has_weapon_slots() -> bool:
	for player_index in get_player_count():
		if player_has_weapon_slots(player_index):
			return true
	return false


func player_has_weapon_slots(player_index: int) -> bool:
	return get_player_effect("weapon_slot", player_index) > 0


func manage_life_steal(weapon_stats: WeaponStats, player_index: int) -> void :
	if randf() < weapon_stats.lifesteal:
		emit_signal("lifesteal_effect", 1, player_index)


func get_stat(stat_name: String, player_index: int) -> float:
	return get_player_effect(stat_name, player_index) * get_stat_gain(stat_name, player_index)


func get_stat_gain(stat_name: String, player_index: int) -> float:
	var effect_name = "gain_" + stat_name
	var effects = get_player_effects(player_index)
	if not effects.has(effect_name):
		return 1.0
	return (1.0 + (effects[effect_name] / 100.0))


func can_combine(weapon_data: WeaponData, player_index: int) -> bool:
	var nb_duplicates = 0

	var weapons: = get_player_weapons(player_index)
	for weapon in weapons:
		if weapon.my_id == weapon_data.my_id:
			nb_duplicates += 1

	var max_weapon_tier = get_player_effect("max_weapon_tier", player_index)
	return nb_duplicates >= 2 and weapon_data.upgrades_into != null and weapon_data.tier < max_weapon_tier


func sort_appearances() -> void :
	for player_data in players_data:
		player_data.appearances.sort_custom(Sorter, "sort_depth_ascending")


func init_remove_speed_data(player_index: int) -> Dictionary:
	var effects: = get_player_effects(player_index)
	var data = {"value": 0, "max_value": 0}
	if effects["remove_speed"].size() > 0:
		for remove_speed_data in effects["remove_speed"]:
			data.value += remove_speed_data[0]
			data.max_value = max(data.max_value, remove_speed_data[1])

	return data


func get_remove_speed_data(player_index) -> Dictionary:
	if player_index == DUMMY_PLAYER_INDEX:
		return dummy_player_remove_speed_data
	return remove_speed_effect_cache[player_index]


func get_armor_coef(armor: int) -> float:
	var percent_dmg_taken = 10.0 / (10.0 + (abs(armor) / 1.5))





	if armor < 0:
		percent_dmg_taken = (1.0 - percent_dmg_taken) + 1.0

	return percent_dmg_taken


func get_hp_regeneration_timer(hp_regen: int) -> float:





	if hp_regen <= 0:
		return 99.0

	var timer_duration = 5.0 / (1.0 + (abs(hp_regen - 1) / 2.25))

	return timer_duration


func reset_background() -> void :
	if ProgressData.settings.background == 0 or ProgressData.settings.background > ItemService.backgrounds.size():
		var zone_data = ZoneService.zones[0]

		for zone in ZoneService.zones:
			if zone.my_id == current_zone:
				zone_data = zone
				break

		var backgrounds_from = zone_data.default_backgrounds if zone_data.default_backgrounds.size() > 0 else ItemService.backgrounds
		current_background = Utils.get_rand_element(backgrounds_from)
	else:
		current_background = ItemService.backgrounds[ProgressData.settings.background - 1]


func get_background() -> Resource:
	return current_background





func add_stat(stat_name: String, value: int, player_index: int) -> void :
	assert (Utils.is_stat_key(stat_name), "%s is not a stat key" % stat_name)
	var effects: = get_player_effects(player_index)
	effects[stat_name] += value
	emit_signal("stat_added", stat_name, value, 0.0, player_index)
	_are_player_stats_dirty[player_index] = true
	Utils.reset_stat_cache(player_index)


func remove_stat(stat_name: String, value: int, player_index: int) -> void :
	assert (Utils.is_stat_key(stat_name), "%s is not a stat key" % stat_name)
	var effects: = get_player_effects(player_index)
	effects[stat_name] -= value
	emit_signal("stat_removed", stat_name, value, 0.0, player_index)
	_are_player_stats_dirty[player_index] = true
	Utils.reset_stat_cache(player_index)


func emit_stats_updated() -> void :
	for player_index in get_player_count():
		if _are_player_stats_dirty[player_index] or TempStats.are_player_stats_dirty[player_index] or LinkedStats.are_player_stats_dirty[player_index]:
			emit_signal("stats_updated", player_index)
			_are_player_stats_dirty[player_index] = false
			TempStats.are_player_stats_dirty[player_index] = false
			LinkedStats.are_player_stats_dirty[player_index] = false
			ChallengeService.check_stat_challenges(player_index)


func get_player_currency(player_index: int) -> int:
	var effects: = get_player_effects(player_index)
	return get_stat("stat_max_hp", player_index) as int if effects["hp_shop"] else get_player_gold(player_index)


func remove_currency(value: int, player_index: int) -> void :
	var effects: = get_player_effects(player_index)
	if effects["hp_shop"]:
		remove_stat("stat_max_hp", value, player_index)
	else:
		remove_gold(value, player_index)


func get_nb_structures(player_index: int) -> int:
	return get_player_effect("structures", player_index).size() + get_nb_item("item_pocket_factory", player_index)


func get_nb_item(item_id: String, player_index: int, use_cache: bool = true) -> int:
	if use_cache and items_nb_cache.size() > player_index and items_nb_cache[player_index].has(item_id):
		return items_nb_cache[player_index][item_id]
	var nb: = 0
	for item in get_player_items(player_index):
		if item_id == item.my_id:
			nb += 1
	if items_nb_cache.size() > player_index:
		items_nb_cache[player_index][item_id] = nb
	return nb


func get_remaining_max_nb_item(item_data: ItemData, player_index: int) -> int:
	if item_data.max_nb == - 1:
		return Utils.LARGE_NUMBER

	var existing_item_count: = get_nb_item(item_data.my_id, player_index)
	return max(0, item_data.max_nb - existing_item_count) as int


func get_nb_different_items_of_tier(tier: int, player_index: int, use_cache: = true) -> int:
	if use_cache and different_items_nb_cache.size() > player_index and different_items_nb_cache[player_index].has(tier):
		return different_items_nb_cache[player_index][tier]
	var nb = 0
	var parsed_items = {}
	for item in get_player_items(player_index):
		if (item.tier == tier or tier == - 1) and not parsed_items.has(item.my_id) and not item.my_id.begins_with("character_"):
			parsed_items[item.my_id] = true
			nb += 1
	if different_items_nb_cache.size() > player_index:
		different_items_nb_cache[player_index][tier] = nb
	return nb


func get_duplicate_items_count(player_index: int, use_cache: = true) -> int:
	if use_cache and duplicate_items_cache.size() > player_index and duplicate_items_cache[player_index] != null:
		return duplicate_items_cache[player_index]

	var duplicate_count: = 0
	var item_counts: = {}
	for item in get_player_items(player_index):
		if item_counts.has(item.my_id):
			item_counts[item.my_id] += 1
			duplicate_count += 1
		else:
			item_counts[item.my_id] = 1

	for weapon in get_player_weapons(player_index):
		if item_counts.has(weapon.weapon_id):
			item_counts[weapon.weapon_id] += 1
			duplicate_count += 1
		else:
			item_counts[weapon.weapon_id] = 1

	if duplicate_items_cache.size() > player_index:
		duplicate_items_cache[player_index] = duplicate_count
	return duplicate_count


func _update_item_caches(item: ItemParentData, player_index: int) -> void :
	if item is ItemData:
		get_nb_item(item.my_id, player_index, false)
		get_nb_different_items_of_tier( - 1, player_index, false)
		get_nb_different_items_of_tier(item.tier, player_index, false)
		get_duplicate_items_count(player_index, false)

	if item is WeaponData:
		get_duplicate_items_count(player_index, false)


func add_recycled(player_index: int) -> void :
	var player_data = players_data[player_index]
	player_data.chal_recycling_current += 1
	ChallengeService.try_complete_challenge("chal_recycling", player_data.chal_recycling_current)


func revert_all_selections() -> void :
	set_player_count(get_player_count(), true)


func add_starting_items_and_weapons() -> void :
	for player_index in players_data.size():
		var effects: = get_player_effects(player_index)

		if effects["starting_item"].size() > 0:
			for item_id in effects["starting_item"]:
				for i in item_id[1]:
					var item = ItemService.get_element(ItemService.items, item_id[0])
					add_item(item, player_index)

		if effects["starting_weapon"].size() > 0:
			for weapon_id in effects["starting_weapon"]:
				for i in weapon_id[1]:
					var weapon = ItemService.get_element(ItemService.weapons, weapon_id[0])
					var _weapon = add_weapon(weapon, player_index)

		if effects["cursed_starting_item"].size() > 0 and ProgressData.is_dlc_available_and_active("abyssal_terrors"):
			var dlc = ProgressData.get_dlc_data("abyssal_terrors")

			for item_id in effects["cursed_starting_item"]:
				for i in item_id[1]:
					var item = ItemService.get_element(ItemService.items, item_id[0])
					if dlc:
						item = dlc.curse_item(item, player_index, true)
					add_item(item, player_index)

		if effects["cursed_starting_weapon"].size() > 0 and ProgressData.is_dlc_available_and_active("abyssal_terrors"):
			var dlc = ProgressData.get_dlc_data("abyssal_terrors")

			for weapon_id in effects["cursed_starting_weapon"]:
				for i in weapon_id[1]:
					var weapon = ItemService.get_element(ItemService.weapons, weapon_id[0])
					if dlc:
						weapon = dlc.curse_item(weapon, player_index, true)
					var _weapon = add_weapon(weapon, player_index)


func handle_explode_effect(key: String, position: Vector2, player_index: int) -> void :
	var effects: = get_player_effects(player_index)

	var explosion_chance: = 0.0
	for explosion in effects[key]:
		explosion_chance += explosion.chance
	if not Utils.get_chance_success(explosion_chance):
		return

	var dmg = 0
	for explosion in effects[key]:
		dmg += WeaponService.get_explosion_damage(explosion.stats, player_index)

	var first_effect = effects[key][0]
	var first_stats = first_effect.stats

	if first_effect is ItemExplodingAndBurnEffect:
		var scaled_burning_data: BurningData = WeaponService.init_burning_data(first_effect.burning_data, player_index)
		first_stats.burning_data = scaled_burning_data

	
	position = Utils.get_random_offset_position(position, 10)

	var args: = WeaponServiceExplodeArgs.new()
	args.pos = position
	args.damage = dmg
	args.accuracy = first_stats.accuracy
	args.crit_chance = first_stats.crit_chance + Utils.get_capped_stat("stat_crit_chance", player_index) / 100.0
	args.crit_damage = first_stats.crit_damage
	args.burning_data = first_stats.burning_data
	args.scaling_stats = first_stats.scaling_stats
	args.damage_tracking_key = first_effect.tracking_key
	args.from_player_index = player_index
	var _inst = WeaponService.explode(first_effect, args)


func update_recycling_tracking_value(item_data: ItemParentData, player_index: int) -> void :
	if get_nb_item("item_recycling_machine", player_index) > 0:
		var value = ItemService.get_value(current_wave, item_data.value, player_index, true, true, item_data.my_id)
		var recycling_gains = get_player_effect("recycling_gains", player_index)
		add_tracked_value(player_index, "item_recycling_machine", (value * (recycling_gains / 100.0)) as int)


func should_show_endless_button() -> bool:
	return current_wave == 19 and not is_endless_run


func get_state() -> Dictionary:
	var players_data_copy: = []
	for player_data in players_data:
		players_data_copy.push_back(player_data.duplicate())

	return {
		"players_data": players_data_copy, 

		"enemy_scaling": current_run_accessibility_settings.duplicate(), 
		"nb_of_waves": nb_of_waves, 
		"current_zone": current_zone, 
		"current_wave": current_wave, 
		"current_difficulty": current_difficulty, 
		"bonus_gold": bonus_gold, 
		"total_bonus_gold": total_bonus_gold, 
		"retries": retries, 
		"elites_spawn": elites_spawn.duplicate(), 
		"bosses_spawn": bosses_spawn.duplicate(), 
		"shop_effects_checked": shop_effects_checked, 
		"elites_killed_this_run": elites_killed_this_run.duplicate(), 
		"bosses_killed_this_run": bosses_killed_this_run.duplicate(), 
		"loot_aliens_killed_this_run": loot_aliens_killed_this_run, 

		"challenges_completed_this_run": challenges_completed_this_run.duplicate(), 
		"locked_shop_items": locked_shop_items.duplicate(true), 
		"current_background": current_background, 

		"max_endless_wave_record_beaten": max_endless_wave_record_beaten, 
		"is_endless_run": is_endless_run, 
		"is_coop_run": is_coop_run, 
		"enabled_dlcs": enabled_dlcs, 

		"tracked_item_effects": tracked_item_effects.duplicate(true)
	}


func reset_to_start_wave_state() -> void :

	for player_data in players_data:
		for weapon in player_data.weapons:
			weapon.tracked_value -= weapon.tracked_value_added_this_wave
	resume_from_state(start_wave_state)

	var run_state = ProgressData.last_saved_run_state if ProgressData.last_saved_run_state else ProgressData._get_empty_run_state()
	ProgressData.reset_and_save_run_state(run_state)


func continue_current_run_in_shop() -> void :
	resume_from_state(ProgressData.saved_run_state)
	resumed_from_state_in_shop = true


func resume_from_state(state: Dictionary) -> void :

	ProgressData.update_dlc_resources_based_on_run_state(state)

	var players_data_copy: = []
	for player_data in state.players_data:
		players_data_copy.push_back(player_data.duplicate())
	players_data = players_data_copy

	current_run_accessibility_settings = state.enemy_scaling.duplicate()

	nb_of_waves = state.nb_of_waves
	retries = state.retries
	current_zone = state.current_zone
	current_wave = state.current_wave
	current_difficulty = state.current_difficulty
	bonus_gold = state.bonus_gold
	total_bonus_gold = state.total_bonus_gold if "total_bonus_gold" in state else 0

	elites_spawn = state.elites_spawn.duplicate()
	bosses_spawn = state.bosses_spawn.duplicate()
	shop_effects_checked = state.shop_effects_checked
	elites_killed_this_run = state.elites_killed_this_run
	bosses_killed_this_run = state.bosses_killed_this_run
	loot_aliens_killed_this_run = state.loot_aliens_killed_this_run

	challenges_completed_this_run = state.challenges_completed_this_run.duplicate()
	locked_shop_items = state.locked_shop_items.duplicate(true)
	current_background = state.current_background

	max_endless_wave_record_beaten = state.max_endless_wave_record_beaten
	is_endless_run = state.is_endless_run
	is_coop_run = state.is_coop_run
	enabled_dlcs = state.enabled_dlcs

	tracked_item_effects = state.tracked_item_effects.duplicate()

	ZoneService.current_zone = ZoneService.get_zone_data(current_zone).duplicate()

	LinkedStats.reset()


func get_shop_scene_path() -> String:
	return "res://ui/menus/shop/coop_shop.tscn" if is_coop_run else "res://ui/menus/shop/shop.tscn"


func get_end_run_scene_path() -> String:
	return "res://ui/menus/run/coop_end_run.tscn" if is_coop_run else "res://ui/menus/run/end_run.tscn"


func is_last_wave() -> bool:
	var is_last_wave = current_wave == ZoneService.get_zone_data(current_zone).waves_data.size()
	if is_endless_run: is_last_wave = false
	return is_last_wave



func apply_end_run() -> void :
	DebugService.log_data("end run...")

	var nb_waves = ZoneService.get_zone_data(current_zone).waves_data.size()

	if all_last_wave_bosses_killed:
		run_won = true
	else:
		run_won = current_wave > nb_waves or (current_wave >= nb_of_waves and not wave_in_progress)

	if run_won:
		apply_run_won()
	else:
		ProgressData.reset_and_save_new_run_state()

	var scene = get_end_run_scene_path()
	var _e = get_tree().change_scene(scene)
	get_tree().paused = false


func apply_run_won() -> void :
	DebugService.log_data("is_run_won")
	for player_index in get_player_count():
		var player_character = get_player_character(player_index)
		var character_chal_name = "chal_" + player_character.name.to_lower().replace("character_", "")

		if Platform.get_type() == PlatformType.STEAM:
			ChallengeService.complete_challenge(character_chal_name, false)

			if current_zone == 0:
				Platform.complete_challenge(character_chal_name)
			elif current_zone == 1:
				Platform.complete_challenge(character_chal_name + "_abyss")
		else:
			ChallengeService.complete_challenge(character_chal_name)

		var character_difficulty = ProgressData.get_character_difficulty_info(player_character.my_id, current_zone)
		if character_difficulty.max_selectable_difficulty < current_difficulty + 1 and current_difficulty + 1 <= ProgressData.MAX_DIFFICULTY:
			
			difficulty_unlocked = current_difficulty + 1

		character_difficulty.max_difficulty_beaten.set_info(
			current_difficulty, 
			current_wave, 
			current_run_accessibility_settings.health, 
			current_run_accessibility_settings.damage, 
			current_run_accessibility_settings.speed, 
			retries, 
			is_coop_run, 
			false
		)

		if "stat_curse" in get_player_effects(player_index):
			ChallengeService.try_complete_challenge("chal_uncorrupted", int(Utils.get_stat("stat_curse", player_index)), true)

	ChallengeService.complete_challenge("chal_difficulty_" + str(current_difficulty))

	for char_diff in ProgressData.difficulties_unlocked:
		for zone_difficulty_info in char_diff.zones_difficulty_info:
			zone_difficulty_info.max_selectable_difficulty = clamp(current_difficulty + 1, zone_difficulty_info.max_selectable_difficulty, ProgressData.MAX_DIFFICULTY)

	ProgressData.reset_and_save_new_run_state()


func cancel_resume() -> void :
	resumed_from_state_in_shop = false


func init_tracked_effects() -> Dictionary:
	return init_tracked_items.duplicate(true)


func get_scaling_bonus(value: int, stat_scaled: String, nb_stat_scaled: int, perm_stats_only: bool, player_index: int) -> int:

	var actual_nb_scaled: = 0.0
	if stat_scaled == "materials":
		actual_nb_scaled = get_player_gold(player_index)
	elif stat_scaled == "structure":
		actual_nb_scaled = get_nb_structures(player_index)
	elif stat_scaled == "living_enemy":
		actual_nb_scaled = current_living_enemies
	elif stat_scaled == "burning_enemy":
		actual_nb_scaled = current_burning_enemies
	elif stat_scaled == "different_item":
		actual_nb_scaled = get_nb_different_items_of_tier( - 1, player_index)
	elif stat_scaled == "common_item":
		actual_nb_scaled = get_nb_different_items_of_tier(Tier.COMMON, player_index)
	elif stat_scaled == "legendary_item":
		actual_nb_scaled = get_nb_different_items_of_tier(Tier.LEGENDARY, player_index)
	elif stat_scaled == "duplicate_item":
		actual_nb_scaled = get_duplicate_items_count(player_index)
	elif stat_scaled.begins_with("item_"):
		actual_nb_scaled = get_nb_item(stat_scaled, player_index)
	elif stat_scaled == "living_tree":
		actual_nb_scaled = current_living_trees
	elif stat_scaled == "percent_player_missing_health":
		var current_health = get_player_current_health(player_index)
		var max_health = get_player_max_health(player_index)
		actual_nb_scaled = WeaponService.apply_inverted_health_bonus(1, 1, current_health, max_health)
	elif stat_scaled == "free_weapon_slots":
		actual_nb_scaled = get_free_weapon_slots(player_index)
	elif perm_stats_only:
		actual_nb_scaled = get_stat(stat_scaled, player_index)
	else:
		actual_nb_scaled = get_stat(stat_scaled, player_index) + TempStats.get_stat(stat_scaled, player_index)

	return int(floor(value * (actual_nb_scaled / nb_stat_scaled)))


const snowball_effect = preload("res://items/all/snowball/effects/snowball_effect_0.tres")

func _apply_gain_stat_for_equipped_item_with_stat_effects(stat_name: String, player_index: int) -> void :
	var effects = get_player_effects(player_index)
	var gain_stat_effects = effects["gain_stat_for_equipped_item_with_stat"]
	for gain_stat_effect in gain_stat_effects:
		var item_stat = gain_stat_effect[2]
		if item_stat != stat_name:
			continue
		var stat_to_gain = gain_stat_effect[0]
		var stat_to_gain_value = gain_stat_effect[1]
		effects[stat_to_gain] += stat_to_gain_value
		if stat_to_gain == snowball_effect.key:
			add_tracked_value(player_index, "item_snowball", stat_to_gain_value)
		emit_signal("stat_added", stat_to_gain, stat_to_gain_value, 0.0, player_index)


func add_tracked_value(player_index: int, tracking_key: String, value: float, index: int = 0) -> void :
	if not tracked_item_effects[player_index].has(tracking_key):
		print("tracking key %s does not exist" % tracking_key)
		return

	if tracked_item_effects[player_index][tracking_key] is Array:
		tracked_item_effects[player_index][tracking_key][index] += value as int
	else:
		tracked_item_effects[player_index][tracking_key] += value as int


func set_tracked_value(player_index: int, tracking_key: String, value: float, index: int = 0) -> void :
	if not tracked_item_effects[player_index].has(tracking_key):
		print("tracking key %s does not exist" % tracking_key)
		return

	if tracked_item_effects[player_index][tracking_key] is Array:
		tracked_item_effects[player_index][tracking_key][index] = value as int
	else:
		tracked_item_effects[player_index][tracking_key] = value as int

