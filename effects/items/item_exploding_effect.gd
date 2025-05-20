class_name ItemExplodingEffect
extends ExplodingEffect

export (Resource) var stats
export (String) var tracking_key
export  var scale_with_missing_health: = false


static func get_id() -> String:
	return "item_exploding"


func apply(player_index: int) -> void :
	var effects = RunData.get_player_effects(player_index)
	effects[key].push_back(self)


func unapply(player_index: int) -> void :
	var effects = RunData.get_player_effects(player_index)
	effects[key].erase(self)


func get_args(player_index: int) -> Array:
	var args: = WeaponServiceInitStatsArgs.new()
	args.effects = [ExplodingEffect.new()]
	var current_stats = WeaponService.init_base_stats(stats, player_index, args)
	var total_damage: int = current_stats.damage + get_additional_scaling_damage(player_index)
	var scaling_text = WeaponService.get_scaling_stats_icon_text(stats.scaling_stats)

	return [str(chance * 100), str(total_damage), scaling_text, str(value)]


func get_additional_scaling_damage(player_index) -> int:
	var damage: = 0
	if scale_with_missing_health:
		var missing_health = RunData.get_player_missing_health(player_index)
		damage -= stats.damage
		damage += value * missing_health
	return damage


func serialize() -> Dictionary:
	var serialized = .serialize()
	serialized.scale_with_missing_health = scale_with_missing_health
	serialized.tracking_key = tracking_key

	if stats != null:
		serialized.stats = stats.serialize()

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void :
	.deserialize_and_merge(serialized)

	scale_with_missing_health = serialized.get("scale_with_missing_health", false)
	tracking_key = serialized.get("tracking_key", "")

	if serialized.has("stats"):
		if serialized.stats.has("type"):
			var exploding_stats = WeaponStats.new()

			if serialized.stats.type == "ranged":
				exploding_stats = RangedWeaponStats.new()
			elif serialized.stats.type == "melee":
				exploding_stats = MeleeWeaponStats.new()

			exploding_stats.deserialize_and_merge(serialized.stats)
			stats = exploding_stats
