class_name Announcement
extends Control

onready var _image: TextureRect = $"%Image"
onready var _tween: Tween = $"%Tween"
onready var _announcement_container: VBoxContainer = $"%AnnouncementContainer"
onready var _speech_bubble: PanelContainer = $"%SpeechBubblePanel"

var _closing: = false


func _ready() -> void :
	if AnnouncementManager.display_announcement:
		display_announcement()
	var _err: = AnnouncementManager.connect("announcement_ready", self, "_on_announcement_ready")


func _on_announcement_ready() -> void :
	display_announcement()


func display_announcement() -> void :
	_image.texture = AnnouncementManager.get_image()

	if AnnouncementManager.initial_display:
		var start: = Vector2(rect_position.x - _announcement_container.rect_size.x, rect_position.y)
		var _res: = _tween.interpolate_property(self, "rect_position", 
		start, rect_position, 0.5, 
		Tween.TRANS_EXPO, Tween.EASE_OUT)
		_res = _tween.start()
		AnnouncementManager.initial_display = false

	else:
		visible = true


func _on_CloseButton_pressed() -> void :
	_closing = true
	AnnouncementManager.announcement_read()

	var end: = Vector2(rect_position.x - _announcement_container.rect_size.x, rect_position.y)
	var _res: = _tween.interpolate_property(self, "rect_position", 
		rect_position, end, 0.4, 
		Tween.TRANS_QUAD, Tween.EASE_IN)
	_res = _tween.start()
	_res = _tween.interpolate_property(self, "rect_scale", 
		rect_scale, Vector2(1.0, 1.0), 0.1, 
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	_res = _tween.start()


func _on_Tween_tween_started(_object: Object, _key: NodePath) -> void :
	yield(get_tree(), "idle_frame")
	visible = true


func _on_AnnouncementButton_pressed() -> void :
	var link: = tr("ANNOUNCEMENT_LINK")
	if link:
		Platform.open_store_page(link)
		_speech_bubble.remove_stylebox_override("panel")


func _on_PanelContainer_mouse_entered() -> void :
	var hover_stylebox: = _speech_bubble.get_stylebox("hover")
	_speech_bubble.add_stylebox_override("panel", hover_stylebox)


func _on_PanelContainer_mouse_exited() -> void :
	if _closing:
		return
	_speech_bubble.remove_stylebox_override("panel")


func _on_AnnouncementButton_button_down() -> void :
	_speech_bubble.remove_stylebox_override("panel")


func _on_AnnouncementButton_button_up() -> void :
	var hover_stylebox: = _speech_bubble.get_stylebox("hover")
	_speech_bubble.add_stylebox_override("panel", hover_stylebox)


func _on_Announcement_mouse_entered() -> void :
	if _closing:
		return

	var _res: = _tween.interpolate_property(self, "rect_scale", 
		rect_scale, Vector2(1.05, 1.05), 0.1, 
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	_res = _tween.start()


func _on_Announcement_mouse_exited() -> void :
	var _res: = _tween.interpolate_property(self, "rect_scale", 
		rect_scale, Vector2(1.0, 1.0), 0.1, 
		Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
	_res = _tween.start()
