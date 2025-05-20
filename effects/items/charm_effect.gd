class_name CharmEffect
extends DoubleValueEffect


static func get_id() -> String:
	return "charm"


func get_args(player_index: int) -> Array:
	var chance = value
	var scaling_text = ""

	if key != "":
		chance = ((value / 100.0) * Utils.get_stat(key, player_index)) as int
		var show_plus_prefix: = false
		scaling_text = Utils.get_scaling_stat_icon_text(key, value / 100.0, show_plus_prefix)

	return [str(value2), str(chance), scaling_text, str(Utils.CHARM_DURATION)]
