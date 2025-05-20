class_name BuilderTurretUpgradeEffect
extends NullEffect


static func get_id() -> String:
	return "effect_builder_turret_upgrade"


func get_args(player_index: int) -> Array:

	var next_lvl_val = BuilderTurret.get_next_level_requirement(player_index)
	var next_lvl_arg = str(next_lvl_val) if next_lvl_val != Utils.LARGE_NUMBER else "-"

	return [
		str(value), 
		tr(key.to_upper()), 
		next_lvl_arg, 
		tr("STRUCTURE_RANGE"), 
		str(RunData.get_player_effect("structure_range", player_index)), 
		next_lvl_arg
	]
