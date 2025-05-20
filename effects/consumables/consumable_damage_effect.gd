class_name ConsumableDamageEffect
extends NullEffect


func apply(player_index: int) -> void :
	var damage_value = value + RunData.get_player_effect("consumable_heal", player_index)
	if damage_value > 0:
		RunData.emit_signal("damage_effect", damage_value, player_index, false, false)
