class_name ChargingAttackBehavior
extends AttackBehavior

signal started_shooting
signal move_unlocked
signal entered_long_cooldown

enum TargetType{PLAYER, RAND_POINT_AROUND_PLAYER, RAND_POINT}
enum Timing{START_SHOOT, SHOOT}

export (float) var cooldown = 60.0
export (int) var long_cooldown_every_x_shoots = 0
export (float) var long_cooldown = 0.0
export (int) var max_cd_randomization = 10
export (int) var min_range = 0
export (int) var max_range = 300
export (float) var attack_anim_speed = 1.0
export (float) var charge_duration = 1.0
export (float) var charge_speed = 500.0
export (Timing) var target_calculation_timing = Timing.START_SHOOT
export (TargetType) var target = TargetType.PLAYER
export (int) var rand_target_size = - 1
export (bool) var only_positions_in_target_direction = false
export (bool) var scale_charge_duration_with_range = false

var _current_cd: float = cooldown
var _charge_direction: Vector2

var _unlock_move_timer: Timer
var _mass_multiplier: = 5
var _shots_taken: int = 0
var _original_mass: int


func _ready() -> void :
	_current_cd = get_cd()
	_unlock_move_timer = Timer.new()
	add_child(_unlock_move_timer)
	_unlock_move_timer.wait_time = charge_duration
	_unlock_move_timer.one_shot = true
	_unlock_move_timer.autostart = false
	var _error_timeout = _unlock_move_timer.connect("timeout", self, "on_unlock_move_timer_timeout")


func init(parent: Node) -> Node:
	.init(parent)
	_original_mass = _parent.mass
	return self


func reset() -> void :
	_current_cd = get_cd()
	_shots_taken = 0
	if _unlock_move_timer.time_left != 0:
		_unlock_move_timer.stop()
		on_unlock_move_timer_timeout()


func physics_process(delta: float) -> void :

	_current_cd = max(_current_cd - Utils.physics_one(delta), 0)

	if _current_cd <= 0 and Utils.is_between(_parent.global_position.distance_to(_parent.current_target.global_position), min_range, max_range):
		_parent._animation_player.playback_speed = attack_anim_speed
		_parent._animation_player.play(_parent.shoot_animation_name)


func start_shoot() -> void :
	emit_signal("started_shooting")
	if target_calculation_timing == Timing.START_SHOOT:
		set_target()

	_parent._can_move = false
	_parent.mass = _original_mass * _mass_multiplier


func set_target() -> void :
	if target == TargetType.PLAYER:
		_charge_direction = (_parent.current_target.global_position - _parent.global_position)

	elif target == TargetType.RAND_POINT_AROUND_PLAYER:
		var rand_size: int = (min(600, max_range / 5) if rand_target_size == - 1 else rand_target_size) as int
		var random_point: = Vector2(rand_range( - rand_size, rand_size), rand_range( - rand_size, rand_size))
		var target_direction = _parent.current_target.get_movement().normalized()

		if only_positions_in_target_direction and target_direction != Vector2.ZERO:
			var cone_half_angle = deg2rad(180 / 2.0)
			var random_angle = rand_range( - cone_half_angle, cone_half_angle)
			var rotated_direction = target_direction.rotated(random_angle)
			var random_distance = rand_range(rand_size / 4.0, rand_size)
			random_point = rotated_direction * random_distance

		var direction_to_player: Vector2 = _parent.global_position.direction_to(_parent.current_target.global_position)
		var move_behind_player: Vector2 = direction_to_player * rand_size
		var target_pos: Vector2 = _parent.current_target.global_position + move_behind_player + random_point

		_charge_direction = (target_pos - _parent.global_position)

		if scale_charge_duration_with_range:
			_unlock_move_timer.wait_time = charge_duration + _charge_direction.length() / 250.0 / 60.0

	else:
		var target_pos: Vector2 = Vector2(
			rand_range(_parent._min_pos.x, _parent._max_pos.x), 
			rand_range(_parent._min_pos.y, _parent._max_pos.y)
		)
		_charge_direction = (target_pos - _parent.global_position)


func shoot() -> void :

	if target_calculation_timing == Timing.SHOOT:
		set_target()

	_parent._can_move = true
	_parent._move_locked = true
	_parent.bonus_speed = charge_speed * RunData.current_run_accessibility_settings.speed
	_parent._current_movement = _charge_direction
	_unlock_move_timer.start()
	_shots_taken += 1
	_current_cd = get_cd() + charge_duration * 60


func on_unlock_move_timer_timeout() -> void :
	_parent.bonus_speed = 0
	_parent._animation_player.playback_speed = _parent._idle_playback_speed
	_parent.mass = _original_mass
	if _parent._move_locked:
		_parent._move_locked = false
		emit_signal("move_unlocked")


func animation_finished(anim_name: String) -> void :
	if anim_name == "shoot":
		_parent._animation_player.playback_speed *= 2


func get_cd() -> float:

	if long_cooldown_every_x_shoots != 0 and _shots_taken >= long_cooldown_every_x_shoots:
		_shots_taken = 0
		emit_signal("entered_long_cooldown")
		return long_cooldown

	return rand_range(max(1, cooldown - max_cd_randomization), cooldown + max_cd_randomization)
