extends Node


var _control: Control = null
var _player_index: int = - 1


func _process(_delta: float) -> void :
	_control = null
	_player_index = - 1


func emit(control: Control, signalName: String, player_index: int, argument = null) -> void :
	_control = control
	_player_index = player_index
	if argument != null:
		control.emit_signal(signalName, argument)
	else:
		control.emit_signal(signalName)


func get_player_index(expected_control: Control) -> int:
	if not RunData.is_coop_run:
		return 0
	if expected_control != _control:
		return - 1
	return _player_index


func set_expected_control(control: Control, player_index: int) -> void :
	_control = control
	_player_index = player_index
