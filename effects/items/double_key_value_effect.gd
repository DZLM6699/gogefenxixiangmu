class_name DoubleKeyValueEffect
extends Effect

export var key2 := ""
export var value2 := 0


static func get_id() -> String:
	return "double_key_value"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effect(custom_key, player_index)
	for existing_effect in effects:
		if existing_effect[0] == key and existing_effect[2] == key2 and existing_effect[3] == value2:
			existing_effect[1] += value
			return
	effects.push_back([key, value, key2, value2])


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effect(custom_key, player_index)
	for i in effects.size():
		var existing_effect = effects[i]
		if existing_effect[0] == key and existing_effect[2] == key2 and existing_effect[3] == value2:
			existing_effect[1] -= value
			if existing_effect[1] == 0:
				effects.remove(i)
			return


func get_args(_player_index: int) -> Array:
	return [str(value), tr(key.to_upper()), str(value2), tr(key2.to_upper())]


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.key2 = key2
	serialized.value2 = value2
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	key2 = serialized.key2
	value2 = serialized.value2
