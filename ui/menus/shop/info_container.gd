class_name InfoContainer
extends VBoxContainer

onready var _description = $PanelContainer / MarginContainer / Description
onready var _panel_container = $PanelContainer


func display(text: String) -> void :
	_description.bbcode_text = text
	show()
