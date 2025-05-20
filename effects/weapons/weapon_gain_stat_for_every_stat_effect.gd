class_name WeaponGainStatForEveryStatEffect
extends GainStatForEveryStatEffect


export (String) var increased_stat_name = ""


static func get_id() -> String:
	return "weapon_gain_stat_for_every_stat"


func apply(_player_index: int) -> void :
	pass


func unapply(_player_index: int) -> void :
	pass
