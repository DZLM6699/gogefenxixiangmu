class_name PlayerGearContainer
extends Container


var player_index: = 0

onready var weapons_container: InventoryContainer = $WeaponsContainer
onready var items_container: InventoryContainer = $ItemsContainer

var _default_weapon_columns: = [3, 10, 8, 6]

var _total_columns: = 12
var _max_weapon_columns: = 6
var _min_item_columns: = 6


func _ready() -> void :
	
	var _error = weapons_container.connect("elements_changed", self, "_on_weapons_changed")


func set_items_data(items: Array) -> void :
	items_container.set_data("ITEMS", Category.ITEM, items, true, true)


func set_weapons_data(weapons: Array) -> void :
	weapons_container.set_data("", Category.WEAPON, weapons)
	
	_on_weapons_changed()


func _on_weapons_changed() -> void :
	var weapon_count = weapons_container.get_element_count()
	var weapon_slot = RunData.get_player_effect("weapon_slot", player_index)
	var text: = tr("WEAPONS") + " (" + str(weapon_count) + "/" + str(weapon_slot) + ")"
	weapons_container.set_label(text)

	_resize_weapons_container(weapon_count)


func _resize_weapons_container(nb_of_weapons: int) -> void :
	if RunData.is_coop_run:
		if nb_of_weapons > _default_weapon_columns[RunData.get_player_count() - 1]:
			weapons_container.reserve_row_count = 2
		else:
			weapons_container.reserve_row_count = 1

	else:
		var weapon_columns: = max(_default_weapon_columns[0], ceil(float(nb_of_weapons) / weapons_container.reserve_row_count)) as int
		weapon_columns = min(_max_weapon_columns, weapon_columns) as int
		weapons_container.reserve_column_count = weapon_columns

		var item_columns: = max(_min_item_columns, _total_columns - weapon_columns) as int
		items_container.reserve_column_count = item_columns
