class_name ItemPanelUI
extends PanelContainer

signal mouse_hovered_category
signal mouse_exited_category


var player_color_index: = - 1 setget _set_player_color_index
func _set_player_color_index(v: int) -> void :
	player_color_index = v
	_update_stylebox()

var selected: = false setget _set_selected
func _set_selected(v: bool) -> void :
	selected = v
	if selected:
		_checkmark.show()
		_item_description.modulate.a = 0.5
	else:
		_checkmark.hide()
		_item_description.modulate.a = 1.0

var item_data: ItemParentData

onready var _checkmark = $"Checkmark"
onready var _item_description = $"%ItemDescription"


func set_data(p_item_data: ItemParentData, player_index: int) -> void :
	item_data = p_item_data
	_item_description.set_item(p_item_data, player_index)
	_update_stylebox()


func set_custom_data(name: String, icon: Resource) -> void :
	item_data = null
	_item_description.set_custom_data(name, icon)
	_update_stylebox()


func _on_ItemDescription_mouse_hovered_category() -> void :
	emit_signal("mouse_hovered_category")


func _on_ItemDescription_mouse_exited_category() -> void :
	emit_signal("mouse_exited_category")


func _update_stylebox() -> void :
	remove_stylebox_override("panel")
	var stylebox = get_stylebox("panel").duplicate()
	if item_data != null:
		ItemService.change_panel_stylebox_from_tier(stylebox, item_data.tier)
	if player_color_index >= 0:
		CoopService.change_stylebox_for_player(stylebox, player_color_index)
	add_stylebox_override("panel", stylebox)
