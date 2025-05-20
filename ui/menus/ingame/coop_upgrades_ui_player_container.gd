class_name CoopUpgradesUIPlayerContainer
extends UpgradesUIPlayerContainer

onready var carousel = $"%Carousel"
onready var primary_stats_container = $"%PrimaryStatsContainer"
onready var secondary_stats_container = $"%SecondaryStatsContainer"
onready var item_popup = $"%ItemPopup"
onready var player_gear_container = $"%PlayerGearContainer"
onready var _toggle_popup_hint = $"%TogglePopupHint"
onready var _margin_container = $"MarginContainer"
onready var _checkmark_group = $"%CheckmarkGroup"
onready var _coop_player_label = $"%CoopPlayerLabel"
onready var _gold_icon = $"%GoldIcon"
onready var _gold_label = $"%GoldLabel"

var focus_emulator: FocusEmulator


var _resume_upgrade_control_focus = null
var _resume_inventory_control_focus = null


func _ready() -> void :
	if player_index >= RunData.get_player_count():
		return
	carousel.player_index = player_index
	for stats_container in [primary_stats_container, secondary_stats_container]:
		stats_container.update_player_stats(player_index)
	_coop_player_label.player_index = player_index
	var player_color = CoopService.get_player_color(player_index)
	_gold_icon.modulate = player_color
	_gold_label.add_color_override("font_color", player_color)
	_reroll_button.gold_icon.modulate = player_color
	_update_stylebox()

	player_gear_container.player_index = player_index
	item_popup.player_index = player_index
	_toggle_popup_hint.player_index = player_index
	item_popup.connect("popup_toggled", self, "_on_popup_toggled")

	
	if RunData.get_player_count() == 2:
		_margin_container.add_constant_override("margin_left", 75)
		_margin_container.add_constant_override("margin_right", 75)


func update_inventory() -> void :
	var weapons = RunData.get_player_weapons(player_index)
	var items = RunData.get_player_items(player_index)
	player_gear_container.set_weapons_data(weapons)
	player_gear_container.set_items_data(items)


func finish() -> void :
	_update_gold_label()
	_checkmark_group.show()
	_items_container.hide()
	_upgrades_container.hide()
	focus_emulator.player_index = - 1


func focus() -> void :
	_set_focus_neighbours()
	if not RunData.is_coop_run or carousel.index == 0:
		
		if _items_container.visible:
			Utils.focus_player_control(_take_button, player_index, focus_emulator)
		elif _resume_upgrade_control_focus:
			Utils.focus_player_control(_resume_upgrade_control_focus, player_index, focus_emulator)
		else:
			var upgrade_ui = _upgrade_ui_2 if _upgrade_ui_2.visible else _upgrade_ui_1
			Utils.focus_player_control(upgrade_ui.button, player_index, focus_emulator)
		return
	if not carousel.are_trigger_buttons_active():
		
		return
	elif carousel.index == 1:
		if _resume_inventory_control_focus:
			Utils.focus_player_control(_resume_inventory_control_focus, player_index, focus_emulator)
		else:
			Utils.focus_player_control(player_gear_container.items_container.get_element(0), player_index, focus_emulator)
	elif carousel.index == 2:
		
		
		Utils.focus_player_control(primary_stats_container.general_stats[0], player_index, focus_emulator)
	else:
		
		focus_emulator.focused_control = null


func update_stats() -> void :
	primary_stats_container.update_player_stats(player_index)
	secondary_stats_container.update_player_stats(player_index)


func _update_gold_label() -> void :
	_gold_label.update_value(RunData.get_player_gold(player_index))


func _update_stylebox() -> void :
	var stylebox = get_stylebox("panel").duplicate()
	CoopService.change_stylebox_for_player(stylebox, player_index)
	add_stylebox_override("panel", stylebox)


func _set_focus_neighbours() -> void :
	if carousel.index == 0:
		if carousel.are_trigger_buttons_active():
			_upgrade_ui_1.button.focus_neighbour_top = _upgrade_ui_1.button.get_path_to(_reroll_button)
			_reroll_button.focus_neighbour_bottom = _reroll_button.get_path_to(_upgrade_ui_1.button)
		else:
			_reroll_button.focus_neighbour_bottom = _reroll_button.get_path_to(carousel.arrow_right)
			carousel.arrow_right.focus_neighbour_top = carousel.arrow_right.get_path_to(_reroll_button)

	elif carousel.index == 1:
		var weapons_container = player_gear_container.weapons_container
		var items_container = player_gear_container.items_container
		var first_weapon = weapons_container.get_element(0)
		var first_item = first_weapon if first_weapon != null else items_container.get_element(0)
		var last_item = items_container.get_element(items_container.get_element_count() - 1)
		if carousel.are_trigger_buttons_active():
			weapons_container.focus_neighbour_top = weapons_container.get_path_to(last_item)
			items_container.focus_neighbour_bottom = items_container.get_path_to(first_item)
		else:
			carousel.arrow_left.focus_neighbour_top = carousel.arrow_left.get_path_to(last_item)
			carousel.arrow_right.focus_neighbour_top = carousel.arrow_right.get_path_to(last_item)
			weapons_container.focus_neighbour_top = weapons_container.get_path_to(carousel.arrow_left)
			items_container.focus_neighbour_bottom = items_container.get_path_to(carousel.arrow_left)
		weapons_container.forward_focus_settings_to_inventory()
		items_container.forward_focus_settings_to_inventory()

	elif carousel.index == 2:
		var loop_focus = carousel.are_trigger_buttons_active()
		primary_stats_container.loop_focus_top = loop_focus
		primary_stats_container.loop_focus_bottom = loop_focus
		if loop_focus:
			primary_stats_container.set_focus_neighbours()
		else:
			carousel.arrow_left.focus_neighbour_top = carousel.arrow_left.get_path_to(primary_stats_container.last_primary_stat)
			carousel.arrow_right.focus_neighbour_top = carousel.arrow_right.get_path_to(primary_stats_container.last_primary_stat)
			primary_stats_container.last_primary_stat.focus_neighbour_bottom = primary_stats_container.last_primary_stat.get_path_to(carousel.arrow_left)

	else:
		for side in [MARGIN_TOP, MARGIN_TOP, MARGIN_LEFT, MARGIN_RIGHT]:
			carousel.arrow_left.set_focus_neighbour(side, NodePath(""))


func _on_Carousel_index_changed(index: int) -> void :
	_set_focus_neighbours()
	if not carousel.are_trigger_buttons_active():
		
		return
	var focused_control = focus_emulator.focused_control
	if focused_control != null:
		if carousel.get_content_element(0).is_a_parent_of(focused_control):
			_resume_upgrade_control_focus = focused_control
		elif carousel.get_content_element(1).is_a_parent_of(focused_control):
			_resume_inventory_control_focus = focused_control
	focus()
	if index == 0:
		_resume_upgrade_control_focus = null
	elif index == 1:
		_resume_inventory_control_focus = null


func _on_popup_toggled(hide_popup: bool, _player_index: int) -> void :
	if hide_popup:
		_toggle_popup_hint.set_text("COOP_POPUP_ENABLE_HINT")
	else:
		_toggle_popup_hint.set_text("COOP_POPUP_DISABLE_HINT")
