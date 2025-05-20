class_name TargetRandPosAroundPlayerMovementBehavior
extends MovementBehavior

export (int) var range_around_player = 300
export (int) var range_randomization = 100
export (int) var update_every_x_frames = - 1

var _actual: int
var _current_target: Vector2 = Vector2.ZERO

var current_check_update: float = 0.0


func init(parent: Node) -> Node:
	var _init = .init(parent)
	_actual = range_around_player + rand_range( - range_randomization, range_randomization)
	return self


func _physics_process(delta: float) -> void :
	if update_every_x_frames != - 1:
		current_check_update += Utils.physics_one(delta)


func get_movement() -> Vector2:
	if (update_every_x_frames != - 1 and current_check_update >= update_every_x_frames) or _current_target == Vector2.ZERO or Utils.vectors_approx_equal(_current_target, _parent.global_position, EQUALITY_PRECISION):
		current_check_update = 0.0
		_current_target = get_new_target()

	return _current_target - _parent.global_position


func get_target_position():
	return _current_target


func get_new_target() -> Vector2:
	var new_target = _parent.current_target.global_position + Vector2(rand_range( - _actual, _actual), rand_range( - _actual, _actual))

	new_target.x = clamp(new_target.x, _parent._min_pos.x, _parent._max_pos.x)
	new_target.y = clamp(new_target.y, _parent._min_pos.y, _parent._max_pos.y)

	return new_target
