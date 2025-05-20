class_name LockedPanel
extends PanelContainer

var player_color_index: = - 1 setget _set_player_color_index
func _set_player_color_index(v: int) -> void :
	player_color_index = v
	_update_stylebox()

onready var _description = $MarginContainer / VBoxContainer / Description


func set_element(element: ItemParentData, type: int) -> void :
	var challenge = ChallengeService.find_challenge_from_reward(type, element)

	if challenge == null:
		_description.text = "NOT_SET"
		return

	_description.text = challenge.get_description_text()


func _update_stylebox() -> void :
	remove_stylebox_override("panel")
	if player_color_index < 0:
		return
	var stylebox = get_stylebox("panel").duplicate()
	CoopService.change_stylebox_for_player(stylebox, player_color_index)
	add_stylebox_override("panel", stylebox)
