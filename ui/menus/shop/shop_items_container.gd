class_name ShopItemsContainer
extends Container

signal shop_item_bought(shop_item)
signal shop_item_stolen(shop_item)
signal shop_item_insufficient_currency(shop_item)
signal mouse_hovered_category(shop_item)
signal mouse_exited_category(shop_item)
signal shop_item_deactivated(shop_item)
signal shop_item_focused(shop_item)
signal shop_item_unfocused(shop_item)

export (Array, NodePath) var _shop_items_node_paths: Array

export  var player_index: = 0 setget _set_player_index
func _set_player_index(value: int) -> void :
	player_index = value
	for shop_item in _shop_items:
		shop_item.player_index = value

var item_steals: = 0

var _shop_items: Array
var _buy_delay_timer: Timer
var _is_delay_active = false


func _ready() -> void :
	_buy_delay_timer = Timer.new()
	_buy_delay_timer.wait_time = 0.05
	_buy_delay_timer.one_shot = true

	var _delay = _buy_delay_timer.connect("timeout", self, "_on_BuyDelayTimer_timeout")
	add_child(_buy_delay_timer)

	for node_path in _shop_items_node_paths:
		_shop_items.push_back(get_node(node_path))

	connect_shop_items()


func connect_shop_items() -> void :
	for shop_item in _shop_items:
		var _error_buy = shop_item.connect("buy_button_pressed", self, "on_shop_item_buy_button_pressed")
		var _error_steal = shop_item.connect("steal_button_pressed", self, "on_shop_item_steal_button_pressed")
		var _error_deactivate = shop_item.connect("shop_item_deactivated", self, "on_shop_item_deactivated")
		var _error_focused = shop_item.connect("shop_item_focused", self, "on_shop_item_focused")
		var _error_unfocused = shop_item.connect("shop_item_unfocused", self, "on_shop_item_unfocused")
		var _error_category_hovered = shop_item.connect("mouse_hovered_category", self, "on_mouse_hovered_category")
		var _error_category_exited = shop_item.connect("mouse_exited_category", self, "on_mouse_exited_category")


func on_shop_item_buy_button_pressed(shop_item: ShopItem) -> void :
	if _is_delay_active:
		return
	if RunData.get_player_currency(player_index) < shop_item.value:
		emit_signal("shop_item_insufficient_currency", shop_item)
		return

	if shop_item.item_data.get_category() == Category.WEAPON:
		if not _can_weapon_be_bought(shop_item):
			return

	emit_signal("shop_item_bought", shop_item)
	shop_item.deactivate()

	update_buttons_color()

	_is_delay_active = true
	_buy_delay_timer.start()


func on_shop_item_steal_button_pressed(shop_item: ShopItem) -> void :
	if item_steals <= 0:
		return

	if _is_delay_active:
		return

	if shop_item.item_data.get_category() == Category.WEAPON:
		if not _can_weapon_be_bought(shop_item):
			return

	emit_signal("shop_item_stolen", shop_item)

	shop_item.deactivate()

	update_buttons_color()

	_is_delay_active = true
	_buy_delay_timer.start()


func _can_weapon_be_bought(shop_item: ShopItem) -> bool:
	var min_weapon_tier = RunData.get_player_effect("min_weapon_tier", player_index)
	var max_weapon_tier = RunData.get_player_effect("max_weapon_tier", player_index)
	var no_melee_weapons = RunData.get_player_effect_bool("no_melee_weapons", player_index)
	var no_ranged_weapons = RunData.get_player_effect_bool("no_ranged_weapons", player_index)
	var no_duplicate_weapons = RunData.get_player_effect_bool("no_duplicate_weapons", player_index)
	var lock_current_weapons = RunData.get_player_effect_bool("lock_current_weapons", player_index)

	var weapon_data: WeaponData = shop_item.item_data
	var weapon_type: = weapon_data.type
	var weapons = RunData.get_player_weapons(player_index)
	var weapon_slot_available: bool = RunData.has_weapon_slot_available(weapon_data, player_index)

	var player_has_weapon = false
	for weapon in weapons:
		if weapon.my_id == weapon_data.my_id:
			player_has_weapon = true
			break

	var player_has_weapon_family = false
	if weapon_data.weapon_id in RunData.get_unique_weapon_ids(player_index):
		player_has_weapon_family = true

	if weapon_data.tier > max_weapon_tier or weapon_data.tier < min_weapon_tier:
		return false

	if no_melee_weapons and weapon_type == WeaponType.MELEE:
		return false

	if no_ranged_weapons and weapon_type == WeaponType.RANGED:
		return false

	if lock_current_weapons and not weapon_slot_available:
		return false

	
	if player_has_weapon and not weapon_slot_available and weapon_data.upgrades_into != null and weapon_data.upgrades_into.tier <= max_weapon_tier:
		return true

	if no_duplicate_weapons and player_has_weapon_family:
		return false

	return weapon_slot_available


func update_buttons_color() -> void :
	for item in _shop_items:
		item.update_color()


func on_shop_item_deactivated(shop_item: ShopItem) -> void :
	emit_signal("shop_item_deactivated", shop_item)


func on_shop_item_focused(shop_item: ShopItem) -> void :
	enable_shop_lock_buttons_focus()
	emit_signal("shop_item_focused", shop_item)


func on_shop_item_unfocused(shop_item: ShopItem) -> void :
	emit_signal("shop_item_unfocused", shop_item)


func get_focus_control(latest_focused_shop_item: ShopItem = null) -> Control:
	var search_index: = 1
	
	if latest_focused_shop_item != null:
		var index = _shop_items.find(latest_focused_shop_item)
		if index >= 0:
			search_index = index

	
	var search_range: = range(search_index, _shop_items.size()) + range(search_index - 1, - 1, - 1)
	for i in search_range:
		var shop_item = _shop_items[i]
		if shop_item.active and shop_item.value <= RunData.get_player_gold(player_index):
			return shop_item._button
	
	for i in search_range:
		var shop_item = _shop_items[i]
		if shop_item.active:
			return shop_item._button
	return null


func reload_shop_items() -> void :
	for i in _shop_items.size():
		if _shop_items[i].active:
			_shop_items[i].item_steals = item_steals

			
			if _shop_items[i].item_data:
				_shop_items[i].set_shop_item(_shop_items[i].item_data, _shop_items[i].wave_value)


func get_shop_item_node(index: int) -> ShopItem:
	return _shop_items[index]


func set_shop_items(items_data: Array) -> void :
	for i in _shop_items.size():
		if i < items_data.size():
			_shop_items[i].item_steals = item_steals
			_shop_items[i].set_shop_item(items_data[i][0], items_data[i][1])
		else:
			_shop_items[i].deactivate()


func disable_shop_buttons_focus() -> void :
	for shop_item in _shop_items:
		shop_item.disable_focus()


func enable_shop_buttons_focus() -> void :
	for shop_item in _shop_items:
		shop_item.enable_focus()


func disable_shop_lock_buttons_focus() -> void :
	for shop_item in _shop_items:
		shop_item.disable_lock_focus()


func enable_shop_lock_buttons_focus() -> void :
	for shop_item in _shop_items:
		shop_item.enable_lock_focus()


func unlock_all_shop_items_visually() -> void :
	for shop_item in _shop_items:
		shop_item.unlock_visually()


func lock_shop_item_visually(index: int) -> void :
	if index < _shop_items.size():
		_shop_items[index].lock_visually()


func is_shop_item_locked_visually(index: int) -> bool:
	return _shop_items[index].locked


func on_mouse_hovered_category(shop_item: ShopItem) -> void :
	emit_signal("mouse_hovered_category", shop_item)


func on_mouse_exited_category(shop_item: ShopItem) -> void :
	emit_signal("mouse_exited_category", shop_item)


func _on_BuyDelayTimer_timeout() -> void :
	if _is_delay_active:
		_is_delay_active = false
