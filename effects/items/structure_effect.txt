class_name StructureEffect
extends Effect

export(int) var spawn_cooldown = -1
export(PackedScene) var scene = null
export(Resource) var stats = null
export(Array, Resource) var effects
export(int) var spawn_in_center = -1
export(int) var spawn_around_player = -1
export(bool) var can_be_grouped = true

var is_cursed: bool = false


static func get_id() -> String:
	return "structure"


func apply(player_index: int) -> void:
	RunData.get_player_effect("structures", player_index).push_back(self)


func unapply(player_index: int) -> void:
	RunData.get_player_effect("structures", player_index).erase(self)


func get_args(player_index: int) -> Array:
	var spawn_cd = WeaponService.apply_structure_attack_speed_effects(spawn_cooldown, player_index)
	var scaling_stats_names = WeaponService.get_scaling_stats_icon_text(stats.scaling_stats)
	var args := WeaponServiceInitStatsArgs.new()
	args.effects = effects
	var init_stats = WeaponService.init_structure_stats(stats, player_index, args)

	return [str(value), str(spawn_cd), str(init_stats.damage), scaling_stats_names]


func serialize() -> Dictionary:
	var serialized = .serialize()

	serialized.spawn_cooldown = spawn_cooldown
	serialized.scene = scene.resource_path if scene else null
	serialized.stats = stats.serialize()

	serialized.effects = []
	for effect in effects:
		serialized.effects.push_back(effect.serialize())

	serialized.spawn_around_player = spawn_around_player
	serialized.spawn_in_center = spawn_in_center
	serialized.can_be_grouped = can_be_grouped
	serialized.is_cursed = is_cursed

	return serialized


func deserialize_and_merge(serialized: Dictionary) -> void:
	.deserialize_and_merge(serialized)

	spawn_cooldown = serialized.spawn_cooldown as int

	if serialized.scene:
		scene = load(serialized.scene)

	var struct_stats = RangedWeaponStats.new()
	struct_stats.deserialize_and_merge(serialized.stats)
	stats = struct_stats

	effects = []
	for serialized_effect in serialized.effects:
		for effect in ItemService.effects:
			if effect.get_id() == serialized_effect.effect_id:
				var instance = effect.new()
				instance.deserialize_and_merge(serialized_effect)
				effects.push_back(instance)
				break

	if serialized.has("spawn_around_player"):
		spawn_around_player = serialized.spawn_around_player

	if serialized.has("can_be_grouped"):
		can_be_grouped = serialized.can_be_grouped

	if serialized.has("spawn_in_center"):
		spawn_in_center = serialized.spawn_in_center

	if serialized.has("is_cursed"):
		is_cursed = serialized.is_cursed
