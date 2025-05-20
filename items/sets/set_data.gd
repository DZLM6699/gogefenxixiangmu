class_name SetData
extends Resource

export (String) var my_id = ""
export (String) var name = ""
export (Array, Array, Resource) var set_bonuses


func serialize() -> Dictionary:

	var serialized_set_bonuses = []

	for set_bonus in set_bonuses:
		var serialized_set_bonus = []
		for effect in set_bonus:
			serialized_set_bonus.push_back(effect.serialize())
		serialized_set_bonuses.push_back(serialized_set_bonus)

	return {
		"my_id": my_id, 
		"name": name, 
		"set_bonuses": serialized_set_bonuses
	}


func deserialize_and_merge(serialized: Dictionary) -> void :
	my_id = serialized.my_id
	name = serialized.name

	var deserialized_set_bonuses = []

	for serialized_set_bonus in serialized.set_bonuses:
		var deserialized_set_bonus = []

		for serialized_effect in serialized_set_bonus:
			for effect in ItemService.effects:
				if effect.get_id() == serialized_effect.effect_id:
					var instance = effect.new()
					instance.deserialize_and_merge(serialized_effect)
					deserialized_set_bonus.push_back(instance)
					break

		deserialized_set_bonuses.push_back(deserialized_set_bonus)

	set_bonuses = deserialized_set_bonuses
