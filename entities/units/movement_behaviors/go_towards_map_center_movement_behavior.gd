class_name GoTowardsMapCenterMovementBehavior
extends MovementBehavior


func get_movement() -> Vector2:
	return get_target_position() - _parent.global_position


func get_target_position():
	return ZoneService.get_map_center()
