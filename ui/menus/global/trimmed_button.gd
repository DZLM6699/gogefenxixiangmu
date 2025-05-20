class_name TrimmedButton
extends Button

var _translation_key: = ""
var _trimmed_text: = ""


func _ready() -> void :
	_set_translation_key(text)


func _set(name, value) -> bool:
	if name == "text":
		_set_translation_key(value)
		return true
	return false


func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			_update_trimmed_text()
		NOTIFICATION_TRANSLATION_CHANGED:
			_update_trimmed_text()


func _set_translation_key(key: String) -> void :
	
	if key != _trimmed_text:
		_translation_key = key
		_update_trimmed_text()


func _update_trimmed_text() -> void :
	var untrimmed_text: = tr(_translation_key)
	var font: = get_font("font")
	var string_size: = font.get_string_size(untrimmed_text)
	var content_size: = _get_content_size()

	_trimmed_text = untrimmed_text
	if string_size.x > content_size.x:
		var elipsis_size: = font.get_string_size(_elipsize(""))
		while string_size.x > content_size.x:
			_trimmed_text = _trimmed_text.left(_trimmed_text.length() - 1)
			if _trimmed_text.empty():
				break
			string_size = font.get_string_size(_trimmed_text) + elipsis_size
		_trimmed_text = _elipsize(_trimmed_text)
	text = _trimmed_text


func _get_content_size() -> Vector2:
	var style: = get_stylebox("normal")
	return rect_size - style.get_minimum_size()


func _elipsize(v: String) -> String:
	return v + "..."
