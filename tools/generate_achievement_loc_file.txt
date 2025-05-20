tool 
extends EditorScript

var translation_folders: = ["res://resources/translations/", "res://dlcs/dlc_1/translations/"]
var chal_folders: = ["res://challenges/", "res://dlcs/dlc_1/challenges/"]
var zones: = ["ZONE_CRASH_ZONE", "ZONE_ABYSS"]

var output_file_path = "res://tools/output/loc_file.vdf"
var steam_output_file_path = "res://tools/output/steam_loc_file.vdf"
var epic_output_file_path = "res://tools/output/achievementLocalizations.csv"

var chals: = []
var translations: = {}
var current_locale: = ""

var epic_locale_mapping: = {
	"en": "default", 
	"zh_Hans_CN": "zh-Hans", 
	"zh_Hant_TW": "zh-Hant", 
	"es": "es-ES", 
	"pt": "pt-BR", 
}


func _run() -> void :
	load_translations()
	load_chals()

	var normal_vdf = File.new()
	normal_vdf.open(output_file_path, File.WRITE)
	generate_vdf(normal_vdf, false)

	var steam_vdf = File.new()
	steam_vdf.open(steam_output_file_path, File.WRITE)
	generate_vdf(steam_vdf, true)

	var epic_csv = File.new()
	epic_csv.open(epic_output_file_path, File.WRITE)
	generate_csv(epic_csv)


func load_translations() -> void :
	for dir_path in translation_folders:
		var dir = Directory.new()
		dir.open(dir_path)
		dir.list_dir_begin(true)
		var sorted_file_names: = []
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				file_name = dir.get_next()
				continue

			if file_name.ends_with(".translation"):
				sorted_file_names.append(file_name)
			file_name = dir.get_next()
		sorted_file_names.sort()

		for file in sorted_file_names:
			var translation: Translation = load(dir.get_current_dir() + file)
			var locale: = translation.locale

			if translations.has(locale):
				translations[locale].append(translation)
			else:
				translations[locale] = [translation]

		dir.list_dir_end()


func load_chals() -> void :
	for dir_path in chal_folders:
		var dir = Directory.new()
		dir.open(dir_path)
		dir.list_dir_begin(true)

		var sorted_file_names: = []
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				file_name = dir.get_next()
				continue

			sorted_file_names.append(file_name)
			file_name = dir.get_next()
		sorted_file_names.sort()

		for file in sorted_file_names:
			var cur_file = load(dir_path + file)

			if cur_file.my_id != "" and not cur_file.my_id.begins_with("unlock_difficulty"):
				chals.push_back(cur_file)


func generate_vdf(file, is_steam) -> void :
	file.store_line("\"lang\" {")

	for locale in translations:
		current_locale = locale

		file.store_line("\"" + get_translation("loc_keys") + "\" {")
		file.store_line("\"Tokens\" {")
		for chal in chals:
			if chal.name.begins_with("CHARACTER_") and is_steam:
				handle_steam_char_challenge(chal, file)
				continue

			var chal_name_translated = get_challenge_name(chal)
			var chal_desc_translated = get_challenge_desc(chal, "\\")

			file.store_line("\"%s\" \"%s\"" % [chal.my_id.to_lower(), chal_name_translated])
			file.store_line("\"%s\" \"%s\"" % [chal.my_id.to_lower() + "_desc", chal_desc_translated])

		file.store_line("}\n}")


func generate_csv(file) -> void :
	file.store_line("name,locale,lockedTitle,lockedDescription,unlockedTitle,unlockedDescription,flavorText,lockedIcon,unlockedIcon")
	for chal in chals:
		for locale in translations:
			current_locale = locale
			var chal_name_translated = get_challenge_name(chal)
			var chal_desc_translated = get_challenge_desc(chal, "\"", true)

			var locked_icon = "achievement_locked_" + chal.my_id.to_lower() + ".jpg"
			var unlocked_icon = "achievement_unlocked_" + chal.my_id.to_lower() + ".jpg"
			var csv_line = [chal.my_id.to_lower(), epic_locale_mapping.get(locale, locale), chal_name_translated, chal_desc_translated, chal_name_translated, chal_desc_translated, "", locked_icon, unlocked_icon]
			file.store_line(",".join(csv_line))


func get_challenge_name(chal) -> String:
	var name = get_translation(chal.name.to_upper())
	name = name.replace("{0}", chal.number)
	return name


func get_challenge_desc(chal, escape_char, return_as_string: = false, custom_key: = "") -> String:
	var description = get_translation(chal.description.to_upper())

	if custom_key != "":
		description = get_translation(custom_key.to_upper())

	var desc_args = get_chal_args(chal)
	for arg_index in desc_args.size():
		description = description.replace("{%s}" % arg_index, desc_args[arg_index])
	description = description.replace("\"", "%s\"" % escape_char)

	if return_as_string:
		description = "\"" + description + "\""

	return description


func handle_steam_char_challenge(chal, new_file) -> void :
	for zone in zones:
		var chal_name_translated = get_challenge_name(chal) + " - " + get_translation(zone)
		var chal_desc_translated = get_challenge_desc(chal, "\\", false, "CHAL_CHARACTER_IN_ZONE_DESC")

		chal_desc_translated = chal_desc_translated.replace("{1}", get_translation(zone))

		var id_addition: String
		if zone == "ZONE_ABYSS":
			id_addition = "_abyss"

		new_file.store_line("\"%s\" \"%s\"" % [chal.my_id.to_lower() + id_addition, chal_name_translated])
		new_file.store_line("\"%s\" \"%s\"" % [chal.my_id.to_lower() + id_addition + "_desc", chal_desc_translated])


func get_chal_args(chal) -> Array:
	if chal.name.begins_with("CHARACTER_"):
		return [get_translation(chal.name)]
	else:
		var args = [str(chal.value), get_translation(chal.stat.to_upper())]

		for arg in chal.additional_args:
			args.push_back(get_translation(arg))

		return args


func get_translation(key) -> String:
	if key is int:
		return key as String

	var message: = ""
	for translation in translations[current_locale]:
		message = translation.get_message(key)
		if message != "":
			break

	return message if message != "" else key
