extends AnimatedSprite

signal finished(object)



func play(anim: String = "", backwards: bool = false) -> void :
	show()
	.play(anim, backwards)


func _on_HitEffect_animation_finished() -> void :
	hide()
	stop()
	frame = 0
	emit_signal("finished", self)
