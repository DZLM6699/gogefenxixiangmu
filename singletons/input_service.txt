extends Node

signal game_lost_focus
signal game_regained_focus

const MAX_DEVICE_COUNT: = 8


var using_gamepad = false
var hide_mouse: = true setget _set_hide_mouse
func _set_hide_mouse(value: bool) -> void :
	hide_mouse = value
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN if hide_mouse else Input.MOUSE_MODE_VISIBLE)

var joystick_deadzone: = 0.5

var _echo_delay: = 0.3
var _echo_interval: = 0.09
var _dpad_timers: = {}
var _joystick_timers: = {}


func _ready() -> void :
	pause_mode = Node.PAUSE_MODE_PROCESS
	var _input_connect = Input.connect("joy_connection_changed", self, "on_joy_connection_changed")

	if ProgressData.settings.movement_with_gamepad:
		enable_gamepad_movement()
	else:
		disable_gamepad_movement()

	set_gamepad_echo_processing(true)


func _input(event: InputEvent) -> void :
	if BugReporter.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return

	if RunData.is_coop_run and RunData.get_player_count() > 1:
		
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		return

	var is_gamepad_input = event is InputEventJoypadButton or Utils.is_valid_joypad_motion_event(event)
	var is_keyboard_input = (event is InputEventKey)

	if hide_mouse and (is_gamepad_input or is_keyboard_input):
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	elif event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if is_gamepad_input:
		using_gamepad = true
	elif is_keyboard_input:
		using_gamepad = false


func disable_gamepad_movement() -> void :
	InputMap.load_from_globals()
	_copy_device_actions()

	for action in InputMap.get_actions():
		var actions_to_disable: = ["move_left", "move_right", "move_up", "move_down", "rjoy_left", "rjoy_right", "rjoy_up", "rjoy_down"]
		if action in actions_to_disable:
			for input_event in InputMap.get_action_list(action):
				if input_event is InputEventJoypadButton or input_event is InputEventJoypadMotion:
					InputMap.action_erase_event(action, input_event)


func enable_gamepad_movement() -> void :
	InputMap.load_from_globals()
	_copy_device_actions()


func on_joy_connection_changed(_device: int, connected: bool) -> void :
	set_gamepad_echo_processing(true)
	if not connected:
		emit_signal("game_lost_focus")


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
		if ProgressData.settings.mute_on_focus_lost:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(0.0))
		emit_signal("game_lost_focus")
	elif what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear2db(ProgressData.settings.volume.master ))
		emit_signal("game_regained_focus")


func set_gamepad_echo_processing(enable: bool) -> void :
	if enable and Input.get_connected_joypads().size() > 0:
		set_process(true)
	else:
		set_process(false)


func _process(delta: float) -> void :
	
	for device in _dpad_timers.keys():
		var is_any_input_pressed = false
		for input in _d_pad_button_range():
			if _is_input_pressed(device, input, "button"):
				is_any_input_pressed = true
				break
		if not is_any_input_pressed:
			var _erased = _dpad_timers.erase(device)

	for device in _joystick_timers.keys():
		var is_any_input_pressed = false
		for input in [JOY_AXIS_0, JOY_AXIS_1]:
			if _is_input_pressed(device, input, "axis"):
				is_any_input_pressed = true
				break
		if not is_any_input_pressed:
			var _erased = _joystick_timers.erase(device)

	_process_input_timers(delta, _d_pad_button_range(), funcref(self, "_on_dpad_timer_timeout"), "button")
	_process_input_timers(delta, [JOY_AXIS_0, JOY_AXIS_1], funcref(self, "_on_joystick_timer_timeout"), "axis")


func _process_input_timers(delta: float, input_range: Array, timeout_callback: FuncRef, input_type: String) -> void :
	var timers = _dpad_timers if input_type == "button" else _joystick_timers

	
	for device in timers.keys():
		var timer = timers[device]
		timer.try_advance(delta)
		if not timer.completed():
			continue
		timeout_callback.call_func(device)
		var _erased = timers.erase(device)
		for input in input_range:
			if not _is_input_pressed(device, input, input_type):
				continue
			
			timer.wait_time = _echo_interval
			timer.start()
			timers[device] = timer
			break

	
	for device in MAX_DEVICE_COUNT:
		if timers.has(device):
			continue
		for input in input_range:
			if _is_input_pressed(device, input, input_type):
				var timer: = FixedTimer.new()
				timer.wait_time = _echo_delay
				timer.start()
				timers[device] = timer
				if input_type == "axis":
					
					timeout_callback.call_func(device)
				break


func _is_input_pressed(device: int, input, input_type: String) -> bool:
	if input_type == "axis":
		return abs(Input.get_joy_axis(device, input)) > joystick_deadzone
	else:
		return Input.is_joy_button_pressed(device, input)


func _d_pad_button_range() -> Array:
	return range(12, 16)


func _on_dpad_timer_timeout(device: int) -> void :
	_emulate_action(device, 12, "ui_up")
	_emulate_action(device, 13, "ui_down")
	_emulate_action(device, 14, "ui_left")
	_emulate_action(device, 15, "ui_right")


func _on_joystick_timer_timeout(device: int) -> void :
	if abs(Input.get_joy_axis(device, JOY_AXIS_0)) > joystick_deadzone:
		_emulate_action(device, JOY_AXIS_0, "ui_right" if Input.get_joy_axis(device, JOY_AXIS_0) > 0 else "ui_left")
	elif abs(Input.get_joy_axis(device, JOY_AXIS_1)) > joystick_deadzone:
		_emulate_action(device, JOY_AXIS_1, "ui_down" if Input.get_joy_axis(device, JOY_AXIS_1) > 0 else "ui_up")


func _emulate_action(device: int, input, action: String) -> void :
	var input_type = "axis" if input in [JOY_AXIS_0, JOY_AXIS_1] else "button"
	if not _is_input_pressed(device, input, input_type):
		return

	var remapped_device = device if device > 0 else CoopService.GAMEPAD_REMAPPED_DEVICE_ID
	var suffix = ("_%s" % remapped_device) if CoopService.is_device_assigned(remapped_device) else ""

	var a = InputEventAction.new()
	a.action = action + suffix
	a.device = device
	a.pressed = true
	Input.parse_input_event(a)


func _copy_device_actions():
	_set_bug_report_key()

	var action_names = InputMap.get_actions()
	for action_name in action_names:
		var action_events = InputMap.get_action_list(action_name)
		var deadzone = InputMap.action_get_deadzone(action_name)
		for event in action_events:
			
			
			

			if event is InputEventJoypadButton:
				for remapped_device in range(0, CoopService.REMAP_END):
					var new_event = InputEventJoypadButton.new()
					new_event.device = 0 if remapped_device == CoopService.GAMEPAD_REMAPPED_DEVICE_ID else remapped_device
					new_event.button_index = event.button_index
					new_event.pressed = event.pressed
					add_action(action_name, remapped_device, deadzone, new_event)

			elif event is InputEventJoypadMotion:
				for remapped_device in range(0, CoopService.REMAP_END):
					var new_event = InputEventJoypadMotion.new()
					new_event.device = 0 if remapped_device == CoopService.GAMEPAD_REMAPPED_DEVICE_ID else remapped_device
					new_event.axis = event.axis
					new_event.axis_value = event.axis_value
					add_action(action_name, remapped_device, deadzone, new_event)

			elif event is InputEventKey:
				for remapped_device in range(0, CoopService.REMAP_END):
					var device = 0 if remapped_device == CoopService.KEYBOARD_REMAPPED_DEVICE_ID else remapped_device
					add_key_action(action_name, remapped_device, device, event)

	if DebugService.coop_multiple_keyboard_inputs:
		var debug_device_id = CoopService.FIRST_DEBUG_DEVICE_ID
		var debug_key_mappings = {
			KEY_W: [debug_device_id, "up"], 
			KEY_A: [debug_device_id, "left"], 
			KEY_S: [debug_device_id, "down"], 
			KEY_D: [debug_device_id, "right"], 
			KEY_E: [debug_device_id, "accept"], 
			KEY_Q: [debug_device_id, "pause"], 
			KEY_Z: [debug_device_id, "cancel"], 
			KEY_X: [debug_device_id, "info"], 
			KEY_C: [debug_device_id, "select"], 
			KEY_T: [debug_device_id + 1, "up"], 
			KEY_F: [debug_device_id + 1, "left"], 
			KEY_G: [debug_device_id + 1, "down"], 
			KEY_H: [debug_device_id + 1, "right"], 
			KEY_Y: [debug_device_id + 1, "accept"], 
			KEY_R: [debug_device_id + 1, "pause"], 
			KEY_V: [debug_device_id + 1, "cancel"], 
			KEY_B: [debug_device_id + 1, "info"], 
			KEY_N: [debug_device_id + 1, "select"], 
			KEY_I: [debug_device_id + 2, "up"], 
			KEY_J: [debug_device_id + 2, "left"], 
			KEY_K: [debug_device_id + 2, "down"], 
			KEY_L: [debug_device_id + 2, "right"], 
			KEY_O: [debug_device_id + 2, "accept"], 
			KEY_U: [debug_device_id + 2, "pause"], 
			KEY_M: [debug_device_id + 2, "cancel"], 
			KEY_COMMA: [debug_device_id + 2, "info"], 
			KEY_PERIOD: [debug_device_id + 2, "select"], 
			KEY_UP: [debug_device_id + 3, "up"], 
			KEY_LEFT: [debug_device_id + 3, "left"], 
			KEY_DOWN: [debug_device_id + 3, "down"], 
			KEY_RIGHT: [debug_device_id + 3, "right"], 
			KEY_PAGEUP: [debug_device_id + 3, "accept"], 
			KEY_INSERT: [debug_device_id + 3, "pause"], 
			KEY_DELETE: [debug_device_id + 3, "cancel"], 
			KEY_END: [debug_device_id + 3, "info"], 
			KEY_PAGEDOWN: [debug_device_id + 3, "select"], 
		}

		for key in debug_key_mappings:
			var remapped_device = debug_key_mappings[key][0]
			var action_suffix = debug_key_mappings[key][1]
			for prefix in ["ui", "move"]:
				var action_name = prefix + "_" + action_suffix
				if not InputMap.has_action(action_name):
					continue
				var device: = 0
				var new_event = InputEventKey.new()
				new_event.device = device
				new_event.physical_scancode = key
				
				InputMap.action_add_event(action_name, new_event)
				add_key_action(action_name, remapped_device, device, new_event)


func add_key_action(action_name: String, remapped_device: int, device: int, event: InputEventKey) -> void :
	var new_event = InputEventKey.new()
	new_event.device = device
	new_event.scancode = event.scancode
	new_event.physical_scancode = event.physical_scancode
	add_action(action_name, remapped_device, 0.5, new_event)


func add_action(action_name: String, remapped_device: int, deadzone: float, new_event: InputEvent) -> void :
	var new_action_name = action_name + "_" + str(remapped_device)
	if not InputMap.has_action(new_action_name):
		InputMap.add_action(new_action_name, deadzone)
	InputMap.action_add_event(new_action_name, new_event)


func _set_bug_report_key() -> void :
	
	
	if OS.has_feature("editor"):
		InputMap.action_erase_events("open_bug_report")
		var new_key_event = InputEventKey.new()
		new_key_event.physical_scancode = KEY_F7
		InputMap.action_add_event("open_bug_report", new_key_event)
