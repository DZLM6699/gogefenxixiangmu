class_name BuilderTurret
extends Turret

const MIN_BASE_WEAPON_CD: float = 8.0
const MAX_BASE_WEAPON_CD: float = 100.0
const STRUCT_RANGE_MAX_SIZE: float = 300.0
const MAX_SIZE = 1.0
const XP_REQUIREMENT_PER_LEVEL = [
	0, 
	STRUCT_RANGE_MAX_SIZE / 10.0, 
	STRUCT_RANGE_MAX_SIZE / 2.0, 
	STRUCT_RANGE_MAX_SIZE
]

signal stat_added(stat_name, value, db_mod, turret_position)

export (Array, Resource) var turret_sprites = []
export (Array, Resource) var upgrade_sounds = []

var main_ref = null

var _current_level = 0

var _structure_range_stats_at_spawn = 0
var _total_bonus_gold = 0
var _nb_materials_per_conversion = 0
var _nb_stats_added_per_conversion = 0
var _stats_every_x_shots: = {}

var _initial_scale = Vector2(0.5, 0.5)
var _initial_position = Vector2.ZERO
var _muzzle_initial_position = Vector2.ZERO
var _initial_collision_scale = Vector2.ONE
var _current_turret_sprite_index = 0

var _current_weapon_ref: WeaponData
var _enemies_killed_this_wave_count = 0


static func get_next_level_requirement(p_player_index: int) -> int:
	var current_xp = RunData.get_player_effect("structure_range", p_player_index)
	var next_level_requirement = XP_REQUIREMENT_PER_LEVEL[1]

	if current_xp >= XP_REQUIREMENT_PER_LEVEL[3]:
		next_level_requirement = Utils.LARGE_NUMBER
	elif current_xp >= XP_REQUIREMENT_PER_LEVEL[2]:
		next_level_requirement = XP_REQUIREMENT_PER_LEVEL[3]
	elif current_xp >= XP_REQUIREMENT_PER_LEVEL[1]:
		next_level_requirement = XP_REQUIREMENT_PER_LEVEL[2]

	return next_level_requirement as int


static func get_best_ranged_weapon(player_index: int) -> WeaponData:
	var player_weapons = RunData.get_player_weapons(player_index)

	var has_ranged_weapon = false

	for weapon in player_weapons:
		if weapon.type == WeaponType.RANGED:
			has_ranged_weapon = true

	if player_weapons.size() == 0 or not has_ranged_weapon:
		return null

	var best_weapon = player_weapons[0]

	for weapon in player_weapons:
		if (
			((weapon.value > best_weapon.value or (weapon.value == best_weapon.value and weapon.stats.damage > best_weapon.stats.damage))
				and weapon.tier >= best_weapon.tier and weapon.type == WeaponType.RANGED)
			or (best_weapon.type == WeaponType.MELEE and weapon.type == WeaponType.RANGED)
		):
			best_weapon = weapon

	return best_weapon


static func apply_scaling(p_stats: WeaponStats, p_level: int) -> WeaponStats:

	var stats_to_mimic = p_stats.duplicate()
	stats_to_mimic.scaling_stats = get_new_scaling_stats(stats_to_mimic.scaling_stats)

	if p_level > 0:
		stats_to_mimic.nb_projectiles += p_level
		stats_to_mimic.projectile_spread += p_level * 0.15 if p_level > 1 else p_level * 0.25

	stats_to_mimic.cooldown = clamp(stats_to_mimic.cooldown, MIN_BASE_WEAPON_CD, MAX_BASE_WEAPON_CD)

	return stats_to_mimic


static func get_new_scaling_stats(scaling_stats: Array) -> Array:
	var new_scaling_stats = [["stat_engineering", 0.0]]

	for scaling_stat in scaling_stats:
		if scaling_stat[0] == "stat_range":
			new_scaling_stats[0][1] += scaling_stat[1] * 5.0
		else:
			new_scaling_stats[0][1] += scaling_stat[1]

	return new_scaling_stats


static func update_effects(base_effects: Array) -> Array:
	var new_effects = []

	for effect in base_effects:
		var new_effect = effect.duplicate()

		if new_effect is BurningEffect:
			var new_burning_data = new_effect.burning_data.duplicate()
			new_burning_data.scaling_stats = get_new_scaling_stats(new_burning_data.scaling_stats)
			new_effect.burning_data = new_burning_data
		elif new_effect is ProjectilesOnHitEffect:
			var new_stats = new_effect.weapon_stats.duplicate()
			new_stats.scaling_stats = get_new_scaling_stats(new_stats.scaling_stats)
			new_effect.weapon_stats = new_stats

		new_effects.push_back(new_effect)

	return new_effects


static func get_level(from_range: int) -> int:
	var level = 0
	if from_range >= XP_REQUIREMENT_PER_LEVEL[3]:
		level = 3
	elif from_range >= XP_REQUIREMENT_PER_LEVEL[2]:
		level = 2
	elif from_range >= XP_REQUIREMENT_PER_LEVEL[1]:
		level = 1

	return level


static func switch_turret_item(old_level: int, new_level: int, p_player_index: int) -> void :
	var player_items = RunData.get_player_items(p_player_index)

	for item in player_items:
		if item.my_id == "item_builder_turret_" + str(old_level):
			RunData.remove_item(item, p_player_index)
			break

	var new_item = ItemService.get_element(ItemService.items, "item_builder_turret_" + str(new_level))

	RunData.add_item(new_item, p_player_index)


func _ready():
	
	max_turret_anim_speed = 5.0
	_initial_position = sprite.position
	_muzzle_initial_position = _muzzle.position


func set_data(data: Resource) -> void :

	var updated_data = data.duplicate()

	_structure_range_stats_at_spawn = RunData.get_player_effect("structure_range", player_index)
	_current_level = get_level(_structure_range_stats_at_spawn)

	set_size(_structure_range_stats_at_spawn)
	sprite.texture = turret_sprites[_current_level]

	var player_weapons = RunData.get_player_weapons(player_index)
	var has_ranged_weapon = false

	for weapon in player_weapons:
		if weapon.type == WeaponType.RANGED:
			has_ranged_weapon = true

	if player_weapons.size() == 0 or not has_ranged_weapon:
		updated_data.stats = apply_scaling(data.stats, _current_level)
		.set_data(updated_data)
		return

	var best_weapon = get_best_ranged_weapon(player_index)
	updated_data.stats = apply_scaling(best_weapon.stats, _current_level)
	updated_data.effects = update_effects(best_weapon.effects)

	_current_weapon_ref = best_weapon

	.set_data(updated_data)

	
	for item in RunData.get_player_items(player_index):
		if "item_builder_turret" in item.my_id:
			RunData.tracked_item_effects[player_index][item.my_id] = 0

	reload_data()


func set_size(from_range: int = 0) -> void :
	var val = (MAX_SIZE - _initial_scale.x) * min(1.0, (from_range / STRUCT_RANGE_MAX_SIZE))
	var scale_sign = sign(sprite.scale.x)
	sprite.scale = Vector2(
		_initial_scale.x + scale_sign * val, 
		_initial_scale.y + val
	)
	sprite.position.y = _initial_position.y - val * 100.0
	_muzzle.position.y = _muzzle_initial_position.y - val * 117.0
	_collision.scale = Vector2(_initial_collision_scale.x + val, _initial_collision_scale.y + val)



func reload_data() -> void :
	var args: = WeaponServiceInitStatsArgs.new()
	args.effects = effects
	stats = WeaponService.init_structure_stats(base_stats, player_index, args)

	_stats_every_x_shots = WeaponService.init_stats_every_x_projectiles(base_stats, player_index, args)
	for x_shot_stats in _stats_every_x_shots.values():
		x_shot_stats.burning_data.from = self

	set_shooting_speed()
	if _range_shape:
		_range_shape.shape.radius = stats.max_range


func shoot() -> void :

	var original_stats: RangedWeaponStats

	for projectile_count in _stats_every_x_shots:
		
		if _nb_shots_taken % projectile_count == 0:
			original_stats = stats
			stats = _stats_every_x_shots[projectile_count]

	.shoot()

	if original_stats:
		stats = original_stats



func die(_args: = DieArgs.new()) -> void :
	pass


func on_bonus_gold_converted(total_bonus_gold: int, nb_materials_per_conversion: int, nb_stats_added_per_conversion: int) -> void :
	var struct_range = RunData.get_player_effect("structure_range", player_index)
	_total_bonus_gold = (total_bonus_gold / RunData.get_player_count()) as int
	_nb_materials_per_conversion = nb_materials_per_conversion
	_nb_stats_added_per_conversion = nb_stats_added_per_conversion
	set_size(struct_range)
	var new_level = get_level(struct_range)

	if new_level != _current_level:
		switch_turret_item(_current_level, new_level, player_index)
		_current_level = new_level
		emit_signal("stat_added", "stat_structure_percent_damage", 1, 0.0, Vector2(global_position.x + 25, global_position.y - 50))
		sprite.texture = turret_sprites[_current_level]
		SoundManager2D.play(Utils.get_rand_element(upgrade_sounds), global_position, 0, 0.1, true)

	if main_ref and main_ref._active_golds.size() <= 0:
		display_stats_added()


func display_stats_added():
	var bonus_gold_already_added = _structure_range_stats_at_spawn * _nb_materials_per_conversion
	var raw_value = (_total_bonus_gold - bonus_gold_already_added) / _nb_materials_per_conversion
	var val_added = floor(raw_value) as int
	if val_added > 0:
		emit_signal("stat_added", "stat_structure_range", val_added, 0.0, global_position)


func _spawn_projectile(position: Vector2) -> Node:
	var proj = ._spawn_projectile(position)

	if effects.size() > 0 and is_instance_valid(proj):
		var _killed_sthing = proj._hitbox.connect("killed_something", self, "on_killed_something", [proj._hitbox])

	return proj


func on_killed_something(_thing_killed: Node, _hitbox: Hitbox) -> void :
	_enemies_killed_this_wave_count += 1
	for effect in effects:
		if effect is GainStatEveryKilledEnemiesEffect and _enemies_killed_this_wave_count % effect.value == 0:
			RunData.add_stat(effect.stat, effect.stat_nb, player_index)
			RunData.emit_stats_updated()
			if _current_weapon_ref:
				_current_weapon_ref.on_tracked_value_updated()
