class_name CoopPlayerLabel
extends Label


export  var player_index: = 0 setget _set_player_index
func _set_player_index(value):
	player_index = value
	add_color_override("font_color", CoopService.get_player_color(player_index))
	text = Text.text("COOP_PLAYER", [str(player_index + 1)])


func _ready():
	_set_player_index(player_index)
