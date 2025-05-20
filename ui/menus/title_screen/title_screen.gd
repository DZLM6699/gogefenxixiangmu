class_name TitleScreen
extends Control

onready var _menus: Control = $"%Menus"
onready var _main_menu: VBoxContainer = $"%MainMenu"
onready var _animated_background_container: Control = $"%AnimatedBackgroundContainer"
onready var _attenuate_background: ColorRect = $"%AttenuateBackground"


func _ready() -> void :

	var _e = ProgressData.connect("dlc_activated", self, "on_dlc_changed")
	_e = ProgressData.connect("dlc_deactivated", self, "on_dlc_changed")

	reload_background()

	if ProgressData.saved_run_state.has_run_state:
		_main_menu.continue_button.show()
		_main_menu.continue_button.activate()
	else:
		_main_menu.continue_button.hide()
		_main_menu.continue_button.disable()

	RunData.current_zone = 0
	RunData.reset()

	if RunData.reload_music:
		MusicManager.play(0)
	else:
		RunData.reload_music = true

	var _switched_result: = _menus.connect("menu_page_switched", self, "on_menu_page_switched")
	_main_menu.init()


func on_dlc_changed(_dlc_id: String) -> void :
	reload_background()


func reload_background() -> void :

	for child in _animated_background_container.get_children():
		child.queue_free()

	var animated_background = ItemService.get_element(ItemService.title_screen_backgrounds, "base")

	if ProgressData.is_dlc_available_and_active("abyssal_terrors"):
		animated_background = ItemService.get_element(ItemService.title_screen_backgrounds, "abyssal_terrors")

	var instance = animated_background.scene.instance()
	_animated_background_container.add_child(instance)


func on_menu_page_switched(_from: Control, to: Control) -> void :
	if to != _main_menu:
		_attenuate_background.show()
	else:
		_attenuate_background.hide()
