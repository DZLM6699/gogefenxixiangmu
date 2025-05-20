extends PanelContainer

onready var _label = $Label

var text setget _set_text, _get_text


func _set_text(value):
	_label.text = value
	
	call_deferred("set", "rect_size", Vector2.ZERO)


func _get_text():
	return _label.text
