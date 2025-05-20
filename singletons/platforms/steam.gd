class_name SteamPlatform
extends AbstractPlatform

var steam

var steam_is_owned: bool = false
var steam_is_online: bool = false
var steam_id: int = 0


var steam_languages_map = {
	"english": "en", 
	"french": "fr", 
	"schinese": "zh", 
	"tchinese": "zh_TW", 
	"japanese": "ja", 
	"koreana": "ko", 
	"russian": "ru", 
	"polish": "pl", 
	"spanish": "es", 
	"brazilian": "pt", 
	"german": "de", 
	"turkish": "tr", 
	"italian": "it"
}

var steam_app_id_mapping: = {
	"base": 1942280, 
	"abyssal_terrors": 2868390, 
}


func _process(_delta: float) -> void :
	steam.run_callbacks()


func _init() -> void :
	if Engine.has_singleton("Steam"):
		steam = Engine.get_singleton("Steam")

	var INIT: Dictionary = steam.steamInit()
	print("Did Steam initialize?: " + str(INIT))

	steam_is_online = steam.loggedOn()
	steam_id = steam.getSteamID()
	steam_is_owned = steam.isSubscribed()

	print("steam_is_online: " + str(steam_is_online))
	print("steam_id: " + str(steam_id))
	print("steam_is_owned: " + str(steam_is_owned))


func _ready() -> void :
	if steam.restartAppIfNecessary(steam_app_id_mapping["base"]):
		get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)

	if not steam_is_owned:
		print("Not owned on Steam: Shutting down")
		get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)

	var _result = steam.requestCurrentStats()


func get_type() -> int:
	return PlatformType.STEAM


func get_user_id() -> String:
	if steam_id != 0:
		return str(steam_id)
	else:
		return "user"


func get_language() -> String:
	var steam_lang = steam.getCurrentGameLanguage()

	if steam_lang != "None" and steam_languages_map.has(steam_lang):
		return steam_languages_map.get(steam_lang)

	return "en"


func is_dlc_owned(dlc_my_id: String) -> bool:
	var steam_app_id: int = steam_app_id_mapping.get(dlc_my_id)
	if steam_app_id != null:
		return steam.isDLCInstalled(steam_app_id)

	else:
		print("DLC installed check for %s failed" % dlc_my_id)
		return false


func get_stat(stat_key: String) -> int:
	return steam.getStatInt(stat_key)


func set_stat(stat_key: String, value: int) -> void :
	var _stat = steam.setStatInt(stat_key, value)
	var _stored = steam.storeStats()


func is_challenge_completed(chal_id: String) -> bool:
	return steam.getAchievement(chal_id).achieved


func complete_challenge(chal_id: String) -> void :
	var steam_achievement = steam.getAchievement(chal_id)
	if not steam_achievement.achieved:
		var _achievement = steam.setAchievement(chal_id)
		var _stored = steam.storeStats()


func reinitialize_store_data() -> void :
	print("steam reset data")
	var _reset = steam.resetAllStats(true)


func open_store_page(url: String) -> void :
	steam.activateGameOverlayToWebPage(url)


func open_mods_page() -> void :
	steam.activateGameOverlayToWebPage("https://steamcommunity.com/app/1942280/workshop/")


func get_dlc_url() -> String:
	return "https://store.steampowered.com/app/2868390"


func get_more_games_url() -> String:
	return "https://www.blobfishgames.com/games"


func get_subscribed_mods() -> Array:
	return steam.getSubscribedItems()
