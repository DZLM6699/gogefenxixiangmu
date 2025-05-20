extends AbstractPlatform

var _platform_impl: AbstractPlatform


func _init() -> void :
	if OS.has_feature("steam"):
		_platform_impl = SteamPlatform.new()
	elif OS.has_feature("epic"):
		_platform_impl = EpicPlatform.new()
	else:
		_platform_impl = LocalPlatform.new()

	add_child(_platform_impl)


func get_type() -> int:
	return _platform_impl.get_type()


func get_type_as_string() -> String:
	var type: = _platform_impl.get_type()
	return PlatformType.get_type_as_string(type)


func get_user_id() -> String:
	return _platform_impl.get_user_id()


func is_challenge_completed(chal_id: String) -> bool:
	return _platform_impl.is_challenge_completed(chal_id)


func complete_challenge(chal_id: String) -> void :
	_platform_impl.complete_challenge(chal_id)


func is_dlc_owned(dlc_my_id: String) -> bool:
	return _platform_impl.is_dlc_owned(dlc_my_id)


func get_language() -> String:
	return _platform_impl.get_language()


func get_stat(stat_key: String) -> int:
	return _platform_impl.get_stat(stat_key)


func set_stat(stat_key: String, value: int) -> void :
	_platform_impl.set_stat(stat_key, value)


func reinitialize_store_data() -> void :
	_platform_impl.reinitialize_store_data()


func open_store_page(url: String) -> void :
	_platform_impl.open_store_page(url)


func open_mods_page() -> void :
	_platform_impl.open_mods_page()


func get_dlc_url() -> String:
	return _platform_impl.get_dlc_url()


func get_more_games_url() -> String:
	return _platform_impl.get_more_games_url()


func get_subscribed_mods() -> Array:
	return _platform_impl.get_subscribed_mods()
