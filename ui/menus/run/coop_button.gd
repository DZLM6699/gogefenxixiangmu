class_name CoopButton
extends CheckButton

signal coop_initialized(active)


func init() -> void :
	pressed = ProgressData.settings.coop_mode_toggled
	
	
	var _e = connect("toggled", self, "_on_toggled")


func _on_toggled(button_pressed: bool) -> void :
	ProgressData.settings.coop_mode_toggled = button_pressed
	emit_signal("coop_initialized", button_pressed)
