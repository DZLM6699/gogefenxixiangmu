
extends CPUParticles2D
class_name RunningSmoke

export (bool) var take_background_color = true


func _ready() -> void :
	if take_background_color:
		color = RunData.get_background().outline_color


func emit() -> void :
	emitting = true


func stop() -> void :
	emitting = false
