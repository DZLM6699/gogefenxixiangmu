class_name ConsumableHealingEffect
extends NullEffect


func apply(player_index: int) -> void :
	var consumable_heal_effect = RunData.get_player_effect("consumable_heal", player_index)
	var total_healing: = max(0, value + consumable_heal_effect)

	if total_healing <= 0:
		return

	var duration: int = RunData.get_player_effect("consumable_heal_over_time", player_index)
	if duration > 0:
		RunData.emit_signal("heal_over_time_effect", total_healing, duration, player_index)
	else:
		RunData.emit_signal("healing_effect", total_healing, player_index, "")
