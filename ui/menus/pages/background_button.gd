class_name BackgroundButton
extends OptionButton


func _ready() -> void :
	on_backgrounds_updated()


func _on_BackgroundButton_item_selected(index: int) -> void :
	if index != 0:
		icon = ItemService.backgrounds[index - 1].icon


func on_backgrounds_updated() -> void :
	clear()
	add_item("RANDOM")
	for bg in ItemService.backgrounds:
		add_item(bg.name)
