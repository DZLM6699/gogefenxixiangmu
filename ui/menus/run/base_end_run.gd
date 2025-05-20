class_name BaseEndRun
extends Control

onready var _title = $"%Title"
onready var _run_info = $"%RunInfo"
onready var _restart_button = $"%RestartButton"
onready var _new_run_button = $"%NewRunButton"
onready var _exit_button = $"%ExitButton"
onready var _popup_manager: PopupManager = $PopupManager

var _button_pressed: = false


func _ready() -> void :
	var diff_text = Text.text(ItemService.get_element(ItemService.difficulties, "", RunData.current_difficulty).name, [str(RunData.current_difficulty)])

	diff_text += " - " + tr("ENDLESS") if RunData.is_endless_run else ""
	diff_text += Utils.get_enemy_scaling_text(
		RunData.current_run_accessibility_settings.health, 
		RunData.current_run_accessibility_settings.damage, 
		RunData.current_run_accessibility_settings.speed, 
		RunData.retries, 
		RunData.is_coop_run
	)

	var wave_and_diff_text = Text.text("WAVE", [str(RunData.current_wave)]) + " - " + diff_text

	if RunData.run_won:
		_title.text = tr("RUN_WON") + " - " + tr(ZoneService.get_zone_data(RunData.current_zone).name)
		_run_info.text = diff_text if not RunData.is_endless_run else wave_and_diff_text
	else:
		_title.text = tr("RUN_LOST") + " - " + tr(ZoneService.get_zone_data(RunData.current_zone).name)
		_run_info.text = wave_and_diff_text


func _on_RestartButton_pressed() -> void :
	if _button_pressed:
		return
	_button_pressed = true
	RunData.reset(true)
	MusicManager.play(0)
	var _error = get_tree().change_scene(MenuData.game_scene)


func _on_NewRunButton_pressed() -> void :
	if _button_pressed:
		return
	_button_pressed = true
	for player_index in RunData.get_player_count():
		Utils.last_elt_selected[player_index] = RunData.get_player_character(player_index)
	RunData.reset()
	MusicManager.tween( - 5)
	var _error = get_tree().change_scene(MenuData.character_selection_scene)


func _on_ExitButton_pressed() -> void :
	if _button_pressed:
		return
	_button_pressed = true
	RunData.reset()
	var _error = get_tree().change_scene(MenuData.title_screen_scene)
