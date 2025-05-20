class_name CoopShopHint
extends ScrollContainer

export  var text = "Press {0} to ..."
export  var ui_action: = "ui_select" setget _set_ui_action
func _set_ui_action(value: String) -> void :
	ui_action = value
	_update_key_icon()

export  var player_index: = 0 setget _set_player_index
func _set_player_index(value: int) -> void :
	player_index = value
	_update_key_icon()

onready var _hbox_container = $"%HBoxContainer"
onready var _label1 = $"%Label1"
onready var _label2 = $"%Label2"
onready var _key_icon = $"%KeyIcon"

var small_font = preload("res://resources/fonts/actual/base/font_very_smallest_text.tres")
var normal_font = preload("res://resources/fonts/actual/base/font_22.tres")


func _ready() -> void :
	set_text(text)
	_update_key_icon()


func set_text(new_text: String) -> void :
	text = new_text
	var split = tr(text).split("{0}")
	_label1.text = split[0].strip_edges()
	_label2.text = split[1].strip_edges()

	if _label1.get_total_character_count() + _label2.get_total_character_count() >= 30:
		rect_min_size.x = 350
		scroll_horizontal_enabled = true
		_label1.add_font_override("font", small_font)
		_label2.add_font_override("font", small_font)
	else:
		rect_min_size.x = 0
		scroll_horizontal_enabled = false
		_label1.add_font_override("font", normal_font)
		_label2.add_font_override("font", normal_font)


func _update_key_icon() -> void :
	if not is_inside_tree():
		return
	_key_icon.texture = CoopService.get_player_key_texture(ui_action, player_index)
