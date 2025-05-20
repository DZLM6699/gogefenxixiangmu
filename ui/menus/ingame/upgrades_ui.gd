class_name UpgradesUI
extends Control

signal options_processed
signal upgrade_selected(upgrade_data, upgrade)
signal consumable_selected(consumable)
signal item_take_button_pressed(item_data, consumable)
signal item_discard_button_pressed(item_data, consumable)

export  var is_coop_ui: = false

onready var _popup_manager: PopupManager = $PopupManager
onready var _stats_container = get_node_or_null("%StatsContainer")
onready var _stat_popup1 = $"%StatPopup1"
onready var _stat_popup2 = get_node_or_null("%StatPopup2")
onready var _stat_popup3 = get_node_or_null("%StatPopup3")
onready var _stat_popup4 = get_node_or_null("%StatPopup4")
onready var _player_container1 = $"%UpgradesUIPlayerContainer1"
onready var _player_container2 = get_node_or_null("%UpgradesUIPlayerContainer2")
onready var _player_container3 = get_node_or_null("%UpgradesUIPlayerContainer3")
onready var _player_container4 = get_node_or_null("%UpgradesUIPlayerContainer4")

class ConsumableToProcess:
	var consumable_data: ConsumableData
	var player_index: int
var _consumables_to_process: Array

class UpgradeToProcess:
	var level: int
	var player_index: int
var _upgrades_to_process: Array

var _showing_option: = [null, null, null, null]
var _player_is_choosing: = [false, false, false, false]
var _extra_items_to_process: = [[], [], [], []]


func _ready() -> void :
	
	if RunData.is_coop_run != is_coop_ui:
		return

	var player_count = RunData.get_player_count()

	if RunData.is_coop_run:
		for i in CoopService.MAX_PLAYER_COUNT:
			_get_player_container(i).visible = i < player_count

	var stat_popups = [_stat_popup1, _stat_popup2, _stat_popup3, _stat_popup4]
	for player_index in player_count:
		var player_container: = _get_player_container(player_index)
		var _error_connect = player_container.connect("choose_button_pressed", self, "_on_choose_button_pressed", [player_index])
		_error_connect = player_container.connect("item_take_button_pressed", self, "_on_take_button_pressed", [player_index])
		_error_connect = player_container.connect("item_discard_button_pressed", self, "_on_discard_button_pressed", [player_index])

		var stat_popup = stat_popups[player_index]
		if RunData.is_coop_run:
			stat_popup.parent_node_path = _get_player_container(player_index).carousel.get_path()
		else:
			stat_popup.parent_node_path = _stats_container.get_path()
		_popup_manager.add_stat_popup(stat_popup, player_index)

		if RunData.is_coop_run:
			player_container.focus_emulator = Utils.get_focus_emulator(player_index, self)
			_popup_manager.connect_stats_container(player_container.primary_stats_container)
			_popup_manager.connect_stats_container(player_container.secondary_stats_container)
			_popup_manager.add_item_popup(player_container.item_popup, player_index)
			_popup_manager.connect_inventory_container(player_container.player_gear_container.weapons_container)
			_popup_manager.connect_inventory_container(player_container.player_gear_container.items_container)

	if not RunData.is_coop_run:
		_popup_manager.connect_stats_container(_stats_container)


func focus() -> void :
	for player_index in RunData.get_player_count():
		var player_container: = _get_player_container(player_index)
		player_container.focus()


func show_options(consumables_to_process: Array, upgrades_to_process: Array) -> bool:
	_consumables_to_process = consumables_to_process
	_upgrades_to_process = upgrades_to_process
	for player_index in RunData.get_player_count():
		var player_container = _get_player_container(player_index)
		player_container.update_inventory()
		player_container.show_remaining_things(upgrades_to_process[player_index], consumables_to_process[player_index])
	return _show_next_player_options()



func _show_next_player_options() -> bool:
	for player_index in RunData.get_player_count():
		if _player_is_choosing[player_index]:
			continue

		var player_container = _get_player_container(player_index)
		if _extra_items_to_process[player_index]:
			var extra_item: ItemData = _extra_items_to_process[player_index].pop_front()
			player_container.show_item(extra_item)
			_player_is_choosing[player_index] = true
			continue

		var do_process_consumables: bool = not _consumables_to_process[player_index].empty()
		var player_options_to_process = _consumables_to_process[player_index] if do_process_consumables else _upgrades_to_process[player_index]
		if player_options_to_process.empty():
			_get_player_container(player_index).finish()
			continue

		var option_to_process = player_options_to_process.pop_front()
		if do_process_consumables:
			set_extra_items_in_crate_effect(player_index)
			player_container.show_consumable_data(option_to_process.consumable_data)

		else:
			player_container.show_upgrades_for_level(option_to_process.level)
		_update_player_stats(player_index)
		show()
		player_container.focus()
		_player_is_choosing[player_index] = true
		_showing_option[player_index] = option_to_process
	for player_index in RunData.get_player_count():
		if _player_is_choosing[player_index]:
			return true
	return false


func set_extra_items_in_crate_effect(player_index: int) -> void :
	if _extra_items_to_process[player_index]:
		return

	var extra_item_effects: Array = RunData.get_player_effect("extra_item_in_crate", player_index)
	for effect in extra_item_effects:
		if Utils.get_chance_success(effect[1] / 100.0):
			var item_data
			var add_item = true

			if effect[0] == "random":
				item_data = ItemService.get_rand_item_for_wave(RunData.current_wave, player_index)
				RunData.add_tracked_value(player_index, "item_treasure_map", 1)
			else:
				item_data = ItemService.get_item_from_id(effect[0]).duplicate()
				item_data.value = 1
				var player_items = RunData.get_player_items(player_index)

				for locked_item in RunData.get_player_locked_shop_items(player_index):
					if locked_item[0] is ItemData:
						player_items.push_back(locked_item[0])

				var limited_items = ItemService.get_limited_items(player_items)

				if limited_items.has(item_data.my_id) and limited_items[item_data.my_id][1] >= limited_items[item_data.my_id][0].max_nb:
					add_item = false

			if add_item:
				_extra_items_to_process[player_index].append(item_data)


func _update_player_stats(player_index: int) -> void :
	if RunData.is_coop_run:
		_get_player_container(player_index).update_stats()
	else:
		_stats_container.update_player_stats(player_index)


func _on_choose_button_pressed(upgrade_data: UpgradeData, player_index: int) -> void :
	_player_is_choosing[player_index] = false
	emit_signal("upgrade_selected", upgrade_data, _showing_option[player_index])
	
	LinkedStats.reset_player(player_index)
	_update_player_stats(player_index)
	if not _show_next_player_options():
		emit_signal("options_processed")


func _on_take_button_pressed(item_data: ItemParentData, player_index: int) -> void :
	_player_is_choosing[player_index] = false
	var consumable = _showing_option[player_index]
	emit_signal("item_take_button_pressed", item_data, consumable)
	
	LinkedStats.reset_player(player_index)
	_update_player_stats(player_index)
	if not _extra_items_to_process[player_index]:
		emit_signal("consumable_selected", consumable)
		_showing_option[player_index] = null
	if not _show_next_player_options():
		emit_signal("options_processed")


func _on_discard_button_pressed(item_data: ItemParentData, player_index: int) -> void :
	_player_is_choosing[player_index] = false
	var consumable = _showing_option[player_index]
	emit_signal("item_discard_button_pressed", item_data, consumable)
	if not _extra_items_to_process[player_index]:
		emit_signal("consumable_selected", consumable)
		_showing_option[player_index] = null
	if not _show_next_player_options():
		emit_signal("options_processed")


func _get_player_container(player_index: int) -> UpgradesUIPlayerContainer:
	return [_player_container1, _player_container2, _player_container3, _player_container4][player_index]
