class_name MenuEndRun
extends VBoxContainer

signal cancel_button_pressed

var confirm_button_pressed = false


func init() -> void :
	$Buttons / ConfirmButton.grab_focus()


func _on_CancelButton_pressed() -> void :
	emit_signal("cancel_button_pressed")


func _on_ConfirmButton_pressed() -> void :
	if confirm_button_pressed:
		return

	confirm_button_pressed = true
	RunData.apply_end_run()
