class_name StatCapEffect
extends Effect

export(String) var set_cap_to_current_stat = ""


static func get_id() -> String:
	return "stat_cap"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	if set_cap_to_current_stat != "":
		effects[key] = Utils.get_stat(set_cap_to_current_stat, player_index)
	else:
		effects[key] = value


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[key] = Utils.LARGE_NUMBER


func get_args(player_index: int) -> Array:
	var effect = RunData.get_player_effect(key, player_index)
	return [str(effect if effect < Utils.LARGE_NUMBER else Utils.get_stat(set_cap_to_current_stat, player_index) as int)]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.set_cap_to_current_stat = set_cap_to_current_stat

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	set_cap_to_current_stat = serialized.set_cap_to_current_stat
