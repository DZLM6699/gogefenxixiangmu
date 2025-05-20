tool 
extends EditorScript

var temp = {}
var temp_array = []

class MyCustomSorter:
	static func sort_value(a, b):
		if a.value < b.value:
			return true
		return false

	static func sort_damage(a, b):
		if a.stats.damage < b.stats.damage:
			return true
		return false

func _run() -> void :
	var dir = Directory.new()



	var dir_path = "res://items/all/"





	dir.open(dir_path)
	dir.list_dir_begin(true)

	update(dir, dir_path)










func update(dir: Directory, dir_path: String) -> void :
	var file_name = dir.get_next()
	while file_name != "":

		if dir.current_is_dir():

			var new_dir = Directory.new()
			new_dir.open(dir_path + file_name)
			new_dir.list_dir_begin(true)
			update(new_dir, dir_path + file_name + "/")


		do_stuff_on_item(file_name, dir_path)

		file_name = dir.get_next()


func do_stuff_on_item(file_name: String, dir_path: String) -> void :

	if file_name.ends_with("_data.tres"):
		var cur_file = load(dir_path + file_name)
		if cur_file is ItemParentData:

			temp_array.push_back(cur_file)
			var txt = ""

			for effect in cur_file.effects:
				if effect.text_key.to_upper() == "EFFECT_GAIN_STAT_FOR_EVERY_PERM_STAT" or effect.text_key.to_upper() == "EFFECT_GAIN_STAT_FOR_EVERY_STAT":
					print(cur_file.my_id)


func link_waves_and_groups_and_units(file_name: String, dir_path: String) -> void :
	if file_name.begins_with("wave") and file_name.ends_with(".tres"):
		var cur_file = load(dir_path + file_name)

		var groups = []
		var units = []

		for i in range(1, 5):
			var group = load(dir_path + "/group_" + str(i) + ".tres")
			var unit = load(dir_path + "/unit_" + str(i) + ".tres")

			group.wave_units_data = [unit]
			ResourceSaver.save(dir_path + "/group_" + str(i) + ".tres", group)
			groups.push_back(group)

		cur_file.groups_data = groups
		ResourceSaver.save(dir_path + file_name, cur_file)
