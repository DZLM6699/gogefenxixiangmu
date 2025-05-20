class_name DetectTargetMovementBehavior
extends MovementBehavior

signal detected_player

export (int) var detection_range = 300
export (int) var speed_bonus_on_target_detection = 300

var movement_behavior_before_target_detection: MovementBehavior
var movement_behavior_after_target_detection: MovementBehavior
var current_movement_behavior: MovementBehavior

var _detected_player: bool = false
var _current_target: Vector2 = Vector2.ZERO


func init(parent: Node) -> Node:
	var _init = .init(parent)
	movement_behavior_before_target_detection = $MovementBehaviorBeforeTargetDetection
	var _e = movement_behavior_before_target_detection.init(parent)
	movement_behavior_after_target_detection = $MovementBehaviorAfterTargetDetection
	_e = movement_behavior_after_target_detection.init(parent)
	current_movement_behavior = movement_behavior_before_target_detection
	return self


func set_detected(is_detected: bool) -> void :
	_detected_player = is_detected
	if _detected_player:
		current_movement_behavior = movement_behavior_after_target_detection
	else:
		current_movement_behavior = movement_behavior_before_target_detection


func get_movement() -> Vector2:

	if _parent.current_target.global_position.distance_to(_parent.global_position) <= detection_range and not _detected_player:
		emit_signal("detected_player")
		_parent.bonus_speed += speed_bonus_on_target_detection * RunData.current_run_accessibility_settings.speed
		_detected_player = true
		current_movement_behavior = movement_behavior_after_target_detection

	return current_movement_behavior.get_movement()


func get_target_position():
	return current_movement_behavior.get_target_position()
