extends Node


const VERSION = "1.1.10.7"
const VERSION_PREFIX = "Brotato v"

var previous_crash_message: = ""
var previous_crashed_mod: = ""

var _mod_unzip_error: = "The mod zip at path"

func _init() -> void :
	
	print(_version_string())

	var log_path: String = ProjectSettings.get_setting("logging/file_logging/log_path")
	log_path = ProjectSettings.globalize_path(log_path)

	var log_directory_path: = log_path.get_base_dir()
	var log_file_paths = get_directory_file_paths(log_directory_path)
	if log_file_paths.empty():
		_print_error("Failed to collect logs in %s" % log_directory_path)
		return

	
	var engine_log_prefix = log_path.get_basename()
	var engine_log_paths: = []
	for log_file_path in log_file_paths:
		if log_file_path != log_path and log_file_path.begins_with(engine_log_prefix):
			var regex = RegEx.new()
			regex.compile("(-?(?:[1-9][0-9]*)?[0-9]{4})-(1[0-2]|0[1-9])-(3[01]|0[1-9]|[12][0-9])T(2[0-3]|[01][0-9])\\.([0-5][0-9])\\.([0-5][0-9])(\\.[0-9]+)?(Z|[+-](?:2[0-3]|[01][0-9])\\.[0-5][0-9])?")
			var result = regex.search(log_file_path)
			if result != null:
				engine_log_paths.push_back(log_file_path)
	if engine_log_paths.empty():
		_print_error("Failed to find engine logs in %s" % log_directory_path)
		return

	engine_log_paths.sort()
	var latest_log_file_path = engine_log_paths.back()
	var file: = File.new()
	if file.open(latest_log_file_path, File.READ) != OK:
		_print_error("Failed to read file %s" % latest_log_file_path)
		return

	var crashed_last_run: = false
	var line0: = ""
	var line1: = ""
	var line: = ""
	while not file.eof_reached():
		line = file.get_line()
		if "ERROR:" in line:
			var next_line: = file.get_line()
			if "mods-unpacked" in line or "mods-unpacked" in next_line or _mod_unzip_error in line:
				if not "Can't open unpacked mods folder" in line:
					crashed_last_run = true
					line0 = line
					line1 = next_line

	if not crashed_last_run:
		return

	previous_crash_message = line0 + "\n" + line1

	if _mod_unzip_error in line0:
		var zip_suffix: = ".zip"
		var zip_index = line0.find(zip_suffix)
		var zip_path: = line0.substr(0, zip_index + zip_suffix.length())
		var zip_name: = zip_path.split("/")[ - 1]
		previous_crashed_mod = zip_name

	else:
		var line_to_process: = line1
		var mod_path_index = line1.find("res://mods-unpacked")
		if mod_path_index == - 1:
			mod_path_index = line0.find("res://mods-unpacked")
			line_to_process = line0
		if mod_path_index != - 1:
			var mod_path = line_to_process.substr(mod_path_index)
			var mod_path_components = mod_path.split("/")
			if mod_path_components.size() >= 4:
				previous_crashed_mod = mod_path_components[3]

	
	var ml_options_path: = "res://addons/mod_loader/options/options.tres"
	var ml_options = load(ml_options_path)
	var profile_paths: = [ml_options.current_options.resource_path]
	for override_option in ml_options.feature_override_options:
		profile_paths.append(ml_options.feature_override_options[override_option].resource_path)

	if crashed_last_run:
		var steam_options: = preload("res://addons/mod_loader/options/profiles/steam.tres")
		steam_options.enable_mods = false
		var epic_options: = preload("res://addons/mod_loader/options/profiles/epic.tres")
		epic_options.enable_mods = false


func get_directory_file_paths(directory_path: String) -> Array:
	var file_paths: = []

	var directory: = Directory.new()
	if directory.open(directory_path) == OK:
		var _e = directory.list_dir_begin()
		var file_name: = directory.get_next()
		while file_name != "":
			if not directory.current_is_dir():
				file_paths.append(directory_path.plus_file(file_name))
			file_name = directory.get_next()
		directory.list_dir_end()

	return file_paths


func _version_string() -> String:
	return VERSION_PREFIX + VERSION


func _print_error(msg: String) -> void :
	push_error("CrashReporter: " + msg)
