class_name Player
extends Unit

signal wanted_to_spawn_gold(value, pos, spread)
signal healed(value, player_index)

const MIN_IFRAMES = 0.2
const MAX_IFRAMES = 0.4

export (Array, Resource) var hp_regen_sounds
export (Array, Resource) var step_sounds
export (Array, Resource) var alien_sounds

var not_moving_bonuses_applied = false
var moving_bonuses_applied = false
var current_weapons: = []
var consumables_in_range: = []
var gamepad_attack_vector: = Vector2(1, 0)

var _sprites: = []
var _item_appearances: = []

var _explode_on_hit_stats = {}
var _explode_when_below_hp_stats = {}
var _explode_when_below_hp_triggers = {}
var _hit_protection: = 0

var _alien_eyes_timer: Timer
var _total_healed_this_wave = 0
var _chal_medicine_value = 0
var _chal_medicine_completed = false

var _hp_regen_val: = 1
var _health_regen_timer: = FixedTimer.new()

var _decaying_stats_on_consumable: = []
var _decaying_stats_on_hit: = []
var _remove_temp_stats_on_hit: = {}
var _one_second_timeouts: = 0

var _original_boost_args: BoostArgs
var _max_hp_before_boost: int

var player_index: = 0

onready var _lifesteal_timer = $LifestealTimer
onready var _invincibility_timer = $InvincibilityTimer
onready var _legs = $Animation / Legs
onready var _shadow: = $Animation / Shadow as Sprite
onready var _item_attract_area: = $ItemAttractArea as ItemAttractArea
onready var _item_pickup_area: = $ItemPickupArea as Area2D

onready var _weapons_container = $Weapons

onready var highlight: Sprite = $Animation / Highlight

onready var _running_smoke: CPUParticles2D = $RunningSmoke
onready var _lose_health_timer: Timer = $LoseHealthTimer
onready var _one_second_timer: Timer = $OneSecondTimer
onready var _moving_timer: Timer = $MovingTimer
onready var _not_moving_timer: Timer = $NotMovingTimer
onready var _boost_timer: Timer = $BoostTimer



func _ready() -> void :
	var pickup_range = RunData.get_player_effect("pickup_range", player_index)
	_item_attract_area.apply_pickup_range_effect(pickup_range)

	_chal_medicine_value = ChallengeService.get_chal("chal_medicine").value

	_hit_protection = RunData.get_player_effect("hit_protection", player_index)

	_running_smoke.stop()

	if RunData.invulnerable:
		disable_hurtbox()

	if DebugService.invisible:
		visible = false

	set_hp_regen_timer_value()

	var init_triggers = true
	init_exploding_stats(init_triggers)

	if RunData.get_player_effect("lose_hp_per_second", player_index) > 0:
		_lose_health_timer.start()

	if RunData.get_player_effect("temp_stats_per_interval", player_index).size() > 0:
		_one_second_timer.start()

	var alien_eyes_effect = RunData.get_player_effect("alien_eyes", player_index)
	if alien_eyes_effect.size() > 0:
		_alien_eyes_timer = Timer.new()
		_alien_eyes_timer.wait_time = alien_eyes_effect[0][3]
		var _alien_eyes = _alien_eyes_timer.connect("timeout", self, "on_alien_eyes_timeout")
		add_child(_alien_eyes_timer)
		_alien_eyes_timer.start()

	update_highlight()
	init_effect_behaviors()


func respawn() -> void :
	assert (false, "Players can't be respawned")


func init_effect_behaviors() -> void :
	assert (effect_behaviors.get_child_count() == 0, "init_effect_behaviors should only be called once")
	for effect_behavior_data in EffectBehaviorService.player_effect_behaviors:
		var effect_behavior = effect_behavior_data.scene.instance().init(self)
		if effect_behavior.should_add_on_spawn():
			effect_behaviors.add_child(effect_behavior)
		else:
			effect_behavior.queue_free()


func update_animation(movement: Vector2) -> void :

	check_not_moving_stats(movement)
	check_moving_stats(movement)

	if movement.x > 0:
		_shadow.scale.x = abs(_shadow.scale.x)
		for sprite in _sprites:
			sprite.scale.x = abs(sprite.scale.x)
	elif movement.x < 0:
		_shadow.scale.x = - abs(_shadow.scale.x)
		for sprite in _sprites:
			sprite.scale.x = - abs(sprite.scale.x)

	if _animation_player.current_animation == "idle":
		_animation_player.playback_speed = 1
	elif _animation_player.current_animation == "move":
		_animation_player.playback_speed = get_move_speed() / stats.speed

	if _animation_player.current_animation == "idle" and movement != Vector2.ZERO:
		_animation_player.play("move")
		_running_smoke.emit()
	elif _animation_player.current_animation == "move" and movement == Vector2.ZERO:
		_animation_player.play("idle")
		_running_smoke.stop()


func check_not_moving_stats(movement: Vector2) -> void :
	assert ( not dead)
	var temp_stats_while_not_moving = RunData.get_player_effect("temp_stats_while_not_moving", player_index)
	if not not_moving_bonuses_applied and temp_stats_while_not_moving.size() > 0 and movement.x == 0 and movement.y == 0:
		not_moving_bonuses_applied = true

		_not_moving_timer.start()

		for temp_stat in temp_stats_while_not_moving:
			if temp_stat[0] != "percent_materials":
				TempStats.add_stat(temp_stat[0], temp_stat[1], player_index)
		RunData.emit_stats_updated()

		reset_weapons_cd()
	elif not_moving_bonuses_applied and (movement.x != 0 or movement.y != 0):
		not_moving_bonuses_applied = false

		_not_moving_timer.stop()

		for temp_stat in temp_stats_while_not_moving:
			if temp_stat[0] != "percent_materials":
				TempStats.remove_stat(temp_stat[0], temp_stat[1], player_index)
		RunData.emit_stats_updated()

		reset_weapons_cd()


func check_moving_stats(movement: Vector2) -> void :
	assert ( not dead)
	var temp_stats_while_moving = RunData.get_player_effect("temp_stats_while_moving", player_index)
	if not moving_bonuses_applied and temp_stats_while_moving.size() > 0 and (movement.x != 0 or movement.y != 0):
		moving_bonuses_applied = true

		_moving_timer.start()

		for temp_stat in temp_stats_while_moving:
			if temp_stat[0] != "percent_materials":
				TempStats.add_stat(temp_stat[0], temp_stat[1], player_index)
		RunData.emit_stats_updated()

		reset_weapons_cd()
	elif moving_bonuses_applied and movement.x == 0 and movement.y == 0:
		moving_bonuses_applied = false

		_moving_timer.stop()

		for temp_stat in temp_stats_while_moving:
			if temp_stat[0] != "percent_materials":
				TempStats.remove_stat(temp_stat[0], temp_stat[1], player_index)
		RunData.emit_stats_updated()

		reset_weapons_cd()


func reset_weapons_cd() -> void :
	for weapon in current_weapons:
		if is_instance_valid(weapon):
			weapon.reset_cooldown()


func disable_hurtbox() -> void :
	_hurtbox.disable()


func enable_hurtbox() -> void :
	_hurtbox.enable()


func disable_gold_pickup() -> void :
	_item_attract_area.set_collision_mask_bit(6, false)
	_item_pickup_area.set_collision_mask_bit(6, false)


func get_nb_weapons() -> int:
	return current_weapons.size()


func get_remote_transform() -> RemoteTransform2D:
	return $RemoteTransform2D as RemoteTransform2D


func get_life_bar_remote_transform() -> RemoteTransform2D:
	return $LifeBarTransform as RemoteTransform2D


func get_damage_value(dmg_value: int, _from_player_index: int, armor_applied: = true, dodgeable: = true, _is_crit: = false, _hitbox: Hitbox = null, _is_burning: = false) -> Unit.GetDamageValueResult:
	var result: = Unit.GetDamageValueResult.new()
	if dodgeable and randf() < current_stats.dodge:
		result.value = 0
		result.dodged = true
	elif _hit_protection > 0:
		result.value = 0
		result.protected = true
		_hit_protection -= 1
	else:
		var armor_coef = RunData.get_armor_coef(current_stats.armor)
		result.value = max(1, round(dmg_value * armor_coef)) as int if armor_applied else dmg_value
	return result


func apply_items_effects() -> void :

	var animation_node = $Animation

	
	var weapons = RunData.get_player_weapons(player_index)
	for i in weapons.size():
		add_weapon(weapons[i], i)

	RunData.sort_appearances()
	var appearances_behind = []

	
	for appearance in RunData.get_player_appearances(player_index):
		var item_sprite = Sprite.new()
		item_sprite.texture = appearance.get_sprite()
		animation_node.add_child(item_sprite)

		if appearance.depth < - 1:
			appearances_behind.push_back(item_sprite)

		_item_appearances.push_back(item_sprite)

	var popped = appearances_behind.pop_back()

	while popped != null:
		animation_node.move_child(popped, 0)
		popped = appearances_behind.pop_back()

	_sprites = animation_node.get_children()

	
	update_player_stats(true)


func update_player_stats(reset_current_health: = false) -> void :
	var old_max_health = max_stats.health
	max_stats.health = RunData.get_player_max_health(player_index)
	max_stats.speed = stats.speed * (1 + (Utils.get_capped_stat("stat_speed", player_index) / 100.0)) as float
	max_stats.armor = Utils.get_stat("stat_armor", player_index) as int
	max_stats.dodge = Utils.get_capped_stat("stat_dodge", player_index) / 100.0

	init_exploding_stats()

	current_stats.copy(max_stats, reset_current_health)

	if old_max_health != max_stats.health:
		emit_signal("health_updated", self, current_stats.health, max_stats.health)

	check_hp_regen()


func add_weapon(weapon: WeaponData, pos: int) -> void :
	var instance = weapon.scene.instance()

	instance.weapon_pos = pos
	instance.stats = weapon.stats.duplicate()
	instance.weapon_id = weapon.weapon_id
	instance.tier = weapon.tier
	instance.weapon_sets = weapon.sets
	instance.is_cursed = weapon.is_cursed
	instance.connect("tracked_value_updated", weapon, "on_tracked_value_updated")
	instance.connect("wanted_to_break", self, "on_weapon_wanted_to_break")

	for effect in weapon.effects:
		instance.effects.push_back(effect.duplicate())

	_weapons_container.add_child(instance)
	instance.global_position = position
	current_weapons.push_back(instance)
	_weapons_container.update_weapons_positions(current_weapons)


func on_weapon_wanted_to_break(weapon: Weapon, gold_dropped: int) -> void :

	if not current_weapons.has(weapon):
		return

	emit_signal("wanted_to_spawn_gold", gold_dropped, weapon.global_position, 300)
	var _r = RunData.remove_weapon_by_index(weapon.weapon_pos, player_index)

	current_weapons.erase(weapon)

	for current_weapon in current_weapons:
		if current_weapon.weapon_pos > weapon.weapon_pos:
			current_weapon.weapon_pos -= 1

	SoundManager.play(Utils.get_rand_element(WeaponService.breaking_sounds), - 15, 0.1, true)

	weapon.queue_free()


func take_damage(value: int, args: TakeDamageArgs) -> Array:
	if dead:
		return [0, 0, false]

	var hitbox = args.hitbox
	var dodgeable = args.dodgeable
	var bypass_invincibility = args.bypass_invincibility

	if hitbox and hitbox.is_healing:
		var _healed = on_healing_effect(value, hitbox.damage_tracking_key)
		return [0, 0, false]

	if _invincibility_timer.is_stopped() or bypass_invincibility:

		var dmg_value_result = get_damage_value(value, args.from_player_index, args.armor_applied, dodgeable, false, hitbox, args.is_burning)
		var full_dmg_value = dmg_value_result.value
		var is_dodge = dmg_value_result.dodged
		var is_protected = dmg_value_result.protected

		var dmg_taken = clamp(full_dmg_value, 0, current_stats.health)
		current_stats.health = max(0.0, current_stats.health - full_dmg_value) as int
		emit_signal("health_updated", self, current_stats.health, max_stats.health)

		if dodgeable:
			disable_hurtbox()
			_invincibility_timer.start(get_iframes(dmg_taken))

		var sound = Utils.get_rand_element(hurt_sounds)
		if is_dodge:
			sound = Utils.get_rand_element(dodge_sounds)

			var dmg_on_dodge_effect = RunData.get_player_effect("dmg_on_dodge", player_index)
			if dmg_on_dodge_effect.size() > 0 and hitbox != null and is_instance_valid(hitbox.from):
				var total_dmg_to_deal = 0
				for dmg_on_dodge in dmg_on_dodge_effect:
					if randf() >= dmg_on_dodge[2] / 100.0:
						continue
					var dmg_from_stat = max(1, (dmg_on_dodge[1] / 100.0) * Utils.get_stat(dmg_on_dodge[0], player_index))
					var dmg = WeaponService.apply_damage_bonus(dmg_from_stat, player_index) as int
					total_dmg_to_deal += dmg
				var dodge_damage_args = TakeDamageArgs.new(player_index)
				var dodge_dmg_dealt = hitbox.from.take_damage(total_dmg_to_deal, dodge_damage_args)
				RunData.add_tracked_value(player_index, "item_riposte", dodge_dmg_dealt[1])

			var heal_on_dodge_effect = RunData.get_player_effect("heal_on_dodge", player_index)
			if heal_on_dodge_effect.size() > 0:
				var total_to_heal = 0
				for heal_on_dodge in heal_on_dodge_effect:
					if randf() < heal_on_dodge[2] / 100.0:
						total_to_heal += heal_on_dodge[1]
				var _healed = on_healing_effect(total_to_heal, "item_adrenaline", false)

			var temp_stats_on_dodge_effect = RunData.get_player_effect("temp_stats_on_dodge", player_index)
			for temp_stat_on_hit in temp_stats_on_dodge_effect:
				TempStats.add_stat(temp_stat_on_hit[0], temp_stat_on_hit[1], player_index)

		if dmg_taken > 0:
			flash()
			_attract_nearby_consumables()

			var explode_on_hit_effects = RunData.get_player_effect("explode_on_hit", player_index)
			var explode_when_below_hp_effects = RunData.get_player_effect("explode_when_below_hp", player_index)
			var nb_explosions = explode_on_hit_effects.size() + explode_when_below_hp_effects.size()

			for effect in explode_on_hit_effects:
				explode(_explode_on_hit_stats[effect], effect, nb_explosions)

			for effect in explode_when_below_hp_effects:
				if current_stats.health <= max_stats.health * (effect.hp_threshold / 100.0) and _explode_when_below_hp_triggers[effect] > 0:
					explode(_explode_when_below_hp_stats[effect], effect, nb_explosions)
					_explode_when_below_hp_triggers[effect] -= 1

			var temp_stats_on_hit_effect = RunData.get_player_effect("temp_stats_on_hit", player_index)
			for temp_stat_on_hit in temp_stats_on_hit_effect:
				TempStats.add_stat(temp_stat_on_hit[0], temp_stat_on_hit[1], player_index)

			if _health_regen_timer.is_stopped():
				_health_regen_timer.start()

			for stat in _remove_temp_stats_on_hit:
				var stat_value: int = _remove_temp_stats_on_hit[stat]
				TempStats.remove_stat(stat, stat_value, player_index)
				_remove_temp_stats_on_hit[stat] = 0

			
			var decaying_stats_on_hit_effects = RunData.get_player_effect("decaying_stats_on_hit", player_index)
			for decaying_stats_on_hit_effect in decaying_stats_on_hit_effects:
				var decaying_stat_name = decaying_stats_on_hit_effect[0]
				var decaying_stat_value = decaying_stats_on_hit_effect[1]
				var decaying_stat_duration = decaying_stats_on_hit_effect[2]
				_start_decaying_stats_effect_timer(_decaying_stats_on_hit, decaying_stat_name, decaying_stat_value, decaying_stat_duration)

		SoundManager2D.play(sound, global_position, 0, 0.2, true)

		if current_stats.health <= 0:
			var die_args: = Entity.DieArgs.new()
			die(die_args)

		RunData.emit_stats_updated()

		emit_signal(
			"took_damage", 
			self, 
			full_dmg_value, 
			Vector2.ZERO, 
			false, 
			is_dodge, 
			is_protected, 
			false, 
			args, 
			HitType.NORMAL
		)

		return [full_dmg_value, dmg_taken, is_dodge]

	return [0, 0, false]


func explode(stats: WeaponStats, effect: ExplodingEffect, nb_explosions: int) -> void :

	if not Utils.get_chance_success(effect.chance):
		return

	var explode_args: = WeaponServiceExplodeArgs.new()
	var max_offset: int = (nb_explosions - 1) * 20
	explode_args.pos = Utils.get_random_offset_position(global_position, max_offset)
	explode_args.damage = stats.damage + effect.get_additional_scaling_damage(player_index)
	explode_args.accuracy = stats.accuracy
	explode_args.crit_chance = stats.crit_chance
	explode_args.crit_damage = stats.crit_damage
	explode_args.burning_data = stats.burning_data
	explode_args.scaling_stats = stats.scaling_stats
	explode_args.from_player_index = player_index
	explode_args.damage_tracking_key = effect.tracking_key

	if stats.shooting_sounds.size() > 0:
		SoundManager2D.play(Utils.get_rand_element(stats.shooting_sounds), global_position, stats.sound_db_mod, 0.2, true)

	var _inst = WeaponService.explode(effect, explode_args)


func get_iframes(damage_taken: float) -> float:
	var pct_dmg_taken = (damage_taken / max_stats.health)

	var min_iframes = MIN_IFRAMES / (max(1.0, RunData.get_endless_factor()))
	var max_iframes = MAX_IFRAMES / (max(1.0, RunData.get_endless_factor()))

	var iframes = clamp((pct_dmg_taken * max_iframes) / 0.15, min_iframes, max_iframes)



	return iframes


func check_hp_regen() -> void :
	set_hp_regen_timer_value()

	var stat_hp_regeneration = Utils.get_stat("stat_hp_regeneration", player_index)
	if RunData.get_player_effect("torture", player_index) <= 0 and stat_hp_regeneration <= 0:
		_health_regen_timer.stop()
	elif _health_regen_timer.is_stopped() and current_stats.health < max_stats.health and not cleaning_up:
		_health_regen_timer.start()


func set_hp_regen_timer_value() -> void :
	if RunData.get_player_effect("torture", player_index) > 0:
		_health_regen_timer.wait_time = 1
		return

	var stat_hp_regeneration = Utils.get_stat("stat_hp_regeneration", player_index)
	_health_regen_timer.wait_time = RunData.get_hp_regeneration_timer(stat_hp_regeneration as int)


func play_step_sound() -> void :
	if DebugService.invisible:
		return

	SoundManager.play(Utils.get_rand_element(step_sounds), - 6, 0.1)


func die(args: = Entity.DieArgs.new()) -> void :
	.die(args)

	for weapon in current_weapons:
		weapon.disable_hitbox()
		weapon.disable_target_tracking()
	Utils.disable_node(_weapons_container)

	highlight.hide()
	_legs.queue_free()
	_shadow.queue_free()
	_running_smoke.queue_free()
	for appearance in _item_appearances:
		appearance.queue_free()

	_item_attract_area.monitoring = false
	_item_pickup_area.monitoring = false

	TempStats.reset_player(player_index)
	_clean_up()


func death_animation_finished() -> void :
	
	
	pass


func _physics_process(delta: float) -> void :
	
	var loop_count: = _health_regen_timer.try_loop(delta)
	if loop_count > 0:
		on_health_regen(loop_count)



func on_room_cleanup() -> void :
	if dead:
		return
	_running_smoke.stop()
	_animation_player.play("idle")
	_clean_up()


func on_health_regen(loop_count: int) -> void :

	var bonus_hp_regen_effects = RunData.get_player_effect("hp_regen_bonus", player_index)

	var hp_regen_val = _hp_regen_val

	if bonus_hp_regen_effects.size() > 0:
		var multiplier = 0
		for effect in bonus_hp_regen_effects:
			if current_stats.health < max_stats.health * (effect[1] / 100.0):
				multiplier += effect[0]
		hp_regen_val = _hp_regen_val * (1.0 + multiplier)

	var torture_effect = RunData.get_player_effect("torture", player_index)
	var base_val = torture_effect if torture_effect > 0 else hp_regen_val
	base_val *= loop_count
	var value = min(base_val, max_stats.health - current_stats.health)

	if value < 0: value = 0
	var _healed = on_healing_effect(value, "", torture_effect > 0)

	if current_stats.health >= max_stats.health:
		_health_regen_timer.stop()


func on_damage_effect(value: int, armor_applied: bool, dodgeable: bool) -> void :
	var args = TakeDamageArgs.new( - 1)
	args.armor_applied = armor_applied
	args.dodgeable = dodgeable
	var _dmg_taken = take_damage(value, args)


func on_lifesteal_effect(value: int) -> void :
	if _lifesteal_timer.is_stopped():
		_lifesteal_timer.start()
		var _healed = on_healing_effect(value)


func on_healing_effect(value: int, tracking_key: String = "", from_torture: bool = false) -> int:

	var actual_value = min(value, max_stats.health - current_stats.health)
	var value_healed = heal(actual_value, from_torture)

	if value_healed > 0:
		SoundManager.play(Utils.get_rand_element(hp_regen_sounds), get_heal_db(), 0.1)
		emit_signal("health_updated", self, current_stats.health, max_stats.health)
		emit_signal("healed", actual_value, player_index)

		if tracking_key != "":
			RunData.add_tracked_value(player_index, tracking_key, value_healed)

	return value_healed


func on_heal_over_time_effect(total_healing: int, duration: int) -> void :
	var interval: = float(duration) / total_healing

	for i in range(1, total_healing + 1):
		var timer: SceneTreeTimer = get_tree().create_timer(interval * i, false)
		var _hot_error: = timer.connect("timeout", self, "on_heal_over_time_timer_timeout")


func on_heal_over_time_timer_timeout() -> void :
	var _e = on_healing_effect(1)


func get_heal_db() -> float:
	if _health_regen_timer.wait_time < 2.5:
		return - 10.0
	elif _health_regen_timer.wait_time < 1.0:
		return - 15.0
	else:
		return 0.0


func heal(value: int, is_from_torture: bool = false) -> int:
	if dead or RunData.get_player_effect_bool("no_heal", player_index):
		return 0

	
	
	var value_healed = 0
	if RunData.get_player_effect("torture", player_index) <= 0 or is_from_torture or cleaning_up:
		current_stats.health += value
		value_healed = value

	_total_healed_this_wave += value_healed

	if _total_healed_this_wave >= _chal_medicine_value and not _chal_medicine_completed:
		_chal_medicine_completed = true
		ChallengeService.complete_challenge("chal_medicine")

	return value_healed


func init_exploding_stats(init_triggers: bool = false) -> void :
	var explode_on_hit = RunData.get_player_effect("explode_on_hit", player_index)
	var explode_when_below_hp = RunData.get_player_effect("explode_when_below_hp", player_index)
	if explode_on_hit.empty() and explode_when_below_hp.empty():
		return
	for effect in explode_on_hit:
		var args: = WeaponServiceInitStatsArgs.new()
		args.effects = [ExplodingEffect.new()]
		_explode_on_hit_stats[effect] = WeaponService.init_base_stats(effect.stats, player_index, args)
	for effect in explode_when_below_hp:
		var args: = WeaponServiceInitStatsArgs.new()
		args.effects = [ExplodingEffect.new()]
		_explode_when_below_hp_stats[effect] = WeaponService.init_base_stats(effect.stats, player_index, args)
		if init_triggers:
			_explode_when_below_hp_triggers[effect] = 1




func _clean_up() -> void :
	assert ( not cleaning_up)
	cleaning_up = true
	_can_move = false
	_current_movement = Vector2.ZERO
	for timer in [
		_health_regen_timer, 
		_lose_health_timer, 
		_moving_timer, 
		_not_moving_timer, 
		_invincibility_timer, 
		_one_second_timer, 
	]:
		timer.stop()
		timer.paused = true

	if _alien_eyes_timer:
		_alien_eyes_timer.stop()
		_alien_eyes_timer.paused = true
	set_physics_process(false)
	disable_hurtbox()


func _on_InvincibilityTimer_timeout() -> void :
	if not cleaning_up:
		enable_hurtbox()


func _on_LoseHealthTimer_timeout() -> void :
	var args: = TakeDamageArgs.new( - 1)
	args.dodgeable = false
	args.armor_applied = false
	args.bypass_invincibility = true
	var lose_hp_per_second = RunData.get_player_effect("lose_hp_per_second", player_index)
	var _dmg_taken = take_damage(lose_hp_per_second, args)


func on_alien_eyes_timeout() -> void :
	var alien_eyes_effect = RunData.get_player_effect("alien_eyes", player_index)

	var projectiles = []
	var alien_stats = WeaponService.init_ranged_stats(alien_eyes_effect[0][1], player_index, true)

	SoundManager.play(Utils.get_rand_element(alien_sounds), 0, 0.1)

	for projectile in alien_eyes_effect:
		for i in projectile[0]:
			projectiles.push_back(projectile)

	for i in projectiles.size():
		var direction = (2 * PI / projectiles.size()) * i

		var auto_target_enemy: bool = projectiles[i][2]
		var args: = WeaponServiceSpawnProjectileArgs.new()
		args.damage_tracking_key = "item_alien_eyes"
		args.from_player_index = player_index
		var _projectile = WeaponService.manage_special_spawn_projectile(
			self, 
			alien_stats, 
			direction, 
			auto_target_enemy, 
			_entity_spawner_ref, 
			self, 
			args
		)


func update_highlight():
	if dead: return

	var value = ProgressData.settings.character_highlighting
	if RunData.is_coop_run:
		var highlight_color = CoopService.get_player_color(player_index)
		highlight_color.a = 1.0 if value else 0.7
		highlight.modulate = highlight_color
		highlight.show()
	else:
		highlight.visible = value
		highlight.modulate = Utils.HIGHLIGHT_COLOR


func update_weapon_highlighting() -> void :
	for weapon in current_weapons:
		weapon.update_highlighting()


func on_consumable_picked_up(consumable_data: ConsumableData) -> void :
	
	var consumable_stats_while_max_effect = RunData.get_player_effect("consumable_stats_while_max", player_index)

	if consumable_stats_while_max_effect.size() > 0 and current_stats.health >= max_stats.health:
		var max_consumable_stats_gained_this_wave = RunData.max_consumable_stats_gained_this_wave[player_index]
		for i in consumable_stats_while_max_effect.size():
			var stat = consumable_stats_while_max_effect[i]
			
			var has_max = stat.size() > 2
			var reached_max = has_max and max_consumable_stats_gained_this_wave[i][2] >= stat[2]
			if not has_max or not reached_max:
				RunData.add_stat(stat[0], stat[1], player_index)
				if stat[0] == "stat_max_hp":
					RunData.add_tracked_value(player_index, "item_extra_stomach", stat[1])
					
					current_stats.health += stat[1]
				if has_max:
					max_consumable_stats_gained_this_wave[i][2] += stat[1]

	
	var decaying_stats_on_consumable_effects = RunData.get_player_effect("decaying_stats_on_consumable", player_index)
	for decaying_stats_on_consumable_effect in decaying_stats_on_consumable_effects:
		var decaying_stat_name = decaying_stats_on_consumable_effect[0]
		var decaying_stat_value = decaying_stats_on_consumable_effect[1]
		var decaying_stat_duration = decaying_stats_on_consumable_effect[2]
		_start_decaying_stats_effect_timer(_decaying_stats_on_consumable, decaying_stat_name, decaying_stat_value, decaying_stat_duration)

	
	if not cleaning_up and current_stats.health >= max_stats.health:
		var consumable_temp_stats_while_max_effect = RunData.get_player_effect("temp_consumable_stats_while_max", player_index)
		for stat in consumable_temp_stats_while_max_effect:
			var temp_stat_name = stat[0]
			var temp_stat_value = stat[1]
			TempStats.add_stat(temp_stat_name, temp_stat_value, player_index)

	if consumable_data.my_id == "consumable_fruit" or consumable_data.my_id == "consumable_poisoned_fruit":
		var stats_on_fruit_effects = RunData.get_player_effect("stats_on_fruit", player_index)
		for stats_on_fruit_effect in stats_on_fruit_effects:
			var stat_name = stats_on_fruit_effect[0]
			var stat_value = stats_on_fruit_effect[1]
			var effect_chance = stats_on_fruit_effect[2]
			if Utils.get_chance_success(effect_chance / 100.0):
				RunData.add_stat(stat_name, stat_value, player_index)
				RunData.add_tracked_value(player_index, "character_druid", stat_value)

	RunData.emit_stats_updated()

	var player_data = RunData.players_data[player_index]
	player_data.consumables_picked_up_this_run += 1
	ChallengeService.try_complete_challenge("chal_hungry", player_data.consumables_picked_up_this_run)
	if RunData.current_wave <= 20:
		ChallengeService.try_complete_challenge("chal_herbalist", player_data.consumables_picked_up_this_run)


func _start_decaying_stats_effect_timer(stats_array: Array, stat_name: String, stat_value: int, stat_duration: int) -> void :

	if cleaning_up:
		return

	
	for existing_stat in stats_array:
		if existing_stat.name == stat_name and existing_stat.duration == stat_duration:
			
			existing_stat.timer.time_left = stat_duration
			if existing_stat.value != stat_value:
				
				TempStats.remove_stat(stat_name, existing_stat.value, player_index)
				TempStats.add_stat(stat_name, stat_value, player_index)
				existing_stat.value = stat_value
			return
	var timer: SceneTreeTimer = Utils.get_tree().create_timer(stat_duration, false)
	var stat_item: = {"name": stat_name, "timer": timer, "value": stat_value, "duration": stat_duration}
	stats_array.push_back(stat_item)
	TempStats.add_stat(stat_name, stat_value, player_index)
	var _error = timer.connect("timeout", self, "_on_decaying_stats_timer_timeout", [stat_item, stats_array])


func _on_decaying_stats_timer_timeout(stat_item: Dictionary, stats_array: Array) -> void :

	if cleaning_up:
		return

	TempStats.remove_stat(stat_item.name, stat_item.value, player_index)
	stats_array.erase(stat_item)
	RunData.emit_stats_updated()


func _attract_nearby_consumables() -> void :
	if not _item_attract_area.monitoring: return

	for area in _item_attract_area.get_overlapping_areas():
		if not area is Consumable:
			continue
		
		if area.attracted_by == null and area.consumable_data and area.consumable_data.my_id != "consumable_poisoned_fruit":
			area.attracted_by = self


func _on_ItemAttractArea_area_entered(item: Item) -> void :
	var is_heal: = item is Consumable and (item as Consumable).has_healing_effect()
	var is_gold: = not item is Consumable
	var should_attract_item: = (is_heal and current_stats.health < max_stats.health) or is_gold
	if not should_attract_item:
		return
	var item_already_attracted_by_player: = item.attracted_by != null
	if should_attract_item and not item_already_attracted_by_player:
		item.attracted_by = self
	
	if is_gold and global_position.distance_squared_to(item.global_position) < global_position.distance_squared_to(item.attracted_by.global_position):
		item.attracted_by = self


func _on_ItemPickupArea_area_entered(area: Area2D) -> void :
	
	if area.attracted_by == null or area.attracted_by == self:
		area.pickup(player_index)


func _on_MovingTimer_timeout() -> void :
	assert ( not dead)
	handle_gold_stat("temp_stats_while_moving")


func _on_NotMovingTimer_timeout() -> void :
	assert ( not dead)
	handle_gold_stat("temp_stats_while_not_moving")


func handle_gold_stat(effect_key: String) -> void :
	for temp_stat in RunData.get_player_effect(effect_key, player_index):
		if temp_stat[0] == "percent_materials":
			var pct = temp_stat[1] / 100.0
			var val = pct * RunData.get_player_gold(player_index)
			var actual_val = max(1, abs(val))

			
			if temp_stat.size() >= 2:
				actual_val = min(actual_val, temp_stat[2])

			if val < 0.0:
				RunData.remove_gold(actual_val, player_index)
				RunData.emit_signal("stat_removed", "stat_materials", actual_val, - 15.0, player_index)
			else:
				RunData.add_gold(actual_val, player_index)
				RunData.emit_signal("stat_added", "stat_materials", actual_val, - 15.0, player_index)


func life_bar_effects() -> Dictionary:
	return {"hit_protection": _hit_protection}


func _on_OneSecondTimer_timeout() -> void :
	_one_second_timeouts += 1

	var effect: Array = RunData.get_player_effect("temp_stats_per_interval", player_index)
	for sub_effect in effect:
		var stat_key: String = sub_effect[0]
		var value: int = sub_effect[1]
		var interval: int = sub_effect[2]
		var reset_on_hit: bool = sub_effect[3]

		if _one_second_timeouts % interval == 0:
			TempStats.add_stat(stat_key, value, player_index)

			if reset_on_hit == true:
				if _remove_temp_stats_on_hit.has(stat_key):
					_remove_temp_stats_on_hit[stat_key] += value
				else:
					_remove_temp_stats_on_hit[stat_key] = value
	RunData.emit_stats_updated()


func _set_outlines(alpha: float = 1.0, desaturation: float = 0.0) -> void :
	._set_outlines(alpha, desaturation)
	for leg in _legs.get_children():
		var leg_sprite: Sprite = leg.get_node("Sprite")
		leg_sprite.material = sprite.material


func boost(boost_args: BoostArgs) -> void :
	if not can_be_boosted:
		return

	.boost(boost_args)
	_original_boost_args = boost_args
	_max_hp_before_boost = max_stats.health
	var health_increase: = int(max_stats.health * (boost_args.hp_boost / 100.0))
	TempStats.add_stat("stat_max_hp", health_increase, player_index)
	current_stats.health += health_increase
	TempStats.add_stat("stat_speed", boost_args.speed_boost, player_index)
	TempStats.add_stat("stat_attack_speed", boost_args.attack_speed_boost, player_index)
	RunData.emit_stats_updated()

	_boost_timer.start()


func boost_ended() -> void :
	.boost_ended()

	if cleaning_up:
		return

	TempStats.remove_stat("stat_max_hp", max_stats.health - _max_hp_before_boost, player_index)
	if current_stats.health > Utils.get_stat("stat_max_hp", player_index):
		current_stats.health = int(Utils.get_stat("stat_max_hp", player_index))
	TempStats.remove_stat("stat_speed", _original_boost_args.speed_boost, player_index)
	TempStats.remove_stat("stat_attack_speed", _original_boost_args.attack_speed_boost, player_index)
	RunData.emit_stats_updated()


func _on_BoostTimer_timeout() -> void :
	if not dead:
		boost_ended()
