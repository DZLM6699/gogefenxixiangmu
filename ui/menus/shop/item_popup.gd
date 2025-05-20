class_name ItemPopup
extends BasePopup

signal item_discard_button_pressed(item_data)
signal item_cancel_button_pressed(item_data)
signal item_combine_button_pressed(item_data)


export (bool) var buttons_enabled = false setget _set_buttons_enabled
func _set_buttons_enabled(value: bool) -> void :
	buttons_enabled = value
	if is_inside_tree():
		_update_button_visibilities()


var player_index: = 0 setget _set_player_index
func _set_player_index(value: int) -> void :
	player_index = value

var item_steals: = 0

onready var _panel = $"%ItemPanelUI"
onready var _combine_button = $"%CombineButton"
onready var _discard_button = $"%DiscardButton"
onready var _cancel_button = $"%CancelButton"
onready var _synergy_container = $"%SynergyContainer"
onready var _last_wave_info_container = $"%LastWaveInfoContainer"

var _item_data: ItemParentData = null
var _focused: = false
var _is_inventory_element: = false


func _ready() -> void :
	_set_buttons_enabled(buttons_enabled)

	var last_wave_dmg_stylebox = _last_wave_info_container._panel_container.get_stylebox("panel").duplicate()
	last_wave_dmg_stylebox.border_color = Color(0.3, 0.3, 0.3)
	_last_wave_info_container._panel_container.add_stylebox_override("panel", last_wave_dmg_stylebox)

	for synergy_panel in _synergy_container.get_children():
		synergy_panel.add_stylebox_override("panel", last_wave_dmg_stylebox)

	set_process_input(false)

func display_element(element: InventoryElement) -> void :
	display_item_data(element.item, element, true)


func display_item_data(item_data: ItemParentData, attachment: Control, is_inventory_element: = false) -> void :
	_item_data = item_data
	_attachment = attachment
	_is_inventory_element = is_inventory_element
	_panel.set_data(item_data, player_index)
	set_synergies_text(item_data)

	_last_wave_info_container.hide()
	if is_inventory_element and item_data is WeaponData and item_data.dmg_dealt_last_wave != 0:
		_last_wave_info_container.display(Text.text("DAMAGE_DEALT_LAST_WAVE", [Text.get_formatted_number(item_data.dmg_dealt_last_wave)], [Sign.POSITIVE]))
	elif is_inventory_element and item_data is ItemData and "item_builder_turret" in item_data.my_id:

		var tracked_id = item_data.my_id

		
		if RunData.tracked_item_effects[player_index][item_data.my_id] == 0:
			var turret_lvl = item_data.my_id.trim_prefix("item_builder_turret_") as int

			if turret_lvl > 0:
				tracked_id = "item_builder_turret_" + str(turret_lvl - 1)

		_last_wave_info_container.display(Text.text("DAMAGE_DEALT_LAST_WAVE", [Text.get_formatted_number(RunData.tracked_item_effects[player_index][tracked_id])], [Sign.POSITIVE]))

	_update_button_visibilities()

	var stylebox_color = _panel.get_stylebox("panel").duplicate()
	ItemService.change_panel_stylebox_from_tier(stylebox_color, item_data.tier, true)
	_panel.add_stylebox_override("panel", stylebox_color)

	show()
	set_pos_from(attachment, _panel)


func set_synergies_text(item_data: ItemParentData) -> void :
	_synergy_container.set_synergies_text(item_data, player_index)


func set_synergies_visible(visible: bool) -> void :
	_synergy_container.visible = visible


func _input(event: InputEvent) -> void :
	if _focused and Utils.is_player_cancel_pressed(event, player_index):
		emit_signal("item_cancel_button_pressed", _item_data)
		get_viewport().set_input_as_handled()


func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not RunData.is_coop_run:
			set_process_input(is_visible_in_tree())


func focus() -> void :
	_focused = true
	
	_update_button_visibilities()
	assert (_cancel_button.visible)
	_cancel_button.grab_focus()


func hide(_player_index: = - 1) -> void :
	.hide(_player_index)
	_focused = false
	
	_update_button_visibilities()


func cancel() -> void :
	if visible:
		_on_CancelButton_pressed()


func _update_button_visibilities() -> void :
	var buttons: = [_combine_button, _discard_button, _cancel_button]
	if _item_data == null or not should_show_buttons(_item_data, _focused):
		for button in buttons:
			button.hide()
			button.focus_mode = FOCUS_NONE
		return
	for button in buttons:
		button.show()
		
		
		button.focus_mode = FOCUS_ALL if _focused else FOCUS_NONE
	_combine_button.visible = RunData.can_combine(_item_data, player_index)

	var base_recycling_value = _item_data.value
	var specific_recycling_price_factor = 1.0

	for specific_item_price in RunData.get_player_effect("specific_items_price", player_index):
		if specific_item_price[0] in _item_data.my_id:
			specific_recycling_price_factor = specific_item_price[1]
			break

	base_recycling_value *= specific_recycling_price_factor

	_discard_button.text = tr("MENU_RECYCLE") + " (+" + str(ItemService.get_recycling_value(RunData.current_wave, base_recycling_value, player_index, _item_data is WeaponData)) + ")"

	if RunData.get_player_effect_bool("lock_current_weapons", player_index):
		_combine_button.hide()
		_discard_button.hide()


func will_show_buttons_when_focused(item_data: ItemParentData) -> bool:
	return should_show_buttons(item_data, true)


func should_show_buttons(item_data: ItemParentData, focused: bool) -> bool:
	
	return buttons_enabled and item_data is WeaponData and ( not RunData.is_coop_run or focused)


func _get_popup_width_factor() -> float:
	
	return 0.8


func _on_DiscardButton_pressed() -> void :
	emit_signal("item_discard_button_pressed", _item_data)
	_focused = false


func _on_CancelButton_pressed() -> void :
	emit_signal("item_cancel_button_pressed", _item_data)
	_focused = false


func _on_CombineButton_pressed() -> void :
	emit_signal("item_combine_button_pressed", _item_data)
	_focused = false
