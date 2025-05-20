class_name UpgradesUIPlayerContainer
extends Container

export (int) var player_index: = 0

signal choose_button_pressed(upgrade)
signal item_take_button_pressed(item_data)
signal item_discard_button_pressed(item_data)

onready var _button_delay_timer = $ButtonDelayTimer
onready var _upgrade_ui_1 = $"%UpgradeUI"
onready var _upgrade_ui_2 = $"%UpgradeUI2"
onready var _upgrade_ui_3 = $"%UpgradeUI3"
onready var _upgrade_ui_4 = $"%UpgradeUI4"
onready var _reroll_button = $"%RerollButton"

onready var _item_panel_container = $"%ItemPanelContainer"
onready var _item_description = $"%ItemDescription"
onready var _take_button = $"%TakeButton"
onready var _discard_button = $"%DiscardButton"

onready var _items_container = $"%ItemsContainer"
onready var _upgrades_container = $"%UpgradesContainer"


onready var _things_to_process_container = get_node_or_null("%UIThingsToProcessPlayerContainer")

var _level: = 0
var _reroll_price: = 0
var _reroll_discount: = 0
var _reroll_count: = 0
var _old_upgrades = []
var _consumable_data: ConsumableData = null
var _item_data: ItemParentData = null
var _button_pressed: = false


func _ready() -> void :
	for upgrade_ui in _get_upgrade_uis():
		upgrade_ui.connect("choose_button_pressed", self, "_on_choose_button_pressed")
	_items_container.hide()
	_upgrades_container.hide()


func show_upgrades_for_level(level: int) -> void :
	if _reroll_price == 0:
		var result = ItemService.get_reroll_price(RunData.current_wave, _reroll_count, player_index)
		_reroll_price = result[0]
		_reroll_discount = result[1]
	_reroll_button.init(_reroll_price, player_index)

	_level = level
	var upgrades = ItemService.get_upgrades(level, 4, _old_upgrades, player_index)
	_old_upgrades = upgrades

	var upgrade_uis: = _get_upgrade_uis()
	for i in upgrade_uis.size():
		var upgrade_ui = upgrade_uis[i]
		upgrade_ui.visible = i < upgrades.size()
		if upgrade_ui.visible:
			upgrade_ui.set_upgrade(upgrades[i], player_index)

	_reroll_button.visible = upgrades.size() > 1
	_update_gold_label()
	_items_container.hide()
	_upgrades_container.show()


func show_consumable_data(consumable_data: ConsumableData):
	var item_data = ItemService.process_item_box(consumable_data, RunData.current_wave, player_index)
	_consumable_data = consumable_data
	show_item(item_data)


func show_item(item_data: ItemParentData) -> void :
	_item_data = item_data

	_item_description.set_item(item_data, player_index)
	_discard_button.text = tr("MENU_RECYCLE") + " (+" + str(ItemService.get_recycling_value(RunData.current_wave, item_data.value, player_index, item_data is WeaponData)) + ")"

	var duplicate_item_icon = ItemService.get_icon_for_duplicate_shop_item(RunData.get_player_character(player_index), RunData.get_player_items(player_index), RunData.get_player_weapons(player_index), item_data, player_index)

	if duplicate_item_icon != null:
		duplicate_item_icon = duplicate_item_icon.duplicate()
		duplicate_item_icon.resize(52, 52)
		var texture = ImageTexture.new()
		texture.create_from_image(duplicate_item_icon)
		_take_button.icon = texture
	else:
		_take_button.icon = null

	var stylebox_color = _item_panel_container.get_stylebox("panel").duplicate()
	ItemService.change_panel_stylebox_from_tier(stylebox_color, item_data.tier)
	_item_panel_container.add_stylebox_override("panel", stylebox_color)

	_update_gold_label()
	_items_container.show()
	_upgrades_container.hide()


func show_remaining_things(upgrades_to_process: Array, consumables_to_process: Array) -> void :
	if _things_to_process_container == null:
		return
	for upgrade_to_process in upgrades_to_process:
		_things_to_process_container.upgrades.add_element(ItemService.get_icon("icon_upgrade_to_process"), upgrade_to_process.level)
	for consumable_to_process in consumables_to_process:
		_things_to_process_container.consumables.add_element(consumable_to_process.consumable_data)


func update_inventory() -> void :
	pass


func update_stats() -> void :
	pass


func finish() -> void :
	pass


func _update_gold_label() -> void :
	pass


func focus() -> void :
	if _items_container.visible:
		_take_button.call_deferred("grab_focus")
	else:
		var upgrade_ui = _upgrade_ui_2 if _upgrade_ui_2.visible else _upgrade_ui_1
		upgrade_ui.button.call_deferred("grab_focus")


func _get_upgrade_uis() -> Array:
	return [_upgrade_ui_1, _upgrade_ui_2, _upgrade_ui_3, _upgrade_ui_4]


func _on_RerollButton_pressed() -> void :
	if RunData.get_player_gold(player_index) < _reroll_price or _button_pressed:
		return
	_button_pressed = true
	_button_delay_timer.start()
	RunData.remove_gold(_reroll_price, player_index)
	_update_gold_label()

	var spyglass_count: int = RunData.get_nb_item("item_spyglass", player_index)
	if spyglass_count > 0:
		var reroll_price_amount: int = RunData.get_player_effect("reroll_price", player_index)
		var spyglass_item = ItemService.get_item_from_id("item_spyglass")
		var sypglass_amount: int = spyglass_item.effects[1].value
		var total_spyglass_amount = spyglass_count * sypglass_amount
		var spyglass_factor = float(total_spyglass_amount) / float(reroll_price_amount)
		RunData.add_tracked_value(player_index, "item_spyglass", ceil(_reroll_discount * spyglass_factor) as int)

	_reroll_count += 1
	var result = ItemService.get_reroll_price(RunData.current_wave, _reroll_count, player_index)
	_reroll_price = result[0]
	_reroll_discount = result[1]
	show_upgrades_for_level(_level)


func _on_ButtonDelayTimer_timeout() -> void :
	_button_pressed = false


func _on_choose_button_pressed(upgrade: UpgradeData) -> void :
	if _button_pressed: return
	_button_pressed = true
	_button_delay_timer.start()
	if _things_to_process_container:
		_things_to_process_container.upgrades.remove_element(_level)
	emit_signal("choose_button_pressed", upgrade)


func _on_TakeButton_pressed():
	if _button_pressed: return
	_button_pressed = true
	_button_delay_timer.start()
	if _things_to_process_container:
		_things_to_process_container.consumables.remove_element(_consumable_data)
	emit_signal("item_take_button_pressed", _item_data)


func _on_DiscardButton_pressed():
	if _button_pressed: return
	_button_pressed = true
	_button_delay_timer.start()
	if _things_to_process_container:
		_things_to_process_container.consumables.remove_element(_consumable_data)
	emit_signal("item_discard_button_pressed", _item_data)
