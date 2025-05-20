class_name LevelContainer
extends PanelContainer

signal focused(button, title, value, player_index)
signal unfocused(player_index)
signal hovered(button, title, value, player_index)
signal unhovered(player_index)

export (String) var key = "CURRENT_LEVEL"

var player_index: = 0

onready var _icon = $HBoxContainer / Icon
onready var _label = $HBoxContainer / Label
onready var _value = $HBoxContainer / Value


func _ready() -> void :
	var _levelled_up_error = RunData.connect("levelled_up", self, "update_info")


func disable_focus() -> void :
	focus_mode = FOCUS_NONE
	_label.focus_mode = FOCUS_NONE


func update_info(p_player_index: int) -> void :
	if p_player_index != player_index:
		return
	_label.text = key
	_value.text = str(RunData.get_player_level(player_index))


func _on_StatContainer_focus_entered() -> void :
	_on_focused_or_hovered("focused")


func _on_StatContainer_focus_exited() -> void :
	_on_unfocused_or_unhovered("unfocused")


func _on_Label_mouse_entered() -> void :
	_on_focused_or_hovered("hovered")


func _on_Label_mouse_exited() -> void :
	_on_unfocused_or_unhovered("unhovered")


func _on_Label_focus_entered():
	_on_focused_or_hovered("focused")


func _on_Label_focus_exited():
	_on_unfocused_or_unhovered("unfocused")


func _on_focused_or_hovered(signal_name: String):
	emit_signal(signal_name, self, key, RunData.get_player_level(player_index), player_index)


func _on_unfocused_or_unhovered(signal_name: String):
	emit_signal(signal_name, player_index)
