class_name ExtraEnemyEffect
extends Effect

export(Resource) var extra_group_data


static func get_id() -> String:
	return "extra_enemy"


func apply(player_index: int) -> void:

	var effect_items = RunData.get_player_effects(player_index)[key]
	for existing_item in effect_items:
		if existing_item[0] == extra_group_data.resource_path:
			existing_item[1] += value
			return

	effect_items.append([extra_group_data.resource_path, value])


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	var effect_items = effects[key]
	for i in effects[key].size():
		var effect_item = effect_items[i]
		if effect_item[0] == extra_group_data.resource_path:
			effect_item[1] -= value
			if effect_item[1] == 0:
				effect_items.remove(i)
			return


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.extra_group_data = extra_group_data.resource_path
	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)
	extra_group_data = load(serialized.extra_group_data)
