tool 
class_name BrotatoolsUI
extends Control

const ICON_SIZE: int = 96
const APPEARANCE_SIZE: int = 150
const WEAPON_RESIZE_FACTOR: float = 3.4

export  var item_dir_path: String = "res://items/all/"
export  var set_dir_path: String = "res://items/sets/"
export  var character_dir_path: String = "res://items/characters/"
export  var melee_weapon_dir_path: String = "res://weapons/melee/"
export  var ranged_weapon_dir_path: String = "res://weapons/ranged/"

export  var based_on_melee_weapon_dir_path: String = "res://weapons/melee/"
export  var based_on_ranged_weapon_dir_path: String = "res://weapons/ranged/"


export  var sprites_dir_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP) + "/assets/art/brotato/brotato_presskit"

onready var content_name_input: LineEdit = $"%ContentName"
onready var based_on_input: LineEdit = $"%BasedOn"
onready var content_type_button: OptionButton = $"%ContentTypeButton"
onready var generate_button: Button = $"%GenerateButton"
onready var link_button: Button = $"%LinkButton"

onready var console: TextEdit = $"%Console"
onready var clear_console_button: Button = $"%ClearConsoleButton"
onready var timer: Timer = $Timer

var brotatools_utils: BrotatoolsUtils

var content_types: Array = ["character", "item", "melee_weapon", "ranged_weapon", "set"]


func _ready():
	brotatools_utils = BrotatoolsUtils.new(console, clear_console_button, timer)
	add_child(brotatools_utils)

	content_type_button.clear()

	for i in content_types.size():
		content_type_button.add_item(content_types[i], i)

	content_type_button.select(0)
	_on_ContentTypeButton_item_selected(0)

	generate_button.connect("pressed", self, "generate")
	link_button.connect("pressed", self, "link")


func generate() -> void :
	var type: String = content_types[content_type_button.selected]
	var id_formatted: String = ""
	var content_name: String = content_name_input.text
	var dir_path: String = ""
	var based_on_dir_path: String = ""
	var sprite_cat: String = ""
	var dir = Directory.new()
	var file = File.new()

	brotatools_utils.print_console("Generating %s %s..." % [type, content_name])

	if type == "character":
		dir_path = character_dir_path
		sprite_cat = "characters"
		id_formatted = "character_" + content_name.to_lower()
	elif type == "item":
		dir_path = item_dir_path
		sprite_cat = "items"
		id_formatted = "item_" + content_name.to_lower()
	elif type == "melee_weapon":
		dir_path = melee_weapon_dir_path
		based_on_dir_path = based_on_melee_weapon_dir_path
		sprite_cat = "weapons"
		id_formatted = "weapon_" + content_name.to_lower()
	elif type == "ranged_weapon":
		dir_path = ranged_weapon_dir_path
		based_on_dir_path = based_on_ranged_weapon_dir_path
		sprite_cat = "weapons"
		id_formatted = "weapon_" + content_name.to_lower()
	elif type == "set":
		dir_path = set_dir_path
		id_formatted = "set_" + content_name.to_lower()

	var full_sprite_dir_path: String = sprites_dir_path if sprite_cat == "" else sprites_dir_path + "/" + sprite_cat
	var new_dir_path: String = dir_path + "/" + content_name
	var new_data_path: String = dir_path + "/" + content_name + "/" + content_name + "_data.tres"

	dir.make_dir(new_dir_path)

	if type == "character":
		generate_item(type, CharacterData, dir, new_dir_path, id_formatted, content_name, full_sprite_dir_path, new_data_path)
	elif type == "item":
		generate_item(type, ItemData, dir, new_dir_path, id_formatted, content_name, full_sprite_dir_path, new_data_path, 1)
	elif type == "melee_weapon" or type == "ranged_weapon":
		generate_weapon(type, dir, new_dir_path, based_on_dir_path, id_formatted, content_name, full_sprite_dir_path, dir_path)
	elif type == "set":
		for i in [2, 3, 4, 5, 6]:
			var tier_path = new_dir_path + "/" + str(i)
			dir.make_dir(tier_path)
			for j in [1, 2]:
				var effect = Effect.new()
				_save_resource(effect, tier_path + "/set_%s_effect_%s.tres" % [i, j])

		var data = SetData.new()
		data.my_id = id_formatted
		data.name = id_formatted.replace("set", "WEAPON_CLASS").to_upper()
		_save_resource(data, new_data_path.replace("_data", "_set_data"))

	brotatools_utils.refresh_filesystem()
	brotatools_utils.print_console("Generation done. Don't forget to link the resources!")


func generate_item(type: String, item_class, dir: Directory, path: String, id: String, content_name: String, spr_dir_path: String, new_data_path: String, nb_effects: int = 3) -> void :
	dir.make_dir(path + "/appearances")
	dir.make_dir(path + "/effects")

	var data = item_class.new()
	data.my_id = id
	data.name = id.to_upper()

	var sprites: Dictionary = brotatools_utils.find_sprites(content_name, spr_dir_path)

	for key in sprites:
		var image = sprites[key]

		if "_app_" in key:
			image.resize(APPEARANCE_SIZE, APPEARANCE_SIZE, Image.INTERPOLATE_LANCZOS)
			image.save_png(path + "/appearances/" + key)

			var appearance_data = ItemAppearanceData.new()
			_save_resource(appearance_data, path + "/appearances/" + key.replace(".png", ".tres"))
		elif "_icon" in key or type == "item":
			image.resize(ICON_SIZE, ICON_SIZE, Image.INTERPOLATE_LANCZOS)

			var file_name = key

			if type == "item":
				file_name = file_name.replace(".png", "_icon.png")

			image.save_png(path + "/" + file_name)

	for i in nb_effects:
		var effect = Effect.new()
		_save_resource(effect, path + "/effects/%s_effect_%s.tres" % [content_name, i])

	_save_resource(data, new_data_path)


func generate_weapon(type: String, dir: Directory, path: String, based_on_path: String, id: String, content_name: String, spr_dir_path: String, category_dir_path: String) -> void :

	var sprites: Dictionary = brotatools_utils.find_sprites(content_name, spr_dir_path, true)

	for key in sprites:
		var image = sprites[key]

		if "_icon" in key:
			image.resize(ICON_SIZE, ICON_SIZE, Image.INTERPOLATE_LANCZOS)
			image.save_png(path + "/" + content_name + "_icon.png")
		else:
			image.resize(image.get_width() / WEAPON_RESIZE_FACTOR, image.get_height() / WEAPON_RESIZE_FACTOR, Image.INTERPOLATE_LANCZOS)
			image.save_png(path + "/" + content_name + ".png")

	var based_on = based_on_input.text

	if based_on == "":
		if type == "melee_weapon":
			based_on = "knife"
		else:
			based_on = "pistol"

	var based_on_dir = based_on_path + "/" + based_on
	var based_on_scene: PackedScene = load(based_on_dir + "/" + based_on + ".tscn")
	var new_scene = based_on_scene.duplicate()
	_save_resource(new_scene, path + "/%s.tscn" % content_name)

	var based_on_stats_dict = {}

	dir.open(based_on_dir)
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()

	while file_name:
		if dir.current_is_dir():
			if file_name == "1":
				based_on_stats_dict[file_name] = [
					load("%s/%s/%s_data.tres" % [based_on_dir, file_name, based_on]), 
					load("%s/%s/%s_stats.tres" % [based_on_dir, file_name, based_on])
				]
			else:
				based_on_stats_dict[file_name] = [
					load("%s/%s/%s_%s_data.tres" % [based_on_dir, file_name, based_on, file_name]), 
					load("%s/%s/%s_%s_stats.tres" % [based_on_dir, file_name, based_on, file_name])
				]
		file_name = dir.get_next()

	dir.list_dir_end()

	for i in [1, 2, 3, 4]:
		var tier_path = path + "/" + str(i)
		dir.make_dir(tier_path)
		var data = WeaponData.new()

		var stats = MeleeWeaponStats.new() if type == "melee_weapon" else RangedWeaponStats.new()

		if not based_on_stats_dict.has(str(i)):
			for j in [1, 2, 3, 4]:
				if based_on_stats_dict.has(str(j)):
					stats = based_on_stats_dict[str(j)][1].duplicate()
					data.value = based_on_stats_dict[str(j)][0].value
					break
		else:
			stats = based_on_stats_dict[str(i)][1].duplicate()
			data.value = based_on_stats_dict[str(i)][0].value

		data.weapon_id = id
		data.my_id = id + "_" + str(i)
		data.name = id.to_upper()
		if i == 2: data.tier = WeaponData.Tier.UNCOMMON
		if i == 3: data.tier = WeaponData.Tier.RARE
		if i == 4: data.tier = WeaponData.Tier.LEGENDARY
		if type == "ranged_weapon": data.type = WeaponData.Type.RANGED

		if str(i) == "1":
			_save_resource(data, tier_path + "/%s_data.tres" % content_name)
			_save_resource(stats, tier_path + "/%s_stats.tres" % content_name)
		else:
			_save_resource(data, tier_path + "/%s_%s_data.tres" % [content_name, i])
			_save_resource(stats, tier_path + "/%s_%s_stats.tres" % [content_name, i])



func link() -> void :
	var dir = Directory.new()
	var type: String = content_types[content_type_button.selected]
	var content_name: String = content_name_input.text
	var path: String = ""

	brotatools_utils.print_console("Linking %s %s..." % [type, content_name])

	if type == "character":
		link_item(dir, character_dir_path + "/" + content_name, content_name)
	elif type == "item":
		link_item(dir, item_dir_path + "/" + content_name, content_name)
	elif type == "melee_weapon":
		link_weapon(dir, melee_weapon_dir_path + "/" + content_name, content_name)
	elif type == "ranged_weapon":
		link_weapon(dir, ranged_weapon_dir_path + "/" + content_name, content_name)
	elif type == "set":
		path = set_dir_path + "/" + content_name
		var data = load(path.plus_file(content_name + "_set_data.tres"))
		var effects = [[], [], [], [], []]

		for i in [2, 3, 4, 5, 6]:
			dir.open(path + "/" + str(i))
			dir.list_dir_begin(true, true)
			var file_name = dir.get_next()

			while file_name:
				var effect = load(path + "/" + str(i) + "/" + file_name)

				if effect.key == "":
					effect.key = "stat_max_hp"
					effect.value = 1

				effects[i - 2].push_back(effect)
				_save_resource(effect, path + "/" + str(i) + "/" + file_name)
				file_name = dir.get_next()

			dir.list_dir_end()

		data.set_bonuses = effects
		_save_resource(data, path.plus_file(content_name + "_set_data.tres"))

	brotatools_utils.refresh_filesystem()
	brotatools_utils.print_console("Linking done. Don't forget to add it to ItemService!")


func link_item(dir: Directory, path: String, content_name: String) -> void :
	var data = load(path.plus_file(content_name + "_data.tres"))
	var icon = load(path.plus_file(content_name + "_icon.png"))

	data.icon = icon

	dir.open(path + "/appearances")
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()
	var appearances = []

	while file_name:
		if ".tres" in file_name:
			var appearance_data = load(path + "/appearances/".plus_file(file_name))

			if appearance_data.depth == 1 and appearance_data.position == ItemAppearanceData.Position.OTHER:
				if "_0" in file_name:
					appearance_data.position = ItemAppearanceData.Position.EYES
					appearance_data.depth = 500.0
				elif "_1" in file_name:
					appearance_data.position = ItemAppearanceData.Position.MOUTH
					appearance_data.depth = 250.0

			appearance_data.sprite = load(path + "/appearances/".plus_file(file_name.replace(".tres", ".png")))
			appearances.push_back(appearance_data)
			_save_resource(appearance_data, path + "/appearances/".plus_file(file_name))

		file_name = dir.get_next()

	dir.list_dir_end()

	dir.open(path + "/effects")
	dir.list_dir_begin(true, true)

	var effect_file_name = dir.get_next()
	var effects = []

	while effect_file_name:
		var effect = load(path + "/effects/".plus_file(effect_file_name))
		effects.push_back(effect)
		effect_file_name = dir.get_next()

	dir.list_dir_end()

	data.item_appearances = appearances
	data.effects = effects
	_save_resource(data, path.plus_file(content_name + "_data.tres"))


func link_weapon(dir: Directory, path: String, content_name: String) -> void :

	dir.open(path)
	dir.list_dir_begin(true, true)
	var file_name = dir.get_next()

	var weapon_scene = load(path + "/" + content_name + ".tscn")
	var weapon_icon = load(path + "/" + content_name + "_icon.png")

	while file_name:
		if dir.current_is_dir():
			var data_path = ""
			var stats_path = ""

			if file_name == "1":
				data_path = "%s/%s/%s_data.tres" % [path, file_name, content_name]
				stats_path = "%s/%s/%s_stats.tres" % [path, file_name, content_name]
			else:
				data_path = "%s/%s/%s_%s_data.tres" % [path, file_name, content_name, file_name]
				stats_path = "%s/%s/%s_%s_stats.tres" % [path, file_name, content_name, file_name]

			var data = load(data_path)
			var stats = load(stats_path)

			if file_name != "4":
				var upgrade_into_data_path = "%s/%s/%s_%s_data.tres" % [path, int(file_name) + 1, content_name, int(file_name) + 1]
				var upgrade_into_data = load(upgrade_into_data_path)
				data.upgrades_into = upgrade_into_data

			data.scene = weapon_scene
			data.icon = weapon_icon
			data.stats = stats

			_save_resource(data, data_path)

		file_name = dir.get_next()

	dir.list_dir_end()
	brotatools_utils.print_console("OK! Don't forget to setup %s's scene file!" % content_name)


func _save_resource(resource: Resource, path: String) -> void :
	brotatools_utils.print_console("Saving resource: %s" % path)
	ResourceSaver.save(path, resource)


func _on_ContentTypeButton_item_selected(index: int):
	based_on_input.visible = content_types[content_type_button.selected].ends_with("weapon")
