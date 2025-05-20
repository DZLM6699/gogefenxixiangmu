class_name StayInRangeFromPlayerMovementBehavior
extends MovementBehavior

export (int) var target_range = 300
export (int) var target_range_randomization = 100

var _actual_target_range: float


func _ready() -> void :
	_actual_target_range = target_range + rand_range( - target_range_randomization, target_range_randomization)


func get_movement() -> Vector2:
	var target_position = get_target_position()
	if Utils.vectors_approx_equal(target_position, _parent.global_position, EQUALITY_PRECISION):
		return Vector2.ZERO
	else:
		return target_position - _parent.global_position


func get_target_position():
	var dir = (_parent.global_position - _parent.current_target.global_position).normalized()
	return _parent.current_target.global_position + _actual_target_range * dir
