class_name DoubleValueEffect
extends Effect

enum SumStrategy { SUM_BOTH, SUM_VALUE_1, SUM_VALUE_2 }

export(int) var value2 = 0
export(SumStrategy) var sum_strategy


static func get_id() -> String:
	return "double_value"


func apply(player_index: int) -> void:
	if key == "": return

	var effects = RunData.get_player_effects(player_index)
	if storage_method == StorageMethod.KEY_VALUE:
		effects[custom_key].push_back([key, value, value2])
	elif storage_method == StorageMethod.SUM:
		var applied := false
		for effect in effects[key]:
			match sum_strategy:
				SumStrategy.SUM_BOTH:
					effect[0] += value
					effect[1] += value2
					applied = true
				SumStrategy.SUM_VALUE_1:
					if effect[1] == value2:
						effect[0] += value
						applied = true
				SumStrategy.SUM_VALUE_2:
					if effect[0] == value:
						effect[1] += value2
						applied = true

		if not applied:
			effects[key].push_back([value, value2])
	else:
		effects[key].push_back([value, value2])


func unapply(player_index: int) -> void:
	if key == "": return

	var effects = RunData.get_player_effects(player_index)
	if storage_method == StorageMethod.KEY_VALUE:
		effects[custom_key].erase([key, value, value2])
	elif storage_method == StorageMethod.SUM:
		for effect in effects[key]:
			match sum_strategy:
				SumStrategy.SUM_BOTH:
					effect[0] -= value
					effect[1] -= value2
					if effect[0] == 0 and effect[1] == 0:
						effects[key].erase(effect)
				SumStrategy.SUM_VALUE_1:
					if effect[1] == value2:
						effect[0] -= value
					if effect[0] == 0:
						effects[key].erase(effect)
				SumStrategy.SUM_VALUE_2:
					if effect[0] == value:
						effect[1] -= value2
					if effect[1] == 0:
						effects[key].erase(effect)

			if effect == [0, 0]:
				effects.erase(effect)
	else:
		effects[key].erase([value, value2])


func get_args(_player_index: int) -> Array:
	return [str(value), tr(key.to_upper()), str(value2)]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.value2 = value2
	serialized.sum_strategy = sum_strategy

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	value2 = serialized.value2
	sum_strategy = serialized.get(sum_strategy, SumStrategy.SUM_VALUE_1)
