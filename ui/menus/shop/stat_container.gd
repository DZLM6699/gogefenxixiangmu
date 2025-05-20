class_name StatContainer
extends PanelContainer

signal focused(button, title, value, player_index)
signal unfocused(player_index)
signal hovered(button, title, value, player_index)
signal unhovered(player_index)

export (String) var key

onready var _icon = $HBoxContainer / Icon
onready var _label = $HBoxContainer / Label
onready var _value = $HBoxContainer / Value

var color_override: Color = Color.black

func enable_focus() -> void :
	focus_mode = FOCUS_ALL


func disable_focus() -> void :
	focus_mode = FOCUS_NONE


func init_label_focus() -> void :
	_label.focus_mode = FOCUS_NONE
	_label.mouse_filter = MOUSE_FILTER_PASS


func update_player_stat(player_index: int) -> void :
	var stat_value = Utils.get_stat(key.to_lower(), player_index)
	var value_text = str(stat_value as int)

	_icon.texture = ItemService.get_stat_small_icon(key.to_lower())
	_label.text = key

	var dodge_cap = RunData.get_player_effect("dodge_cap", player_index)
	var hp_cap = RunData.get_player_effect("hp_cap", player_index)
	var speed_cap = RunData.get_player_effect("speed_cap", player_index)
	var crit_chance_cap = RunData.get_player_effect("crit_chance_cap", player_index)

	if key.to_lower() == "stat_dodge" and (dodge_cap < stat_value or dodge_cap < 60):
		value_text += " | " + str(dodge_cap as int)
	elif key.to_lower() == "stat_max_hp" and hp_cap < Utils.LARGE_NUMBER:
		value_text += " | " + str(hp_cap as int)
	elif key.to_lower() == "stat_speed" and speed_cap < Utils.LARGE_NUMBER:
		value_text += " | " + str(speed_cap as int)
	elif key.to_lower() == "stat_crit_chance" and crit_chance_cap < Utils.LARGE_NUMBER:
		value_text += " | " + str(crit_chance_cap as int)

	_value.text = value_text

	if color_override != Color.black:
		_label.add_color_override("font_color", color_override)
		_value.add_color_override("font_color", color_override)
	elif stat_value > 0:
		_label.add_color_override("font_color", Color.green)
		_value.add_color_override("font_color", Color.green)
	elif stat_value < 0:
		_label.add_color_override("font_color", Color.red)
		_value.add_color_override("font_color", Color.red)
	else:
		_label.add_color_override("font_color", Color.white)
		_value.add_color_override("font_color", Color.white)


func _on_StatContainer_focus_entered():
	_on_focused_or_hovered("focused", self)


func _on_StatContainer_focus_exited():
	_on_unfocused_or_unhovered("unfocused", self)


func _on_Label_mouse_entered():
	_on_focused_or_hovered("hovered", _label)


func _on_Label_mouse_exited():
	_on_unfocused_or_unhovered("unhovered", _label)


func _on_Label_focus_entered():
	_on_focused_or_hovered("focused", _label)


func _on_Label_focus_exited():
	_on_unfocused_or_unhovered("unfocused", _label)


func _on_focused_or_hovered(signal_name: String, target: Control):
	var player_index = FocusEmulatorSignal.get_player_index(target)
	if player_index < 0:
		push_error("Focus emulator signal not triggered")
		return

	_apply_focus_theme(player_index)
	emit_signal(signal_name, self, key, Utils.get_stat(key.to_lower(), player_index), player_index)


func _on_unfocused_or_unhovered(signal_name: String, target: Control):
	remove_stylebox_override("panel")

	var player_index = FocusEmulatorSignal.get_player_index(target)
	if player_index < 0:
		push_error("Focus emulator signal not triggered")
		return

	emit_signal(signal_name, player_index)


func _apply_focus_theme(player_index: int) -> void :
	var stylebox_override: = get_stylebox("panel").duplicate()

	if RunData.is_coop_run:
		stylebox_override.draw_center = true
		CoopService.change_stylebox_for_player(stylebox_override, player_index)
	else:
		stylebox_override.border_color = _label.get_color("font_color")

	add_stylebox_override("panel", stylebox_override)
