class_name WeaponData
extends ItemParentData

enum Type { MELEE, RANGED }

export(String) var weapon_id = ""
export(Type) var type := Type.MELEE
export(Array, Resource) var sets
export(PackedScene) var scene = null
export(Resource) var stats = null
export(Resource) var upgrades_into

export(Array, String) var add_to_chars_as_starting = []

var dmg_dealt_last_wave := 0
var tracked_value := 0
var tracked_value_added_this_wave := 0


func get_category() -> int:
	return Category.WEAPON


func get_weapon_stats_text(player_index: int) -> String:
	var args := WeaponServiceInitStatsArgs.new()
	args.sets = sets
	args.effects = effects
	var current_stats
	if type == Type.MELEE:
		current_stats = WeaponService.init_melee_stats(stats, player_index, args)
	else:
		current_stats = WeaponService.init_ranged_stats(stats, player_index, false, args)

	return current_stats.get_text(stats, player_index, effects)


func get_effects_text(player_index: int, with_tracking_text: bool = true) -> String:
	var text = .get_effects_text(player_index)

	if with_tracking_text and tracking_text != "":
		text += "\n[color=#" + Utils.SECONDARY_FONT_COLOR.to_html() + "]" + Text.text(tracking_text.to_upper(), [str(tracked_value)]) + "[/color]"

	return text


func on_tracked_value_updated() -> void:
	tracked_value += 1
	tracked_value_added_this_wave += 1


func get_name_text() -> String:
	var tier_number = ItemService.get_tier_number(tier)
	return tr(name) + (" " + tier_number if tier_number != "" else "")


func serialize() -> Dictionary:

	var serialized = .serialize()

	serialized.weapon_id = weapon_id
	serialized.type = str(type)
	serialized.stats = stats.serialize()
	serialized.dmg_dealt_last_wave = str(dmg_dealt_last_wave)
	serialized.tracked_value = str(tracked_value)
	serialized.tracked_value_added_this_wave = str(tracked_value_added_this_wave)
	serialized.add_to_chars_as_starting = add_to_chars_as_starting

	var serialized_sets = []

	for set in sets:
		serialized_sets.push_back(set.serialize())

	serialized.sets = serialized_sets

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	weapon_id = serialized.weapon_id
	type = serialized.type as int
	dmg_dealt_last_wave = serialized.dmg_dealt_last_wave as int
	tracked_value = serialized.tracked_value as int
	tracked_value_added_this_wave = serialized.tracked_value_added_this_wave as int if "tracked_value_added_this_wave" in serialized else 0
	add_to_chars_as_starting = serialized.add_to_chars_as_starting if "add_to_chars_as_starting" in serialized else []

	var deserialized_sets = []

	for serialized_set in serialized.sets:
		var set = ItemService.get_element(ItemService.sets, serialized_set.my_id).duplicate()
		set.deserialize_and_merge(serialized_set)
		deserialized_sets.push_back(set)

	sets = deserialized_sets

	stats = serialized.stats
	var deserialized_stats = WeaponStats.new()

	if serialized.stats.type == "ranged":
		deserialized_stats = RangedWeaponStats.new()
	elif serialized.stats.type == "melee":
		deserialized_stats = MeleeWeaponStats.new()

	deserialized_stats.deserialize_and_merge(serialized.stats)
	stats = deserialized_stats
