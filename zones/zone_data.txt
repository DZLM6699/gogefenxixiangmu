class_name ZoneData
extends Resource

export (int, 0, 9999) var my_id = 0
export (bool) var unlocked_by_default = false
export (String) var name = ""
export (Resource) var icon = null
export (int) var width = 32
export (int) var height = 24
export (Array, Resource) var waves_data

export (Array, Resource) var loot_alien_groups
export (Array, Resource) var groups_data_in_all_waves
export (Array, Resource) var horde_groups
export (Array, Resource) var endless_enemy_scenes
export (Array, Resource) var default_backgrounds = []
export (Resource) var fruit_sprite
export (Resource) var item_box_sprite
export (Resource) var legendary_box_sprite
export (Resource) var ui_background


func get_zone_consumable_sprite(consumable: ConsumableData) -> Texture:
	var sprite: Texture

	match consumable.my_id:
		"consumable_fruit":
			sprite = fruit_sprite
		"consumable_item_box":
			sprite = item_box_sprite
		"consumable_legendary_item_box":
			sprite = legendary_box_sprite
		_:
			sprite = consumable.icon

	return sprite
