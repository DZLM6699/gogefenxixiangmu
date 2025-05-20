class_name AbstractPlatform
extends Node


func get_type() -> int:
	printerr("Method needs to be overwritten")
	return 0


func get_user_id() -> String:
	printerr("Method needs to be overwritten")
	return ""


func is_challenge_completed(_chal_id: String) -> bool:
	printerr("Method needs to be overwritten")
	return false


func complete_challenge(_chal_id: String) -> void :
	printerr("Method needs to be overwritten")


func is_dlc_owned(_dlc_my_id: String) -> bool:
	printerr("Method needs to be overwritten")
	return false


func get_language() -> String:
	printerr("Method needs to be overwritten")
	return ""


func get_stat(_stat_key: String) -> int:
	printerr("Method needs to be overwritten")
	return 0


func set_stat(_stat_key: String, _value: int) -> void :
	printerr("Method needs to be overwritten")


func reinitialize_store_data() -> void :
	printerr("Method needs to be overwritten")


func open_store_page(_link: String) -> void :
	printerr("Method needs to be overwritten")


func open_mods_page() -> void :
	printerr("Method needs to be overwritten")


func get_dlc_url() -> String:
	printerr("Method needs to be overwritten")
	return ""


func get_more_games_url() -> String:
	printerr("Method needs to be overwritten")
	return ""


func get_subscribed_mods() -> Array:
	printerr("Method needs to be overwritten")
	return []
