class_name StatPopup
extends BasePopup


export  var description_min_width: = 460

onready var _icon = $MarginContainer / HBoxContainer / Icon
onready var _title = $MarginContainer / HBoxContainer / VBoxContainer / Title
onready var _description = $MarginContainer / HBoxContainer / VBoxContainer / Description


func _ready() -> void :
	_description.rect_min_size.x = description_min_width


func display_stat(button: Node, title: String, value: int, player_index: int) -> void :
	_icon.visible = true
	_description.visible = true

	_icon.texture = ItemService.get_stat_icon(title.to_lower())
	_title.text = title
	_description.text = ItemService.get_stat_description_text(title, value, player_index)

	show()
	set_pos_from(button, self)


func _get_popup_width_factor() -> float:
	return 0.9
