class_name PooledParticles
extends CPUParticles2D

onready var _finished_timer: Timer = $"%FinishedTimer"


signal finished(object)


func _ready():
	var _error: = _finished_timer.connect("timeout", self, "_on_FinishedTimer_timeout")


func restart() -> void :
	show()
	_finished_timer.start()
	.restart()


func _on_FinishedTimer_timeout() -> void :
	emit_signal("finished", self)
