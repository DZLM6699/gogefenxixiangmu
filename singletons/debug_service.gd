extends Node

export (int, 1, 1000) var starting_wave: = 1
export (int) var starting_gold = 30
export (bool) var invulnerable = false
export (bool) var invisible = false
export (bool) var one_shot_enemies = false
export (bool) var instant_waves = false
export (int) var custom_wave_duration = - 1
export (bool) var no_fullscreen_on_launch = false
export (Array, Resource) var debug_weapons
export (Array, Resource) var debug_items
export (bool) var remove_starting_weapons = false
export (bool) var add_all_weapons = false
export (bool) var add_all_items = false
export (bool) var curse_debug_items_and_weapons = false
export (bool) var unlock_all_chars = false
export (bool) var unlock_all_challenges = false
export (bool) var unlock_all_difficulties = false
export (bool) var generate_full_unlocked_save_file = false
export (bool) var reinitialize_save = false
export (bool) var reinitialize_store_data = false
export (bool) var disable_saving = false
export (bool) var randomize_equipment = false
export (bool) var randomize_waves = false
export (bool) var hide_wave_timer = false
export (bool) var nullify_enemy_speed = false
export (bool) var always_drop_crates = false
export (float, 0.0, 10.0, 0.1) var nb_enemies_mult = 1.0
export (bool) var no_enemies = false
export (bool) var spawn_debug_enemies = false
export (Array, Resource) var debug_enemies
export (String) var spawn_specific_elite = ""
export (String) var spawn_specific_boss = ""
export (String) var force_item_in_shop = ""

export (bool) var coop_multiple_keyboard_inputs = false
export (bool) var has_dlc = true

export (bool) var enable_time_scale_buttons = false
export (bool) var always_curse = false
export (bool) var spawn_horde = false
export (bool) var display_fps = false

var debug_items_added: = [false, false, false, false]
var debug_weapons_added: = [false, false, false, false]
var starting_weapons_removed: = [false, false, false, false]


func reset_for_new_run() -> void :
	for i in 4:
		debug_items_added[i] = false
		debug_weapons_added[i] = false
		starting_weapons_removed[i] = false


func reset() -> void :
	starting_wave = 1
	starting_gold = 30
	invulnerable = false
	invisible = false
	one_shot_enemies = false
	instant_waves = false
	no_fullscreen_on_launch = false
	debug_weapons = []
	debug_items = []
	remove_starting_weapons = false
	add_all_weapons = false
	add_all_items = false
	unlock_all_chars = false
	unlock_all_challenges = false
	unlock_all_difficulties = false
	generate_full_unlocked_save_file = false
	reinitialize_save = false
	reinitialize_store_data = false
	disable_saving = false
	randomize_equipment = false
	randomize_waves = false
	hide_wave_timer = false
	nullify_enemy_speed = false
	no_enemies = false
	coop_multiple_keyboard_inputs = false
	debug_enemies = []
	spawn_specific_elite = ""


func handle_player_spawn_debug_options(player_index: int) -> void :
	if remove_starting_weapons and not starting_weapons_removed[player_index]:
		RunData.remove_all_weapons(player_index)
		starting_weapons_removed[player_index] = true

	if randomize_equipment:
		var weapon = Utils.get_rand_element(ItemService.weapons)
		for _i in range(6):
			var weapon_to_add = weapon
			if curse_debug_items_and_weapons:
				weapon_to_add = ProgressData.available_dlcs[0].curse_item(weapon, player_index)
			var _weapon = RunData.add_weapon(weapon_to_add, player_index)

		for i in 10:
			var item = Utils.get_rand_element(ItemService.items).duplicate()
			if curse_debug_items_and_weapons:
				item = ProgressData.available_dlcs[0].curse_item(item, player_index)
			RunData.add_item(item, player_index)

		for i in 30:
			var upg = Utils.get_rand_element(ItemService.upgrades)
			RunData.add_item(upg, player_index)

	if add_all_weapons and not debug_weapons_added[player_index]:
		for weapon in ItemService.weapons:
			var weapon_to_add = weapon
			if curse_debug_items_and_weapons:
				weapon_to_add = ProgressData.available_dlcs[0].curse_item(weapon, player_index)
			var _added_weapon = RunData.add_weapon(weapon_to_add, player_index)
		debug_weapons_added[player_index] = true

	if add_all_items and not debug_items_added[player_index]:
		for item in ItemService.items:
			if item.my_id == "item_axolotl":
				continue
			var item_to_add = item
			if curse_debug_items_and_weapons:
				item_to_add = ProgressData.available_dlcs[0].curse_item(item, player_index)
			RunData.add_item(item_to_add, player_index)
		debug_items_added[player_index] = true

	if debug_weapons.size() > 0 and not debug_weapons_added[player_index]:
		for weapon in debug_weapons:
			var weapon_to_add = weapon
			if curse_debug_items_and_weapons:
				weapon_to_add = ProgressData.available_dlcs[0].curse_item(weapon, player_index)
			var _added_weapon = RunData.add_weapon(weapon_to_add, player_index)
		debug_weapons_added[player_index] = true

	if debug_items.size() > 0 and not debug_items_added[player_index]:
		for item in debug_items:
			var item_to_add = item
			if curse_debug_items_and_weapons:
				item_to_add = ProgressData.available_dlcs[0].curse_item(item, player_index)
			RunData.add_item(item_to_add, player_index)
		debug_items_added[player_index] = true


func log_run_info(upgrades: Array = [[], [], [], []], consumables: Array = [[], [], [], []]) -> void :

	var log_file = File.new()
	var error = log_file.open(ProgressData.LOG_PATH, File.READ_WRITE)

	if error != OK:
		printerr("Could not open the file %s. Aborting save operation. Error code: %s" % 
		[ProgressData.LOG_PATH, error])
		return

	log_file.seek_end()
	log_file.store_line("--Run Data--")
	for player_index in RunData.get_player_count():
		log_file.store_line("** Player %s" % player_index)
		log_file.store_line("Character: " + str(RunData.get_player_character(player_index).my_id))
		log_file.store_line("Wave: " + str(RunData.current_wave))
		log_file.store_line("Danger: " + str(RunData.current_difficulty))
		log_file.store_line("Level ups: " + str(upgrades[player_index].size()))
		log_file.store_line("Consumables: " + str(consumables[player_index].size()))
		log_file.store_line("Gold: " + str(RunData.get_player_gold(player_index)))
		log_file.store_line("Bonus Gold: " + str(RunData.bonus_gold))

		var items = ""

		for item in RunData.get_player_items(player_index):
			items += item.my_id + ", "

		log_file.store_line("Items: " + str(items))

		var weapons = ""

		for item in RunData.get_player_weapons(player_index):
			weapons += item.my_id + ", "

		log_file.store_line("Weapons: " + str(weapons))

	log_file.store_line("--Run Data end--")
	log_file.close()


func log_data(text: String) -> void :
	var log_file = File.new()
	var error = log_file.open(ProgressData.LOG_PATH, File.READ_WRITE)

	if error != OK:
		printerr("Could not open the file %s. Aborting save operation. Error code: %s" % 
		[ProgressData.LOG_PATH, error])
		return

	log_file.seek_end()
	log_file.store_line(text)
	log_file.close()
