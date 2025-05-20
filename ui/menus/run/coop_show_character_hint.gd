class_name CoopShowCharacterHint
extends Container

const UI_ACTION: String = "ui_info"

export  var text = "COOP_SHOW_CHARACTER_HINT"

onready var _label1 = $"%Label1"
onready var _label2 = $"%Label2"
onready var _keyboard_icon = $"%KeyboardIcon"
onready var _label_slash = $"%LabelSlash"
onready var _xbox_icon = $"%XboxIcon"
onready var _playstation_icon = $"%PlaystationIcon"
onready var _switch_icon = $"%SwitchIcon"


func _ready() -> void :
	visible = RunData.is_coop_run
	if not visible:
		return

	var input_types: = {}
	for player_index in RunData.get_player_count():
		
		if RunData.player_has_weapon_slots(player_index):
			input_types[CoopService.get_player_input_type(player_index)] = true

	_keyboard_icon.visible = input_types.has(CoopService.PlayerType.KEYBOARD_AND_MOUSE)
	_keyboard_icon.texture = CoopService.get_input_type_key_texture(UI_ACTION, CoopService.PlayerType.KEYBOARD_AND_MOUSE)

	_xbox_icon.visible = input_types.has(CoopService.PlayerType.GAMEPAD_XBOX)
	_xbox_icon.texture = CoopService.get_input_type_key_texture(UI_ACTION, CoopService.PlayerType.GAMEPAD_XBOX)

	_playstation_icon.visible = input_types.has(CoopService.PlayerType.GAMEPAD_PLAYSTATION)
	_playstation_icon.texture = CoopService.get_input_type_key_texture(UI_ACTION, CoopService.PlayerType.GAMEPAD_PLAYSTATION)

	_switch_icon.visible = input_types.has(CoopService.PlayerType.GAMEPAD_SWITCH)
	_switch_icon.texture = CoopService.get_input_type_key_texture(UI_ACTION, CoopService.PlayerType.GAMEPAD_SWITCH)

	var displayed_icons: = []
	for icon in [_keyboard_icon, _xbox_icon, _playstation_icon, _switch_icon]:
		if icon.visible:
			displayed_icons.append(icon)

	
	_label_slash.hide()
	for i in displayed_icons.size() - 1:
		var icon = displayed_icons[i]
		var slash = _label_slash.duplicate()
		slash.show()
		icon.get_parent().add_child_below_node(icon, slash)

	var translated = tr(text)
	var split = translated.split("{0}")
	_label1.text = split[0].strip_edges()
	_label2.text = split[1].strip_edges()
