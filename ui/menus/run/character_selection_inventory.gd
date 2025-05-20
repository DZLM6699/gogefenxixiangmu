class_name CharacterSelectionInventory
extends Inventory


func _ready():
	if ProgressData.is_dlc_available_and_active("abyssal_terrors"):
		element_size = Vector2(75, 75)
		columns = 21


func update_elements_color(current_zone_id: int) -> void :
	for element in get_children():
		if not element.item:
			continue
		var new_item = element.item.duplicate()
		var diff_info = ProgressData.get_character_difficulty_info(new_item.my_id, current_zone_id)
		if diff_info.max_difficulty_beaten.difficulty_value < 0:
			new_item.tier = Tier.COMMON
		if diff_info.max_difficulty_beaten.difficulty_value == 0:
			new_item.tier = Tier.DANGER_0
		elif diff_info.max_difficulty_beaten.difficulty_value > 0:
			new_item.tier = diff_info.max_difficulty_beaten.difficulty_value
		element.item = new_item
		element.update_background_color()
