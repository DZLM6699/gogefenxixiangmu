class_name ProgressDataLoaderV2
extends Reference


const LOG_PREFIX: = "ProgressDataLoaderV2: "
const MAX_BACKUP_FILES: = 5

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

var save_path: = ""
var _tmp_path: = ""


func _init(save_dir: = "") -> void :
	var dir: = Directory.new()
	var directory_exists: = not save_dir.empty() and dir.dir_exists(save_dir)
	if not directory_exists:
		return
	save_path = save_dir + "/save_v2.json"
	_tmp_path = save_dir + "/save_v2.json.tmp"
	
	print(LOG_PREFIX + "Save path: " + save_path)


func load_game_file(path: = "") -> void :
	if path.empty():
		path = save_path
	if path.empty():
		printerr(LOG_PREFIX + "Loading failed - missing save path")
		return

	print(LOG_PREFIX + "Loading %s" % path)

	var save_file: = File.new()
	if not save_file.file_exists(path):
		print(LOG_PREFIX + "No v2 save found")
		load_status = LoadStatus.SAVE_MISSING
		return

	var error = save_file.open(path, File.READ)
	if error != OK:
		printerr(LOG_PREFIX + "Could not open %s. Error code: %s" % [path, error])
		_close_file_and_load_backups(save_file, path)
		return

	var parse_result: = JSON.parse(save_file.get_as_text())
	if parse_result.error != OK:
		var error_line: = parse_result.error_line
		var error_string: = parse_result.error_string
		printerr(LOG_PREFIX + "Error parsing save file (%s): %s at line %s" % [parse_result.error, error_string, error_line])
		_close_file_and_load_backups(save_file, path)
		return

	var save_object = parse_result.result
	if typeof(save_object) != TYPE_DICTIONARY:
		printerr(LOG_PREFIX + "Save file is not a dictionary")
		_close_file_and_load_backups(save_file, path)
		return

	for property in ["zones_unlocked", "characters_unlocked", "upgrades_unlocked", "consumables_unlocked", "weapons_unlocked", "items_unlocked", "challenges_completed", "difficulties_unlocked", "inactive_mods"]:
		if not save_object.has(property):
			printerr(LOG_PREFIX + "Save file is missing property: %s" % property)
			_close_file_and_load_backups(save_file, path)
			return
		if typeof(save_object[property]) != TYPE_ARRAY:
			printerr(LOG_PREFIX + "Property %s is not an array" % property)
			_close_file_and_load_backups(save_file, path)
			return

	for property in ["current_run_state", "settings", "data"]:
		if not save_object.has(property):
			printerr(LOG_PREFIX + "Save file is missing property: %s" % property)
			_close_file_and_load_backups(save_file, path)
			return
		if typeof(save_object[property]) != TYPE_DICTIONARY:
			printerr(LOG_PREFIX + "Property %s is not a dictionary" % property)
			_close_file_and_load_backups(save_file, path)
			return

	zones_unlocked = save_object.zones_unlocked
	characters_unlocked = save_object.characters_unlocked
	upgrades_unlocked = save_object.upgrades_unlocked
	consumables_unlocked = save_object.consumables_unlocked
	weapons_unlocked = save_object.weapons_unlocked
	items_unlocked = save_object.items_unlocked
	challenges_completed = save_object.challenges_completed
	difficulties_unlocked_serialized = save_object.difficulties_unlocked
	inactive_mods = save_object.inactive_mods
	read_announcements = save_object.get("read_announcements", [])
	settings = save_object.settings
	data = save_object.data
	run_state_deserialized = deserialize_run_state(save_object.current_run_state)

	save_file.close()


func deserialize_run_state(state: Dictionary) -> Dictionary:
	var result = state.duplicate()

	if not state.has_run_state:
		return result

	result.players_data = []
	for serialized_player_data in state.players_data:
		if serialized_player_data is String:
			result.has_run_state = false
			return result
		result.players_data.push_back(PlayerRunData.new().deserialize(serialized_player_data))

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
	for player_index in state.locked_shop_items.size():
		for locked_item in state.locked_shop_items[player_index]:
			var item_data = ItemService.get_element(ItemService.items, locked_item[0].my_id)
			var weapon_data = ItemService.get_element(ItemService.weapons, locked_item[0].my_id)

			if item_data != null:
				item_data = item_data.duplicate()
				item_data.deserialize_and_merge(locked_item[0])
				result.locked_shop_items[player_index].push_back([item_data, locked_item[1]])

			if weapon_data != null:
				weapon_data = weapon_data.duplicate()
				weapon_data.deserialize_and_merge(locked_item[0])
				result.locked_shop_items[player_index].push_back([weapon_data, locked_item[1]])

	result.shop_items = [[], [], [], []]
	for player_index in state.shop_items.size():
		for shop_item in state.shop_items[player_index]:

			if shop_item[0] is String:
				continue

			var item_data = ItemService.get_element(ItemService.items, shop_item[0].my_id)
			var weapon_data = ItemService.get_element(ItemService.weapons, shop_item[0].my_id)

			if item_data != null:
				item_data = item_data.duplicate()
				item_data.deserialize_and_merge(shop_item[0])
				result.shop_items[player_index].push_back([item_data, shop_item[1]])

			if weapon_data != null:
				weapon_data = weapon_data.duplicate()
				weapon_data.deserialize_and_merge(shop_item[0])
				result.shop_items[player_index].push_back([weapon_data, shop_item[1]])

	return result


func _close_file_and_load_backups(save_file: File, load_path: String) -> void :
	save_file.close()
	_load_backups(load_path)


func _load_backups(previous_path: String) -> void :
	load_status = LoadStatus.CORRUPTED_SAVE
	var backup_paths: = _collect_backup_paths()
	var next_index: = 0 if previous_path == save_path else (backup_paths.find(previous_path) + 1)
	if next_index == - 1 or next_index >= backup_paths.size():
		
		load_status = LoadStatus.CORRUPTED_ALL_SAVES
		return
	load_game_file(backup_paths[next_index])


func save() -> void :
	if save_path.empty() or _tmp_path.empty():
		printerr(LOG_PREFIX + "Saving failed - missing save path")
		return

	var save_file: = File.new()

	
	var error = save_file.open(_tmp_path, File.WRITE)
	if error != OK:
		printerr(LOG_PREFIX + "Could not create %s. Aborting save operation. Error code: %s" % [_tmp_path, error])
		return

	var save_object: = get_save_object()
	var sort_keys: = true
	var indent = ""
	if OS.has_feature("editor"):
		indent = "  "
	var save_json: = JSON.print(save_object, indent, sort_keys)
	save_file.store_string(save_json)
	save_file.close()

	var dir: = Directory.new()

	
	var do_backup: = true
	var latest_backup_path: = save_path.replace("save_v2", "save_v2_01") + ".bak"
	if dir.file_exists(latest_backup_path):
		var latest_backup_file: = File.new()
		error = latest_backup_file.open(latest_backup_path, File.READ)
		if error != OK:
			printerr(LOG_PREFIX + "Could not open %s. Error code: %s" % [latest_backup_path, error])
			return
		var latest_backup_json = latest_backup_file.get_as_text()
		latest_backup_file.close()
		if latest_backup_json == save_json:
			do_backup = false

	if do_backup:
		var backup_path = save_path.replace("save_v2", "save_v2_00") + ".bak"
		print(LOG_PREFIX + "Writing save to backup path %s" % backup_path)
		error = dir.copy(_tmp_path, backup_path)
		if error != OK:
			printerr(LOG_PREFIX + "Could not copy save to %s. Error code: %s" % [backup_path, error])
			return

	
	print(LOG_PREFIX + "Writing save to main save path %s" % save_path)
	error = dir.copy(_tmp_path, save_path)
	if error != OK:
		printerr(LOG_PREFIX + "Could not copy save to %s. Error code: %s" % [save_path, error])
		return

	
	error = dir.remove(_tmp_path)
	if error != OK:
		printerr(LOG_PREFIX + "Could not delete %s. Error code: %s" % [_tmp_path, error])
		return

	var backup_paths: = _collect_backup_paths()
	if backup_paths.empty():
		printerr(LOG_PREFIX + "Could not find backup files")
		return

	
	while backup_paths.size() > MAX_BACKUP_FILES:
		var remove_path = backup_paths.pop_back()
		error = dir.remove(remove_path)
		if error != OK:
			printerr(LOG_PREFIX + "Could not remove %s. Error code: %s" % [remove_path, error])
			return
		print(LOG_PREFIX + "Removed old backup file: %s" % remove_path)

	if do_backup:
		
		for i in range(backup_paths.size(), 0, - 1):
			var path = backup_paths[i - 1]
			var new_path = path.replace("save_v2_%02d" % BackupFilenameSorter.parse_backup_number(path), "save_v2_%02d" % (BackupFilenameSorter.parse_backup_number(path) + 1))
			if path == new_path:
				printerr(LOG_PREFIX + "Could not increment backup file number: %s" % path)
				return
			error = dir.rename(path, new_path)
			if error != OK:
				printerr(LOG_PREFIX + "Could not rename %s to %s. Error code: %s" % [path, new_path, error])
				return


func get_save_object() -> Dictionary:
	return {
		"zones_unlocked": zones_unlocked, 
		"characters_unlocked": characters_unlocked, 
		"upgrades_unlocked": upgrades_unlocked, 
		"consumables_unlocked": consumables_unlocked, 
		"weapons_unlocked": weapons_unlocked, 
		"items_unlocked": items_unlocked, 
		"challenges_completed": challenges_completed, 
		"difficulties_unlocked": difficulties_unlocked_serialized, 
		"inactive_mods": inactive_mods, 
		"read_announcements": read_announcements, 
		"current_run_state": serialize_run_state(run_state_deserialized), 
		"settings": settings, 
		"data": data, 
		"version": 2
	}


func serialize_run_state(state: Dictionary) -> Dictionary:
	var result = state.duplicate()

	if not state.has_run_state:
		return result

	if not "current_background" in state:
		result.has_run_state = false
		return result

	result.players_data = []
	for player_data in state.players_data:
		result.players_data.push_back(player_data.serialize())

	if state.current_background != null and state.current_background is BackgroundData:
		result.current_background = state.current_background.name.to_lower()

	result.challenges_completed_this_run = []
	for challenge in state.challenges_completed_this_run:
		result.challenges_completed_this_run.push_back(challenge.my_id)

	result.locked_shop_items = [[], [], [], []]
	for player_index in state.locked_shop_items.size():
		var player_locked_items = state.locked_shop_items[player_index]
		for locked_item in player_locked_items:
			result.locked_shop_items[player_index].push_back([locked_item[0].serialize(), locked_item[1]])

	result.shop_items = [[], [], [], []]
	for player_index in state.shop_items.size():
		var player_shop_items = state.shop_items[player_index]
		for shop_item in player_shop_items:
			result.shop_items[player_index].push_back([shop_item[0].serialize(), shop_item[1]])

	return result



func _collect_backup_paths() -> Array:
	var dir: = Directory.new()
	var paths: = []
	var save_dir_path: = save_path.get_base_dir()
	var error = dir.open(save_dir_path)
	if error != OK:
		printerr(LOG_PREFIX + "Could not open directory %s. Error code: %s" % [save_dir_path, error])
		return []
	error = dir.list_dir_begin()
	if error != OK:
		printerr(LOG_PREFIX + "Could not list directory %s. Error code: %s" % [save_dir_path, error])
		return []
	var next_filename = dir.get_next()
	while next_filename != "":
		if next_filename.begins_with("save_v2") and next_filename.get_extension() == "bak":
			paths.push_back("%s/%s" % [save_dir_path, next_filename])
		next_filename = dir.get_next()
	for path in paths:
		var test_number = BackupFilenameSorter.parse_backup_number(path)
		if test_number < 0:
			printerr(LOG_PREFIX + "Could not parse number from backup filename: %s" % path.get_file())
			return []
	if paths.size() <= 1:
		return paths
	paths.sort_custom(BackupFilenameSorter, "sort_ascending")
	if BackupFilenameSorter.parse_backup_number(paths.front()) > BackupFilenameSorter.parse_backup_number(paths.back()):
		printerr(LOG_PREFIX + "Backup paths not sorted correctly")
		return []
	return paths


class BackupFilenameSorter:
	static func sort_ascending(a: String, b: String) -> bool:
		var number_a = parse_backup_number(a)
		var number_b = parse_backup_number(b)
		return number_a < number_b


	static func parse_backup_number(path: String) -> int:
		var filename: = path.get_file()
		
		var components = filename.get_basename().get_basename().split("_")
		var number: = 0
		if components.size() < 3:
			printerr("Could not parse number from backup filename: %s" % filename)
			return - 1
		number = int(components[2])
		if number == 0 and components[2] != "00":
			printerr("Could not parse number from backup filename: %s" % filename)
			return - 1
		return number
