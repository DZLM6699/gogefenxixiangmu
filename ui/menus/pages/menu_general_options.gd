class_name MenuGeneralOptions
extends Control

signal back_button_pressed

onready var left_container = $"%LeftContainer"
onready var right_container = $"%RightContainer"

onready var master_slider = $"%MasterSlider"
onready var sound_slider = $"%SoundSlider"
onready var music_slider = $"%MusicSlider"

onready var language_button = $"%LanguageButton" as OptionButton
onready var screenshake_button = $"%ScreenshakeButton" as CheckButton
onready var fullscreen_button = $"%FullScreenButton" as CheckButton
onready var visual_effects_button = $"%VisualEffectsButton" as CheckButton
onready var background_button = $"%BackgroundButton" as OptionButton
onready var damage_display_button = $"%DamageDisplayButton" as CheckButton
onready var optimize_end_waves_button = $"%OptimizeEndWavesButton" as CheckButton
onready var limit_fps_button = $"%LimitFPSButton" as CheckButton

onready var mute_on_focus_lost_button = $"%MuteOnFocusLostButton" as CheckButton
onready var pause_on_focus_lost_button = $"%PauseOnFocusLostButton" as CheckButton
onready var new_tracks_button = $"%NewTracksButton" as CheckButton
onready var old_tracks_button = $"%OldTracksButton" as CheckButton
onready var abyssal_terrors_tracks_button = $"%AbyssalTerrorsTracksButton" as CheckButton

onready var old_tracks_warning_label = $"%OldTracksWarningLabel" as Label

var all_check_buttons = []
var small_font = preload("res://resources/fonts/actual/base/font_32_outline.tres")
var normal_font = preload("res://resources/fonts/actual/base/font_40_outline.tres")


func init() -> void :

	var all_children = left_container.get_children()
	all_children.append_array(right_container.get_children())

	for child in all_children:
		if child is CheckButton:
			all_check_buttons.push_back(child)

	adjust_buttons_font_size()
	$BackButton.grab_focus()

	master_slider.set_value(ProgressData.settings.volume.master )
	sound_slider.set_value(ProgressData.settings.volume.sound)
	music_slider.set_value(ProgressData.settings.volume.music)

	var i = 0

	for language in ProgressData.languages:
		if language == ProgressData.settings.language:
			language_button.select(i)
			break
		i += 1

	var selected_background = ProgressData.settings.background
	if selected_background > ItemService.backgrounds.size():
		selected_background = 0

	background_button.select(selected_background)
	background_button._on_BackgroundButton_item_selected(selected_background)

	if not ItemService.is_connected("backgrounds_updated", background_button, "on_backgrounds_updated"):
		var _e = ItemService.connect("backgrounds_updated", background_button, "on_backgrounds_updated")

	visual_effects_button.pressed = ProgressData.settings.visual_effects
	screenshake_button.pressed = ProgressData.settings.screenshake
	fullscreen_button.pressed = ProgressData.settings.fullscreen
	damage_display_button.pressed = ProgressData.settings.damage_display
	optimize_end_waves_button.pressed = ProgressData.settings.optimize_end_waves
	limit_fps_button.pressed = ProgressData.settings.limit_fps

	mute_on_focus_lost_button.pressed = ProgressData.settings.mute_on_focus_lost
	pause_on_focus_lost_button.pressed = ProgressData.settings.pause_on_focus_lost
	new_tracks_button.set_pressed_no_signal(ProgressData.settings.streamer_mode_tracks)
	old_tracks_button.set_pressed_no_signal(ProgressData.settings.legacy_tracks)

	if not ProgressData.is_dlc_available("abyssal_terrors"):
		abyssal_terrors_tracks_button.hide()

	abyssal_terrors_tracks_button.set_pressed_no_signal( not ProgressData.settings.deactivated_dlc_tracks.has("abyssal_terrors"))


func adjust_buttons_font_size() -> void :
	for check_button in all_check_buttons:
		if tr(check_button.text).length() > 30:
			check_button.add_font_override("font", small_font)
		else:
			check_button.add_font_override("font", normal_font)


func _on_BackButton_pressed() -> void :
	emit_signal("back_button_pressed")


func _on_MasterSlider_value_changed(value: float) -> void :
	ProgressData.settings.volume.master = value
	set_volume(value, "Master")


func _on_SoundSlider_value_changed(value: float) -> void :
	ProgressData.settings.volume.sound = value
	set_volume(value, "Sound")


func _on_MusicSlider_value_changed(value: float) -> void :
	ProgressData.settings.volume.music = value
	set_volume(value, "Music")


func set_volume(value: float, bus: String) -> void :
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus), linear2db(value))


func _on_MenuOptions_hide() -> void :
	ProgressData.save()


func _on_LanguageButton_item_selected(index: int) -> void :
	var language: String = ProgressData.languages[index]
	ProgressData.change_language(language)
	adjust_buttons_font_size()


func _on_ScreenshakeButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.screenshake = button_pressed


func _on_FullScreenButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.fullscreen = button_pressed
	OS.window_fullscreen = button_pressed


func _on_BackgroundButton_item_selected(index: int) -> void :
	ProgressData.settings.background = index
	RunData.reset_background()


func _on_VisualEffectsButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.visual_effects = button_pressed


func _on_DamageDisplayButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.damage_display = button_pressed


func _on_MuteOnFocusLostButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.mute_on_focus_lost = button_pressed


func _on_PauseOnFocusLostButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.pause_on_focus_lost = button_pressed


func _on_OptimizeEndWavesButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.optimize_end_waves = button_pressed


func _on_LimitFPSButton_toggled(button_pressed: bool) -> void :
	ProgressData.set_fps_limit(button_pressed)


func _on_StreamerModeTracksButton_toggled(button_pressed):
	ProgressData.settings.streamer_mode_tracks = button_pressed
	MusicManager.set_shuffled_tracks()
	MusicManager.play()


func _on_LegacyTracksButton_toggled(button_pressed):
	ProgressData.settings.legacy_tracks = button_pressed
	MusicManager.set_shuffled_tracks()
	MusicManager.play()


func _on_AbyssalTerrorsTracksButton_toggled(button_pressed):
	if button_pressed:
		ProgressData.settings.deactivated_dlc_tracks.erase("abyssal_terrors")
	else:
		ProgressData.settings.deactivated_dlc_tracks.push_back("abyssal_terrors")
	MusicManager.set_shuffled_tracks()
	MusicManager.play()


func _on_OldTracksButton_focus_entered():
	old_tracks_warning_label.text = "(!) " + tr("MENU_OLD_TRACKS_INFO")


func _on_OldTracksButton_focus_exited():
	old_tracks_warning_label.text = ""


func _on_OldTracksButton_mouse_entered():
	old_tracks_warning_label.text = "(!) " + tr("MENU_OLD_TRACKS_INFO")


func _on_OldTracksButton_mouse_exited():
	old_tracks_warning_label.text = ""
