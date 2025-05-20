class_name ChanceStatDamageEffect
extends Effect

export(int) var chance := 3
export(String) var tracking_text


static func get_id() -> String:
	return "chance_stat_damage"


func apply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[custom_key].push_back([key, value, chance, tracking_text])


func unapply(player_index: int) -> void:
	var effects = RunData.get_player_effects(player_index)
	effects[custom_key].erase([key, value, chance, tracking_text])


func get_args(player_index: int) -> Array:

	var dmg = value
	var scaling_text = ""

	if key != "":

		var dmg_from_stat := ((value / 100.0) * Utils.get_stat(key, player_index)) as int
		dmg = WeaponService.apply_damage_bonus(dmg_from_stat, player_index)
		var show_plus_prefix := false
		scaling_text = Utils.get_scaling_stat_icon_text(key, value / 100.0, show_plus_prefix)

	return [str(chance), str(dmg), scaling_text]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.chance = chance
	serialized.tracking_text = tracking_text

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	chance = serialized.chance as int
	tracking_text = serialized.tracking_text
