class_name SynergyPanel
extends PanelContainer

var _plain_text: = ""

onready var _margin_container = $MarginContainer
onready var _synergy_effects = $MarginContainer / VBoxContainer / SynergyEffects
onready var _synergy_name = $MarginContainer / VBoxContainer / SynergyName

var small_font = preload("res://resources/fonts/actual/base/font_very_smallest_text.tres")
var normal_font = preload("res://resources/fonts/actual/base/font_smallest_text.tres")


func set_data(set: SetData, player_index: int) -> void :
	var active_sets = RunData.players_data[player_index].active_sets
	var nb = min(set.set_bonuses.size() + 1, active_sets[set.my_id]) as int if active_sets.has(set.my_id) else 0

	_synergy_name.text = tr(set.name)

	_synergy_effects.bbcode_text = ""

	var new_text = ""
	_plain_text = ""

	for i in set.set_bonuses.size():

		var is_applied = i + 2 == nb
		var col_a = "" if is_applied else "[color=" + Utils.GRAY_COLOR_STR + "]"
		var col_b = "" if is_applied else "[/color]"
		var new_line = ""

		var value_text: = "(" + str(i + 2) + ") "
		new_line += value_text
		_plain_text += value_text

		var set_bonuses = set.set_bonuses[i]
		for j in set_bonuses.size():
			new_line += set_bonuses[j].get_text(player_index, is_applied)
			
			_plain_text += set_bonuses[j].get_text(player_index, false)
			if j != set_bonuses.size() - 1:
				new_line += ", "
				_plain_text += ", "

		if i != set.set_bonuses.size() - 1:
			new_line += "\n"
			_plain_text += "\n"

		new_text += col_a + new_line + col_b

	_synergy_effects.bbcode_text = new_text

	if RunData.is_coop_run:
		if new_text.length() >= 300:
			_synergy_effects.add_font_override("normal_font", small_font)
		else:
			_synergy_effects.add_font_override("normal_font", normal_font)

	_resize_to_text()


func _resize_to_text() -> void :
	var lines = _plain_text.split("\n")
	var font = _synergy_effects.get_font("normal_font")
	var max_width = 0
	for line in lines:
		var text_size = font.get_string_size(line).x
		if text_size > max_width:
			max_width = text_size
	var style: = get_stylebox("panel")
	
	
	var error: = 5
	var margin = _margin_container.get_constant("margin_left") + _margin_container.get_constant("margin_right") + style.get_margin(MARGIN_LEFT) + style.get_margin(MARGIN_RIGHT) + error
	rect_min_size.x = max_width + margin
