class_name ItemParentData
extends Resource

enum Tier { COMMON, UNCOMMON, RARE, LEGENDARY, DANGER_4, DANGER_5 }

export(String) var my_id = ""
export(bool) var unlocked_by_default = false
export(Resource) var icon
export(String) var name = ""
export(Tier) var tier = Tier.COMMON
export(int) var value = 1
export(Array, Resource) var effects
export(String) var tracking_text = ""

export(bool) var is_lockable := true

export(bool) var is_cursed := false
export(float) var curse_factor: float = 0.0

var is_locked := false


func get_icon() -> Resource:
	return SkinManager.get_skin(icon)


func get_category() -> int:
	return -1


func get_effects_text(player_index: int) -> String:
	var text = ""

	for i in effects.size():
		var effect_text = effects[i].get_text(player_index)

		text += effect_text

		if effect_text != "" and i < effects.size() - 1:
			 text += "\n"

	if player_index != RunData.DUMMY_PLAYER_INDEX and RunData.tracked_item_effects[player_index].has(my_id) and tracking_text != "[EMPTY]":
		if RunData.tracked_item_effects[player_index][my_id] is Array:
			for i in RunData.tracked_item_effects[player_index][my_id].size():
				var tracked_count = RunData.tracked_item_effects[player_index][my_id][i]

				var tracking_text_to_use = tracking_text

				if my_id == "item_bone_dice" and i == 1:
					tracking_text_to_use = "stats_lost"
				elif my_id == "character_hiker" and i == 0:
					tracking_text_to_use = "materials_gained"

				text += "\n[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(tracking_text_to_use.to_upper(), [Text.get_formatted_number(tracked_count)]) + "[/color]"
		else:
			var after = ""
			if my_id == "item_fish_hook":
				after = "%"

			var append_text = "\n[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(tracking_text.to_upper(), [Text.get_formatted_number(RunData.tracked_item_effects[player_index][my_id])]) + after + "[/color]"

			if my_id == "item_fish_hook" and RunData.tracked_item_effects[player_index][my_id] == 0:
				append_text = ""

			text += append_text

	return text


func get_name_text() -> String:
	return tr(name)


func serialize() -> Dictionary:

	var serialized_effects = []

	for effect in effects:
		serialized_effects.push_back(effect.serialize())

	return {
		"my_id": my_id,
		"name": name,
		"tier": str(tier),
		"value": str(value),
		"effects": serialized_effects,
		"tracking_text": tracking_text,
		"is_locked": is_locked,
		"is_cursed": is_cursed,
		"curse_factor": curse_factor,
		"is_lockable": is_lockable
	}


func deserialize_and_merge(serialized: Dictionary) -> void:
	my_id = serialized.my_id
	name = serialized.name
	tier = serialized.tier as int
	value = serialized.value as int
	tracking_text = serialized.tracking_text
	is_locked = serialized.is_locked
	is_cursed = serialized.is_cursed
	is_lockable = serialized.is_lockable if "is_lockable" in serialized else true
	curse_factor = serialized.curse_factor as float if "curse_factor" in serialized else 0.0

	var deserialized_effects = []

	for serialized_effect in serialized.effects:
		for effect in ItemService.effects:
			if effect.get_id() == serialized_effect.effect_id:
				var instance = effect.new()
				instance.deserialize_and_merge(serialized_effect)
				deserialized_effects.push_back(instance)
				break

	effects = deserialized_effects
