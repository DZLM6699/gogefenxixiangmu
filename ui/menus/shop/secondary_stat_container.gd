class_name SecondaryStatContainer
extends PanelContainer

signal focused(button, title, value, player_index)
signal unfocused(player_index)

export (String) var key
export (String) var custom_text_key
export (bool) var reverse = false

onready var _label = $HBoxContainer / Label
onready var _value = $HBoxContainer / Value


func disable_focus() -> void :
	focus_mode = FOCUS_NONE
	_label.focus_mode = FOCUS_NONE


func update_player_stat(player_index: int) -> void :
	var stat_value = Utils.get_stat(key.to_lower(), player_index)

	
	if key.to_lower() == "structure_attack_speed":
		stat_value = WeaponService.get_structure_attack_speed(player_index)

	var value_text = str(stat_value as int)

	_label.text = custom_text_key if custom_text_key != "" else key
	_value.text = value_text

	if (stat_value > 0 and not reverse) or (stat_value < 0 and reverse):
		_label.modulate = Color.green
		_value.modulate = Color.green
	elif (stat_value < 0 and not reverse) or (stat_value > 0 and reverse):
		_label.modulate = Color.red
		_value.modulate = Color.red
	else:
		_label.modulate = Color.white
		_value.modulate = Color.white


func _on_SecondaryStatContainer_focus_entered():
	var player_index = FocusEmulatorSignal.get_player_index(self)
	if player_index < 0:
		push_error("Focus emulator signal not triggered")
		return
	var text_key = custom_text_key if custom_text_key != "" else key
	emit_signal("focused", self, text_key, Utils.get_stat(key.to_lower(), player_index), player_index)


func _on_SecondaryStatContainer_focus_exited():
	var player_index = FocusEmulatorSignal.get_player_index(self)
	if player_index < 0:
		push_error("Focus emulator signal not triggered")
		return
	emit_signal("unfocused", player_index)
