class_name MenuCredits
extends Control

signal back_button_pressed

onready var _back_button = $"%BackButton"
onready var _names: Label = $"%Names"


func init() -> void :
	_back_button.grab_focus()


func _on_BackButton_pressed() -> void :
	emit_signal("back_button_pressed")
