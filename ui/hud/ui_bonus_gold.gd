class_name UIBonusGold
extends HBoxContainer


onready var _gold_label = $GoldLabel
onready var _icon = $Icon


func _ready() -> void :
	_gold_label.set_message_translation(false)
	_gold_label.text = str(RunData.bonus_gold)


func update_value(new_value: int) -> void :
	_gold_label.text = str(new_value)
