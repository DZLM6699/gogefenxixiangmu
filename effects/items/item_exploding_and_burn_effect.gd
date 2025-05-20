class_name ItemExplodingAndBurnEffect
extends ItemExplodingEffect

export (Resource) var burning_data = null


static func get_id() -> String:
	return "item_exploding_and_burn"


func get_args(player_index: int) -> Array:
	var args = .get_args(player_index)

	var current_burning_data = WeaponService.init_burning_data(burning_data, player_index)
	var scaling_stats: String = WeaponService.get_scaling_stats_icon_text(current_burning_data.scaling_stats)

	args.append_array([str(current_burning_data.duration), str(current_burning_data.damage), scaling_stats])

	return args


func serialize() -> Dictionary:
	var serialized = .serialize()

	if burning_data != null:
		serialized.burning_data = burning_data.serialize()

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	if serialized.has("burning_data"):
		var data = BurningData.new()
		data.deserialize_and_merge(serialized.burning_data)
		burning_data = data
