class_name UIGold
extends HBoxContainer


onready var gold_label = $GoldLabel
onready var icon = $Icon


func _ready() -> void :
	gold_label.set_message_translation(false)


func update_value(value: int) -> void :
	gold_label.text = str(value)
