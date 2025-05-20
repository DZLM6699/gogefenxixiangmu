class_name BrotatoolsUtils
extends Node

var editor_interface: EditorInterface = EditorPlugin.new().get_editor_interface()
var console: TextEdit
var clear_console_button: Button
var timer: Timer


func _init(p_console: TextEdit, p_clear_console_button: Button, p_timer: Timer) -> void :
	console = p_console
	clear_console_button = p_clear_console_button
	timer = p_timer

	clear_console_button.connect("pressed", self, "clear")


func find_sprites(content_name: String, path: String, is_weapon: bool = false) -> Dictionary:
	var sprites = {}
	var dir = Directory.new()
	print(path)
	dir.open(path)

	dir.list_dir_begin()

	var file_name = dir.get_next()
	var app_found = false
	var icon_found = false

	var regex: RegEx = RegEx.new()
	regex.compile("\\b" + content_name + "(_app_[0-9])?(_icon)?\\.png\\b(?!~)")

	while file_name != "":
		if regex.search(file_name):
			var is_appearance: bool = "_app_" in file_name if not is_weapon else not ("_icon" in file_name)
			var image: Image = Image.new()
			image.load(path.plus_file(file_name))

			sprites[file_name] = image

			if is_appearance:
				app_found = true
			else:
				icon_found = true

		file_name = dir.get_next()

	if not app_found:
		print_console("No appearance found for %s" % content_name)

	if not icon_found:
		print_console("No icon found for %s" % content_name)

	dir.list_dir_end()

	return sprites


func refresh_filesystem() -> void :
	editor_interface.get_resource_filesystem().scan()

	while editor_interface.get_resource_filesystem().is_scanning():
		timer.start()
		yield(timer, "timeout")


func print_console(msg, clear: bool = false) -> void :

	if console.text.length() > 10000 or clear:
		console.text = ""

	var date_time: Dictionary = Time.get_datetime_dict_from_system()
	var date_prefix: String = "%02d:%02d:%02d - " % [date_time.hour, date_time.minute, date_time.second]

	if console.text == "":
		console.text += date_prefix + str(msg)
	else:
		console.text += "\n" + date_prefix + str(msg)

	console.scroll_vertical = 9999


func print_error(p_name: String, error: int) -> void :
	print_console("Error: " + get_error_text(p_name, error))


func get_error_text(p_name: String, error: int) -> String:
	if error == 32:
		return p_name + " already exists"
	else:
		return str(error)


func clear() -> void :
	console.text = ""
