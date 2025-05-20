extends PanelContainer

const EMPTY_INNER_COLOR = Color(0.33, 0.33, 0.33)

export  var player_index: = 0

var instructions_visible setget _set_instructions_visible, _get_instructions_visible
func _set_instructions_visible(value):
	_coop_join_instructions.visible = value
func _get_instructions_visible():
	return _coop_join_instructions.visible

onready var _coop_join_instructions: Control = $"%CoopJoinInstructions"
onready var _coop_join_progress: CoopJoinProgress = $"%CoopJoinProgress"


func _ready():
	_coop_join_instructions.visible = false
	_coop_join_progress.visible = false
	_reset_join_progress()


func update_indicators(connected_players: Array, connection_progress: Array) -> void :
	
	var are_main_join_instructions_showing: = connected_players.empty()
	
	var is_panel_for_next_player: = player_index == connected_players.size() + connection_progress.size()
	_coop_join_instructions.visible = not are_main_join_instructions_showing and is_panel_for_next_player
	var join_progress: = _coop_join_progress
	var connection_progress_index: = player_index - connected_players.size()
	var is_player_connecting: = player_index >= connected_players.size() and connection_progress.size() > connection_progress_index
	if is_player_connecting:
		join_progress.show()
		join_progress.progress = connection_progress[connection_progress_index] * 100.0
		join_progress.inner_color = CoopService.get_player_color(player_index, 0.4)
	else:
		join_progress.hide()
		_reset_join_progress()


func _reset_join_progress() -> void :
	var join_progress = _coop_join_progress
	join_progress.progress = 0.0
	join_progress.text = ""
	join_progress.progress_color = CoopService.get_player_color(player_index)
	join_progress.inner_color = EMPTY_INNER_COLOR
