class_name PlayerMovementBehavior
extends MovementBehavior

const MIN_MOVE_DIST = 20

var device: = 0


func get_movement() -> Vector2:
	var movement: Vector2 = Vector2.ZERO

	if ProgressData.settings.mouse_only and not RunData.is_coop_run:
		var mouse_pos = get_global_mouse_position()
		movement = Vector2(mouse_pos.x - _parent.global_position.x, mouse_pos.y - _parent.global_position.y)

		if (abs(movement.x) < MIN_MOVE_DIST and abs(movement.y) < MIN_MOVE_DIST) or Input.is_mouse_button_pressed(BUTTON_LEFT):
			movement = Vector2.ZERO
	else:
		if RunData.is_coop_run:
			movement = Input.get_vector(
				"move_left_%s" % device, 
				"move_right_%s" % device, 
				"move_up_%s" % device, 
				"move_down_%s" % device
			)

		else:
			movement = Input.get_vector(
				"move_left", 
				"move_right", 
				"move_up", 
				"move_down"
			)

	return movement
