class_name CharacterData
extends ItemData

export (Array, String) var wanted_tags
export (Array, String) var banned_item_groups
export (Array, String) var banned_items
export (Array, Resource) var starting_weapons


func get_category() -> int:
	return Category.CHARACTER
