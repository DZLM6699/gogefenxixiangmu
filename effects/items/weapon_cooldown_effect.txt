class_name WeaponCooldownEffect
extends Effect


static func get_id() -> String:
	return "weapon_cooldown"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[key].push_back(value)

	effects[key].sort()


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[key].erase(value)


func get_args(_player_index: int) -> Array:
	var seconds = value / 60.0
	return [str(stepify(seconds, 0.01))]
