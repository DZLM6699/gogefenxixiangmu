extends Control


var _players_to_join: = []

onready var _progress_bar: UIProgressBar = $"%UIProgressBar"
onready var _player_label = $"%CoopPlayerLabel"
onready var _player_info_container = $"%PlayerInfoContainer"
onready var _gold_icon = $"%GoldIcon"
onready var _gold_label = $"%GoldLabel"
onready var _player_gear_container = $"%PlayerGearContainer"


func _ready() -> void :
	_progress_bar.modulate.a = 0.0
	CoopService.listening_for_inputs = true
	for player_index in RunData.get_player_count():
		_players_to_join.push_back(player_index)
	
	var _error = CoopService.connect("connected_players_updated", self, "_on_connected_players_updated")
	_error = CoopService.connect("connection_progress_updated", self, "_on_connection_progress_updated")
	_setup_next_player()
	CoopService.set_process_input(true)


func _exit_tree() -> void :
	CoopService.set_process_input(false)


func _input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel"):
		var _error = get_tree().change_scene(MenuData.title_screen_scene)


func _setup_next_player() -> void :
	if _players_to_join.empty():
		CoopService.listening_for_inputs = false
		var _error = get_tree().change_scene("res://ui/menus/shop/coop_shop.tscn")
		return

	var player_index = _players_to_join.pop_front()
	_update_player_index(player_index)


func _update_player_index(player_index: int) -> void :
	_player_label.player_index = player_index
	var items = RunData.get_player_items(player_index)
	var weapons = RunData.get_player_weapons(player_index)
	_player_gear_container.set_items_data(items)
	_player_gear_container.set_weapons_data(weapons)
	_gold_label.update_value(RunData.get_player_gold(player_index))

	var player_color = CoopService.get_player_color(player_index)
	_gold_icon.modulate = player_color
	_gold_label.add_color_override("font_color", player_color)

	var stylebox = _player_info_container.get_stylebox("panel").duplicate()
	CoopService.change_stylebox_for_player(stylebox, player_index)
	_player_info_container.add_stylebox_override("panel", stylebox)


func _on_connected_players_updated(_connected_players: Array) -> void :
	_setup_next_player()


func _on_connection_progress_updated(connection_progress: Array) -> void :
	var progress = 0.0 if connection_progress.empty() else connection_progress.front()
	_progress_bar.modulate.a = 1.0 if progress > 0.0 else 0.0
	_progress_bar.value = progress
