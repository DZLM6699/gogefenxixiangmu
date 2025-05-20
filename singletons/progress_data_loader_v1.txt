class_name ProgressDataLoaderV1
extends Reference


const LOG_PREFIX: = "ProgressDataLoaderV1: "

var load_status = LoadStatus.SAVE_OK

var zones_unlocked: = []
var characters_unlocked: = []

var upgrades_unlocked: = []
var consumables_unlocked: = []

var weapons_unlocked: = []
var items_unlocked: = []
var challenges_completed: = []

var difficulties_unlocked_serialized: = []
var inactive_mods: = []

var read_announcements: = []

var run_state_deserialized: Dictionary
var settings: Dictionary = {}
var data: Dictionary = {
	"enemies_killed": 0, 
	"materials_collected": 0, 
	"trees_killed": 0, 
	"steps_taken": 0, 
}

var _save_path: = ""



var _save_latest_path: = ""



var _save_stable_path: = ""


func _init(save_dir: = "") -> void :
	var dir: = Directory.new()
	var directory_exists: = not save_dir.empty() and dir.dir_exists(save_dir)
	if not directory_exists:
		return
	_save_path = save_dir + "/save.json"
	_save_latest_path = save_dir + "/save_latest.json"
	_save_stable_path = save_dir + "/save_stable.json"
	print(LOG_PREFIX + "Save path: " + _save_path)


func load_game_file(path: = "") -> void :
	if path.empty():
		path = _save_path
	if path.empty():
		printerr(LOG_PREFIX + "Loading failed - missing save path")
		return

	print(LOG_PREFIX + "Loading %s" % path)

	var save_file: = File.new()
	if not save_file.file_exists(path):
		print(LOG_PREFIX + "No v1 save found")
		load_status = LoadStatus.SAVE_MISSING
		return

	var error = save_file.open(path, File.READ)
	if error != OK:
		printerr(LOG_PREFIX + "Could not open %s. Error code: %s" % [path, error])
		_close_file_and_load_backups(save_file, path)
		return

	var parsed_zones = parse_json(save_file.get_line())
	var parsed_characters = parse_json(save_file.get_line())
	var parsed_upgrades = parse_json(save_file.get_line())
	var parsed_consumables = parse_json(save_file.get_line())
	var parsed_weapons = parse_json(save_file.get_line())
	var parsed_items = parse_json(save_file.get_line())
	var parsed_challenges = parse_json(save_file.get_line())
	var parsed_difficulties = parse_json(save_file.get_line())

	if (parsed_zones == null or parsed_characters == null or parsed_upgrades == null
		or parsed_consumables == null or parsed_weapons == null or parsed_items == null
		or parsed_challenges == null or parsed_difficulties == null
		):
			printerr(LOG_PREFIX + path + " is corrupted")
			_close_file_and_load_backups(save_file, path)
			return

	zones_unlocked = parsed_zones
	characters_unlocked = parsed_characters

	upgrades_unlocked = parsed_upgrades
	consumables_unlocked = parsed_consumables

	weapons_unlocked = parsed_weapons
	items_unlocked = parsed_items
	challenges_completed = parsed_challenges

	difficulties_unlocked_serialized = parsed_difficulties

	settings.clear()
	var saved_settings = parse_json(save_file.get_line())
	if saved_settings != null and saved_settings is Dictionary:
		settings = saved_settings

	data.clear()
	var saved_data = parse_json(save_file.get_line())
	if saved_data != null and saved_data is Dictionary:
		data = saved_data

	run_state_deserialized.clear()
	if save_file.get_position() < save_file.get_len():
		var saved_run_state = parse_json(save_file.get_line())
		if saved_run_state != null and saved_run_state is Dictionary:
			run_state_deserialized = deserialize_run_state(saved_run_state)

	inactive_mods.clear()
	if save_file.get_position() < save_file.get_len():
		var saved_inactive_mods = parse_json(save_file.get_line())
		if saved_inactive_mods != null and saved_inactive_mods is Array:
			inactive_mods = saved_inactive_mods

	save_file.close()


func _close_file_and_load_backups(save_file: File, save_path: String) -> void :
	save_file.close()
	_load_backups(save_path)


func _load_backups(previous_path: String) -> void :
	if previous_path == _save_path:
		load_status = LoadStatus.CORRUPTED_SAVE
		load_game_file(_save_latest_path)
	elif previous_path == _save_latest_path:
		load_status = LoadStatus.CORRUPTED_SAVE_LATEST
		load_game_file(_save_stable_path)
	elif previous_path == _save_stable_path:
		
		load_status = LoadStatus.CORRUPTED_ALL_SAVES


func deserialize_run_state(state: Dictionary) -> Dictionary:
	var result = state.duplicate()

	if not state.has_run_state:
		return result

	
	result.erase("current_character")
	result.erase("current_level")
	result.erase("current_xp")
	result.erase("gold")
	result.erase("starting_weapon")
	result.erase("max_weapons")
	result.erase("difficulty_unlocked")

	result.erase("weapons")
	result.erase("items")
	result.erase("appearances_displayed")
	result.erase("effects")
	result.erase("active_sets")
	result.erase("active_set_effects")
	result.erase("unique_effects")
	result.erase("additional_weapon_effects")
	result.erase("tier_iv_weapon_effects")
	result.erase("tier_i_weapon_effects")

	result.erase("chal_recycling_current")
	result.erase("consumables_picked_up_this_run")

	result.enabled_dlcs = []

	
	var serialized_player_run_data: = {
		"current_character": state.current_character if "current_character" in state else null, 
		"current_health": PlayerRunData.DEFAULT_MAX_HP, 
		"current_level": state.current_level if "current_level" in state else 0, 
		"current_xp": state.current_xp if "current_xp" in state else 0, 
		"gold": state.gold if "gold" in state else 0, 
		"weapons": state.weapons if "weapons" in state else [], 
		"items": state.items if "items" in state else [], 
		"appearances": state.appearances_displayed if "appearances_displayed" in state else [], 
		"effects": state.effects if "effects" in state else [], 
		"selected_weapon": state.starting_weapon if "starting_weapon" in state else null, 
		"active_sets": state.active_sets if "active_sets" in state else {}, 
		"active_set_effects": state.active_set_effects if "active_set_effects" in state else [], 
		"unique_effects": state.unique_effects if "unique_effects" in state else [], 
		"additional_weapon_effects": state.additional_weapon_effects if "additional_weapon_effects" in state else [], 
		"tier_iv_weapon_effects": state.tier_iv_weapon_effects if "tier_iv_weapon_effects" in state else [], 
		"tier_i_weapon_effects": state.tier_i_weapon_effects if "tier_i_weapon_effects" in state else [], 
		"chal_recycling_current": state.chal_recycling_current if "chal_recycling_current" in state else 0, 
		"consumables_picked_up_this_run": state.consumables_picked_up_this_run if "consumables_picked_up_this_run" in state else 0, 
		"curse_locked_shop_items_pity": 0
	}

	var new_weapons = []
	for weapon_id in state.weapons:

		if not weapon_id is String:
			continue

		var weapon_data = ItemService.get_element(ItemService.weapons, weapon_id)

		if weapon_data:
			new_weapons.push_back(weapon_data.serialize())

	serialized_player_run_data.weapons = new_weapons

	var new_items = []
	for item_id in state.items:
		var item_data = ItemService.get_element(ItemService.items, item_id)
		var character_data = ItemService.get_element(ItemService.characters, item_id)

		if item_data != null:
			new_items.push_back(item_data.serialize())
		elif character_data != null:
			new_items.push_back(character_data.serialize())

	serialized_player_run_data.items = new_items

	var player_data: PlayerRunData = PlayerRunData.new().deserialize(serialized_player_run_data)

	
	var test = PlayerRunData.init_effects()
	player_data.effects.merge(test)

	
	if player_data.effects.hp_cap >= 999999.0:
		
		player_data.effects.hp_cap = float(Utils.LARGE_NUMBER)
	if player_data.effects.speed_cap >= 999999.0:
		player_data.effects.speed_cap = float(Utils.LARGE_NUMBER)

	
	player_data.effects["gold_drops"] -= 100

	
	var old_value: int = player_data.effects["extra_enemies_next_wave"] if player_data.effects["extra_enemies_next_wave"] is int else 0
	if old_value != 0:
		player_data.effects["extra_enemies_next_wave"] = ["res://zones/zone_1/000_extra/bait_group.tres", float(old_value)]

	
	if "temp_stats_stacking" in player_data.effects:
		for effect in player_data.effects["temp_stats_stacking"]:
			if player_data.effects.has("temp_stats_per_interval"):
				player_data.effects["temp_stats_per_interval"].append([effect[0], effect[1], 5.0, false])
			else:
				player_data.effects["temp_stats_per_interval"] = [[effect[0], effect[1], 5.0, false]]

	
	if "giant_crit_damage" in player_data.effects:
		if player_data.effects["giant_crit_damage"] == 0:
			player_data.effects["giant_crit_damage"] = []
		else:
			player_data.effects["giant_crit_damage"] = [[player_data.effects["giant_crit_damage"], player_data.effects["giant_crit_damage"] / 10.0]]

	
	if player_data.effects["remove_speed"].size() > 0:
		player_data.effects["remove_speed"] = [[10, 30]]

	
	if "double_hp_regen_below_half_health" in player_data.effects and player_data.effects["double_hp_regen_below_half_health"]:
		player_data.effects["hp_regen_bonus"].push_back([1, 50])

	var _e = player_data.effects.erase("double_hp_regen_below_half_health")

	if "double_hp_regen" in player_data.effects and player_data.effects["double_hp_regen"]:
		player_data.effects["hp_regen_bonus"].push_back([1, 100])

	_e = player_data.effects.erase("double_hp_regen")

	
	
	player_data.effects["danger_enemy_health"] = 0
	player_data.effects["danger_enemy_damage"] = 0

	result.players_data = [player_data]
	result.is_coop_run = false
	result.retries = 0
	result.elites_killed_this_run = []
	result.bosses_killed_this_run = []
	result.loot_aliens_killed_this_run = 0
	result.total_bonus_gold = 0

	
	if not state.has("enemy_scaling"):
		result.enemy_scaling = ProgressData.settings.enemy_scaling.duplicate()
	if "current_character" in state and ( not state.has("current_difficulty") or state.current_difficulty < 0):
		
		
		
		result.current_difficulty = 0
		var current_zone: = 0
		for character_difficulty_info in difficulties_unlocked_serialized:
			if character_difficulty_info.character_id != state.current_character:
				continue
			for zone_difficulty_info in character_difficulty_info.zones_difficulty_info:
				if zone_difficulty_info.zone_id == current_zone:
					result.current_difficulty = zone_difficulty_info.difficulty_selected_value
					break
			break
	if not state.has("elites_spawn"):
		result.elites_spawn = []
	if not state.has("bosses_spawn") and "current_difficulty" in result:
		result.bosses_spawn = RunData.get_bosses_to_spawn(result.current_difficulty >= 5)
	if not state.has("shop_effects_checked"):
		result.shop_effects_checked = false
	if not state.has("chal_recyling_current"):
		result.chal_recycling_current = 0
	if not state.has("tracked_item_effects"):
		result.tracked_item_effects = [RunData.init_tracked_effects()]
	else:
		result.tracked_item_effects = [state["tracked_item_effects"].merge(RunData.init_tracked_effects())]

	if "current_background" in state:
		for bg in ItemService.backgrounds:
			if bg.name.to_lower() == state.current_background:
				result.current_background = bg
				break

	result.challenges_completed_this_run = []
	for challenge_id in state.challenges_completed_this_run:
		for chal_data in ChallengeService.challenges:
			if chal_data.my_id == challenge_id:
				result.challenges_completed_this_run.push_back(chal_data)
				break

	
	result.locked_shop_items = [[], [], [], []]
	for locked_item in state.locked_shop_items:
		var item_data = ItemService.get_element(ItemService.items, locked_item[0])
		var weapon_data = ItemService.get_element(ItemService.weapons, locked_item[0])

		if item_data != null:
			result.locked_shop_items[0].push_back([item_data, locked_item[1]])

		if weapon_data != null:
			result.locked_shop_items[0].push_back([weapon_data, locked_item[1]])

	
	result.shop_items = [[], [], [], []]
	for shop_item in state.shop_items:
		var item_data = ItemService.get_element(ItemService.items, shop_item[0])
		var weapon_data = ItemService.get_element(ItemService.weapons, shop_item[0])

		if item_data != null:
			result.shop_items[0].push_back([item_data, shop_item[1]])

		if weapon_data != null:
			result.shop_items[0].push_back([weapon_data, shop_item[1]])

	
	
	
	var reroll_count: = 0

	if "current_wave" in state:
		while true:
			var current_price: int = ItemService.get_reroll_price(state.current_wave, reroll_count, 0)[0]
			if current_price >= state.last_reroll_price or reroll_count > 100:
				reroll_count -= 1
				break
			reroll_count += 1

	
	result.reroll_count = [reroll_count, 0, 0, 0]
	result.paid_reroll_count = [reroll_count, 0, 0, 0]

	if "initial_free_rerolls" in state:
		result.initial_free_rerolls = [state.initial_free_rerolls, 0, 0, 0]

	if "free_rerolls" in state:
		result.free_rerolls = [state.free_rerolls, 0, 0, 0]

	if "tracked_item_effects" in state:
		result.tracked_item_effects = [state.tracked_item_effects, {}, {}, {}]

	result.item_steals = [0, 0, 0, 0]

	return result
