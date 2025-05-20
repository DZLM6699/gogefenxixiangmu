extends Node

signal connected_players_updated(connected_players)
signal connection_progress_updated(progress_values)

export (float, 0.0, 1.0, 0.01) var additional_enemies_per_coop_player: = 0.0
export (float, 0.0, 1.0, 0.01) var additional_enemy_health_per_coop_player: = 0.0
export (float, 0.0, 1.0, 0.01) var additional_enemy_damage_per_coop_player: = 0.0

export (Texture) var keyboard_ui_accept_icon
export (Texture) var gamepad_xbox_ui_accept_icon
export (Texture) var gamepad_playstation_ui_accept_icon
export (Texture) var gamepad_switch_ui_accept_icon
export (Texture) var keyboard_ui_select_icon
export (Texture) var gamepad_xbox_ui_select_icon
export (Texture) var gamepad_playstation_ui_select_icon
export (Texture) var gamepad_switch_ui_select_icon
export (Texture) var keyboard_ui_info_icon
export (Texture) var gamepad_xbox_ui_info_icon
export (Texture) var gamepad_playstation_ui_info_icon
export (Texture) var gamepad_switch_ui_info_icon
export (Texture) var gamepad_ltrigger_icon
export (Texture) var gamepad_rtrigger_icon
export (Array, Color) var player_colors: = [
	Color("a1fced"), 
	Color("f2ad87"), 
	Color("a9fca1"), 
	Color("fcf08f")
]

const REMAP_END: = 8
const GAMEPAD_REMAPPED_DEVICE_ID: = 6
const KEYBOARD_REMAPPED_DEVICE_ID: = 7
const MAX_PLAYER_COUNT: = 4
const FIRST_DEBUG_DEVICE_ID: = 8
const DEBUG_DEVICE_COUNT: = 4
const HOLD_DURATION: = 0.7

enum PlayerType{KEYBOARD_AND_MOUSE, GAMEPAD_XBOX, GAMEPAD_PLAYSTATION, GAMEPAD_SWITCH}


var connected_players: = []
var connection_progress: = []
var listening_for_inputs: bool = false

var _hold_timers: = {}


func _ready() -> void :
	var _err = Input.connect("joy_connection_changed", self, "_on_Input_joy_connection_changed")
	set_process_input(false)


func _input(event: InputEvent) -> void :
	var device_to_add = event.device
	if event.device == 0:
		
		device_to_add = GAMEPAD_REMAPPED_DEVICE_ID if event is InputEventJoypadButton else KEYBOARD_REMAPPED_DEVICE_ID

	if event is InputEventKey and DebugService.coop_multiple_keyboard_inputs:
		var debug_device = _get_next_free_debug_device()
		if debug_device >= 0:
			device_to_add = debug_device

	if event.is_action_pressed("ui_accept_%s" % device_to_add) and not _hold_timers.has(device_to_add):
		_hold_timers[device_to_add] = 0.0
		set_process(true)


func _process(delta: float) -> void :
	var max_timer_before: = 0.0
	for timer in _hold_timers:
		max_timer_before = max(max_timer_before, timer)

	if not listening_for_inputs or not _can_add_new_device():
		_hold_timers.clear()

	for device in _hold_timers.keys():
		if not Input.is_action_pressed("ui_accept_%s" % device) or is_device_assigned(device):
			var _erased = _hold_timers.erase(device)
			continue
		_hold_timers[device] += delta
		if _hold_timers[device] < HOLD_DURATION:
			continue
		
		var _erased = _hold_timers.erase(device)
		
		_update_connection_progress()
		var unmapped_device = 0 if device == GAMEPAD_REMAPPED_DEVICE_ID or device == KEYBOARD_REMAPPED_DEVICE_ID else device
		var joy_name = Input.get_joy_name(unmapped_device)
		var joy_name_components = joy_name.to_lower().split(" ")
		if device == KEYBOARD_REMAPPED_DEVICE_ID or joy_name.empty():
			_add_player(device, PlayerType.KEYBOARD_AND_MOUSE)
		elif "ps4" in joy_name_components or "ps5" in joy_name_components or "playstation" in joy_name_components:
			_add_player(device, PlayerType.GAMEPAD_PLAYSTATION)
		elif "nintendo" in joy_name_components or "switch" in joy_name_components:
			_add_player(device, PlayerType.GAMEPAD_SWITCH)
		else:
			_add_player(device, PlayerType.GAMEPAD_XBOX)
		break

	_update_connection_progress()
	if _hold_timers.empty():
		set_process(false)

const ADDITIONAL_MATERIALS_FACTOR: = 0.8

func get_additional_materials_per_coop_player() -> float:
	var nb_players = RunData.get_player_count()

	if nb_players == 1:
		return 0.0

	var nb_enemies = 1.0 + (additional_enemies_per_coop_player * (nb_players - 1))
	return (((nb_players / nb_enemies) - 1.0) / (nb_players - 1)) * ADDITIONAL_MATERIALS_FACTOR


func get_coop_materials_factor() -> float:
	return get_additional_materials_per_coop_player() * (RunData.get_player_count() - 1)


func clear() -> void :
	listening_for_inputs = false
	clear_coop_players()


func clear_coop_players() -> void :
	connected_players.clear()
	emit_signal("connected_players_updated", connected_players)


func change_stylebox_for_player(stylebox: StyleBoxFlat, player_index: int) -> void :
	var background_value = stylebox.bg_color.v
	stylebox.border_color = get_player_color(player_index, 1)

	var player_color = get_player_color(player_index, clamp(background_value, 0.2, 0.75))
	var a = stylebox.bg_color.a
	stylebox.bg_color = stylebox.bg_color.linear_interpolate(player_color, 0.7)
	stylebox.bg_color.a = a


func get_player_color(player_index: int, value: = 1.0) -> Color:
	var c = player_colors[player_index]
	c.s = min(c.s + 0.5, 1.0)
	c.v = min(c.v * value, 1.0)
	return c



func get_remapped_player_device(player_index: int) -> int:
	if player_index < 0 or player_index >= len(connected_players):
		return - 1
	return connected_players[player_index][0]


func is_player_using_gamepad(player_index: int) -> bool:
	if player_index < 0 or player_index >= len(connected_players):
		return false
	return get_player_input_type(player_index) != PlayerType.KEYBOARD_AND_MOUSE


func get_player_key_texture(action: String, player_index: int) -> Texture:
	if player_index < 0 or player_index >= len(connected_players):
		return null
	var input_type = get_player_input_type(player_index)
	return get_input_type_key_texture(action, input_type)


func get_input_type_key_texture(action: String, input_type: int) -> Texture:
	if action == "ui_accept":
		match input_type:
			PlayerType.KEYBOARD_AND_MOUSE:
				return keyboard_ui_accept_icon
			PlayerType.GAMEPAD_XBOX:
				return gamepad_xbox_ui_accept_icon
			PlayerType.GAMEPAD_PLAYSTATION:
				return gamepad_playstation_ui_accept_icon
			PlayerType.GAMEPAD_SWITCH:
				return gamepad_switch_ui_accept_icon
	elif action == "ui_select":
		match input_type:
			PlayerType.KEYBOARD_AND_MOUSE:
				return keyboard_ui_select_icon
			PlayerType.GAMEPAD_XBOX:
				return gamepad_xbox_ui_select_icon
			PlayerType.GAMEPAD_PLAYSTATION:
				return gamepad_playstation_ui_select_icon
			PlayerType.GAMEPAD_SWITCH:
				return gamepad_switch_ui_select_icon
	elif action == "ui_info":
		match input_type:
			PlayerType.KEYBOARD_AND_MOUSE:
				return keyboard_ui_info_icon
			PlayerType.GAMEPAD_XBOX:
				return gamepad_xbox_ui_info_icon
			PlayerType.GAMEPAD_PLAYSTATION:
				return gamepad_playstation_ui_info_icon
			PlayerType.GAMEPAD_SWITCH:
				return gamepad_switch_ui_info_icon
	elif action == "ltrigger":
		if input_type != PlayerType.KEYBOARD_AND_MOUSE:
			return gamepad_ltrigger_icon
	elif action == "rtrigger":
		if input_type != PlayerType.KEYBOARD_AND_MOUSE:
			return gamepad_rtrigger_icon
	return null


func get_player_input_type(player_index: int) -> int:
	return connected_players[player_index][1]


func _add_player(device: int, player_type: int) -> void :
	if is_device_assigned(device):
		return
	connected_players.push_back([device, player_type])
	emit_signal("connected_players_updated", connected_players)


func _update_connection_progress() -> void :
	connection_progress = _hold_timers.values()
	
	connection_progress.sort()
	connection_progress.invert()
	for i in connection_progress.size():
		connection_progress[i] = min(connection_progress[i] / HOLD_DURATION, 1.0)
	emit_signal("connection_progress_updated", connection_progress)


func is_device_assigned(device: int) -> bool:
	for player in connected_players:
		if player[0] == device:
			return true

	return false


func _can_add_new_device() -> bool:
	return len(connected_players) < MAX_PLAYER_COUNT


func _get_next_free_debug_device() -> int:
	for device_id in range(FIRST_DEBUG_DEVICE_ID, FIRST_DEBUG_DEVICE_ID + DEBUG_DEVICE_COUNT):
		if not is_device_assigned(device_id):
			return device_id

	return - 1


func _on_Input_joy_connection_changed(device: int, connected: bool) -> void :
	
	if connected or not listening_for_inputs:
		return
	if device == 0:
		device = GAMEPAD_REMAPPED_DEVICE_ID
	for player_index in connected_players.size():
		var player = connected_players[player_index]
		if player[0] != device:
			continue
		connected_players.remove(player_index)
		emit_signal("connected_players_updated", connected_players)
		break
