class_name BugReporterResponse
extends CanvasItem

signal done

export (NodePath) var tooltip_path

onready var _id_button = $IDButton as Button
onready var _tooltip = get_node(tooltip_path)

var _issue_id: String


func open(issue_id: String) -> void :
	visible = true
	_issue_id = issue_id
	_id_button.text = "ID: " + issue_id


func _on_IDButton_pressed():
	OS.clipboard = _issue_id


func _on_ReturnButton_pressed():
	emit_signal("done")


func _on_IDButton_mouse_exited():
	_tooltip.visible = false


func _on_IDButton_mouse_entered():
	_tooltip.visible = true
	_tooltip.text = tr("BUG_REPORT_COPY_ID")
