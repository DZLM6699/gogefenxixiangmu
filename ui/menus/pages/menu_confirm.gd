class_name MenuConfirm
extends VBoxContainer

signal cancel_button_pressed


func init() -> void :
	$Buttons / ConfirmButton.grab_focus()


func _on_CancelButton_pressed() -> void :
	emit_signal("cancel_button_pressed")


func _on_ConfirmButton_pressed() -> void :
	
	get_tree().paused = false
	ProgressData.reset_dlc_resources_to_active_dlcs()
	var _error = get_tree().change_scene(MenuData.title_screen_scene)
