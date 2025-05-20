class_name FollowPlayerMovementBehavior
extends MovementBehavior


func get_movement() -> Vector2:
	return get_target_position() - _parent.global_position


func get_target_position():
	if not is_instance_valid(_parent.current_target):
		return global_position
	return _parent.current_target.global_position
