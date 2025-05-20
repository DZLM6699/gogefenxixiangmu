class_name EliteContainer
extends Inventory

var elite_elements: = []
var displays_something: = false

func _ready() -> void :
	elite_elements = get_children()

	for element in elite_elements:
		element.hide()

		if element_size != Utils.BASE_INVENTORY_ELEMENT_SIZE:
			element.set_element_size(element_size)
			if element_size.x <= 80 and element_size.y <= 80:
				element.call_deferred("set_font", element_font_small)

	var next_wave = RunData.current_wave + 1
	for i in min(RunData.elites_spawn.size(), elite_elements.size()):
		if RunData.elites_spawn[i][0] < next_wave:
			continue

		
		
		
		if RunData.elites_spawn[i][0] == next_wave:
			var stylebox_color = elite_elements[i].get_stylebox("normal").duplicate()
			ItemService.change_inventory_element_stylebox_from_tier(stylebox_color, Tier.DANGER_0, 0.25)
			elite_elements[i].add_stylebox_override("normal", stylebox_color)

		elite_elements[i].show()
		displays_something = true

		if RunData.elites_spawn[i][1] == EliteType.ELITE:
			elite_elements[i].set_icon(ItemService.get_icon("icon_elite"))
		elif RunData.elites_spawn[i][1] == EliteType.HORDE:
			elite_elements[i].set_icon(ItemService.get_icon("icon_horde"))

		elite_elements[i].set_number(RunData.elites_spawn[i][0])
