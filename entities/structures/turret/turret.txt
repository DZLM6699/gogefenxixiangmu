class_name Turret
extends Structure




var max_turret_anim_speed: = 3.0

var reset_shooting_speed_on_shoot: bool = false
var _shooting_speed: = 1.0
var _targets_in_range: = []
var _current_target: = []
var _cooldown: float = 0.0
var _is_shooting: = false
var _next_proj_rotation = 0
var _original_base_stats: Resource
var _damage_tracking_key: String
var _nb_shots_taken: int = 0

onready var _range_shape = $Range / CollisionShape2D
onready var _boost_timer = get_node_or_null("BoostTimer")


func _physics_process(delta: float) -> void :

	if dead: return

	_cooldown = max(_cooldown - Utils.physics_one(delta), 0)

	_current_target = Utils.get_nearest(_targets_in_range, global_position, stats.min_range)

	if should_shoot():
		_is_shooting = true
		_animation_player.playback_speed = _shooting_speed
		_animation_player.play("shoot")


func set_data(data: Resource) -> void :
	.set_data(data)
	_shooting_speed = data.shooting_animation_speed
	_damage_tracking_key = data.tracking_key


func reload_data() -> void :
	.reload_data()
	if _range_shape:
		_range_shape.shape.radius = stats.max_range

	set_shooting_speed()


func set_shooting_speed() -> void :
	var anim_length = _animation_player.get_animation("shoot").length * 60
	var max_cooldown = _get_max_cooldown()

	if anim_length / _shooting_speed > max_cooldown:
		_shooting_speed = min(anim_length / max_cooldown, max_turret_anim_speed)


func should_shoot() -> bool:
	return (_cooldown == 0 and 
		not _is_shooting and 
		(
			_current_target.size() > 0
			and is_instance_valid(_current_target[0])
			and Utils.is_between(_current_target[1], stats.min_range, stats.max_range)
		)
	)


func shoot() -> void :
	_nb_shots_taken += 1
	if _current_target.size() == 0 or not is_instance_valid(_current_target[0]):
		_is_shooting = false
		_cooldown = _get_next_cooldown()
	else:
		var target_dir = (_current_target[0].global_position - global_position).angle()
		var accuracy_factor = rand_range( - 1 + stats.accuracy, 1 - stats.accuracy)
		_next_proj_rotation = target_dir + accuracy_factor

	SoundManager2D.play(Utils.get_rand_element(stats.shooting_sounds), global_position, stats.sound_db_mod, 0.2)

	for i in stats.nb_projectiles:
		var _projectile = _spawn_projectile(_muzzle.global_position)

	if reset_shooting_speed_on_shoot:
		set_shooting_speed()
		reset_shooting_speed_on_shoot = false


func set_instant_shoot() -> void :
	_cooldown = 0
	_shooting_speed = min(_shooting_speed * 2.0, max_turret_anim_speed)
	reset_shooting_speed_on_shoot = true


func _spawn_projectile(position: Vector2) -> Node:
	var proj_rotation = rand_range(_next_proj_rotation - stats.projectile_spread, _next_proj_rotation + stats.projectile_spread)
	var args: = WeaponServiceSpawnProjectileArgs.new()
	args.knockback_direction = Vector2(cos(proj_rotation), sin(proj_rotation))
	args.effects = effects
	args.from_player_index = player_index
	args.damage_tracking_key = _damage_tracking_key
	return WeaponService.spawn_projectile(position, stats, proj_rotation, self, args)


func _get_next_cooldown(at_wave_begin: bool = false) -> float:
	if is_big_reload_active(at_wave_begin):
		return WeaponService.apply_structure_attack_speed_effects(stats.cooldown * stats.additional_cooldown_multiplier, player_index) as float
	var max_cooldown = _get_max_cooldown()
	return rand_range(max(1, max_cooldown * 0.7), max_cooldown * 1.3)


func _get_max_cooldown() -> int:
	return WeaponService.apply_structure_attack_speed_effects(stats.cooldown, player_index)


func is_big_reload_active(at_wave_begin: bool = false) -> bool:
	return not at_wave_begin and stats.additional_cooldown_every_x_shots != - 1 and _nb_shots_taken % stats.additional_cooldown_every_x_shots == 0


func _on_Range_body_entered(body: Node) -> void :
	_targets_in_range.push_back(body)
	var _error = body.connect("died", self, "on_target_died")


func _on_Range_body_exited(body: Node) -> void :
	_targets_in_range.erase(body)
	if _current_target.size() > 0 and body == _current_target[0]:
		_current_target.clear()
	body.disconnect("died", self, "on_target_died")


func on_target_died(target: Node, _args: Entity.DieArgs) -> void :
	_targets_in_range.erase(target)
	if _current_target.size() > 0 and target == _current_target[0]:
		_current_target.clear()


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void :
	if anim_name == "shoot" and not dead:
		_is_shooting = false
		_cooldown = _get_next_cooldown()
		_animation_player.playback_speed = 1.0
		_animation_player.play("idle")


func boost(boost_args: BoostArgs) -> void :
	if can_be_boosted:
		.boost(boost_args)
		_original_base_stats = base_stats
		base_stats = base_stats.duplicate()

		base_stats.damage *= 1.0 + boost_args.damage_boost / 100.0
		base_stats.max_range *= 1.0 + boost_args.range_boost / 100.0
		base_stats.cooldown -= base_stats.cooldown * (boost_args.attack_speed_boost / 100.0)
		reload_data()

		var reduced_cooldown = _get_max_cooldown() * (boost_args.attack_speed_boost / 100.0)
		_cooldown = max(0.0, _cooldown - reduced_cooldown)
		_boost_timer.start()


func boost_ended() -> void :
	.boost_ended()
	base_stats = _original_base_stats
	reload_data()


func _on_BoostTimer_timeout() -> void :
	boost_ended()
