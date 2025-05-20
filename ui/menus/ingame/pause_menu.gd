class_name PauseMenu
extends PanelContainer

signal paused
signal unpaused


var _player_index: = 0
var enabled: = true

onready var menu_general_options = $Menus / MenuGeneralOptions
onready var menu_gameplay_options = $Menus / MenuGameplayOptions
onready var _main_menu = $Menus / MainMenu
onready var _menus = $Menus
onready var _focus_emulator: FocusEmulator = $FocusEmulator


func _ready() -> void :
	var _error = _main_menu.connect("resume_button_pressed", self, "on_resume_button_pressed")
	_focus_emulator.player_index = - 1
	set_process_input(false)
	_focus_emulator.set_process_input(false)


func init() -> void :
	_player_index = 0
	_main_menu.init(0)


func _input(event: InputEvent) -> void :
	if get_tree().paused:
		if Utils.is_player_cancel_pressed(event, _player_index) or Utils.is_player_pause_pressed(event, _player_index):
			manage_back()
			get_viewport().set_input_as_handled()


func manage_back() -> void :
	if _main_menu.visible:
		unpause()
	else:
		_menus.back()


func unpause() -> void :
	set_process_input(false)
	_focus_emulator.set_process_input(false)
	_focus_emulator.player_index = - 1
	hide()
	get_tree().paused = false
	_menus.reset()
	emit_signal("unpaused")


func pause(player_index: int) -> void :
	set_process_input(true)
	_focus_emulator.set_process_input(true)
	if not enabled:
		return
	_player_index = player_index
	_focus_emulator.player_index = player_index
	
	
	get_tree().paused = true
	emit_signal("paused")
	show()
	_main_menu.init(player_index)


func on_resume_button_pressed() -> void :
	unpause()


func on_game_lost_focus() -> void :
	if not get_tree().paused and ProgressData.settings.pause_on_focus_lost:
		_player_index = 0
		pause(0)
