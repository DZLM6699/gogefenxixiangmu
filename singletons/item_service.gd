extends Node

signal backgrounds_updated


const TIER_DANGER_5_COLOR = Color(208.0 / 255, 193.0 / 255, 66.0 / 255, 1)
const TIER_DANGER_4_COLOR = Color(255.0 / 255, 119.0 / 255, 59.0 / 255, 1)
const TIER_DANGER_0_COLOR = Color(230.0 / 255, 230.0 / 255, 230.0 / 255, 1)

const TIER_DANGER_5_COLOR_DARK = Color(26.0 / 255, 24.0 / 255, 8.0 / 255, 1)
const TIER_DANGER_4_COLOR_DARK = Color(36.0 / 255, 17.0 / 255, 8.0 / 255, 1)
const TIER_DANGER_0_COLOR_DARK = Color(0.0 / 255, 0.0 / 255, 0.0 / 255, 1)

const TIER_LEGENDARY_COLOR = Color(255.0 / 255, 59.0 / 255, 59.0 / 255, 1)
const TIER_RARE_COLOR = Color(173.0 / 255, 90.0 / 255, 255.0 / 255, 1)
const TIER_UNCOMMON_COLOR = Color(90.0 / 255, 190.0 / 255, 255.0 / 255, 1)

const TIER_LEGENDARY_COLOR_DARK = Color(36.0 / 255, 9.0 / 255, 9.0 / 255, 1)
const TIER_RARE_COLOR_DARK = Color(16.0 / 255, 10.0 / 255, 27.0 / 255, 1)
const TIER_UNCOMMON_COLOR_DARK = Color(15.0 / 255, 32.0 / 255, 40.0 / 255, 1)

const NB_SHOP_ITEMS: = 4

const CHANCE_WEAPON: = 0.35
const CHANCE_SAME_WEAPON: = 0.2
const CHANCE_SAME_WEAPON_SET: = 0.35
const MAX_WAVE_TWO_WEAPONS_GUARANTEED: = 2
const MAX_WAVE_ONE_WEAPON_GUARANTEED: = 5
const BONUS_CHANCE_SAME_WEAPON_SET: = 0.2
const BONUS_CHANCE_SAME_WEAPON: = 0.05
const CHANCE_WANTED_ITEM_TAG: = 0.05

enum TierData{
	ALL_ITEMS, 
	ITEMS, 
	WEAPONS, 
	CONSUMABLES, 
	UPGRADES, 
	MIN_WAVE, 
	BASE_CHANCE, 
	WAVE_BONUS_CHANCE, 
	MAX_CHANCE
}

var _tiers_data: Array
var _item_id_lookup: Dictionary

export (Array, Resource) var elites
export (Array, Resource) var bosses
export (Array, Resource) var effects
export (Array, Resource) var stats
export (Array, Resource) var characters
export (Array, Resource) var items
export (Array, Resource) var weapons
export (Array, Resource) var consumables
export (Array, Resource) var upgrades
export (Array, Resource) var sets
export (Array, Resource) var difficulties
export (Array, Resource) var icons
export (Array, Resource) var title_screen_backgrounds
export (Array, Resource) var backgrounds
export (Array, Color) var background_colors

export (Resource) var weapon_slot_upgrade_data = null


var item_groups: Dictionary = {
	"harvesting": ["item_blood_donation", "item_crown", "item_fertilizer", "item_tractor", "item_wheelbarrow"], 
	"melee_damage": ["item_mastery", "item_goat_skull", "item_riposte"], 
	"ranged_damage": ["item_lens"], 
	"melee_and_ranged_damage": ["item_big_arms", "item_hedgehog"], 
	"lifesteal": ["item_butterfly", "item_bat", "item_whetstone", "item_decomposing_flesh", "item_bloody_hand"], 
	"lifesteal_and_hp_regeneration": ["item_blood_leech"], 
	"hp_regeneration": ["item_mushroom", "item_plant", "item_sad_tomato", "item_medikit", "item_fairy", "item_potion", "item_fried_rice", "item_baby_squid", "item_coral", "item_penguin"], 
	"consumable_heal": ["item_jerky", "item_weird_food", "item_lemonade"], 
	"speed": ["item_terrified_onion", "item_beanie", "item_power_generator"], 
	"engineering": ["item_lighthouse", "item_cog", "item_nail", "item_toolbox", "item_book", "item_pencil"], 
	"elemental_damage": ["item_strange_book", "item_frozen_heart", "item_boiling_water", "item_snowball", "item_toxic_sludge", "item_fuel_tank"], 
	"armor": ["item_stone_skin", "item_helmet", "item_metal_plate"], 
	"dodge": ["item_adrenaline", "item_chameleon", "item_gambling_token"], 
}


func _ready() -> void :
	Utils.reset_stat_keys()


func reset_tiers_data() -> void :
		_tiers_data = [
		[[], [], [], [], [], 0, 1.0, 0.0, 1.0], 
		[[], [], [], [], [], 0, 0.0, 0.06, 0.6], 
		[[], [], [], [], [], 2, 0.0, 0.02, 0.25], 
		[[], [], [], [], [], 6, 0.0, 0.0023, 0.08]
	]


func init_unlocked_pool() -> void :

	reset_tiers_data()

	for item in items:
		if ProgressData.items_unlocked.has(item.my_id) and item.max_nb != 0:
			_tiers_data[item.tier][TierData.ALL_ITEMS].push_back(item)
			_tiers_data[item.tier][TierData.ITEMS].push_back(item)

	for weapon in weapons:
		if ProgressData.weapons_unlocked.has(weapon.weapon_id):
			_tiers_data[weapon.tier][TierData.ALL_ITEMS].push_back(weapon)
			_tiers_data[weapon.tier][TierData.WEAPONS].push_back(weapon)

	for upgrade in upgrades:
		if ProgressData.upgrades_unlocked.has(upgrade.upgrade_id):
			_tiers_data[upgrade.tier][TierData.UPGRADES].push_back(upgrade)

	for consumable in consumables:
		if ProgressData.consumables_unlocked.has(consumable.my_id):
			_tiers_data[consumable.tier][TierData.CONSUMABLES].push_back(consumable)


func add_mod_item(item: ItemParentData) -> void :

	items.push_back(item)

	if item.unlocked_by_default and not ProgressData.items_unlocked.has(item.my_id):
		ProgressData.items_unlocked.push_back(item.my_id)


func remove_mod_item(p_item: ItemParentData) -> void :

	for item in items:
		if item.my_id == p_item.my_id:
			items.erase(item)
			break

	if ProgressData.items_unlocked.has(p_item.my_id):
		ProgressData.items_unlocked.erase(p_item.my_id)


func get_consumable_to_drop(unit: Unit, item_chance: float) -> ConsumableData:
	var luck: = 0.0
	for player_index in RunData.get_player_count():
		luck += Utils.get_stat("stat_luck", player_index) / 100.0

	var consumable_drop_chance: = min(1.0, unit.stats.base_drop_chance * (1.0 + luck))
	if RunData.current_wave > RunData.nb_of_waves:
		consumable_drop_chance /= (1.0 + RunData.get_endless_factor())

	if DebugService.always_drop_crates:
		consumable_drop_chance = 1.0
		item_chance = 1.0

	var consumable_to_drop: ConsumableData = null
	if Utils.get_chance_success(consumable_drop_chance) or unit.stats.always_drop_consumables:
		var consumable_tier: int = Utils.randi_range(unit.stats.min_consumable_tier, unit.stats.max_consumable_tier)

		if Utils.get_chance_success(item_chance):
			if unit is Boss and RunData.current_wave <= RunData.nb_of_waves:
				consumable_tier = Tier.LEGENDARY
			else:
				consumable_tier = Tier.UNCOMMON

		consumable_to_drop = get_consumable_for_tier(consumable_tier)

	elif Utils.get_chance_success(RunData.sum_all_player_effects("enemy_fruit_drops") / 100.0):
		consumable_to_drop = get_consumable_for_tier(Tier.COMMON)

	return consumable_to_drop


func get_consumable_for_tier(tier: int = Tier.COMMON) -> ConsumableData:
	var consumable = Utils.get_rand_element(_tiers_data[tier][TierData.CONSUMABLES])

	for dlc_id in RunData.enabled_dlcs:
		var dlc_data = ProgressData.get_dlc_data(dlc_id)
		if dlc_data:
			consumable = dlc_data.update_consumable_to_get(consumable)

	consumable = consumable.duplicate()
	var cur_zone: Resource = ZoneService.get_zone_data(RunData.current_zone)
	consumable.icon = cur_zone.get_zone_consumable_sprite(consumable)

	return consumable


func process_item_box(consumable_data: ConsumableData, wave: int, player_index: int) -> ItemParentData:
	var owned_items: Array = RunData.get_player_items(player_index)
	
	for locked_item in RunData.get_player_locked_shop_items(player_index):
		if locked_item[0] is ItemData:
			owned_items.push_back(locked_item[0])
	var args: = GetRandItemForWaveArgs.new()
	args.owned_and_shop_items = owned_items
	if consumable_data.my_id == "consumable_legendary_item_box":
		args.fixed_tier = Tier.LEGENDARY
	var item: = _get_rand_item_for_wave(wave, player_index, TierData.ITEMS, args)
	return item


func get_player_shop_items(wave: int, player_index: int, args: ItemServiceGetShopItemsArgs) -> Array:
	var new_items: = []
	var nb_weapons_guaranteed = 0
	var nb_weapons_added = 0
	var guaranteed_items = RunData.get_player_effect("guaranteed_shop_items", player_index).duplicate()

	var nb_locked_weapons = 0

	for locked_item in args.locked_items:
		if locked_item[0] is WeaponData:
			nb_locked_weapons += 1

	if RunData.current_wave <= MAX_WAVE_TWO_WEAPONS_GUARANTEED:
		nb_weapons_guaranteed = 2
	elif RunData.current_wave <= MAX_WAVE_ONE_WEAPON_GUARANTEED:
		nb_weapons_guaranteed = 1

	var minimum_weapons_in_shop = RunData.get_player_effect("minimum_weapons_in_shop", player_index)
	nb_weapons_guaranteed = max(nb_weapons_guaranteed, minimum_weapons_in_shop)

	for i in args.count:

		var type

		if RunData.current_wave <= MAX_WAVE_TWO_WEAPONS_GUARANTEED:
			type = TierData.WEAPONS if (nb_weapons_added + nb_locked_weapons < nb_weapons_guaranteed) else TierData.ITEMS
		elif guaranteed_items.size() > 0:
			type = TierData.ITEMS
		else:
			type = TierData.WEAPONS if (Utils.get_chance_success(CHANCE_WEAPON) or nb_weapons_added + nb_locked_weapons < nb_weapons_guaranteed) else TierData.ITEMS

		if type == TierData.WEAPONS:
			nb_weapons_added += 1

		if not RunData.player_has_weapon_slots(player_index):
			type = TierData.ITEMS

		var new_item

		if type == TierData.ITEMS and guaranteed_items.size() > 0:
			new_item = apply_item_effect_modifications(get_element(items, guaranteed_items[0][0]), player_index)
			guaranteed_items.pop_front()
		else:
			
			
			var rand_item_args: = GetRandItemForWaveArgs.new()
			rand_item_args.excluded_items = args.prev_items + new_items
			rand_item_args.owned_and_shop_items = args.owned_and_shop_items
			rand_item_args.increase_tier = args.increase_tier
			new_item = _get_rand_item_for_wave(wave, player_index, type, rand_item_args)

		new_items.push_back([new_item, wave])
	return new_items


func get_pool(item_tier: int, type: int) -> Array:
	return _tiers_data[item_tier][type].duplicate()


class GetRandItemForWaveArgs:
	var excluded_items: = []
	var owned_and_shop_items
	var fixed_tier: = - 1
	var increase_tier: = 0


func get_rand_item_for_wave(wave: int, player_index: int) -> ItemParentData:
	var args: = GetRandItemForWaveArgs.new()
	var owned_items: Array = RunData.get_player_items(player_index)

	for locked_item in RunData.get_player_locked_shop_items(player_index):
		if locked_item[0] is ItemData:
			owned_items.push_back(locked_item[0])

	args.owned_and_shop_items = owned_items
	return _get_rand_item_for_wave(wave, player_index, TierData.ITEMS, args)


func _get_rand_item_for_wave(wave: int, player_index: int, type: int, args: GetRandItemForWaveArgs) -> ItemParentData:
	var player_character = RunData.get_player_character(player_index)
	var rand_wanted = randf()
	var item_tier = get_tier_from_wave(wave, player_index, args.increase_tier)

	if args.fixed_tier != - 1:
		item_tier = args.fixed_tier

	if type == TierData.WEAPONS:
		var min_weapon_tier = RunData.get_player_effect("min_weapon_tier", player_index)
		var max_weapon_tier = RunData.get_player_effect("max_weapon_tier", player_index)
		item_tier = clamp(item_tier, min_weapon_tier, max_weapon_tier)

	var pool = get_pool(item_tier, type)
	var backup_pool = get_pool(item_tier, type)
	var items_to_remove = []

	
	for shop_item in args.excluded_items:
		pool = remove_element_by_id(pool, shop_item[0])
		backup_pool = remove_element_by_id(pool, shop_item[0])

	if type == TierData.WEAPONS:
		var bonus_chance_same_weapon_set = max(0, (MAX_WAVE_ONE_WEAPON_GUARANTEED + 1 - RunData.current_wave) * (BONUS_CHANCE_SAME_WEAPON_SET / MAX_WAVE_ONE_WEAPON_GUARANTEED))
		var chance_same_weapon_set = CHANCE_SAME_WEAPON_SET + bonus_chance_same_weapon_set
		var bonus_chance_same_weapon = max(0, (MAX_WAVE_ONE_WEAPON_GUARANTEED + 1 - RunData.current_wave) * (BONUS_CHANCE_SAME_WEAPON / MAX_WAVE_ONE_WEAPON_GUARANTEED))
		var chance_same_weapon = CHANCE_SAME_WEAPON + bonus_chance_same_weapon

		var no_melee_weapons: bool = RunData.get_player_effect_bool("no_melee_weapons", player_index)
		var no_ranged_weapons: bool = RunData.get_player_effect_bool("no_ranged_weapons", player_index)
		var no_duplicate_weapons: bool = RunData.get_player_effect_bool("no_duplicate_weapons", player_index)
		var no_structures: bool = RunData.get_player_effect("remove_shop_items", player_index).has("structure")

		var player_sets: Array = RunData.get_player_sets(player_index)
		var unique_weapon_ids: Dictionary = RunData.get_unique_weapon_ids(player_index)

		for item in pool:
			if no_melee_weapons and item.type == WeaponType.MELEE:
				backup_pool = remove_element_by_id(backup_pool, item)
				items_to_remove.push_back(item)
				continue

			if no_ranged_weapons and item.type == WeaponType.RANGED:
				backup_pool = remove_element_by_id(backup_pool, item)
				items_to_remove.push_back(item)
				continue

			if no_duplicate_weapons:
				for weapon in unique_weapon_ids.values():
					
					if item.weapon_id == weapon.weapon_id and item.tier < weapon.tier:
						backup_pool = remove_element_by_id(backup_pool, item)
						items_to_remove.push_back(item)
						break

					
					elif item.my_id == weapon.my_id and weapon.upgrades_into == null:
						backup_pool = remove_element_by_id(backup_pool, item)
						items_to_remove.push_back(item)
						break

			if no_structures and EntityService.is_weapon_spawning_structure(item):
				backup_pool = remove_element_by_id(backup_pool, item)
				items_to_remove.append(item)

			if rand_wanted < chance_same_weapon:
				if not item.weapon_id in unique_weapon_ids:
					items_to_remove.push_back(item)
					continue

			elif rand_wanted < chance_same_weapon_set:
				var remove: = true
				for set in item.sets:
					if set.my_id in player_sets:
						remove = false
				if remove:
					items_to_remove.push_back(item)
					continue

	elif type == TierData.ITEMS:
		if Utils.get_chance_success(CHANCE_WANTED_ITEM_TAG) and player_character.wanted_tags.size() > 0:
			for item in pool:
				var has_wanted_tag = false

				for tag in item.tags:
					if player_character.wanted_tags.has(tag):
						has_wanted_tag = true
						break

				if not has_wanted_tag:
					items_to_remove.push_back(item)

		var remove_item_tags: Array = RunData.get_player_effect("remove_shop_items", player_index)
		for tag_to_remove in remove_item_tags:
			for item in pool:
				if tag_to_remove in item.tags:
					items_to_remove.append(item)

		if RunData.current_wave < RunData.nb_of_waves:
			if player_character.banned_item_groups.size() > 0:
				for banned_item_group in player_character.banned_item_groups:

					if not banned_item_group in item_groups:
						print(str(banned_item_group) + " does not exist in ItemService.item_groups")
						continue

					for item in pool:
						if item_groups[banned_item_group].has(item.my_id):
							items_to_remove.append(item)

			if player_character.banned_items.size() > 0:
				for item in pool:
					if player_character.banned_items.has(item.my_id):
						items_to_remove.append(item)

	var limited_items = get_limited_items(args.owned_and_shop_items)

	for key in limited_items:
		if limited_items[key][1] >= limited_items[key][0].max_nb:
			backup_pool = remove_element_by_id(backup_pool, limited_items[key][0])
			items_to_remove.push_back(limited_items[key][0])

	for item in items_to_remove:
		pool = remove_element_by_id(pool, item)

	var elt

	if pool.size() == 0:
		if backup_pool.size() > 0:
			elt = Utils.get_rand_element(backup_pool)
		else:
			elt = Utils.get_rand_element(_tiers_data[item_tier][type])
	else:
		elt = Utils.get_rand_element(pool)
		if elt.my_id == "item_axolotl" and randf() < 0.5:
			elt = Utils.get_rand_element(pool)

	if DebugService.force_item_in_shop != "" and randf() < 0.5:
		elt = get_element(items, DebugService.force_item_in_shop)
		if elt == null:
			elt = get_element(weapons, DebugService.force_item_in_shop)

	
	if elt.my_id == "item_axolotl" and elt.effects.size() > 0 and "stats_swapped" in elt.effects[0]:
		elt.effects[0].stats_swapped = []

	return apply_item_effect_modifications(elt, player_index)


func get_limited_items(from_items: Array) -> Dictionary:
	var limited_items = {}

	for item in from_items:
		if item.max_nb != - 1:
			if limited_items.has(item.my_id):
				limited_items[item.my_id][1] += 1
			else:
				var non_cursed_item = item
				if item.is_cursed:
					non_cursed_item = get_element(items, item.my_id)

				limited_items[item.my_id] = [non_cursed_item, 1]

	return limited_items


func remove_element_by_id(from: Array, element: ItemParentData) -> Array:
	var from_copy = from.duplicate()

	for i in from.size():
		if from[i].my_id == element.my_id:
			from_copy.remove(i)
			break

	return from_copy


func apply_item_effect_modifications(item: ItemParentData, player_index: int) -> ItemParentData:
	for dlc_id in RunData.enabled_dlcs:
		var dlc_data = ProgressData.get_dlc_data(dlc_id)

		if dlc_data:
			item = dlc_data.update_item_effects(item, player_index)

	return item


func get_tier_from_wave(wave: int, player_index: int, increase_tier: = 0) -> int:
	var rand = rand_range(0.0, 1.0)
	var luck = Utils.get_stat("stat_luck", player_index) / 100.0

	var tier: int = Tier.COMMON
	for i in range(_tiers_data.size() - 1, - 1, - 1):
		var tier_data = _tiers_data[i]

		
		var wave_base_chance = max(0.0, ((wave - 1) - tier_data[TierData.MIN_WAVE]) * tier_data[TierData.WAVE_BONUS_CHANCE])

		
		var wave_chance = 0.0
		if luck >= 0:
			wave_chance = wave_base_chance * (1 + luck)
		else:
			wave_chance = wave_base_chance / (1 + abs(luck))

		var chance = tier_data[TierData.BASE_CHANCE] + wave_chance
		var max_chance = tier_data[TierData.MAX_CHANCE]

		if rand <= min(chance, max_chance):
			tier = i
			break

	tier = clamp(tier + increase_tier, Tier.COMMON, Tier.LEGENDARY) as int

	return tier


func get_upgrades(level: int, number: int, old_upgrades: Array, player_index: int) -> Array:

	var weapon_slot_upgrades = RunData.get_player_effect("weapon_slot_upgrades", player_index)
	var current_weapon_slots = RunData.get_player_effect("weapon_slot", player_index)

	if weapon_slot_upgrades > 0 and current_weapon_slots < weapon_slot_upgrades:
		return [weapon_slot_upgrade_data]

	var upgrades_to_show = []
	for i in number:
		var upgrade = get_upgrade_data(level, player_index)
		var tries = 0

		while (is_upgrade_already_added(upgrades_to_show, upgrade) or is_upgrade_already_added(old_upgrades, upgrade)) and tries < 50:
			upgrade = get_upgrade_data(level, player_index)
			tries += 1

		upgrades_to_show.push_back(upgrade)

	return upgrades_to_show


func is_upgrade_already_added(p_upgrades: Array, upgrade: UpgradeData) -> bool:

	for upg in p_upgrades:
		if upg.upgrade_id == upgrade.upgrade_id:
			return true

	return false


func get_upgrade_data(level: int, player_index: int) -> UpgradeData:
	var tier = get_tier_from_wave(level, player_index)

	if level == 5:
		tier = Tier.UNCOMMON
	elif level == 10 or level == 15 or level == 20:
		tier = Tier.RARE
	elif level % 5 == 0:
		tier = Tier.LEGENDARY

	var upgrade_data: UpgradeData = Utils.get_rand_element(_tiers_data[tier][TierData.UPGRADES])
	var level_upgrades_modifications = RunData.get_player_effect("level_upgrades_modifications", player_index)
	if level_upgrades_modifications != 0:
		upgrade_data = upgrade_data.duplicate()
		var new_effects: = []
		for effect in upgrade_data.effects:
			var new_effect = effect.duplicate()
			new_effect.value = int(effect.value * (1.0 + level_upgrades_modifications / 100.0))
			new_effects.push_back(new_effect)
		upgrade_data.effects = new_effects
	return upgrade_data


func get_color_from_tier(tier: int, dark_version: bool = false) -> Color:
	match tier:
		Tier.UNCOMMON:
			return TIER_UNCOMMON_COLOR_DARK if dark_version else TIER_UNCOMMON_COLOR
		Tier.RARE:
			return TIER_RARE_COLOR_DARK if dark_version else TIER_RARE_COLOR
		Tier.LEGENDARY:
			return TIER_LEGENDARY_COLOR_DARK if dark_version else TIER_LEGENDARY_COLOR
		Tier.DANGER_0:
			return TIER_DANGER_0_COLOR_DARK if dark_version else TIER_DANGER_0_COLOR
		Tier.DANGER_4:
			return TIER_DANGER_4_COLOR_DARK if dark_version else TIER_DANGER_4_COLOR
		Tier.DANGER_5:
			return TIER_DANGER_5_COLOR_DARK if dark_version else TIER_DANGER_5_COLOR
		_:
			return Color.white


func get_tier_text(tier: int) -> String:
	if tier == 0: return "TIER_COMMON"
	elif tier == 1: return "TIER_UNCOMMON"
	elif tier == 2: return "TIER_RARE"
	else: return "TIER_LEGENDARY"


func get_tier_number(tier: int) -> String:
	if tier == 0: return ""
	elif tier == 1: return "II"
	elif tier == 2: return "III"
	else: return "IV"


func get_weapon_sets_text(weapon_sets: Array) -> String:
	var text = ""

	for set in weapon_sets:
		text += tr(set.name) + ", "

	text = text.trim_suffix(", ")

	return text


func get_category_text(category: int) -> String:
	if category == Category.ITEM: return "CATEGORY_ITEM"
	else: return "CATEGORY_WEAPON"


func change_panel_stylebox_from_tier(stylebox: StyleBoxFlat, tier: int, is_popup: = false) -> void :
	var tier_color = get_color_from_tier(tier)
	var dark_tier_color = get_color_from_tier(tier, true)

	if tier_color == Color.white:
		tier_color = Color(0.3, 0.3, 0.3) if is_popup else Color.black

	if dark_tier_color == Color.white:
		dark_tier_color = Color.black

	stylebox.border_color = tier_color

	dark_tier_color.a = stylebox.bg_color.a
	stylebox.bg_color = dark_tier_color


func change_inventory_element_stylebox_from_tier(stylebox: StyleBoxFlat, tier: int, alpha: float = 1) -> void :
	var tier_color = get_color_from_tier(tier)

	if tier_color == Color.white:
		tier_color = Color.black
		tier_color.a = 0.39
	else:
		tier_color.a = alpha

	stylebox.bg_color = tier_color


func get_value(wave: int, base_value: int, player_index: int, affected_by_items_price_stat: bool, is_weapon: bool, item_id: String = "") -> int:
	var value_after_weapon_price = base_value
	var specific_item_price_factor = 0
	var items_price_factor = 1.0

	var weapons_price = RunData.get_player_effect("weapons_price", player_index)
	value_after_weapon_price = base_value if not is_weapon or not affected_by_items_price_stat else base_value * (1.0 + weapons_price / 100.0)

	for specific_item_price in RunData.get_player_effect("specific_items_price", player_index):
		if specific_item_price[0] in item_id:
			specific_item_price_factor = specific_item_price[1]
			break

	var items_price = RunData.get_player_effect("items_price", player_index)
	items_price_factor = 1.0 + (items_price + specific_item_price_factor) / 100.0 if affected_by_items_price_stat else 1.0

	var endless_factor = RunData.get_endless_factor(wave) / 5.0 if affected_by_items_price_stat else 0.0
	return max(1.0, ((value_after_weapon_price + wave + (value_after_weapon_price * wave * 0.1)) * items_price_factor * (1 + endless_factor))) as int



func get_reroll_price(wave: int, reroll_count: int, player_index: int) -> Array:
	var delta: = int(max(1.0, (0.4 * wave * pow(1.0 + RunData.get_endless_factor(wave), 0.5))))
	var normal_price: = int(wave * 0.75) + delta + delta * reroll_count
	var reroll_price_amount: int = RunData.get_player_effect("reroll_price", player_index)
	var reroll_price_factor: float = max(0.1, 1.0 + reroll_price_amount / 100.0)
	var discounted_price: = ceil(normal_price * reroll_price_factor) as int
	return [discounted_price, normal_price - discounted_price]


func get_recycling_value(wave: int, from_value: int, player_index: int, is_weapon: bool = false, affected_by_items_price_stat: bool = true) -> int:
	var actually_affected = affected_by_items_price_stat and RunData.current_wave <= RunData.nb_of_waves
	var recycling_gains = RunData.get_player_effect("recycling_gains", player_index)
	var shop_value = get_value(wave, from_value, player_index, affected_by_items_price_stat, is_weapon)
	var recycling_value = max(1.0, (get_value(wave, from_value, player_index, actually_affected, is_weapon) * clamp(0.25 + recycling_gains / 100.0, 0.01, 1.0))) as int

	
	if from_value == 1:
		return 1

	return min(shop_value, recycling_value) as int


func get_element(from_array: Array, id: String = "", value: int = - 1) -> Resource:
	for elt in from_array:
		if elt.my_id == id or (id == "" and elt.value == value):
			return elt

	return null


func get_set(p_set: String) -> SetData:
	for set in sets:
		if set.my_id == p_set:
			return set

	return SetData.new()


func get_stat_icon(stat_name: String) -> Resource:
	var stat = get_stat(stat_name)

	if stat:
		return stat.icon

	return null


func get_stat_small_icon(stat_name: String) -> Resource:
	var stat = get_stat(stat_name)

	if stat:
		return stat.small_icon

	return null


func get_stat(stat_name: String) -> Resource:
	for stat in stats:
		if stat.stat_name == stat_name:
			return stat

	return null


func get_stat_description_text(stat_name: String, value: int, player_index: int) -> String:
	stat_name = stat_name.to_upper()
	var stat_sign = "POS_" if value >= 0 else "NEG_"
	var key = "INFO_" + stat_sign + stat_name
	if stat_name == "STAT_ARMOR":
		return Text.text(key, [str(abs(round((1.0 - RunData.get_armor_coef(value)) * 100.0)))])
	elif stat_name == "STAT_HARVESTING":
		if value >= 0: key += "_LIMITED"
		return Text.text(key, [str(abs(value)), str(RunData.get_player_effect("harvesting_growth", player_index)), str(RunData.nb_of_waves), str(RunData.ENDLESS_HARVESTING_DECREASE)])
	elif stat_name == "STAT_LIFESTEAL":
		return Text.text(key, [str(abs(value)), "10"])
	elif stat_name == "STAT_HP_REGENERATION":
		var val = RunData.get_hp_regeneration_timer(value)
		var amount = 1
		var amount_per_sec = 1 / val
		return Text.text(key, [str(amount), str(stepify(val, 0.01)), str(stepify(amount_per_sec, 0.01))])
	elif stat_name == "STAT_DODGE":
		return Text.text(key, [str(abs(value)), str(RunData.get_player_effect("dodge_cap", player_index)) + "%"])
	elif stat_name == "STAT_CRIT_CHANCE":
		return Text.text(key, [str(abs(value)), str(RunData.get_player_effect("crit_chance_cap", player_index)) + "%"])
	elif stat_name == "STAT_CURSE":
		var chance = 0.0
		for dlc_data in ProgressData.available_dlcs:
			if "max_curse_item_chance" in dlc_data:
				chance = dlc_data.max_curse_item_chance
				break

		var enemy_curse_chance = stepify(abs(Utils.get_curse_factor(value) / 2.0), 0.1)
		var item_curse_chance = stepify(abs(Utils.get_curse_factor(value, chance * 100.0)), 0.1)

		return Text.text(key, [str(enemy_curse_chance), str(item_curse_chance)])
	return Text.text(key, [str(abs(value))])


func get_random_elite_id_from_zone(zone_id: int) -> String:
	return Utils.get_rand_element(get_elites_from_zone(zone_id)).my_id


func get_elites_from_zone(zone_id: int) -> Array:
	var possible_elites = []

	for elite in elites:
		if elite.zone_id == zone_id:
			possible_elites.push_back(elite)

	return possible_elites


func get_bosses_from_zone(zone_id: int) -> Array:
	var possible_bosses = []

	for boss in bosses:
		if boss.zone_id == zone_id:
			possible_bosses.push_back(boss)

	return possible_bosses


func get_item_from_id(item_id: String) -> ItemData:
	if not _item_id_lookup or not _item_id_lookup.has(item_id):
		for item in items:
			_item_id_lookup[item.my_id] = item

	assert (_item_id_lookup.has(item_id), "item_id not found in items")
	return _item_id_lookup[item_id]


func get_icon(icon_id: String) -> Resource:
	return get_element(icons, icon_id).icon


func get_icon_for_duplicate_shop_item(character: CharacterData, player_items: Array, player_weapons: Array, shop_item: ItemParentData, player_index: int) -> Texture:

	if character == null or shop_item == null:
		return null

	var copies = 0
	var same_tier_copies = 0
	var fairy_data = null
	var has_free_weapon_slot = false

	if shop_item is ItemData:
		for item in player_items:
			if item.my_id == shop_item.my_id:
				copies += 1

			if item.my_id == "item_fairy":
				fairy_data = item

	if shop_item is WeaponData:
		has_free_weapon_slot = RunData.has_weapon_slot_available(shop_item, player_index)
		for weapon in player_weapons:
			if weapon.weapon_id == shop_item.weapon_id:
				copies += 1
			if weapon.my_id == shop_item.my_id:
				same_tier_copies += 1

	var already_has_it = copies > 0
	var weapon_is_max_tier = shop_item.tier == Tier.LEGENDARY
	var would_combine_on_buy = not weapon_is_max_tier and not has_free_weapon_slot and same_tier_copies >= 1

	var renegade_cond = character.my_id == "character_renegade" and shop_item is ItemData and shop_item.tier == Tier.COMMON and not already_has_it
	var curious_cond_neg = character.my_id == "character_curious" and already_has_it and ( not (shop_item is WeaponData) or not would_combine_on_buy)
	var curious_cond_pos = character.my_id == "character_curious" and shop_item is ItemData and not already_has_it
	var king_cond_pos = character.my_id == "character_king" and ((shop_item is ItemData and not already_has_it) or shop_item is WeaponData) and shop_item.tier == Tier.LEGENDARY
	var king_cond_neg = character.my_id == "character_king" and ((shop_item is ItemData and not already_has_it) or shop_item is WeaponData) and shop_item.tier == Tier.COMMON and not would_combine_on_buy

	var fairy_cond_pos = fairy_data and shop_item.tier == Tier.COMMON and not already_has_it
	var fairy_cond_neg = fairy_data and shop_item.tier == Tier.LEGENDARY and not already_has_it

	if curious_cond_pos:
		return get_icon("icon_curious_happy").get_data()
	elif curious_cond_neg:
		return get_icon("icon_curious_sad").get_data()
	elif king_cond_pos:
		return get_icon("icon_king_happy").get_data()
	elif king_cond_neg:
		return get_icon("icon_king_sad").get_data()
	elif fairy_cond_pos:
		return get_icon("icon_fairy_happy").get_data()
	elif fairy_cond_neg:
		return get_icon("icon_fairy_sad").get_data()
	elif renegade_cond:
		return character.get_icon().get_data()

	return null


func get_chance_getting_caught(shop_item: ShopItem, wave: int, base_chance: float = 0.0) -> float:
	var wave_factor: float = wave * 10.0 / 100.0
	var value_factor: float = shop_item.value / 300.0
	var tier_factor: float = (shop_item.item_data.tier + 1.0) * 25.0 / 100.0
	var caught_chance: float = min(0.95, base_chance + wave_factor * value_factor * tier_factor)
	return caught_chance


func is_same_weapon(a: WeaponData, b: WeaponData) -> bool:
	var scaling_stats_are_the_same = false

	if a.stats.scaling_stats.size() == b.stats.scaling_stats.size():
		scaling_stats_are_the_same = true
		for i in a.stats.scaling_stats.size():
			if a.stats.scaling_stats[i][0] == b.stats.scaling_stats[i][0] and a.stats.scaling_stats[i][1] == b.stats.scaling_stats[i][1]:
				continue
			scaling_stats_are_the_same = false

	var effects_are_the_same = false

	if a.effects.size() == b.effects.size():
		effects_are_the_same = true
		for i in a.effects.size():
			if a.effects[i].key == b.effects[i].key and a.effects[i].value == b.effects[i].value:
				continue
			effects_are_the_same = false

	return (
		a.my_id == b.my_id and 
		a.stats.damage == b.stats.damage and 
		a.is_cursed == b.is_cursed and 
		scaling_stats_are_the_same and 
		effects_are_the_same
	)


func is_same_item(a: ItemData, b: ItemData) -> bool:
	return str(a.serialize()) == str(b.serialize())


func add_backgrounds(p_backgrounds: Array) -> void :
	backgrounds.append_array(p_backgrounds)
	emit_signal("backgrounds_updated")


func remove_backgrounds(p_backgrounds: Array) -> void :
	for p_background in p_backgrounds:
		backgrounds.erase(p_background)
	emit_signal("backgrounds_updated")


func get_background_gradient_color() -> Resource:
	return Utils.get_rand_element(background_colors)


func get_ordered_starting_weapons(starting_weapons: Array) -> Array:
	var new_starting_weapons = []

	for starting_weapon in starting_weapons:
		if starting_weapon.type == WeaponType.MELEE:
			new_starting_weapons.push_back(starting_weapon)

	for starting_weapon in starting_weapons:
		if starting_weapon.type == WeaponType.RANGED:
			new_starting_weapons.push_back(starting_weapon)

	return new_starting_weapons
