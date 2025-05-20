extends Boss


func on_state_changed(new_state: int) -> void :
	.on_state_changed(new_state)

	if new_state == 0:
		reset_speed_stat( - 25)
	elif new_state == 1:
		reset_speed_stat( - 40)
