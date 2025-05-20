class_name InfoPopup
extends BasePopup


onready var _panel = $PanelContainer
onready var _description = $PanelContainer / MarginContainer / Description


func display(from: Node, key: String) -> void :
	_description.text = key
	show()
	set_pos_from(from, _panel)
