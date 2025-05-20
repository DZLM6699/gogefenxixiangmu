class_name CoopShopStealHint
extends CoopShopHint

onready var _label3 = $"%Label3"


func set_steal_percentage(percentage: int) -> void :
	_label3.text = "( %s%%" % str(percentage)
