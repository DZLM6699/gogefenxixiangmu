class_name MainMenu
extends Control

signal options_button_pressed
signal credits_button_pressed
signal progress_button_pressed
signal mods_button_pressed

onready var continue_button = $"%ContinueButton"
onready var start_button = $"%StartButton"
onready var options_button = $"%OptionsButton"
onready var progress_button = $"%ProgressButton"
onready var mods_button = $"%ModsButton"
onready var quit_button = $"%QuitButton"


onready var more_games_button = $"%MoreGamesButton"
onready var newsletter_button = $"%NewsletterButton"
onready var community_button = $"%CommunityButton"
onready var credits_button = $"%CreditsButton"

onready var error_label = $"%ErrorLabel"
onready var version_label = $"%VersionLabel"
onready var logo_container = $"%LogoContainer"


func init() -> void :

	for child in logo_container.get_children():
		child.queue_free()

	var title_screen_background_data = ItemService.get_element(ItemService.title_screen_backgrounds, "base")

	if ProgressData.is_dlc_available_and_active("abyssal_terrors"):
		title_screen_background_data = ItemService.get_element(ItemService.title_screen_backgrounds, "abyssal_terrors")

	var instance = title_screen_background_data.logo_scene.instance()
	logo_container.add_child(instance)

	more_games_button.text = "MENU_DLC_AVAILABLE_STANDARD"
	more_games_button.add_color_override("font_color", Utils.DLC_BUTTON_TEXT_COLOR)
	more_games_button.theme = load("res://resources/themes/special_button_theme.tres")
	for dlc in ProgressData.available_dlcs:
		if dlc.my_id == "abyssal_terrors":
			more_games_button.text = "MENU_MORE_GAMES"
			more_games_button.remove_color_override("font_color")
			more_games_button.theme = null
			break

	reset_resume_state()

	if ProgressData.saved_run_state.has_run_state:
		continue_button.grab_focus()
		start_button.focus_neighbour_top = continue_button.get_path()
		quit_button.focus_neighbour_bottom = continue_button.get_path()

		set_neighbours(continue_button, mods_button)
	else:
		start_button.grab_focus()
		start_button.focus_neighbour_top = quit_button.get_path()
		quit_button.focus_neighbour_bottom = start_button.get_path()

		set_neighbours(start_button, mods_button)

	version_label.text = "version " + ProgressData.VERSION

	if ProgressData.load_status != LoadStatus.SAVE_OK:

		var status_text = "(!) "

		if ProgressData.load_status == LoadStatus.CORRUPTED_SAVE:
			status_text += tr("CORRUPTED_SAVE")
		elif ProgressData.load_status == LoadStatus.CORRUPTED_SAVE_LATEST:
			status_text += tr("CORRUPTED_SAVE_LATEST")
		elif ProgressData.load_status == LoadStatus.CORRUPTED_ALL_SAVES_STEAM:
			status_text += tr("CORRUPTED_ALL_SAVES_STEAM")
		elif ProgressData.load_status == LoadStatus.CORRUPTED_ALL_SAVES_NO_STEAM:
			status_text += tr("CORRUPTED_ALL_SAVES_NO_STEAM")
		elif ProgressData.load_status == LoadStatus.CORRUPTED_ALL_SAVES_EPIC:
			status_text += tr("CORRUPTED_ALL_SAVES_EPIC")
		elif ProgressData.load_status == LoadStatus.CORRUPTED_ALL_SAVES_NO_EPIC:
			status_text += tr("CORRUPTED_ALL_SAVES_NO_EPIC")

		error_label.text = status_text
		error_label.show()
	elif not CrashReporter.previous_crash_message.empty():
		var error_text = "(!) "
		if CrashReporter.previous_crashed_mod.empty():
			error_text += "%s %s" % [
				tr("CRASH_RECOVERY_MESSAGE_GENERAL"), 
				tr("CRASH_RECOVERY_MESSAGE_MODS_DISABLED")
			]
		else:
			error_text += "%s %s" % [
				tr("CRASH_RECOVERY_MESSAGE_MOD").replace("{0}", CrashReporter.previous_crashed_mod), 
				tr("CRASH_RECOVERY_MESSAGE_MODS_DISABLED")
			]
		error_label.text = error_text
		error_label.show()
	else:
		error_label.hide()


func set_neighbours(a: Node, b: Node) -> void :
	a.focus_neighbour_right = b.get_path()
	a.focus_neighbour_left = b.get_path()
	b.focus_neighbour_right = a.get_path()
	b.focus_neighbour_left = a.get_path()


func _on_StartButton_pressed() -> void :
	MusicManager.tween( - 5)
	var _error = get_tree().change_scene(MenuData.character_selection_scene)


func _on_OptionsButton_pressed() -> void :
	emit_signal("options_button_pressed")


func _on_CommunityButton_pressed() -> void :
	var _error = OS.shell_open(MenuData.community_url)


func _on_QuitButton_pressed() -> void :
	get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)


func _on_NewsletterButton_pressed() -> void :
	var _error = OS.shell_open(MenuData.newsletter_url)


func _on_MoreGamesButton_pressed() -> void :
	if more_games_button.text == "MENU_MORE_GAMES":
		Platform.open_store_page(MenuData.more_games_url)

	else:
		Platform.open_store_page(MenuData.dlc_url)


func _on_CreditsButton_pressed() -> void :
	emit_signal("credits_button_pressed")


func _on_ProgressButton_pressed() -> void :
	emit_signal("progress_button_pressed")


func _on_ContinueButton_pressed() -> void :
	if not ProgressData.saved_run_state.has_run_state:
		return

	RunData.continue_current_run_in_shop()

	var scene: = "res://ui/menus/shop/coop_resume.tscn" if RunData.is_coop_run else "res://ui/menus/shop/shop.tscn"
	var _error = get_tree().change_scene(scene)


func _on_ModsButton_pressed() -> void :
	emit_signal("mods_button_pressed")


static func reset_resume_state() -> void :
	
	CoopService.clear()
	RunData.cancel_resume()
