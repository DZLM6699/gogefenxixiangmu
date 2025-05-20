extends CanvasLayer

onready var _input_container: BugReporterInput = $"%InputContainer"
onready var _response_container: BugReporterResponse = $"%ResponseContainer"
onready var _tooltip: Control = $"%Tooltip"

var _restore_focus_control = null
var _restore_paused_value: = false


func _ready() -> void :
	hide()
	set_process_input(false)


func _input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_cancel") and visible:
		_close()
		
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void :
	if Input.is_action_just_pressed("open_bug_report"):
		if visible:
			_close()
		else:
			_open()

	if visible and _tooltip.visible:
		_tooltip.rect_global_position = (
			get_viewport().get_mouse_position()
			+ CursorManager.get_tooltip_offset()
		)


func _open() -> void :
	set_process_input(true)
	_restore_focus_control = _input_container.get_focus_owner()
	_input_container.open()
	_response_container.visible = false
	_tooltip.visible = false
	visible = true
	_restore_paused_value = get_tree().paused
	get_tree().paused = true

	
	var last_child_idx = get_parent().get_child_count() - 1
	get_parent().move_child(self, last_child_idx)



func _close() -> void :
	set_process_input(false)
	get_tree().paused = _restore_paused_value
	_input_container.visible = false
	_response_container.visible = false
	_tooltip.visible = false
	visible = false
	if _restore_focus_control != null:
		
		_restore_focus_control.call_deferred("grab_focus")


func _on_InputContainer_submitted(issue_id):
	_input_container.visible = false
	_tooltip.visible = false
	_response_container.open(issue_id)


func _on_InputContainer_cancelled():
	_close()


func _on_ResponseContainer_done():
	_close()


func get_input() -> BugReporterInput:
	return _input_container
