class_name ShopItem
extends Control

signal buy_button_pressed(shop_item)
signal steal_button_pressed(shop_item)
signal shop_item_deactivated(shop_item)
signal shop_item_focused(shop_item)
signal shop_item_unfocused(shop_item)
signal mouse_hovered_category(shop_item)
signal mouse_exited_category(shop_item)

export  var player_index: = 0

var item_data: ItemParentData
var active: = true
var value: = 1
var locked = false
var item_steals: = 0

var wave_value: = 1

onready var _panel = $PanelContainer
onready var _button = $"%BuyButton"
onready var _item_description = $"%ItemDescription"
onready var _steal_button = $"%StealButton"
onready var _lock_button = $"%LockButton"
onready var _lock_icon = $"%LockIcon"


func disable_focus() -> void :
	_button.focus_mode = FOCUS_NONE


func enable_focus() -> void :
	if active:
		_button.focus_mode = FOCUS_ALL


func disable_lock_focus() -> void :
	_lock_button.focus_mode = FOCUS_NONE


func enable_lock_focus() -> void :
	if active:
		_lock_button.focus_mode = FOCUS_ALL


func deactivate() -> void :
	modulate = Color(1, 1, 1, 0)
	_button.disable()
	_steal_button.disable()
	_steal_button.pressed = false
	_lock_button.disable()
	_lock_button.pressed = false
	_lock_icon.hide()
	locked = false
	active = false
	emit_signal("shop_item_deactivated", self)


func activate() -> void :
	modulate = Color(1, 1, 1, 1)
	_button.reinitialize_colors(player_index)
	if item_steals > 0:
		_steal_button.activate()
	else:
		_steal_button.disable()
		_steal_button.hide()

	manage_lock_button_visibility()

	
	if not _lock_button.visible and not _steal_button.visible:
		_steal_button.modulate = Color(1, 1, 1, 0)
		_steal_button.show()

	_button.activate()
	active = true


func manage_lock_button_visibility() -> void :
	if RunData.get_player_effect_bool("disable_item_locking", player_index):
		_lock_button.disable()
		_lock_button.hide()
	else:
		if not RunData.is_coop_run:
			_lock_button.show()
		_lock_button.activate()


func set_shop_item(p_item_data: ItemParentData, p_wave_value: int = RunData.current_wave) -> void :
	activate()
	item_data = p_item_data
	wave_value = p_wave_value
	value = ItemService.get_value(wave_value, p_item_data.value, player_index, true, p_item_data is WeaponData, p_item_data.my_id)

	var item_count: = 1
	var additional_icon: Image

	if RunData.get_player_effect_bool("hp_shop", player_index):
		value = ceil(value / 20.0) as int
		var material_icon: Image = ItemService.get_stat_icon("stat_max_hp").get_data()
		var texture: = ImageTexture.new()
		texture.create_from_image(material_icon)
		_button.set_material_icon(texture)

	var current_character = RunData.get_player_character(player_index)
	var duplicate_item_effects: Array = RunData.get_player_effect("duplicate_item", player_index)
	var duplicate_item_icon = ItemService.get_icon_for_duplicate_shop_item(current_character, RunData.get_player_items(player_index), RunData.get_player_weapons(player_index), item_data, player_index)

	if duplicate_item_icon != null:
		additional_icon = duplicate_item_icon

	if duplicate_item_effects.size() > 0:

		if item_data.get_category() == Category.ITEM:
			var remaining_item_count: int = RunData.get_remaining_max_nb_item(item_data, player_index)
			var max_clones: = 1
			for effect in duplicate_item_effects:
				max_clones = min(max_clones + effect[1], remaining_item_count) as int
			item_count = max_clones

			if remaining_item_count > 1:
				
				var item_id: String = duplicate_item_effects[0][0]
				var source_item: ItemData = ItemService.get_item_from_id(item_id)
				additional_icon = source_item.icon.get_data()

	_button.remove_additional_icon()

	if additional_icon:
		var texture = ImageTexture.new()
		texture.create_from_image(additional_icon)
		_button.set_additional_icon(texture)

	_button.set_value(value, RunData.get_player_currency(player_index))

	var steal_spawn_elite_effect = RunData.get_player_effect("item_steals_spawns_random_elite", player_index)
	var steal_chance = ItemService.get_chance_getting_caught(self, RunData.current_wave, steal_spawn_elite_effect / 100.0)

	var displayed_steal_chance = steal_chance * 100.0

	if displayed_steal_chance < 1.0:
		displayed_steal_chance = stepify(displayed_steal_chance, 0.1)
	else:
		displayed_steal_chance = stepify(displayed_steal_chance, 1.0)

	if not RunData.is_coop_run:
		_steal_button.text = tr("MENU_STEAL") + "  " + str(displayed_steal_chance) + "%"

	_item_description.set_item(p_item_data, player_index, item_count)

	if not p_item_data.is_lockable:
		_lock_button.disable()
		_lock_button.hide()
	else:
		manage_lock_button_visibility()

	_set_panel_lock_style()


func steal_item() -> void :
	_steal_button.emit_signal("pressed")


func update_color() -> void :
	_button.set_color_from_currency(RunData.get_player_currency(player_index))


func lock_visually() -> void :

	if not item_data: return

	locked = true
	_lock_button.set_pressed_no_signal(true)
	_lock_icon.show()
	_set_panel_lock_style()


func unlock_visually() -> void :

	if not item_data: return
	locked = false
	_lock_button.set_pressed_no_signal(false)
	_lock_icon.hide()
	_set_panel_lock_style()


func _on_LockButton_toggled(button_pressed: bool) -> void :
	change_lock_status(button_pressed)


func change_lock_status(button_pressed: bool) -> void :
	if RunData.get_player_effect_bool("disable_item_locking", player_index):
		return

	if button_pressed:
		lock_visually()
		RunData.lock_player_shop_item(item_data, wave_value, player_index)
	else:
		unlock_visually()
		RunData.unlock_player_shop_item(item_data, player_index)


func get_category_text_pos() -> Vector2:
	return _item_description._category.rect_global_position


func _set_panel_lock_style() -> void :
	var panel = _item_description.icon_panel if RunData.is_coop_run else _panel
	var stylebox = panel.get_stylebox("panel").duplicate()
	if RunData.is_coop_run:
		var tier_color = ItemService.get_color_from_tier(item_data.tier)
		tier_color.a = stylebox.bg_color.a
		stylebox.bg_color = tier_color
		stylebox.set_border_width_all(3 if locked else 0)
		stylebox.border_blend = true
	else:
		ItemService.change_panel_stylebox_from_tier(stylebox, item_data.tier)
	if locked:
		stylebox.border_color = Color.white
	panel.add_stylebox_override("panel", stylebox)


func _on_BuyButton_focus_entered() -> void :
	emit_signal("shop_item_focused", self)


func _on_BuyButton_focus_exited() -> void :
	emit_signal("shop_item_unfocused", self)


func _on_BuyButton_pressed() -> void :
	emit_signal("buy_button_pressed", self)


func _on_StealButton_pressed() -> void :
	emit_signal("steal_button_pressed", self)


func _on_ItemDescription_mouse_hovered_category() -> void :
	if active:
		emit_signal("mouse_hovered_category", self)


func _on_ItemDescription_mouse_exited_category() -> void :
	emit_signal("mouse_exited_category", self)


func _on_BuyButton_mouse_exited() -> void :
	emit_signal("shop_item_unfocused", self)


func _on_BuyButton_mouse_entered() -> void :
	emit_signal("shop_item_focused", self)
