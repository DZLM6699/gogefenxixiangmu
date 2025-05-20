class_name ItemExplodingWhenBelowHPEffect
extends ItemExplodingEffect

export (int) var hp_threshold = 0


static func get_id() -> String:
	return "item_exploding_when_below_threshold"


func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)
	args.push_back(str(hp_threshold))
	return args


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.hp_threshold = hp_threshold
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)
	hp_threshold = serialized.hp_threshold
