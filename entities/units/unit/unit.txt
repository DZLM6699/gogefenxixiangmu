class_name Unit
extends Entity

signal speed_removed(enemy)
signal health_updated(unit, current_health, max_health)
signal took_damage(unit, value, knockback_direction, is_crit, is_dodge, is_protected, armor_did_something, args, hit_type)

export (Array, Resource) var crit_sounds
export (Array, Resource) var hurt_sounds
export (Array, Resource) var burn_sounds
export (Array, Resource) var dodge_sounds
export (Resource) var stats
export (bool) var mirror_sprite_with_movement = true
export (Resource) var flash_mat


const THRESHOLD_DIST_TO_LOWER_DMG_ON_PULL: = 200
const MIN_DEATH_KNOCKBACK_AMOUNT: = 15.0

var current_stats: LiveStats = LiveStats.new()
var max_stats: LiveStats = LiveStats.new()

var can_drop_loot: = true
var bonus_speed: int = 0
var knockback_vector: = Vector2.ZERO

var _speed_percent_modifier: = 0
var _speed_rand_value: = 0
var _hitbox_damage_modifier: = 0

var players_ref: = []
var _entity_spawner_ref: EntitySpawner
var _can_move: bool = true
var _current_movement: = Vector2.ZERO
var _move_locked: = false
var decaying_bonus_speed: = 0.0
var _non_flash_material: ShaderMaterial = null

var burning_particles = null
var _burning: BurningData
var _burning_player_index: int = - 1
var _is_burning: bool = false

var _current_movement_behavior: MovementBehavior

onready var effect_behaviors: = $EffectBehaviors
onready var _flash_timer: = $FlashTimer as Timer
onready var _hurtbox: = $Hurtbox as Area2D
onready var _movement_behavior: = $MovementBehavior
onready var _burning_timer: = $BurningTimer as Timer
onready var _burning_particles: = $BurningParticles


func _ready() -> void :
	_current_movement_behavior = _movement_behavior


func init(zone_min_pos: Vector2, zone_max_pos: Vector2, p_players_ref: Array = [], entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos)

	var burning_cooldown_reduction = RunData.sum_all_player_effects("burning_cooldown_reduction") / 100.0
	var burning_cooldown_increase = RunData.sum_all_player_effects("burning_cooldown_increase") / 100.0
	var burning_cooldown_diff = burning_cooldown_increase - burning_cooldown_reduction

	_burning_timer.wait_time = max(0.1, _burning_timer.wait_time * (1.0 + burning_cooldown_diff))

	players_ref = p_players_ref
	_entity_spawner_ref = entity_spawner_ref

	_movement_behavior.init(self)
	_speed_rand_value = rand_range( - stats.speed_randomization * RunData.current_run_accessibility_settings.speed, stats.speed_randomization * RunData.current_run_accessibility_settings.speed) as int


func respawn() -> void :
	.respawn()
	knockback_vector = Vector2.ZERO
	_can_move = true
	can_drop_loot = true
	bonus_speed = 0
	_hurtbox.enable()
	_current_movement_behavior = _movement_behavior
	_collision.set_deferred("disabled", false)
	_speed_rand_value = rand_range( - stats.speed_randomization * RunData.current_run_accessibility_settings.speed, stats.speed_randomization * RunData.current_run_accessibility_settings.speed) as int


func init_current_stats() -> void :
	max_stats.copy_stats(stats)
	current_stats.copy(max_stats)
	reset_health_stat(0)
	reset_damage_stat(0)
	reset_speed_stat(0)
	reset_armor_stat(0)


func reset_health_stat(percent_modifier: int = 0) -> void :
	current_stats.health = EntityService.get_final_enemy_health(stats.get_base_health(RunData.current_wave), percent_modifier)
	max_stats.health = current_stats.health


func reset_damage_stat(percent_modifier: int = 0) -> void :
	current_stats.damage = EntityService.get_final_enemy_damage(stats.get_base_damage(RunData.current_wave), percent_modifier)
	max_stats.damage = current_stats.damage


func reset_speed_stat(percent_modifier: int = 0) -> void :
	_speed_percent_modifier = percent_modifier

	var effect_modifiers: = 1.0
	for player_index in RunData.get_player_count():
		effect_modifiers *= 1.0 + get_speed_effect_mods(player_index) / 100.0

	current_stats.speed = EntityService.get_final_enemy_speed(stats.speed + _speed_rand_value, effect_modifiers, percent_modifier)
	max_stats.speed = current_stats.speed


func get_speed_effect_mods(player_index: int) -> int:
	var enemy_speed = Utils.get_stat("enemy_speed", player_index)
	var speed_from_burn = RunData.get_player_effect("burning_enemy_speed", player_index) if _is_burning else 0
	return enemy_speed + speed_from_burn


func reset_armor_stat(percent_modifier: = 0) -> void :
	var base_armor = (stats.armor + (stats.armor_increase_each_wave * (RunData.current_wave - 1))) * (1.0 + percent_modifier / 100.0)
	current_stats.armor = round(base_armor) as int
	max_stats.armor = current_stats.armor


var _integrate_forces_velocity: Vector2
func _physics_process(delta: float) -> void :
	_current_movement = get_movement() if _can_move else Vector2.ZERO
	update_animation(_current_movement)

	var velocity = get_next_velocity()
	_integrate_forces_velocity = velocity
	if mode == MODE_KINEMATIC:
		
		var infinite_inertia = true
		var margin = 0.08
		var delta_position: = Vector2.ZERO
		var result = Physics2DTestMotionResult.new()
		var is_colliding = test_motion(velocity * delta, infinite_inertia, margin, result)
		global_position += result.motion
		delta_position += result.motion
		if is_colliding:
			var slide_velocity = velocity.slide(result.collision_normal)
			var _is_colliding = test_motion(slide_velocity * delta, infinite_inertia, margin, result)
			global_position += result.motion
			delta_position += result.motion
		_on_moved(delta_position)

	if decaying_bonus_speed > 0:
		decaying_bonus_speed = max(decaying_bonus_speed - Utils.physics_one(delta), 0.0)
	elif decaying_bonus_speed < 0:
		decaying_bonus_speed = min(decaying_bonus_speed + Utils.physics_one(delta) * 5, 0.0)


func _integrate_forces(state: Physics2DDirectBodyState) -> void :
	if sleeping:
		return

	if mode == MODE_KINEMATIC:
		
		state.transform.origin = global_position
		return
	
	
	var target_position = _current_movement_behavior.get_target_position()
	
	if (
		target_position == null
		or _integrate_forces_velocity == Vector2.ZERO
		or not _can_move
		or _move_locked
	):
		state.linear_velocity = _integrate_forces_velocity
		return
	var origin = state.transform.origin
	var origin_to_next_origin = _integrate_forces_velocity * state.step
	var origin_to_target = target_position - origin
	
	if origin_to_target.length_squared() > origin_to_next_origin.length_squared():
		state.linear_velocity = _integrate_forces_velocity
		return
	
	
	var projected_target = origin + origin_to_target.project(origin_to_next_origin)
	
	
	
	var next_origin = origin + origin_to_next_origin
	if (next_origin - projected_target).dot(origin - projected_target) <= 0:
		state.linear_velocity = Vector2.ZERO
		state.transform.origin = target_position
		return
	state.linear_velocity = _integrate_forces_velocity


func get_movement() -> Vector2:
	return _current_movement_behavior.get_movement() if not _move_locked else _current_movement


func get_move_input() -> Vector2:
	return _current_movement.normalized() * get_move_speed()


func get_move_speed() -> float:
	return max(0.0, (current_stats.speed + bonus_speed + decaying_bonus_speed))


func get_next_velocity() -> Vector2:
	var move_input: = get_move_input()
	var velocity: = move_input + get_next_knockback_value()
	return velocity


func get_next_knockback_value() -> Vector2:
	var value = get_knockback_value()
	knockback_vector = knockback_vector.linear_interpolate(Vector2.ZERO, 0.1)
	return value


func get_knockback_value() -> Vector2:
	return (knockback_vector * (100 - (stats.knockback_resistance * 100)))


func get_direction() -> int:
	return sprite.scale.x as int


func get_current_target() -> Vector2:
	return _current_movement_behavior.get_target_position()


func update_animation(movement: Vector2) -> void :
	if mirror_sprite_with_movement:
		if movement.x > 0:
			sprite.scale.x = abs(sprite.scale.x)
		elif movement.x < 0:
			sprite.scale.x = - abs(sprite.scale.x)


func _get_movement() -> Vector2:
	return Vector2.ZERO


func take_damage(value: int, args: TakeDamageArgs) -> Array:
	if dead:
		return [0, 0, false]

	var hitbox = args.hitbox
	var from_player_index = args.from_player_index

	var crit_damage = 0.0
	var crit_chance = 0.0
	var knockback_direction = Vector2.ZERO
	var knockback_amount = 0.0
	var knockback_piercing = 0.0
	var dmg_taken = 0

	if hitbox != null:
		crit_damage = hitbox.crit_damage
		crit_chance = hitbox.crit_chance
		knockback_direction = hitbox.knockback_direction
		if from_player_index < players_ref.size() and is_instance_valid(players_ref[from_player_index]):
			knockback_direction = 0.2 * knockback_direction + 0.8 * players_ref[from_player_index].global_position.direction_to(global_position)
		knockback_amount = hitbox.knockback_amount
		knockback_piercing = hitbox.knockback_piercing

	var is_crit = true if Utils.get_chance_success(crit_chance) else false
	if hitbox:
		for effect in hitbox.effects:
			if effect.key == "crit_on_hitting_burning_target" and _is_burning:
				is_crit = true

	var dmg_value = value
	var sound = Utils.get_rand_element(hurt_sounds)
	if is_crit:
		dmg_value = round(value * crit_damage) as int
		sound = Utils.get_rand_element(crit_sounds)

	var dmg_value_result = get_damage_value(dmg_value, from_player_index, args.armor_applied, args.dodgeable, is_crit, hitbox, args.is_burning)
	var full_dmg_value = dmg_value_result.value
	dmg_taken = clamp(full_dmg_value, 0, current_stats.health)
	current_stats.health = max(0.0, current_stats.health - full_dmg_value) as int

	if is_crit and hitbox:
		hitbox.critically_hit_something(self, dmg_taken)

	if full_dmg_value > 0:
		flash()

	if args.custom_sound:
		sound = args.custom_sound

	SoundManager2D.play(sound, global_position, 0, 0.2)

	var final_knockback_amount = knockback_amount

	
	if final_knockback_amount < 0 and hitbox != null:
		final_knockback_amount = get_knockback_amount_based_on_distance_to_attacker(final_knockback_amount, hitbox, players_ref[from_player_index])
	elif knockback_piercing > 0:
		final_knockback_amount = get_increased_piercing_knockback_amount(knockback_amount, knockback_piercing, stats.knockback_resistance)

	knockback_vector = knockback_direction * final_knockback_amount
	emit_signal("health_updated", self, current_stats.health, max_stats.health)

	var hit_type = HitType.NORMAL

	for effect_behavior in effect_behaviors.get_children():
		var behavior_hit_type_result = effect_behavior.on_taken_damage(args)

		if behavior_hit_type_result != HitType.NORMAL:
			hit_type = behavior_hit_type_result

	if current_stats.health <= 0:
		if hitbox:
			hitbox.killed_something(self)

		var die_args: = Entity.DieArgs.new()
		die_args.knockback_vector = knockback_direction * max(knockback_amount, MIN_DEATH_KNOCKBACK_AMOUNT)
		die_args.killed_by_player_index = from_player_index
		die_args.killing_blow_dmg_value = full_dmg_value
		die(die_args)

		if from_player_index >= 0 and Utils.get_chance_success(RunData.get_player_effect("heal_on_kill", from_player_index) / 100.0):
			RunData.emit_signal("healing_effect", 1, from_player_index, "item_goblet")
		if is_crit:
			
			assert (from_player_index >= 0)

			if hitbox.from is Structure:
				for effect in RunData.get_player_effect("temp_stats_on_structure_crit", from_player_index):
					TempStats.add_stat(effect[0], effect[1], from_player_index)

			var gold_added = 0
			for effect in RunData.get_player_effect("gold_on_crit_kill", from_player_index):
				if Utils.get_chance_success(effect[1] / 100.0):
					gold_added += 1
					RunData.add_tracked_value(from_player_index, "item_hunting_trophy", 1)

			if Utils.get_chance_success(RunData.get_player_effect("heal_on_crit_kill", from_player_index) / 100.0):
				RunData.emit_signal("healing_effect", 1, from_player_index, "item_tentacle")

			for effect in hitbox.effects:
				if effect.key == "gold_on_crit_kill" and randf() <= effect.value / 100.0:
					gold_added += 1
					hitbox.added_gold_on_crit(gold_added)

			if gold_added > 0:
				RunData.add_gold(gold_added, from_player_index)
				hit_type = HitType.GOLD_ON_CRIT_KILL

	emit_signal(
		"took_damage", 
		self, 
		full_dmg_value, 
		knockback_direction, 
		is_crit, 
		false, 
		false, 
		dmg_value_result.armor_did_something, 
		args, 
		hit_type
	)

	return [full_dmg_value, dmg_taken, false]


func get_knockback_amount_based_on_distance_to_attacker(base_amount: float, hitbox: Hitbox, attacker: Unit) -> float:
	var adjusted_amount = base_amount
	var direction_to_attacker = global_position.direction_to(attacker.global_position)
	var distance_to_attacker = global_position.distance_to(attacker.global_position)
	var movement_dot_product = direction_to_attacker.dot(_current_movement.normalized())
	var attacker_movement_dot_product = direction_to_attacker.dot(attacker._current_movement.normalized())

	var size_factor = _hurtbox._collision.shape.radius
	var attacker_size_factor = attacker._hurtbox._collision.shape.radius
	var speed_factor = movement_dot_product * current_stats.speed / 6.0
	var attacker_speed_factor = - (attacker_movement_dot_product * attacker.current_stats.speed / 6.0)

	
	if attacker_movement_dot_product > 0:
		attacker_speed_factor *= 0.1

	var buffer = size_factor + attacker_size_factor + speed_factor + attacker_speed_factor + min(distance_to_attacker / 3.0, 150.0)
	var max_travel_distance = max(0.0, distance_to_attacker - buffer)

	if max_travel_distance > THRESHOLD_DIST_TO_LOWER_DMG_ON_PULL:
		set_hitbox_damage_modifier()

	
	
	
	var expected_travel_distance = abs(base_amount * 100 / 6.0)

	if expected_travel_distance > max_travel_distance:
		adjusted_amount = - (max_travel_distance * 6.0 / 100.0)

	if hitbox.knockback_piercing > 0:
		adjusted_amount = get_increased_piercing_knockback_amount(adjusted_amount, hitbox.knockback_piercing, stats.knockback_resistance)

	add_decaying_speed( - adjusted_amount)

	return adjusted_amount


func set_hitbox_damage_modifier() -> void :
	pass



func get_increased_piercing_knockback_amount(amount: float, piercing: float, resistance: float) -> float:
	if resistance == 1:
		return amount
	return amount + (amount * min(resistance, piercing) / (1 - resistance))


class GetDamageValueResult:
	var value: int = 0
	var dodged: = false
	var protected: = false
	var armor_did_something: = false


func get_damage_value(dmg_value: int, from_player_index: int, armor_applied: = true, _dodgeable: = true, _is_crit: = false, hitbox: Hitbox = null, _p_is_burning: = false) -> GetDamageValueResult:
	var result = GetDamageValueResult.new()
	var bonus_damage_against_targets_above_hp_from_items = RunData.get_player_effect("bonus_damage_against_targets_above_hp", from_player_index)
	var bonus_damage_against_targets_below_hp_from_items = RunData.get_player_effect("bonus_damage_against_targets_below_hp", from_player_index)
	var total_bonus_damage = 0

	if hitbox:
		for effect in hitbox.effects:
			if effect.key == "bonus_damage_against_targets_above_hp" and current_stats.health >= (effect.value2 / 100.0) * max_stats.health:
				total_bonus_damage += effect.value
			elif effect.key == "bonus_damage_against_targets_below_hp" and current_stats.health <= (effect.value2 / 100.0) * max_stats.health:
				total_bonus_damage += effect.value

		var bonus_non_elemental_damage_against_burning_targets = RunData.get_player_effect("bonus_non_elemental_damage_against_burning_targets", from_player_index)

		if bonus_non_elemental_damage_against_burning_targets > 0 and _is_burning:
			var is_elemental = false
			for scaling_stat in hitbox.scaling_stats:
				if scaling_stat[0] == "stat_elemental_damage":
					is_elemental = true
					break

			if not is_elemental:
				total_bonus_damage += bonus_non_elemental_damage_against_burning_targets

	for effect_behavior in effect_behaviors.get_children():
		total_bonus_damage += effect_behavior.get_bonus_damage(hitbox, from_player_index)

	if bonus_damage_against_targets_above_hp_from_items.size() > 0:
		assert (from_player_index >= 0)
		for bonus in bonus_damage_against_targets_above_hp_from_items:
			if current_stats.health >= (bonus[1] / 100.0) * max_stats.health:
				total_bonus_damage += bonus[0]

	if bonus_damage_against_targets_below_hp_from_items.size() > 0:
		assert (from_player_index >= 0)
		for bonus in bonus_damage_against_targets_below_hp_from_items:
			if current_stats.health <= (bonus[1] / 100.0) * max_stats.health:
				total_bonus_damage += bonus[0]

	dmg_value = round(dmg_value * (1.0 + (total_bonus_damage / 100.0))) as int

	result.value = max(1, dmg_value - current_stats.armor) as int if armor_applied else dmg_value

	if armor_applied and dmg_value != result.value:
		result.armor_did_something = true

	return result


func flash() -> void :
	
	
	var is_already_flashing = sprite.material == flash_mat
	if not is_already_flashing:
		_non_flash_material = sprite.material
		sprite.material = flash_mat
	_flash_timer.start()


func die(args: = Entity.DieArgs.new()) -> void :
	.die(args)
	knockback_vector = args.knockback_vector
	_can_move = false
	_hurtbox.disable()
	_collision.set_deferred("disabled", true)
	for effect_behavior in effect_behaviors.get_children():
		effect_behavior.on_death(args)
		effect_behavior.queue_free()


func _on_hurt(_hitbox: Hitbox) -> void :
	pass


func _on_Hurtbox_area_entered(hitbox: Area2D) -> void :
	if not hitbox.active or hitbox.ignored_objects.has(self):
		return
	var dmg = hitbox.damage
	var dmg_taken = [0, 0]
	var from = hitbox.from if is_instance_valid(hitbox.from) else null
	var from_player_index = from.player_index if (from != null and "player_index" in from) else RunData.DUMMY_PLAYER_INDEX

	if hitbox.deals_damage:
		
		for effect_behavior in effect_behaviors.get_children():
			effect_behavior.on_hurt(hitbox)
		_on_hurt(hitbox)

		var is_exploding = false
		for effect in hitbox.effects:
			if effect is ExplodingEffect:
				if Utils.get_chance_success(effect.chance):
					var args: = WeaponServiceExplodeArgs.new()
					args.pos = global_position
					args.damage = hitbox.damage
					args.accuracy = hitbox.accuracy
					args.crit_chance = hitbox.crit_chance
					args.crit_damage = hitbox.crit_damage
					args.burning_data = hitbox.burning_data
					args.scaling_stats = hitbox.scaling_stats
					args.from_player_index = from_player_index
					args.is_healing = hitbox.is_healing
					args.damage_tracking_key = hitbox.damage_tracking_key

					var explosion = WeaponService.explode(effect, args)
					if from != null and from.has_method("on_weapon_hit_something"):
						explosion.connect("hit_something", from, "on_weapon_hit_something", [explosion._hitbox])

					is_exploding = true
			elif effect is PlayerHealthStatEffect and effect.key == "stat_damage":
				dmg += effect.get_bonus_damage(from_player_index)

		
		if not is_exploding:
			var args: = TakeDamageArgs.new(from_player_index, hitbox)
			dmg_taken = take_damage(dmg, args)
			if hitbox.burning_data != null and Utils.get_chance_success(hitbox.burning_data.chance) and not hitbox.is_healing and RunData.get_player_effect("can_burn_enemies", from_player_index) > 0:
				apply_burning(hitbox.burning_data)

		if hitbox.projectiles_on_hit.size() > 0:
			for i in hitbox.projectiles_on_hit[0]:
				var weapon_stats: RangedWeaponStats = hitbox.projectiles_on_hit[1]
				var auto_target_enemy: bool = hitbox.projectiles_on_hit[2]
				var args = WeaponServiceSpawnProjectileArgs.new()
				args.from_player_index = from_player_index
				var projectile = WeaponService.manage_special_spawn_projectile(
					self, 
					weapon_stats, 
					rand_range( - PI, PI), 
					auto_target_enemy, 
					_entity_spawner_ref, 
					from, 
					args
				)
				if from != null and from.has_method("on_weapon_hit_something") and not projectile.is_connected("hit_something", from, "on_weapon_hit_something"):
					projectile.connect("hit_something", from, "on_weapon_hit_something", [projectile._hitbox])

				projectile.call_deferred("set_ignored_objects", [self])

		if hitbox.speed_percent_modifier != 0:
			add_decaying_speed((get_base_speed_value_for_pct_based_decrease() * hitbox.speed_percent_modifier / 100.0) as int)

	hitbox.hit_something(self, dmg_taken[1])


func get_base_speed_value_for_pct_based_decrease() -> int:
	return current_stats.speed


func apply_burning(burning_data: BurningData) -> void :
	if dead:
		
		return

	var from = burning_data.from
	var new_burning_player_index: int
	if is_instance_valid(from):
		new_burning_player_index = from.player_index
	else:
		new_burning_player_index = _burning_player_index if _burning_player_index >= 0 else Utils.randi() % RunData.get_player_count()

	if _burning != null:
		if _burning.damage <= burning_data.damage:
			_burning.scaling_stats = burning_data.scaling_stats
			_burning.from = from
			_burning_player_index = new_burning_player_index

		_burning.chance = max(_burning.chance, burning_data.chance)
		_burning.damage = max(_burning.damage, burning_data.damage) as int
		_burning.duration = max(_burning.duration, burning_data.duration) as int
		_burning.spread = max(_burning.spread, burning_data.spread) as int

	else:
		SoundManager2D.play(Utils.get_rand_element(burn_sounds), global_position, 0, 0.2)
		_burning = burning_data.duplicate()
		_burning_player_index = new_burning_player_index
		_burning_timer.start()
		set_burning(true)

	_burning_particles.burning_data = _burning
	_burning_particles.start_emitting()

	if _burning.spread > 0:
		_burning_particles.activate_spread()



func _on_FlashTimer_timeout() -> void :
	if sprite.material == flash_mat:
		sprite.material = _non_flash_material


func _on_BurningTimer_timeout() -> void :
	if _burning != null:
		
		for effect_behavior in effect_behaviors.get_children():
			effect_behavior.on_burned(_burning, _burning_player_index)

		var args: = TakeDamageArgs.new(_burning_player_index)
		args.dodgeable = false
		args.armor_applied = false
		args.custom_sound = Utils.get_rand_element(burn_sounds)
		args.base_effect_scale = 0.1
		args.is_burning = true
		var dmg_taken = take_damage(_burning.damage, args)

		var slow_on_hit_effects = RunData.get_player_effect("slow_on_hit", _burning_player_index)
		for slow_on_hit_effect in slow_on_hit_effects:
			if slow_on_hit_effect[0] == "stat_elemental_damage":
				add_decaying_speed((current_stats.speed * - slow_on_hit_effect[1] / 100.0) as int)
				break

		if _burning.is_global_burn:
			RunData.add_tracked_value(_burning_player_index, "item_scared_sausage", dmg_taken[1])
		else:
			var nb_sausages = RunData.get_nb_item("item_scared_sausage", _burning_player_index)
			RunData.add_tracked_value(_burning_player_index, "item_scared_sausage", min(nb_sausages, dmg_taken[1]))

		if Utils.get_first_scaling_stat(_burning.scaling_stats) == "stat_engineering":
			
			RunData.add_tracked_value(_burning_player_index, "item_turret_flame", dmg_taken[1])

		var from = _burning.from
		if is_instance_valid(from) and from.has_method("on_weapon_hit_something"):
			from.on_weapon_hit_something(self, dmg_taken[1], null)

		_burning.duration -= 1
		if _burning.duration <= 0:
			stop_burning()
		elif _burning.spread <= 0:
			_burning_particles.deactivate_spread()


func stop_burning() -> void :
	_burning_timer.stop()
	_burning_particles.emitting = false
	_burning_particles.deactivate_spread()
	set_burning(false)
	_burning = null


func set_burning(p_is_burning: bool) -> void :
	if p_is_burning:
		assert ( not dead)
	if not _is_burning and p_is_burning:
		RunData.current_burning_enemies += 1
	elif _is_burning and not p_is_burning:
		RunData.current_burning_enemies -= 1
	_is_burning = p_is_burning
	
	reset_speed_stat(_speed_percent_modifier)


func add_decaying_speed(value: int, emit_signal: = true) -> void :

	if value < 0 and emit_signal:
		emit_signal("speed_removed", self)
	if decaying_bonus_speed < - (current_stats.speed * 0.7):
		return
	if decaying_bonus_speed < - (current_stats.speed * 0.45):
		value /= 20

	value = max(value, - current_stats.speed * 0.9) as int

	decaying_bonus_speed += value


func _on_moved(delta_position: Vector2) -> void :
	for effect_behavior in effect_behaviors.get_children():
		effect_behavior.on_moved(delta_position)


func _get_health_effect_percent_factor() -> float:
	return 100.0


func _on_Hitbox_body_entered(_body: Node) -> void :
	pass
