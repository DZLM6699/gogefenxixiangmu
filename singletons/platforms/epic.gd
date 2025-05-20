class_name EpicPlatform
extends AbstractPlatform

var epic
var initialized: = false
var init_success: = false

var user_id: String
var epic_language: String


func _ready():
	epic = load("res://addons/epic_bindings/epic_bindings.gdns").new()
	add_child(epic)
	var _e = epic.connect("init_finished", self, "_on_init_finished")

	var arguments = Utils.get_startup_arguments()
	epic.client_id = "xyza7891C21j49Oc0g9k8FOHSs4afyL8"
	epic.client_secret = "2rD4I9ZP1EsKAce1R9o7WsWiyIK6Gpfrq1VANjFvliI"

	epic.product_id = "2c5525406ea34caebf391f1f4c8a44a5"
	epic.exchange_code = arguments.get("AUTH_PASSWORD", "")
	epic.sandbox_id = arguments.get("epicsandboxid", "")
	epic.deployment_id = arguments.get("epicdeploymentid", "")
	user_id = arguments.get("epicuserid", "")
	epic_language = arguments.get("epiclocale", "").to_lower()

	
	
	
	
	
	
	

	epic.initialize("Brotato", ProgressData.VERSION)


func _on_init_finished(success: bool) -> void :
	initialized = true
	init_success = success


func get_type() -> int:
	return PlatformType.EPIC


func get_user_id() -> String:
	if not user_id:
		return "user"
	return user_id


func is_challenge_completed(chal_id: String) -> bool:
	if not initialized:
		yield(epic, "init_finished")
	if init_success:
		return epic.is_achievement_unlocked(chal_id)
	return false


func complete_challenge(chal_id: String) -> void :
	if not initialized:
		yield(epic, "init_finished")
	if init_success and not epic.is_achievement_unlocked(chal_id):
		epic.unlock_achievement(chal_id)


func is_dlc_owned(_dlc_my_id: String) -> bool:
	return true


func get_language() -> String:
	if epic_language == "zh-hans":
		return "zh"
	if epic_language == "zh-hant":
		return "zh_TW"
	if epic_language in ProgressData.languages:
		return epic_language
	var epic_start = epic_language.substr(0, 2)
	if epic_start in ProgressData.languages:
		return epic_start
	return "en"


func get_stat(stat_key: String) -> int:
	if not initialized:
		yield(epic, "init_finished")
	if init_success:
		return epic.get_stat(stat_key)
	return 0


func set_stat(stat_key: String, value: int) -> void :
	if not initialized:
		yield(epic, "init_finished")
	if init_success:
		epic.ingest_stat(stat_key, value)


func reinitialize_store_data() -> void :
	return


func open_store_page(url: String) -> void :
	var _error: = OS.shell_open(url)


func open_mods_page() -> void :
	return


func get_dlc_url() -> String:
	return "https://store.epicgames.com/p/brotato-brotato-abyssal-terrors-5d2d1a"


func get_more_games_url() -> String:
	return "https://www.blobfishgames.com/epic-games"
