class_name FloatingText
extends Label

signal available

onready var _icon: Sprite = $"%Icon"
onready var _tween: Tween = $"%Tween"


func display(content: String, direction: Vector2, duration: float, spread: float, color: Color = Color.white, all_caps: bool = false) -> void :
	show()
	self_modulate = color
	text = content
	uppercase = all_caps
	var movement: = direction.rotated(rand_range( - spread / 2, spread / 2))
	rect_pivot_offset = rect_size / 2
	rect_scale = Vector2.ONE
	modulate.a = 1.0

	var _success = _tween.interpolate_property(
		self, 
		"rect_position", 
		rect_position, 
		rect_position + movement, 
		duration, 
		Tween.TRANS_ELASTIC, 
		Tween.EASE_OUT
	)
	_success = _tween.start()
	yield(_tween, "tween_all_completed")

	_success = _tween.interpolate_property(
		self, 
		"rect_scale", 
		rect_scale, 
		Vector2.ZERO, 
		duration, 
		Tween.TRANS_ELASTIC, 
		Tween.EASE_IN_OUT
	)

	_success = _tween.interpolate_property(
		self, 
		"modulate:a", 
		modulate.a, 
		0.0, 
		duration, 
		Tween.TRANS_LINEAR, 
		Tween.EASE_IN_OUT
	)
	_success = _tween.start()
	yield(_tween, "tween_all_completed")

	hide()
	_icon.hide()
	emit_signal("available", self)


func set_icon(icon: Texture, icon_scale: Vector2) -> void :
	_icon.show()
	_icon.texture = icon
	_icon.scale = icon_scale
	_icon.position.x = get_minimum_size().x + 8
