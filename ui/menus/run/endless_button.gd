class_name EndlessButton
extends CheckButton


func _ready() -> void :
	var _e = connect("toggled", self, "_on_toggled")
	pressed = ProgressData.settings.endless_mode_toggled
	RunData.is_endless_run = ProgressData.settings.endless_mode_toggled


func _on_toggled(button_pressed: bool) -> void :
	RunData.is_endless_run = button_pressed
	ProgressData.settings.endless_mode_toggled = button_pressed
