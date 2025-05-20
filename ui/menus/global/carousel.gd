class_name Carousel
extends Container

const ARROW_ALPHA: = 0.9

signal index_changed(index)

export  var enable_trigger_buttons: = true setget _set_enable_trigger_buttons
func _set_enable_trigger_buttons(value):
	enable_trigger_buttons = value
	if not is_inside_tree():
		return
	_try_activate_trigger_buttons()

var index: = 0 setget _set_index
func _set_index(value):
	value = int(clamp(value, 0, _get_max_index()))
	index = value

	for i in _headings.get_child_count():
		_headings.get_child(i).visible = i == value

	var content_has_visible_children = false
	for i in _content.get_child_count():
		var visible = i == value
		_content.get_child(i).visible = visible
		if visible:
			content_has_visible_children = true
	_content.visible = content_has_visible_children

	arrow_left.disabled = value == 0
	arrow_left.modulate.a = 0.0 if value == 0 else ARROW_ALPHA
	arrow_right.disabled = value == _get_max_index()
	arrow_right.modulate.a = 0.0 if value == _get_max_index() else ARROW_ALPHA
	_try_activate_trigger_buttons()

var player_index: = - 1 setget _set_player_index
func _set_player_index(value):
	player_index = value
	if value < 0: return
	_try_activate_trigger_buttons()

onready var arrow_left: TextureButton = $"%ArrowLeft"
onready var arrow_right: TextureButton = $"%ArrowRight"
onready var _headings = $"%Headings"
onready var _content = $"%Content"

var active: = true setget _set_active
func _set_active(value):
	active = value
	$MarginContainer.visible = value

var max_index: = - 1


func _ready() -> void :
	_set_enable_trigger_buttons(enable_trigger_buttons)
	_set_index(index)
	_set_player_index(player_index)
	_set_active(active)
	set_process_input(false)


func _input(event: InputEvent) -> void :
	if not active or not enable_trigger_buttons or player_index < 0:
		return
	if not CoopService.is_player_using_gamepad(player_index):
		return
	var remapped_device = CoopService.get_remapped_player_device(player_index)
	if event.is_action_pressed("ltrigger_%s" % remapped_device):
		_on_ArrowLeft_pressed()
	elif event.is_action_pressed("rtrigger_%s" % remapped_device):
		_on_ArrowRight_pressed()


func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process_input(is_visible_in_tree())


func get_content_element(element_index: int) -> Node:
	return _content.get_child(element_index)


func are_trigger_buttons_active() -> bool:
	return CoopService.is_player_using_gamepad(player_index) and enable_trigger_buttons


func _set_arrow_texture(arrow: TextureButton, texture: Texture) -> void :
	arrow.texture_normal = texture
	arrow.texture_pressed = texture
	arrow.texture_hover = texture
	arrow.texture_disabled = texture
	arrow.texture_focused = texture


func _try_activate_trigger_buttons() -> void :
	if not are_trigger_buttons_active():
		return
	arrow_left.disabled = true
	arrow_right.disabled = true
	var ltrigger_texture = CoopService.get_player_key_texture("ltrigger", player_index)
	if ltrigger_texture:
		_set_arrow_texture(arrow_left, ltrigger_texture)
	var rtrigger_texture = CoopService.get_player_key_texture("rtrigger", player_index)
	if rtrigger_texture:
		_set_arrow_texture(arrow_right, rtrigger_texture)


func _get_max_index():
	return max_index if max_index >= 0 else _headings.get_child_count() - 1


func _on_ArrowLeft_pressed():
	if not active:
		return
	_set_index(index - 1)
	emit_signal("index_changed", index)
	if index == 0 and not arrow_right.disabled:
		arrow_right.call_deferred("grab_focus")


func _on_ArrowRight_pressed():
	if not active:
		return
	_set_index(index + 1)
	emit_signal("index_changed", index)
	if index == _get_max_index() and not arrow_left.disabled:
		arrow_left.call_deferred("grab_focus")
