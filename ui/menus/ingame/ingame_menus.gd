class_name IngameMenus
extends Menus

onready var _menu_confirm = $MenuConfirm
onready var _menu_restart = $MenuRestart
onready var _menu_end_run = $MenuEndRun


func _ready() -> void :
	_main_menu.connect("quit_button_pressed", self, "on_quit_button_pressed")
	_main_menu.connect("restart_button_pressed", self, "on_restart_button_pressed")
	_main_menu.connect("end_run_button_pressed", self, "on_end_run_button_pressed")
	_menu_confirm.connect("cancel_button_pressed", self, "on_cancel_button_pressed")
	_menu_restart.connect("cancel_button_pressed", self, "on_restart_cancel_button_pressed")
	_menu_end_run.connect("cancel_button_pressed", self, "on_end_run_cancel_button_pressed")


func on_restart_button_pressed() -> void :
	switch(_main_menu, _menu_restart)


func on_quit_button_pressed() -> void :
	switch(_main_menu, _menu_confirm)


func on_cancel_button_pressed() -> void :
	switch(_menu_confirm, _main_menu)


func on_restart_cancel_button_pressed() -> void :
	switch(_menu_restart, _main_menu)


func on_end_run_cancel_button_pressed() -> void :
	switch(_menu_end_run, _main_menu)


func on_end_run_button_pressed() -> void :
	switch(_main_menu, _menu_end_run)
