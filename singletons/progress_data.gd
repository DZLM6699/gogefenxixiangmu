extends Node

signal dlc_activated(dlc_id)
signal dlc_deactivated(dlc_id)
signal recreate_savegame_finished()
signal language_changed()

const VERSION = "1.1.10.7"

var smallest_text_font = preload("res://resources/fonts/actual/base/font_smallest_text.tres")

var languages = [
	"en", "fr", "zh", "zh_TW", "ja", "ko", "ru", "pl", "es", "pt", "de", "tr", "it"
]

const MAX_DIFFICULTY: = 5
const SMALLEST_FONT_BASE_SIZE: = 21
const FPS_LIMIT: = 60

var SAVE_DIR: = ""
var SAVE_PATH: = ""
var LOG_PATH: = ""
var fallback_dir_name: String = "user"


var load_status = LoadStatus.SAVE_OK

var available_dlcs: = []

var zones_unlocked: = []
var characters_unlocked: = []

var upgrades_unlocked: = []
var consumables_unlocked: = []

var weapons_unlocked: = []
var items_unlocked: = []
var challenges_completed: = []

var difficulties_unlocked: = []
var inactive_mods: = []

var read_announcements: = []

var saved_run_state: Dictionary
var last_saved_run_state: Dictionary
var settings: Dictionary = {}
var data: Dictionary = {}
var stats_dirty: bool = false


func _ready() -> void :
	init_save_paths()
	if DebugService.has_dlc and not get_tree().current_scene.name == "GutRunner":
		load_dlc_pcks()
		add_all_dlcs()

	init_settings()
	init_data()
	randomize()
	saved_run_state = _get_empty_run_state()

	
	for available_dlc in available_dlcs:
		available_dlc.add_resources()

	RunData.reset()

	if DebugService.generate_full_unlocked_save_file:
		unlock_all()
		save()
	else:
		load_game_file()
		add_unlocked_by_default()

	set_max_selectable_difficulty()

	for available_dlc in available_dlcs:
		if settings.deactivated_dlcs.has(available_dlc.my_id):
			available_dlc.remove_resources()


func init_settings() -> void :
	settings = {"version": "", "endless_mode_toggled": false, "coop_mode_toggled": false, "zone_selected": 0}
	settings.merge(init_general_options())
	settings.merge(init_gameplay_options())
	settings.language = Platform.get_language()


func init_data() -> void :
	data = {
		"enemies_killed": 0, 
		"materials_collected": 0, 
		"trees_killed": 0, 
		"steps_taken": 0, 
		"enemies_killed_far_away": 0, 
	}


func reset() -> void :
	saved_run_state = _get_empty_run_state()
	zones_unlocked.clear()
	characters_unlocked.clear()
	upgrades_unlocked.clear()
	consumables_unlocked.clear()
	weapons_unlocked.clear()
	items_unlocked.clear()
	challenges_completed.clear()
	difficulties_unlocked.clear()
	init_settings()
	init_data()
	add_unlocked_by_default()


func init_general_options() -> Dictionary:
	return {
		"volume": {
			"master": 0.5, 
			"sound": 0.75, 
			"music": 0.25
		}, 
		"fullscreen": true, 
		"screenshake": true, 
		"language": "en", 
		"background": 0, 
		"visual_effects": true, 
		"damage_display": true, 
		"optimize_end_waves": false, 
		"limit_fps": false, 
		"mute_on_focus_lost": false, 
		"pause_on_focus_lost": true, 
		"streamer_mode_tracks": true, 
		"legacy_tracks": false, 
		"deactivated_dlc_tracks": [], 
	}


func init_gameplay_options() -> Dictionary:
	return {
		"mouse_only": false, 
		"manual_aim": false, 
		"manual_aim_on_mouse_press": false, 
		"movement_with_gamepad": true, 
		"hp_bar_on_character": true, 
		"hp_bar_on_bosses": true, 
		"keep_lock": true, 
		"lock_coop_camera": false, 
		"endless_score_storing": 0, 
		"enemy_scaling": {
			"health": 1.0, 
			"damage": 1.0, 
			"speed": 1.0
		}, 
		"explosion_opacity": 1.0, 
		"projectile_opacity": 1.0, 
		"font_size": 1.0, 
		"character_highlighting": false, 
		"weapon_highlighting": false, 
		"projectile_highlighting": false, 
		"alt_gold_sounds": false, 
		"darken_screen": true, 
		"retry_wave": false, 
		"share_coop_loot": true, 
		"deactivated_dlcs": [], 
		"deactivated_skin_sets": [], 
	}


func load_dlc_pcks() -> void :
	var dlc_pck_names: = ["BrotatoAbyssalTerrors.pck"]
	for dlc_name in dlc_pck_names:
		var file = File.new()
		var dlc_path: String = Utils.get_game_dir() + "/" + dlc_name
		if file.file_exists(dlc_path):
			var success = ProjectSettings.load_resource_pack(dlc_path)
			if success:
				DebugService.log_data("Loaded DLC package: " + dlc_name)
			else:
				DebugService.log_data("Could not load DLC package: " + dlc_name)


func add_all_dlcs() -> void :
	var dir = Directory.new()
	var dir_path = "res://dlcs/"

	DebugService.log_data(dir_path + " exists: " + str(dir.dir_exists(dir_path)))

	if not dir.dir_exists(dir_path):
		return

	DebugService.log_data("Open " + dir_path)

	dir.open(dir_path)
	dir.list_dir_begin(true)

	var dlc_dirs: Array = []

	var dir_name = dir.get_next()
	while dir_name != "":
		if dir.current_is_dir():
			dlc_dirs.push_back(dir_path + dir_name)
		dir_name = dir.get_next()

	for path in dlc_dirs:
		dir.open(path)
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "dlc_data.tres":
				var dlc_data: = load(path + "/" + file_name) as DLCData
				if Platform.is_dlc_owned(dlc_data.my_id):
					DebugService.log_data("Found dlc file, loading resources from: " + str(dlc_data.my_id))
					available_dlcs.push_back(dlc_data)
				else:
					DebugService.log_data("Dlc is not owned: " + str(dlc_data.my_id))

			file_name = dir.get_next()

	dir.list_dir_end()


func save_run_state(
	shop_items: = [], 
	reroll_count: = [], 
	paid_reroll_count: = [], 
	initial_free_rerolls: = [], 
	free_rerolls: = [], 
	item_steals: = []
) -> void :
	saved_run_state = get_run_state(
		shop_items, 
		reroll_count, 
		paid_reroll_count, 
		initial_free_rerolls, 
		free_rerolls, 
		item_steals
	)
	last_saved_run_state = saved_run_state
	save()


func reset_and_save_new_run_state() -> void :
	reset_and_save_run_state(_get_empty_run_state())


func reset_and_save_run_state(run_state: Dictionary) -> void :
	saved_run_state = run_state
	settings.version = VERSION
	save()


func get_run_state(
	shop_items: = [], 
	reroll_count: = [], 
	paid_reroll_count: = [], 
	initial_free_rerolls: = [], 
	free_rerolls: = [], 
	item_steals: = []
) -> Dictionary:
	var run_state = RunData.get_state()
	run_state["has_run_state"] = true
	run_state["shop_items"] = shop_items.duplicate(true)
	run_state["reroll_count"] = reroll_count.duplicate()
	run_state["paid_reroll_count"] = paid_reroll_count.duplicate()
	run_state["initial_free_rerolls"] = initial_free_rerolls.duplicate()
	run_state["free_rerolls"] = free_rerolls.duplicate()
	run_state["item_steals"] = item_steals.duplicate()

	return run_state


func init_save_paths(user_dir_override: = "user://") -> void :
	var dir = Directory.new()
	var dir_path = user_dir_override + Platform.get_user_id()
	var directory_exists = dir.dir_exists(dir_path)
	if not directory_exists:
		var err = dir.make_dir(dir_path)
		if err != OK:
			printerr("Could not create the directory %s. Error code: %s" % [dir_path, err])
			return

	SAVE_DIR = dir_path
	SAVE_PATH = ProgressDataLoaderV2.new(SAVE_DIR).save_path
	LOG_PATH = dir_path + "/log.txt"
	print("LOG_PATH: " + str(LOG_PATH))
	var file = File.new()
	file.open(LOG_PATH, File.WRITE)
	file.close()

	if not directory_exists:
		_copy_files_from_fallback_dir(user_dir_override)


func _copy_files_from_fallback_dir(user_dir_override: String) -> void :
	var dir: Directory = Directory.new()
	var dir_path: String = user_dir_override + fallback_dir_name
	if dir.dir_exists(dir_path) and dir_path != SAVE_DIR:
		print("fallback save dir found at %s. Copying files into %s" % [dir_path, SAVE_DIR])
		var err: int = dir.open(dir_path)
		if err != OK:
			printerr("Could not change directory to %s. Error code: %s" % [dir_path, err])
			return

		err = dir.list_dir_begin(false)
		if err != OK:
			printerr("Could not list directory %s. Error code: %s" % [dir_path, err])
			return

		var filename: String = dir.get_next()
		while filename != "":
			if not dir.current_is_dir():
				var file_path: String = dir.get_current_dir() + "/" + filename
				err = dir.copy(file_path, SAVE_DIR + "/" + filename)
				if err != OK:
					printerr("Could not copy file %s. Error code: %s" % [file_path, err])
			filename = dir.get_next()


func load_game_file(try_fallback: = true) -> void :
	if DebugService.reinitialize_save:
		save()
		return
	var loader_v2 = ProgressDataLoaderV2.new(SAVE_DIR)
	load_with_generic_loader(loader_v2)
	if load_status == LoadStatus.SAVE_OK:
		return
	if load_status != LoadStatus.SAVE_MISSING:
		
		return
	var loader_v1 = ProgressDataLoaderV1.new(SAVE_DIR)
	load_with_generic_loader(loader_v1)
	if load_status == LoadStatus.SAVE_OK:
		print("Migrating v1 save to v2")
	elif load_status != LoadStatus.SAVE_MISSING:
		
		print("Migrating corrupted v1 save to v2")
	else:
		if try_fallback:
			print("No save found, trying to copy from fallback")
			_use_fallback_save()
			return
		print("No save found, creating new save")
		load_status = LoadStatus.SAVE_OK
	save()


func _use_fallback_save() -> void :
	var split: = SAVE_DIR.split("//")
	_copy_files_from_fallback_dir(split[0] + "//")
	load_game_file(false)


func load_with_generic_loader(loader, path: = "") -> void :
	loader.load_game_file(path)
	load_status = loader.load_status

	if load_status == LoadStatus.CORRUPTED_ALL_SAVES:
		_recreate_from_achievements()
		return
	if load_status == LoadStatus.SAVE_MISSING:
		return

	_append_without_duplicates(zones_unlocked, loader.zones_unlocked)
	_append_without_duplicates(characters_unlocked, loader.characters_unlocked)
	_append_without_duplicates(upgrades_unlocked, loader.upgrades_unlocked)
	_append_without_duplicates(consumables_unlocked, loader.consumables_unlocked)
	_append_without_duplicates(weapons_unlocked, loader.weapons_unlocked)
	_append_without_duplicates(items_unlocked, loader.items_unlocked)
	_append_without_duplicates(challenges_completed, loader.challenges_completed)

	for difficulty_json in loader.difficulties_unlocked_serialized:
		var difficulty: = CharacterDifficultyInfo.new()
		difficulty.deserialize_and_merge(difficulty_json)
		difficulties_unlocked.append(difficulty)

	_dedublicate_difficulties_unlocked()

	inactive_mods = loader.inactive_mods.duplicate()
	read_announcements = loader.read_announcements.duplicate()

	saved_run_state = Utils.merge_dictionaries(saved_run_state, loader.run_state_deserialized)
	
	for k in ["nb_of_waves", "current_wave", "current_difficulty", "bonus_gold", "retries"]:
		if saved_run_state.has(k) and typeof(saved_run_state[k]) == TYPE_REAL:
			saved_run_state[k] = int(saved_run_state[k])
	for k in ["reroll_count", "paid_reroll_count", "initial_free_rerolls", "free_rerolls"]:
		if saved_run_state.has(k) and typeof(saved_run_state[k]) == TYPE_ARRAY:
			for i in saved_run_state[k].size():
				if typeof(saved_run_state[k][i]) == TYPE_REAL:
					saved_run_state[k][i] = int(saved_run_state[k][i])

	settings = Utils.merge_dictionaries(settings, loader.settings)

	data = Utils.merge_dictionaries(data, loader.data)
	for k in ["enemies_killed", "materials_collected", "trees_killed", "steps_taken", "enemies_killed_far_away"]:
		if data.has(k):
			
			data[k] = int(data[k])


func _dedublicate_difficulties_unlocked() -> void :
	var processed_characters: = {}
	var new_difficulties_unlocked: = []
	for difficulty in difficulties_unlocked:
		if not difficulty.character_id in processed_characters:
			new_difficulties_unlocked.append(difficulty)
			processed_characters[difficulty.character_id] = true

		var processed_zones: = {}
		var new_zones_difficulty_info: = []
		for zone_diff_info in difficulty.zones_difficulty_info:
			if not zone_diff_info.zone_id in processed_zones:
				new_zones_difficulty_info.append(zone_diff_info)
				processed_zones[zone_diff_info.zone_id] = true

		difficulty.zones_difficulty_info = new_zones_difficulty_info
	difficulties_unlocked = new_difficulties_unlocked


func save() -> void :
	if DebugService.disable_saving:
		return
	if load_status == LoadStatus.CORRUPTED_ALL_SAVES_NO_STEAM or load_status == LoadStatus.CORRUPTED_ALL_SAVES_NO_EPIC:
		printerr("Aborting save due to unrecoverable corruption")
		return
	var loader_v2 = ProgressDataLoaderV2.new(SAVE_DIR)
	_set_loader_properties(loader_v2, saved_run_state)
	loader_v2.save()

	sync_stats()



func get_current_save_object() -> Dictionary:
	var loader_v2 = ProgressDataLoaderV2.new(SAVE_DIR)
	_set_loader_properties(loader_v2, _get_current_run_state())
	return loader_v2.get_save_object()


func add_unlocked_by_default() -> void :
	for zone in ZoneService.zones:
		if zone.unlocked_by_default and not zones_unlocked.has(zone.my_id):
			zones_unlocked.push_back(zone.my_id)

	for item in ItemService.items:
		if item.unlocked_by_default and not items_unlocked.has(item.my_id):
			items_unlocked.push_back(item.my_id)

	for weapon in ItemService.weapons:
		if weapon.unlocked_by_default and not weapons_unlocked.has(weapon.weapon_id):
			weapons_unlocked.push_back(weapon.weapon_id)

	for upgrade in ItemService.upgrades:
		if upgrade.unlocked_by_default and not upgrades_unlocked.has(upgrade.upgrade_id):
			upgrades_unlocked.push_back(upgrade.upgrade_id)

	for character in ItemService.characters:
		if character.unlocked_by_default and not characters_unlocked.has(character.my_id):
			characters_unlocked.push_back(character.my_id)

	for consumable in ItemService.consumables:
		if consumable.unlocked_by_default and not consumables_unlocked.has(consumable.my_id):
			consumables_unlocked.push_back(consumable.my_id)

	for character in ItemService.characters:
		var character_difficulty_info_exists = false
		var existing_zones_difficulty_info = []
		var char_diff_info_to_modify: = CharacterDifficultyInfo.new(character.my_id)

		for difficulty_unlocked in difficulties_unlocked:
			if difficulty_unlocked.character_id == character.my_id:
				character_difficulty_info_exists = true
				char_diff_info_to_modify = difficulty_unlocked
				for zone_diff_info in difficulty_unlocked.zones_difficulty_info:
					existing_zones_difficulty_info.push_back(zone_diff_info.zone_id)

		for zone in ZoneService.zones:
			if zone.unlocked_by_default:
				var already_has_zone_diff_info = existing_zones_difficulty_info.has(zone.my_id)

				if not already_has_zone_diff_info:
					char_diff_info_to_modify.zones_difficulty_info.push_back(ZoneDifficultyInfo.new(zone.my_id))

		if not character_difficulty_info_exists:
			difficulties_unlocked.push_back(char_diff_info_to_modify)


func unlock_all() -> void :
	for zone in ZoneService.zones:
		if zone.unlocked_by_default:
			zones_unlocked.push_back(zone.my_id)

	for item in ItemService.items:
			items_unlocked.push_back(item.my_id)

	for weapon in ItemService.weapons:
		if not weapons_unlocked.has(weapon.weapon_id):
			weapons_unlocked.push_back(weapon.weapon_id)

	for upgrade in ItemService.upgrades:
		if not upgrades_unlocked.has(upgrade.upgrade_id):
			upgrades_unlocked.push_back(upgrade.upgrade_id)

	for character in ItemService.characters:
		characters_unlocked.push_back(character.my_id)

	for consumable in ItemService.consumables:
		if consumable.unlocked_by_default and not consumables_unlocked.has(consumable.my_id):
			consumables_unlocked.push_back(consumable.my_id)

	difficulties_unlocked = []

	for character in ItemService.characters:
		var character_diff_info = CharacterDifficultyInfo.new(character.my_id)

		for zone in ZoneService.zones:
			if zone.unlocked_by_default:
				var info = ZoneDifficultyInfo.new(zone.my_id)
				info.max_selectable_difficulty = MAX_DIFFICULTY
				character_diff_info.zones_difficulty_info.push_back(info)

		difficulties_unlocked.push_back(character_diff_info)

	ChallengeService.complete_all_challenges()


func set_max_selectable_difficulty() -> void :
	var overall_max_selectable_difficulty: = 0
	for difficulty_info in difficulties_unlocked:
		for zone_difficulty_info in difficulty_info.zones_difficulty_info:
			overall_max_selectable_difficulty = int(max(overall_max_selectable_difficulty, zone_difficulty_info.max_selectable_difficulty))

	for difficulty in difficulties_unlocked:
		for zone_difficulty_info in difficulty.zones_difficulty_info:
			if zone_difficulty_info.max_selectable_difficulty < overall_max_selectable_difficulty:
				zone_difficulty_info.max_selectable_difficulty = overall_max_selectable_difficulty


func apply_settings() -> void :
	if settings.has("volume"):
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(settings.volume.master ))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"), linear2db(settings.volume.sound))
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear2db(settings.volume.music))

	TranslationServer.set_locale(settings.language)

	if not DebugService.no_fullscreen_on_launch:
		OS.window_fullscreen = settings.fullscreen

	smallest_text_font.size = SMALLEST_FONT_BASE_SIZE * settings.font_size
	RunData.reset_background()
	set_fps_limit(settings.limit_fps)


func set_font_size(value: float) -> void :
	smallest_text_font.size = SMALLEST_FONT_BASE_SIZE * value
	settings.font_size = value


func set_fps_limit(enabled: bool) -> void :
	Engine.target_fps = FPS_LIMIT if enabled else 0
	settings.limit_fps = enabled


func get_all_available_dlc_ids() -> Array:
	var ids = []

	for dlc in available_dlcs:
		ids.push_back(dlc.my_id)

	return ids


func update_dlc_resources_based_on_run_state(state: Dictionary) -> void :
	for enabled_dlc_id in state.enabled_dlcs:
		if enabled_dlc_id in settings.deactivated_dlcs:
			var dlc_data = get_dlc_data(enabled_dlc_id)

			if dlc_data:
				dlc_data.add_resources()

	for active_dlc_id in get_active_dlc_ids():
		if not active_dlc_id in state.enabled_dlcs:
			var dlc_data = get_dlc_data(active_dlc_id)

			if dlc_data:
				dlc_data.remove_resources()


func get_active_dlc_ids() -> Array:
	var active_dlcs = get_all_available_dlc_ids()

	for deactivated_dlc_id in settings.deactivated_dlcs:
		active_dlcs.erase(deactivated_dlc_id)

	return active_dlcs


func get_active_dlc_tracks() -> Array:
	var ids = get_all_available_dlc_ids()

	for deactivated_dlc_id in settings.deactivated_dlc_tracks:
		ids.erase(deactivated_dlc_id)

	return ids


func reset_dlc_resources_to_active_dlcs() -> void :
	for dlc in available_dlcs:
		dlc.remove_resources()

	for dlc_id in get_active_dlc_ids():
		var dlc_data = get_dlc_data(dlc_id)
		if dlc_data:
			dlc_data.add_resources()


func get_dlc_data(dlc_id: String) -> DLCData:
	for dlc in available_dlcs:
		if dlc.my_id == dlc_id:
			return dlc

	return null


func activate_dlc(dlc_id: String) -> void :

	print("activate dlc " + dlc_id)

	if get_active_dlc_ids().has(dlc_id):
		print(dlc_id + " already exists")
		return

	settings.deactivated_dlcs.erase(dlc_id)

	for dlc in available_dlcs:
		if dlc.my_id == dlc_id:
			dlc.add_resources()

	add_unlocked_by_default()
	RunData.reset()
	emit_signal("dlc_activated", dlc_id)


func deactivate_dlc(dlc_id: String) -> void :

	print("deactivate dlc " + dlc_id)

	if settings.deactivated_dlcs.has(dlc_id):
		print(dlc_id + " doesn't exist")
		return

	settings.deactivated_dlcs.push_back(dlc_id)
	for dlc in available_dlcs:
		if dlc.my_id == dlc_id:
			dlc.remove_resources()

	RunData.current_zone = 0
	RunData.reset()
	emit_signal("dlc_deactivated", dlc_id)


func is_dlc_available(dlc_id: String) -> bool:
	for dlc in available_dlcs:
		if dlc.my_id == dlc_id:
			return true
	return false


func is_dlc_available_and_active(dlc_id: String) -> bool:
	var is_available = is_dlc_available(dlc_id)

	if not is_available:
		return false

	return not settings.deactivated_dlcs.has(dlc_id)


func get_character_difficulty_info(character_id: String, zone_id: int) -> ZoneDifficultyInfo:

	for character_difficulty_info in difficulties_unlocked:
		if character_difficulty_info.character_id != character_id: continue

		for zone_difficulty_info in character_difficulty_info.zones_difficulty_info:
			if zone_difficulty_info.zone_id != zone_id: continue
			return zone_difficulty_info

	return null


func increment_stat(key: String) -> void :
	data[key] += 1
	stats_dirty = true


func sync_stats() -> void :
	if stats_dirty:
		for key in data.keys():
			Platform.set_stat(key, data[key])
		stats_dirty = false


func is_manual_aim(player_index: int) -> bool:
	if settings.manual_aim_on_mouse_press:
		
		var is_mouse_pressed = not RunData.is_coop_run and Input.is_mouse_button_pressed(BUTTON_LEFT)
		var is_gamepad_pressed = Utils.is_player_using_gamepad(player_index) and Utils.get_player_rjoy_vector(player_index) != Vector2.ZERO
		return is_mouse_pressed or is_gamepad_pressed
	return settings.manual_aim and ( not RunData.is_coop_run or Utils.is_player_using_gamepad(player_index))


func _recreate_from_achievements() -> void :
	if Platform.get_type() == PlatformType.STEAM:
		if Platform.get_user_id() == "0":
			load_status = LoadStatus.CORRUPTED_ALL_SAVES_NO_STEAM
			printerr("All saves corrupted and not on steam")
			return

		load_status = LoadStatus.CORRUPTED_ALL_SAVES_STEAM

	if Platform.get_type() == PlatformType.EPIC:
		if Platform.get_user_id() == "0":
			load_status = LoadStatus.CORRUPTED_ALL_SAVES_NO_EPIC
			printerr("All saves corrupted and not on epic")
			return
		load_status = LoadStatus.CORRUPTED_ALL_SAVES_EPIC

	print("Recreating progress data from achievements")

	var max_diff: = 0
	var characters_won: = []

	for chal in ChallengeService.challenges:
		var result = Platform.is_challenge_completed(chal.my_id)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == true:
			ChallengeService.complete_challenge(chal.my_id)

			if (chal.my_id == "chal_difficulty_0" or chal.my_id == "chal_difficulty_1" or chal.my_id == "chal_difficulty_2"
			or chal.my_id == "chal_difficulty_3" or chal.my_id == "chal_difficulty_4" or chal.my_id == "chal_difficulty_5"):
				max_diff = int(max(max_diff, chal.value + 1))

			characters_won.push_back("character_" + chal.my_id.trim_prefix("chal_"))

	for char_diff in difficulties_unlocked:
		for zone_difficulty_info in char_diff.zones_difficulty_info:
			zone_difficulty_info.max_selectable_difficulty = int(clamp(max_diff, zone_difficulty_info.max_selectable_difficulty, MAX_DIFFICULTY))

	for character in ItemService.characters:
		var character_difficulty = get_character_difficulty_info(character.my_id, RunData.current_zone)

		if characters_won.has(character.my_id):
				character_difficulty.max_difficulty_beaten.set_info(
					0, 
					20, 
					RunData.current_run_accessibility_settings.health, 
					RunData.current_run_accessibility_settings.damage, 
					RunData.current_run_accessibility_settings.speed, 
					RunData.retries, 
					false, 
					false
				)

	data.enemies_killed = Platform.get_stat("enemies_killed")
	data.materials_collected = Platform.get_stat("materials_collected")
	data.trees_killed = Platform.get_stat("trees_killed")
	data.steps_taken = Platform.get_stat("steps_taken")
	data.enemies_killed_far_away = Platform.get_stat("enemies_killed_far_away")

	save()
	emit_signal("recreate_savegame_finished")


func _set_loader_properties(loader_v2: ProgressDataLoaderV2, run_state: Dictionary) -> void :
	loader_v2.zones_unlocked = zones_unlocked.duplicate()
	loader_v2.characters_unlocked = characters_unlocked.duplicate()
	loader_v2.upgrades_unlocked = upgrades_unlocked.duplicate()
	loader_v2.consumables_unlocked = consumables_unlocked.duplicate()
	loader_v2.weapons_unlocked = weapons_unlocked.duplicate()
	loader_v2.items_unlocked = items_unlocked.duplicate()
	loader_v2.challenges_completed = challenges_completed.duplicate()
	loader_v2.difficulties_unlocked_serialized.clear()
	for difficulty_unlocked in difficulties_unlocked:
		loader_v2.difficulties_unlocked_serialized.push_back(difficulty_unlocked.serialize())
	loader_v2.inactive_mods = inactive_mods.duplicate()
	loader_v2.read_announcements = read_announcements.duplicate()
	loader_v2.run_state_deserialized = run_state.duplicate()
	loader_v2.settings = settings.duplicate()
	loader_v2.data = data.duplicate()


func _get_current_run_state() -> Dictionary:
	if saved_run_state.has_run_state:
		
		return get_run_state(
			saved_run_state.shop_items, 
			saved_run_state.reroll_count, 
			saved_run_state.paid_reroll_count, 
			saved_run_state.initial_free_rerolls, 
			saved_run_state.free_rerolls, 
			saved_run_state.item_steals
		)
	else:
		return get_run_state()


func _get_empty_run_state() -> Dictionary:
	return {"has_run_state": false}


func _append_without_duplicates(array: Array, array_to_append: Array) -> void :
	var dict: = {}
	for item in array:
		dict[item] = true
	for item in array_to_append:
		if not dict.has(item):
			array.push_back(item)
			dict[item] = true


func change_language(new_language: String) -> void :
	if not new_language in languages:
		printerr("Language %s is not a valid language option" % new_language)
		return

	settings.language = new_language
	TranslationServer.set_locale(new_language)
	emit_signal("language_changed")
