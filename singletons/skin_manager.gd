extends Node

var _skins: = {}
var _available_skin_sets: = []


func _ready() -> void :
	load_skin_pcks()
	add_all_skins()

	for skin_set in _available_skin_sets:
		if not skin_set.my_id in ProgressData.settings.deactivated_skin_sets:
			activate_skins(skin_set)


func get_skin_set(my_id: String) -> SkinSetData:
	for skin_set in _available_skin_sets:
		if skin_set.my_id == my_id:
			return skin_set

	printerr("Skin line %s not found" % my_id)
	return SkinSetData.new()


func load_skin_pcks() -> void :
	var skin_pck_names: = ["GreenSkins.pck"]
	for skin_name in skin_pck_names:
		var file = File.new()
		var skin_path: String = Utils.get_game_dir() + "/" + skin_name
		if file.file_exists(skin_path):
			var success = ProjectSettings.load_resource_pack(skin_path)
			if success:
				DebugService.log_data("Loaded Skin package: " + skin_name)
			else:
				DebugService.log_data("Could not load Skin package: " + skin_name)


func add_all_skins() -> void :
	var dir = Directory.new()
	var dir_path = "res://skins/"

	DebugService.log_data(dir_path + " exists: " + str(dir.dir_exists(dir_path)))

	if not dir.dir_exists(dir_path):
		return

	DebugService.log_data("Open " + dir_path)

	dir.open(dir_path)
	dir.list_dir_begin(true)

	var skin_dirs: Array = []

	var dir_name = dir.get_next()
	while dir_name != "":
		if dir.current_is_dir():
			skin_dirs.push_back(dir_path + dir_name)
		dir_name = dir.get_next()

	for path in skin_dirs:
		dir.open(path)
		dir.list_dir_begin(true)
		var file_name = dir.get_next()
		while file_name != "":
			if file_name == "skin_set_data.tres":
				var skin_data: = load(path + "/" + file_name) as SkinSetData
				_available_skin_sets.push_back(skin_data)

			file_name = dir.get_next()

	dir.list_dir_end()


func is_skin_set_available(set_id: String) -> bool:
	for skin_set in _available_skin_sets:
		if skin_set.my_id == set_id:
			return true

	return false


func activate_skins(skin_set: SkinSetData) -> void :
	ProgressData.settings.deactivated_skin_sets.erase(skin_set.my_id)

	for skin_data in skin_set.skins:
		_handle_skin_data(skin_data)


func deactivate_skins(skin_set: SkinSetData) -> void :
	if not ProgressData.settings.deactivated_skin_sets.has(skin_set.my_id):
		ProgressData.settings.deactivated_skin_sets.append(skin_set.my_id)

	for skin_data in skin_set.skins:
		_handle_skin_data(skin_data, true)


func _handle_skin_data(skin_data: SkinData, remove: = false) -> void :
	var resource_path: String = skin_data.original.resource_path
	if remove:
		_skins.erase(resource_path)
	else:
		_skins[resource_path] = skin_data.skin

	for appearance_skin_data in skin_data.appearances:
		_handle_skin_data(appearance_skin_data, remove)


func get_skin(original_texture: Texture) -> Texture:
	if _skins.has(original_texture.resource_path):
		return _skins[original_texture.resource_path]

	return original_texture
