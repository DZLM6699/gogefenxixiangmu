extends Panel

onready var _coop_count: Label = $"%CoopCount"
onready var _count: Label = $"%Count"
onready var _curse: TextureRect = $"%Curse"


func _ready() -> void :
	_coop_count.visible = RunData.is_coop_run
	_count.visible = not RunData.is_coop_run
	_curse.visible = false


func set_count(count: int) -> void :
	if count <= 1:
		_coop_count.text = ""
		_count.text = ""
	else:
		_coop_count.text = "x" + str(count)
		_count.text = "x" + str(count)


func _update_stylebox(is_cursed: bool) -> void :
	var stylebox = get_stylebox("panel").duplicate()
	_curse.visible = is_cursed
	add_stylebox_override("panel", stylebox)
