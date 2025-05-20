extends Control

enum State{READY, BOOT_SPLASH, HIDE_SCENE, CHANGE_SCENE}
var state = State.READY

var ready_for_main_menu: = false


func _init() -> void :
	var _ready_error = ProgressData.connect("ready", self, "_on_progress_data_ready")
	var _recreate_error = ProgressData.connect("recreate_savegame_finished", self, "_on_recreate_savegame_finished")


func _process(_delta: float):
	match state:
		State.READY:
			
			pass
		State.BOOT_SPLASH:
			if ready_for_main_menu:
				state = State.HIDE_SCENE
		State.HIDE_SCENE:
			
			$BlackRect.visible = true
			state = State.CHANGE_SCENE
		State.CHANGE_SCENE:
			ProgressData.apply_settings()
			var _error = get_tree().change_scene("res://ui/menus/title_screen/title_screen.tscn")


func _draw():
	
	if state == State.READY:
		state = State.BOOT_SPLASH


func _on_progress_data_ready() -> void :
	if not ProgressData.load_status in [LoadStatus.CORRUPTED_ALL_SAVES_EPIC, LoadStatus.CORRUPTED_ALL_SAVES_STEAM]:
		ready_for_main_menu = true


func _on_recreate_savegame_finished() -> void :
	ready_for_main_menu = true
