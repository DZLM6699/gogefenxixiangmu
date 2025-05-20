class_name UIDimScreen
extends ColorRect

onready var _tween: Tween = $Tween


func dim() -> void :
	var _error_interpolate = _tween.interpolate_property(
		self, 
		"color:a", 
		0, 
		0.5, 
		1, 
		Tween.TRANS_LINEAR
	)

	var _error = _tween.start()


func color_for_player(player_index: int) -> void :
	var color_value: = color.v
	var player_color = CoopService.get_player_color(player_index, color_value)
	player_color.s *= 0.5
	player_color.a = color.a
	color = player_color
