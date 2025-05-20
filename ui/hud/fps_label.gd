class_name FPSLabel
extends Label


func _process(_delta):
	if not visible:
		return

	set_text("FPS: " + str(Engine.get_frames_per_second()))
