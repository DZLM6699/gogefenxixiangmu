class_name BurningEffect
extends NullEffect

export (Resource) var burning_data = null


static func get_id() -> String:
	return "weapon_burning"


func get_args(player_index: int) -> Array:
	var first_scaling_stat = Utils.get_first_scaling_stat(burning_data.scaling_stats)
	var is_structure: = false
	if first_scaling_stat == "stat_engineering":
		is_structure = true

	var current_burning_data: BurningData = WeaponService.init_burning_data(burning_data, player_index, is_structure)
	var scaling_stats: String = WeaponService.get_scaling_stats_icon_text(burning_data.scaling_stats)
	return [str(current_burning_data.duration), str(current_burning_data.damage), scaling_stats]


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


func _add_custom_args() -> void :
	var duration_as_neutral: = CustomArg.new()
	duration_as_neutral.arg_sign = Sign.NEUTRAL
	custom_args.append(duration_as_neutral)
