extends HBoxContainer

const DEFAULT_TEXTURE_SIZE: int = 50

export  var texture_size: = DEFAULT_TEXTURE_SIZE
export  var show_keyboard: = true

onready var _label1 = $"%Label1"
onready var _label2 = $"%Label2"
onready var _label3 = $"%Label3"
onready var _texture_rect = $"%TextureRect"
onready var _texture_rect2 = $"%TextureRect2"


func _ready():
	
	add_constant_override("separation", get_constant("separation") * texture_size / DEFAULT_TEXTURE_SIZE)

	for texture_rect in [_texture_rect, _texture_rect2]:
		texture_rect.rect_min_size = Vector2(texture_size, texture_size)
	var text = tr("COOP_HOLD_TO_JOIN")
	text = text.replace("{1}", "{0}")
	var split = text.split("{0}")
	if split.size() < 3:
		return
	_label1.text = split[0].strip_edges()
	_label1.visible = not _label1.text.empty()
	_label2.text = split[1].strip_edges()
	_label3.text = split[2].strip_edges()
	_label3.visible = not _label3.text.empty()

	if not show_keyboard:
		_label2.hide()
		_texture_rect2.hide()
