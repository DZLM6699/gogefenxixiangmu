class_name LocalPlatform
extends AbstractPlatform


var stats = {
	"enemies_killed": 0, 
	"materials_collected": 0, 
	"trees_killed": 0, 
	"steps_taken": 0, 
	"enemies_killed_far_away": 0, 
}


func _ready() -> void :
	print("local platform initialized")


func get_type() -> int:
	return PlatformType.LOCAL


func get_user_id() -> String:
	return "user"


func get_language() -> String:
	return "en"


func is_challenge_completed(_chal_id: String) -> bool:
	return false


func complete_challenge(_chal_id: String) -> void :
	return


func is_dlc_owned(_dlc_my_id: String) -> bool:
	return DebugService.has_dlc


func get_stat(stat_key: String) -> int:
	return stats[stat_key]


func set_stat(stat_key: String, value: int) -> void :
	stats[stat_key] = value


func reinitialize_store_data() -> void :
	return


func open_store_page(url: String) -> void :
	var _error: = OS.shell_open(url)


func open_mods_page() -> void :
	return


func get_dlc_url() -> String:
	return "https://store.steampowered.com/app/2868390"


func get_more_games_url() -> String:
	return "https://www.blobfishgames.com/games"


func get_subscribed_mods() -> Array:
	return []
