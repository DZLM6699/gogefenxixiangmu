class_name RerollButton
extends ButtonWithIcon


func init(value: int, player_index: int) -> void :
	set_value(value, RunData.get_player_gold(player_index))
	set_text((tr("REROLL") + " - " + str(value)).to_upper())
