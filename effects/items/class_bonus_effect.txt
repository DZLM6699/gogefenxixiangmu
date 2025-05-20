class_name ClassBonusEffect
extends Effect

export(String) var set_id = ""
export(String) var stat_displayed_name = "stat_damage"
export(String) var stat_name = "damage"


static func get_id() -> String:
	return "class_bonus"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects["weapon_class_bonus"].push_back([set_id, stat_name, value])


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects["weapon_class_bonus"].erase([set_id, stat_name, value])


func get_args(_player_index: int) -> Array:
	var set = ItemService.get_set(set_id)
	return [str(value), tr(stat_displayed_name.to_upper()), tr(set.name)]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.set_id = set_id
	serialized.stat_displayed_name = stat_displayed_name
	serialized.stat_name = stat_name

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	set_id = serialized.set_id if "set_id" in serialized else ""
	stat_displayed_name = serialized.stat_displayed_name if "stat_displayed_name" in serialized else "stat_damage"
	stat_name = serialized.stat_name if "stat_name" in serialized else "damage"
