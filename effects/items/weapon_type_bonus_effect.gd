class_name WeaponTypeBonusEffect
extends Effect

enum Type { MELEE, RANGED }

export(Type) var weapon_type
export(String) var stat_displayed_name
export(String) var stat_name


static func get_id() -> String:
	return "weapon_type_bonus"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects["weapon_type_bonus"].push_back([weapon_type, stat_name, value])


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects["weapon_type_bonus"].erase([weapon_type, stat_name, value])


func get_args(_player_index: int) -> Array:
	return [str(value), tr(stat_displayed_name.to_upper())]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.weapon_type = weapon_type
	serialized.stat_displayed_name = stat_displayed_name
	serialized.stat_name = stat_name

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	weapon_type = serialized.weapon_type if "weapon_type" in serialized else Type.MELEE
	stat_displayed_name = serialized.stat_displayed_name if "stat_displayed_name" in serialized else ""
	stat_name = serialized.stat_name if "stat_name" in serialized else ""
