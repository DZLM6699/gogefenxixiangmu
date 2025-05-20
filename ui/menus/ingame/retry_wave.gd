class_name MenuRetryWave
extends VBoxContainer

var confirm_button_pressed = false
var cancel_button_pressed = false

onready var _focus_emulator = $FocusEmulator
onready var _confirm_button = $Buttons / ConfirmButton


func _ready() -> void :
	_focus_emulator.set_process_input(false)


func show() -> void :
	.show()
	_confirm_button.grab_focus()
	_focus_emulator.set_process_input(true)


func _on_CancelButton_pressed() -> void :
	if cancel_button_pressed:
		return
	cancel_button_pressed = true
	DebugService.log_data("end run...")
	var scene = RunData.get_end_run_scene_path()
	_change_scene(scene)


func _on_ConfirmButton_pressed() -> void :
	if confirm_button_pressed:
		return
	confirm_button_pressed = true

	RunData.reset_to_start_wave_state()
	RunData.retries += 1
	_change_scene(MenuData.game_scene)


func _change_scene(path: String) -> void :
	var _error = get_tree().change_scene(path)
