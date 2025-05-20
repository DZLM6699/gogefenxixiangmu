class_name MenuGameplayOptions
extends Control

signal hp_bar_on_character_changed(value)
signal darken_screen_changed(value)
signal back_button_pressed
signal character_highlighting_changed(value)
signal weapon_highlighting_changed(value)
signal lock_coop_camera_changed(value)

onready var left_container = $"%LeftContainer" as VBoxContainer
onready var accessibility_container = $"%AccessibilityContainer" as VBoxContainer
onready var accessibility_slider_container = $"Options/Column2/AccessibilityContainer/VBoxContainer" as VBoxContainer

onready var mouse_only_button = $"%MouseOnlyButton" as CheckButton
onready var manual_aim_button = $"%ManualAimButton" as CheckButton
onready var manual_aim_on_mouse_press_button = $"%ManualAimOnMousePressButton" as CheckButton
onready var movement_with_gamepad: CheckButton = $"%MovementWithGamepad"
onready var hp_bar_button = $"%HPbarOnCharacterButton" as CheckButton
onready var boss_hp_bar_button = $"%BossHPBarButton" as CheckButton
onready var keep_lock_button = $"%KeepLockButton" as CheckButton
onready var lock_coop_camera_button = $"%LockCoopCameraButton" as CheckButton
onready var score_storing_button = $"%ScoreStoringButton" as OptionButton
onready var enemy_health_slider = $"%EnemyHealthSlider"
onready var enemy_damage_slider = $"%EnemyDamageSlider"
onready var enemy_speed_slider = $"%EnemySpeedSlider"
onready var explosion_opacity_slider = $"%ExplosionOpacitySlider"
onready var projectile_opacity_slider = $"%ProjectileOpacitySlider"
onready var font_size_slider = $"%FontSizeSlider"
onready var character_highlighting_button = $"%CharacterHighlightingButton" as CheckButton
onready var weapon_highlighting_button = $"%WeaponHighlightingButton" as CheckButton
onready var projectile_highlighting_button = $"%ProjectileHighlightingButton" as CheckButton
onready var gold_sounds_button = $"%GoldSoundsButton" as CheckButton
onready var darken_screen_button = $"%DarkenScreenButton" as CheckButton
onready var retry_wave_button = $"%RetryWaveButton" as CheckButton
onready var share_coop_loot_button = $"%ShareCoopLootButton" as CheckButton
onready var abyssal_terrors_dlc_button = $"%AbyssalTerrorsDLCButton" as CheckButton
onready var green_skins_button: CheckButton = $"%GreenSkinsButton"


var all_check_buttons = []
var small_font = preload("res://resources/fonts/actual/base/font_32_outline.tres")
var normal_font = preload("res://resources/fonts/actual/base/font_40_outline.tres")

var all_slider_labels = []
var small_slider_font = preload("res://resources/fonts/actual/base/font_35_outline.tres")
var normal_slider_font = preload("res://resources/fonts/actual/base/font_menus.tres")


func init() -> void :
	$BackButton.grab_focus()

	adjust_buttons_font_size()
	init_values_from_progress_data()


func adjust_buttons_font_size() -> void :
	var all_children = left_container.get_children()
	all_children.append_array(accessibility_container.get_children())

	for child in all_children:
		if child is CheckButton:
			all_check_buttons.push_back(child)

	for check_button in all_check_buttons:
		if tr(check_button.text).length() > 30:
			check_button.add_font_override("font", small_font)
		else:
			check_button.add_font_override("font", normal_font)

	var slider_children = accessibility_slider_container.get_children()

	for child in slider_children:
		if child._label.text.to_lower() == "menu_font_size":
			continue

		if tr(child._label.text).length() > 18:
			child._label.add_font_override("font", small_slider_font)
		else:
			child._label.add_font_override("font", normal_slider_font)


func init_values_from_progress_data() -> void :
	mouse_only_button.pressed = ProgressData.settings.mouse_only
	manual_aim_button.pressed = ProgressData.settings.manual_aim
	manual_aim_on_mouse_press_button.pressed = ProgressData.settings.manual_aim_on_mouse_press
	movement_with_gamepad.pressed = ProgressData.settings.movement_with_gamepad
	hp_bar_button.pressed = ProgressData.settings.hp_bar_on_character
	boss_hp_bar_button.pressed = ProgressData.settings.hp_bar_on_bosses
	keep_lock_button.pressed = ProgressData.settings.keep_lock
	lock_coop_camera_button.pressed = ProgressData.settings.lock_coop_camera
	score_storing_button.select(ProgressData.settings.endless_score_storing)
	enemy_health_slider.set_value(ProgressData.settings.enemy_scaling.health)
	enemy_damage_slider.set_value(ProgressData.settings.enemy_scaling.damage)
	enemy_speed_slider.set_value(ProgressData.settings.enemy_scaling.speed)
	explosion_opacity_slider.set_value(ProgressData.settings.explosion_opacity)
	projectile_opacity_slider.set_value(ProgressData.settings.projectile_opacity)
	font_size_slider.set_value(ProgressData.settings.font_size)
	character_highlighting_button.pressed = ProgressData.settings.character_highlighting
	weapon_highlighting_button.pressed = ProgressData.settings.weapon_highlighting
	projectile_highlighting_button.pressed = ProgressData.settings.projectile_highlighting
	gold_sounds_button.pressed = ProgressData.settings.alt_gold_sounds
	darken_screen_button.pressed = ProgressData.settings.darken_screen
	retry_wave_button.pressed = ProgressData.settings.retry_wave
	share_coop_loot_button.pressed = ProgressData.settings.share_coop_loot

	if not ProgressData.is_dlc_available("abyssal_terrors"):
		abyssal_terrors_dlc_button.hide()
	abyssal_terrors_dlc_button.set_pressed_no_signal( not ProgressData.settings.deactivated_dlcs.has("abyssal_terrors"))

	if not SkinManager.is_skin_set_available("green"):
		green_skins_button.hide()
	green_skins_button.set_pressed_no_signal( not ProgressData.settings.deactivated_skin_sets.has("green"))


func _on_BackButton_pressed() -> void :
	emit_signal("back_button_pressed")


func _on_MenuOptions_hide() -> void :
	ProgressData.save()


func _on_MouseOnlyButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.mouse_only = button_pressed


func _on_ManualAimButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.manual_aim = button_pressed


func _on_ManualAimOnMousePressButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.manual_aim_on_mouse_press = button_pressed


func _on_MovementWithGamepad_toggled(button_pressed: bool) -> void :
	ProgressData.settings.movement_with_gamepad = button_pressed
	if button_pressed:
		InputService.enable_gamepad_movement()
	else:
		InputService.disable_gamepad_movement()


func _on_HPbarOnCharacterButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.hp_bar_on_character = button_pressed
	emit_signal("hp_bar_on_character_changed", button_pressed)


func _on_BossHPBarButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.hp_bar_on_bosses = button_pressed


func _on_KeepLockButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.keep_lock = button_pressed


func _on_LockCoopCameraButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.lock_coop_camera = button_pressed
	emit_signal("lock_coop_camera_changed", button_pressed)


func _on_ScoreButton_item_selected(index: int) -> void :
	ProgressData.settings.endless_score_storing = index


func _on_EnemyHealthSlider_value_changed(value) -> void :
	ProgressData.settings.enemy_scaling.health = value


func _on_EnemyDamageSlider_value_changed(value) -> void :
	ProgressData.settings.enemy_scaling.damage = value


func _on_EnemySpeedSlider_value_changed(value) -> void :
	ProgressData.settings.enemy_scaling.speed = value


func _on_ExplosionOpacitySlider_value_changed(value) -> void :
	ProgressData.settings.explosion_opacity = value


func _on_ProjectileOpacitySlider_value_changed(value) -> void :
	ProgressData.settings.projectile_opacity = value


func _on_FontSizeSlider_value_changed(value) -> void :
	ProgressData.set_font_size(value)


func _on_CharacterHighlightingButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.character_highlighting = button_pressed
	emit_signal("character_highlighting_changed", button_pressed)


func _on_WeaponHighlightingButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.weapon_highlighting = button_pressed
	emit_signal("weapon_highlighting_changed", button_pressed)


func _on_ProjectileHighlightingButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.projectile_highlighting = button_pressed


func _on_GoldSoundsButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.alt_gold_sounds = button_pressed


func _on_DarkenScreenButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.darken_screen = button_pressed
	emit_signal("darken_screen_changed", button_pressed)


func _on_RetryWaveButton_toggled(button_pressed: bool) -> void :
	ProgressData.settings.retry_wave = button_pressed


func _on_DefaultButton_pressed() -> void :
	ProgressData.settings.merge(ProgressData.init_gameplay_options(), true)
	init_values_from_progress_data()


func _on_ShareCoopLootButton_toggled(button_pressed):
	ProgressData.settings.share_coop_loot = button_pressed


func _on_AbyssalTerrorsDLCButton_toggled(button_pressed):
	if button_pressed:
		ProgressData.activate_dlc("abyssal_terrors")
	else:
		ProgressData.deactivate_dlc("abyssal_terrors")


func _on_GreenSkinsButton_toggled(button_pressed: bool) -> void :
	var skin_set: = SkinManager.get_skin_set("green")
	if button_pressed:
		SkinManager.activate_skins(skin_set)
	else:
		SkinManager.deactivate_skins(skin_set)
