class_name PatrolEdgesOfMapMovementBehavior
extends MovementBehavior

export (int) var edge_distance = 300
export (int) var edge_randomization = 100
export (int) var max_target_distance = 300

var _actual: int
var _current_target: Vector2 = Vector2.ZERO


func init(parent: Node) -> Node:
	var _init = .init(parent)
	_actual = edge_distance + rand_range( - edge_randomization, edge_randomization)
	return self






func get_movement() -> Vector2:
	if _current_target == Vector2.ZERO or Utils.vectors_approx_equal(_current_target, _parent.global_position, EQUALITY_PRECISION):
		_current_target = get_new_target()

	return _current_target - _parent.global_position


func get_target_position():
	return _current_target


func get_new_target() -> Vector2:
	var direction = Utils.get_direction_from_pos(_parent.global_position, _parent._min_pos, _parent._max_pos, _actual)
	var new_target = Utils.get_rand_pos_from_direction_within_distance(direction, _parent._min_pos, _parent._max_pos, _actual)

	var actual_target = _parent.global_position.direction_to(new_target).normalized() * max_target_distance

	actual_target.x = clamp(new_target.x, _parent._min_pos.x, _parent._max_pos.x)
	actual_target.y = clamp(new_target.y, _parent._min_pos.y, _parent._max_pos.y)

	return actual_target
