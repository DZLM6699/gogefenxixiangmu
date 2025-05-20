class_name BaseShop
extends Control

export (Array, Resource) var combine_sounds
export (Array, Resource) var recycle_sounds
export  var go_text: = "MENU_GO"

var _shop_items: = [[], [], [], []]
var _focused_shop_item: = [null, null, null, null]
var _latest_focused_shop_item: = [null, null, null, null]
var _player_pressed_go_button: = [false, false, false, false]

var _has_bonus_free_reroll: = [false, false, false, false]
var _reroll_price: = [0, 0, 0, 0]
var _initial_free_rerolls: = [0, 0, 0, 0]
var _free_rerolls: = [0, 0, 0, 0]
var _item_steals: = [0, 0, 0, 0]
var _reroll_count: = [0, 0, 0, 0]
var _paid_reroll_count: = [0, 0, 0, 0]
var _reroll_discount: = [0, 0, 0, 0]

onready var _pause_menu = $PauseMenu
onready var _synergy_popup: SynergyContainer = $Content / SynergyPopup
onready var _popup_manager: PopupManager = $PopupManager
onready var _background = $"%Background"
onready var _floating_text_manager: FloatingTextManagerShop = $"%FloatingTextManagerShop"
onready var _floating_texts: Node2D = $"%FloatingTexts"


func _ready() -> void :
	LinkedStats.reset()
	TempStats.reset()

	_find_nodes()

	var _error_exited_tree = self.connect("tree_exited", self, "_on_tree_exited")

	var _error_connect = _popup_manager.connect("shop_item_focused", self, "_on_shop_item_focused")
	_error_connect = _popup_manager.connect("shop_item_unfocused", self, "_on_shop_item_unfocused")

	_error_connect = _popup_manager.connect("element_focused", self, "_on_element_focused")
	_error_connect = _popup_manager.connect("element_unfocused", self, "_on_element_unfocused")
	_error_connect = _popup_manager.connect("element_pressed", self, "_on_element_pressed")

	var player_count: int = RunData.get_player_count()
	for player_index in player_count:
		_item_steals[player_index] = RunData.get_player_effect("item_steals", player_index)
		var free_rerolls = RunData.get_player_effect("free_rerolls", player_index)
		_initial_free_rerolls[player_index] = free_rerolls
		_free_rerolls[player_index] = free_rerolls

	if not RunData.shop_effects_checked:
		var update_stats_container: = false
		for player_index in player_count:
			if RunData.get_player_effect_bool("destroy_weapons", player_index):
				RunData.remove_all_weapons(player_index)
				update_stats_container = true

		for player_index in player_count:
			var effects = RunData.get_player_effects(player_index)
			for effect in effects["upgrade_random_weapon"]:
				update_stats_container = true

				var possible_upgrades = []
				var weapons = RunData.get_player_weapons(player_index)
				for weapon in weapons:
					if weapon.upgrades_into != null and weapon.tier < effects["max_weapon_tier"]:
						possible_upgrades.push_back(weapon)

				if possible_upgrades.size() > 0 and not RunData.get_player_effect("lock_current_weapons", player_index):
					var weapon_to_upgrade = Utils.get_rand_element(possible_upgrades)
					_combine_weapon(weapon_to_upgrade, player_index, true)
				else:
					RunData.add_stat(effect[0], effect[1], player_index)
					RunData.add_tracked_value(player_index, "item_anvil", effect[1])

		RunData.emit_stats_updated()

		if update_stats_container:
			_update_stats()

	RunData.shop_effects_checked = true

	var next_elite_wave = - 1
	var next_elite_type = EliteType.ELITE
	for elite_spawn in RunData.elites_spawn:
		if elite_spawn[0] > RunData.current_wave:
			next_elite_wave = elite_spawn[0]
			next_elite_type = elite_spawn[1]
			break

	var key = "ELITE_APPEARING" if next_elite_type == EliteType.ELITE else "HORDE_APPEARING"
	var elite_info_panel = _get_elite_info_panel(0)
	var elite_container = _get_elite_container(0)
	elite_info_panel.visible = next_elite_wave != - 1
	elite_container.visible = next_elite_wave != - 1
	if elite_info_panel.visible:
		elite_info_panel.info_box.text = Text.text(key, [str(next_elite_wave)])
		if next_elite_wave == RunData.current_wave + 1:
			var stylebox_color = elite_info_panel.get_stylebox("panel").duplicate()
			stylebox_color.border_color = Color.gray
			elite_info_panel.add_stylebox_override("panel", stylebox_color)

	var need_to_set_locked = false
	if RunData.resumed_from_state_in_shop:
		_shop_items = ProgressData.saved_run_state.shop_items
		_reroll_count = ProgressData.saved_run_state.reroll_count
		_paid_reroll_count = ProgressData.saved_run_state.paid_reroll_count
		_initial_free_rerolls = ProgressData.saved_run_state.initial_free_rerolls
		_free_rerolls = ProgressData.saved_run_state.free_rerolls
		_item_steals = ProgressData.saved_run_state.item_steals

		RunData.resumed_from_state_in_shop = false
		need_to_set_locked = true
	else:
		for player_index in player_count:
			var player_locked_items = RunData.get_player_locked_shop_items(player_index)
			fill_shop_items(player_locked_items, player_index, true)

		if ProgressData.settings.keep_lock:
			need_to_set_locked = true
		else:
			for player_locked_items in RunData.locked_shop_items:
				player_locked_items.clear()

	for player_index in player_count:
		var result: Array = ItemService.get_reroll_price(RunData.current_wave, _paid_reroll_count[player_index], player_index)
		_reroll_price[player_index] = result[0]
		_reroll_discount[player_index] = result[1]

		_has_bonus_free_reroll[player_index] = _shop_items[player_index].empty()
		set_reroll_button_price(player_index)

	_error_connect = _pause_menu.connect("paused", self, "on_paused")
	_error_connect = _pause_menu.connect("unpaused", self, "on_unpaused")

	for player_index in player_count:
		var weapons = RunData.get_player_weapons(player_index)
		var items = RunData.get_player_items(player_index)

		var player_gear_container = _get_gear_container(player_index)
		player_gear_container.set_weapons_data(weapons)
		player_gear_container.set_items_data(items)

		var shop_items_container = _get_shop_items_container(player_index)
		shop_items_container.item_steals = _item_steals[player_index]
		shop_items_container.set_shop_items(_shop_items[player_index])
		_error_connect = shop_items_container.connect("shop_item_bought", self, "on_shop_item_bought", [player_index])
		_error_connect = shop_items_container.connect("shop_item_stolen", self, "on_shop_item_stolen", [player_index])
		_error_connect = shop_items_container.connect("shop_item_insufficient_currency", self, "_on_shop_item_insufficient_currency", [player_index])
		_error_connect = shop_items_container.connect("shop_item_deactivated", self, "on_shop_item_deactivated", [player_index])

		var gold_label = _get_gold_label(player_index)
		gold_label.update_value(RunData.get_player_gold(player_index))

		var reroll_button = _get_reroll_button(player_index)
		_error_connect = reroll_button.connect("pressed", self, "_on_RerollButton_pressed", [player_index])

		var item_popup = _get_item_popup(player_index)
		item_popup.item_steals = _item_steals[player_index]
		_error_connect = item_popup.connect("item_cancel_button_pressed", self, "_on_item_cancel_button_pressed", [player_index])
		_error_connect = item_popup.connect("item_discard_button_pressed", self, "_on_item_discard_button_pressed", [player_index])
		_error_connect = item_popup.connect("item_combine_button_pressed", self, "_on_item_combine_button_pressed", [player_index])

		_popup_manager.add_item_popup(item_popup, player_index)

		var weapons_container = player_gear_container.weapons_container
		_popup_manager.connect_inventory_container(weapons_container)
		_error_connect = weapons_container._elements.connect("focus_lost", self, "_on_player_focus_lost", [player_index])

		var items_container = player_gear_container.items_container
		_popup_manager.connect_inventory_container(items_container)
		_error_connect = items_container._elements.connect("focus_lost", self, "_on_player_focus_lost", [player_index])

		var go_button = _get_go_button(player_index)
		_error_connect = go_button.connect("pressed", self, "_on_GoButton_pressed", [player_index])
		_error_connect = go_button.connect("focus_exited", self, "_on_GoButton_focus_exited", [player_index])
		go_button.text = tr(go_text) + " (" + Text.text("WAVE", [str(RunData.current_wave + 1)]) + ")"


	if need_to_set_locked:
		_update_visual_locks()

	var _error_category_hovered = _get_shop_items_container(0).connect("mouse_hovered_category", self, "on_mouse_hovered_category")
	var _error_category_exited = _get_shop_items_container(0).connect("mouse_exited_category", self, "on_mouse_exited_category")

	var _error_gold = RunData.connect("gold_changed", self, "_on_gold_changed")

	for player_index in player_count:
		Utils.focus_player_control(_get_default_focus_control(player_index), player_index)

	_background.texture = ZoneService.get_zone_data(RunData.current_zone).ui_background

	ProgressData.save_run_state(_shop_items, _reroll_count, _paid_reroll_count, _initial_free_rerolls, _free_rerolls, _item_steals)


func _input(event: InputEvent) -> void :
	for player_index in RunData.get_player_count():
		if Utils.is_player_pause_pressed(event, player_index):
			_pause_menu.pause(player_index)
			break

	for player_index in RunData.get_player_count():
		var shop_item = _focused_shop_item[player_index]
		if Utils.is_player_select_pressed(event, player_index) and shop_item != null:
			if _item_steals[player_index] > 0:
				shop_item.steal_item()
			if not RunData.get_player_effect_bool("disable_item_locking", player_index) and shop_item.item_data.is_lockable:
				shop_item.change_lock_status( not shop_item.locked)

			if RunData.is_coop_run:
				_get_item_popup(player_index).show_shop_hints(shop_item)
			get_tree().set_input_as_handled()

		elif (
			_player_pressed_go_button[player_index]
			and (
				Utils.is_player_cancel_pressed(event, player_index)
				or Utils.is_player_action_pressed(event, player_index, "ltrigger")
				or Utils.is_player_action_pressed(event, player_index, "rtrigger")
			)
		):
			_clear_go_button_pressed(player_index)
			get_tree().set_input_as_handled()



func on_paused() -> void :
	ProgressData.save_run_state(_shop_items, _reroll_count, _paid_reroll_count, _initial_free_rerolls, _free_rerolls, _item_steals)
	$Content.hide()


func on_unpaused() -> void :
	$Content.show()


func get_player_shop_items(player_index: int) -> Array:
	return _shop_items[player_index]


func _update_visual_locks() -> void :
	unlock_all_shop_items_visually()
	for player_index in RunData.get_player_count():
		var shop_items_container = _get_shop_items_container(player_index)
		var player_shop_items = _shop_items[player_index]
		var player_locked_items = RunData.get_player_locked_shop_items(player_index)
		for locked_item in player_locked_items:
			for i in player_shop_items.size():
				if shop_items_container.is_shop_item_locked_visually(i):
					continue
				var shop_item = player_shop_items[i]
				if locked_item[0].my_id == shop_item[0].my_id:
					shop_items_container.lock_shop_item_visually(i)
					break


func _on_player_focus_lost(player_index: int) -> void :
	var focus_control = _get_reroll_button(player_index) if _reroll_price[player_index] == 0 else _get_go_button(player_index)
	Utils.focus_player_control(focus_control, player_index)


func _on_GoButton_pressed(player_index: int) -> void :
	
	
	if get_tree().paused:
		return

	if _player_pressed_go_button[player_index]:
		
		_clear_go_button_pressed(player_index)
		return

	_player_pressed_go_button[player_index] = true
	var checkmark = _get_checkmark(player_index)
	if checkmark != null:
		checkmark.show()

	
	for other_player_index in RunData.get_player_count():
		if not _player_pressed_go_button[other_player_index]:
			return

	ProgressData.save_run_state(_shop_items, _reroll_count, _paid_reroll_count, _initial_free_rerolls, _free_rerolls, _item_steals)

	RunData.current_wave += 1
	var _error = get_tree().change_scene(MenuData.game_scene)


func _on_GoButton_focus_exited(player_index: int):
	_clear_go_button_pressed(player_index)


func _clear_go_button_pressed(player_index: int) -> void :
	_player_pressed_go_button[player_index] = false
	var checkmark = _get_checkmark(player_index)
	if checkmark != null:
		checkmark.hide()


func fill_shop_items(player_locked_items: Array, player_index: int, just_entered_shop: bool = false) -> void :
	var player_shop_items = _shop_items[player_index]
	var prev_items = player_locked_items.duplicate() if just_entered_shop else player_shop_items.duplicate()
	_shop_items[player_index] = player_locked_items.duplicate()

	var new_item_count = ItemService.NB_SHOP_ITEMS - player_locked_items.size()

	if new_item_count > 0:
		var args: = ItemServiceGetShopItemsArgs.new(_shop_items, player_index)
		args.count = new_item_count
		args.prev_items = prev_items
		args.locked_items = player_locked_items

		if not just_entered_shop:
			var increase_tier_effects: Array = RunData.get_player_effect("increase_tier_on_reroll", player_index)
			for increase_tier_effect in increase_tier_effects:
				args.increase_tier = increase_tier_effect[1]
				var source_item

				for player_item in RunData.get_player_items(player_index):
					if player_item.my_id == increase_tier_effect[0]:
						for effect in player_item.effects:
							if effect.custom_key == "increase_tier_on_reroll" and effect.value == increase_tier_effect[1]:
								source_item = player_item
								if source_item.my_id == "item_goldfish":
									SoundManager.play(load("res://ui/sounds/goldfish.wav"), 0, 0.2)
								break

				if not source_item:
					break

				RunData.remove_item(source_item, player_index)
				_get_gear_container(player_index).set_items_data(RunData.get_player_items(player_index))
				break

		var items_to_add = ItemService.get_player_shop_items(RunData.current_wave, player_index, args)
		_shop_items[player_index].append_array(items_to_add)


func _on_RerollButton_pressed(player_index: int) -> void :
	var player_locked_items = RunData.get_player_locked_shop_items(player_index)
	var shop_items_container = _get_shop_items_container(player_index)

	if player_locked_items.size() >= ItemService.NB_SHOP_ITEMS:
		return
	if RunData.get_player_gold(player_index) < _reroll_price[player_index]:
		_get_flasher(player_index).flash()
		return

	RunData.remove_gold(_reroll_price[player_index], player_index)

	for gain_stats in RunData.get_player_effect("gain_stats_on_reroll", player_index):
		var chance: int = gain_stats[2]
		var stat: String = gain_stats[0]
		var stat_increase: int = gain_stats[1]
		if Utils.get_chance_success(chance / 100.0):
			RunData.add_stat(stat, stat_increase, player_index)

			var reroll_button: = _get_reroll_button(player_index)
			var pos = reroll_button.rect_global_position
			if not RunData.is_coop_run:
				pos.y += reroll_button.rect_size.y / 2
			else:
				pos.x += reroll_button.rect_size.x - 80

			_floating_text_manager.stat_added(stat, stat_increase, 0, pos)

			if stat_increase > 0:
				RunData.add_tracked_value(player_index, "item_bone_dice", stat_increase, 0)
			elif stat_increase < 0:
				RunData.add_tracked_value(player_index, "item_bone_dice", abs(stat_increase) as int, 1)

	shop_items_container.unlock_all_shop_items_visually()

	fill_shop_items(player_locked_items, player_index)

	shop_items_container.set_shop_items(_shop_items[player_index])
	for i in player_locked_items.size():
		shop_items_container.lock_shop_item_visually(i)

	_reroll_count[player_index] += 1
	if _free_rerolls[player_index] > 0 and not _has_bonus_free_reroll[player_index]:
		_free_rerolls[player_index] -= 1
		var saved_materials: int = ItemService.get_reroll_price(RunData.current_wave, _paid_reroll_count[player_index], player_index)[0]
		RunData.add_tracked_value(player_index, "item_dangerous_bunny", saved_materials)
	elif _has_bonus_free_reroll[player_index]:
		_has_bonus_free_reroll[player_index] = false
	else:
		var spyglass_count: int = RunData.get_nb_item("item_spyglass", player_index)
		if spyglass_count > 0:
			var reroll_price_amount: int = RunData.get_player_effect("reroll_price", player_index)
			var spyglass_item: ItemData = ItemService.get_item_from_id("item_spyglass")
			var sypglass_amount: int = spyglass_item.effects[1].value
			var total_spyglass_amount: = spyglass_count * sypglass_amount
			var spyglass_factor: = float(total_spyglass_amount) / float(reroll_price_amount)
			RunData.add_tracked_value(player_index, "item_spyglass", ceil(_reroll_discount[player_index] * spyglass_factor) as int)

		_paid_reroll_count[player_index] += 1

	var result: Array = ItemService.get_reroll_price(RunData.current_wave, _paid_reroll_count[player_index], player_index)
	_reroll_price[player_index] = result[0]
	_reroll_discount[player_index] = result[1]
	set_reroll_button_price(player_index)

	_update_stats(player_index)
	shop_items_container.update_buttons_color()

	
	if RunData.get_player_gold(player_index) < _reroll_price[player_index]:
		var available_shop_item = shop_items_container.get_focus_control()
		if available_shop_item == null:
			Utils.focus_player_control(_get_go_button(player_index), player_index)

	ChallengeService.try_complete_challenge("chal_unlucky", _reroll_count[player_index])


func set_reroll_button_price(player_index: int) -> void :
	if _free_rerolls[player_index] > 0 or _has_bonus_free_reroll[player_index]:
		_reroll_price[player_index] = 0
	var reroll_button: = _get_reroll_button(player_index)
	reroll_button.init(_reroll_price[player_index], player_index)

	reroll_button.remove_additional_icon()
	for increase_tier_effect in RunData.get_player_effect("increase_tier_on_reroll", player_index):
		var source_item: ItemData = ItemService.get_item_from_id(increase_tier_effect[0])
		var texture: ImageTexture = ImageTexture.new()
		texture.create_from_image(source_item.icon.get_data())
		reroll_button.set_additional_icon(texture)
		break


func on_shop_item_bought(shop_item: ShopItem, player_index: int) -> void :
	for item in _shop_items[player_index]:
		if item[0].my_id == shop_item.item_data.my_id:
			_shop_items[player_index].erase(item)
			break

	RunData.remove_currency(shop_item.value, player_index)

	var nb_coupons = RunData.get_nb_item("item_coupon", player_index)

	if nb_coupons > 0:
		var coupon_value = get_coupon_value(player_index)
		var coupon_effect = nb_coupons * (coupon_value / 100.0)
		var base_value = ItemService.get_value(shop_item.wave_value, shop_item.item_data.value, player_index, false, shop_item.item_data is WeaponData, shop_item.item_data.my_id)
		RunData.add_tracked_value(player_index, "item_coupon", (base_value * coupon_effect) as int)

	var reroll_price_before: int = RunData.get_player_effect("reroll_price", player_index)

	if shop_item.item_data.get_category() == Category.ITEM:
		buy_item(shop_item.item_data, player_index)
	elif shop_item.item_data.get_category() == Category.WEAPON:
		buy_weapon(shop_item.item_data, player_index)

	_update_stats(player_index)
	_get_shop_items_container(player_index).reload_shop_items()

	
	var reroll_price_after: int = RunData.get_player_effect("reroll_price", player_index)
	if _reroll_price[player_index] > 0 and reroll_price_after < reroll_price_before:
		var result: Array = ItemService.get_reroll_price(RunData.current_wave, _paid_reroll_count[player_index], player_index)
		_reroll_price[player_index] = result[0]
		_reroll_discount[player_index] = result[1]

	
	var total_free_rerolls = RunData.get_player_effect("free_rerolls", player_index)
	var has_new_rerolls = total_free_rerolls > _initial_free_rerolls[player_index]
	if has_new_rerolls:
		var new_rerolls = total_free_rerolls - _initial_free_rerolls[player_index]
		_initial_free_rerolls[player_index] = total_free_rerolls
		_free_rerolls[player_index] += new_rerolls

	_has_bonus_free_reroll[player_index] = _shop_items[player_index].empty()
	set_reroll_button_price(player_index)


func on_shop_item_stolen(shop_item: ShopItem, player_index: int) -> void :
	if _item_steals[player_index] > 0:
		_item_steals[player_index] -= 1
		_get_shop_items_container(player_index).item_steals = _item_steals[player_index]
		_get_item_popup(player_index).item_steals = _item_steals[player_index]

		var effects: Dictionary = RunData.get_player_effects(player_index)
		for effect in effects["item_steals_spawns_enemy"]:
			var spawn_chance: int = effect[1]
			var group_data_path: String = effect[0]
			if Utils.get_chance_success(spawn_chance / 100.0):
				effects["extra_enemies_next_wave"].append([group_data_path, 1])

		var caught_chance = ItemService.get_chance_getting_caught(shop_item, RunData.current_wave, effects["item_steals_spawns_random_elite"])

		if Utils.get_chance_success(caught_chance):
			var icon = ItemService.get_element(ItemService.icons, "icon_elite").icon
			var popup_pos = shop_item._steal_button.rect_global_position
			var direction: Vector2

			if RunData.is_coop_run:
				popup_pos.x -= 35
				direction = Vector2(0, - 30)
			else:
				popup_pos.x += shop_item._steal_button.rect_size.x / 2.0
				direction = Vector2(25, - 100)

			_floating_text_manager.display_shop_icon(icon, popup_pos, direction)
			var rand_elite_id = ItemService.get_random_elite_id_from_zone(ZoneService.current_zone.my_id)
			effects["extra_enemies_next_wave"].append(["res://zones/common/elite/group_elite.tres", 1, rand_elite_id])

		shop_item.value = 0
		on_shop_item_bought(shop_item, player_index)


func buy_item(item_data: ItemData, player_index: int) -> void :
	var were_items_duplicated: = false
	var duplicate_item_effects: Array = RunData.get_player_effect("duplicate_item", player_index)

	for duplicate_item_effect in duplicate_item_effects:
		var source_item = RunData.get_player_item(duplicate_item_effect[0], player_index)
		var remaining_item_count: int = RunData.get_remaining_max_nb_item(item_data, player_index)
		var value: int = duplicate_item_effect[1]
		var normal_buy_count: = 1
		var duplicated_count: = min(value, remaining_item_count - normal_buy_count)

		for _nb in range(duplicated_count):
			were_items_duplicated = true
			RunData.remove_item(source_item, player_index, true)
			RunData.add_item(item_data, player_index)

	RunData.add_item(item_data, player_index)

	var player_gear_container = _get_gear_container(player_index)
	if were_items_duplicated:
		player_gear_container.set_items_data(RunData.get_player_items(player_index))
	else:
		player_gear_container.items_container._elements.add_element(item_data, true)


func buy_weapon(item_data: WeaponData, player_index: int) -> void :
	var player_gear_container = _get_gear_container(player_index)
	player_gear_container.weapons_container._elements.add_element(item_data)

	if not RunData.has_weapon_slot_available(item_data, player_index):
		var weapons = RunData.get_player_weapons(player_index)
		for weapon in weapons:
			if weapon.my_id == item_data.my_id and item_data.upgrades_into != null:
				var _weapon = RunData.add_weapon(item_data, player_index)
				_combine_weapon(item_data, player_index, false)
				_on_player_focus_lost(player_index)
				break
	else:
		var _weapon = RunData.add_weapon(item_data, player_index)


func _on_shop_item_insufficient_currency(_shop_item: ShopItem, player_index: int) -> void :
	_get_flasher(player_index).flash()


func _on_item_combine_button_pressed(weapon_data: WeaponData, player_index: int, is_upgrade: bool = false) -> void :
	if RunData.get_player_effect_bool("lock_current_weapons", player_index):
		return

	_popup_manager.reset_focus(player_index)
	_combine_weapon(weapon_data, player_index, is_upgrade)



func _combine_weapon(weapon_data: WeaponData, player_index: int, is_upgrade: bool) -> void :
	var nb_to_remove = 2
	var removed_weapons_tracked_value = 0
	var curse_new_weapon = false
	var new_cursed_weapon_min_factor = 0.0

	if is_upgrade:
		nb_to_remove = 1

	var weapons_container: = _get_gear_container(player_index).weapons_container
	weapons_container._elements.remove_element(weapon_data, 1, true)
	removed_weapons_tracked_value += RunData.remove_weapon(weapon_data, player_index)

	var existing_weapon_to_remove

	if nb_to_remove == 2:

		var existing_weapons = []

		for element in weapons_container._elements.get_children():
			existing_weapons.push_back(element.item)

		
		existing_weapons.erase(weapon_data)

		for weapon in existing_weapons:
			if weapon.my_id == weapon_data.my_id:
				existing_weapon_to_remove = weapon

				
				if ( not weapon_data.is_cursed and weapon.is_cursed) or (weapon_data.is_cursed and not weapon.is_cursed):
					break

		weapons_container._elements.remove_element(existing_weapon_to_remove, 1, true)
		removed_weapons_tracked_value += RunData.remove_weapon(existing_weapon_to_remove, player_index)

	if weapon_data.is_cursed or (existing_weapon_to_remove and existing_weapon_to_remove.is_cursed):
		curse_new_weapon = true

	if weapon_data.is_cursed:
		new_cursed_weapon_min_factor = weapon_data.curse_factor
		for effect in weapon_data.effects:
			new_cursed_weapon_min_factor = max(new_cursed_weapon_min_factor, effect.curse_factor)

	if existing_weapon_to_remove and existing_weapon_to_remove.is_cursed:
		new_cursed_weapon_min_factor = max(new_cursed_weapon_min_factor, existing_weapon_to_remove.curse_factor)
		for effect in existing_weapon_to_remove.effects:
			new_cursed_weapon_min_factor = max(new_cursed_weapon_min_factor, effect.curse_factor)

	var weapon_to_upgrade_into = weapon_data.upgrades_into

	if curse_new_weapon:
		for dlc_id in RunData.enabled_dlcs:
			var dlc_data = ProgressData.get_dlc_data(dlc_id)
			if dlc_data and dlc_data.has_method("curse_item"):
				weapon_to_upgrade_into = dlc_data.curse_item(weapon_to_upgrade_into, player_index, false, new_cursed_weapon_min_factor)

	var new_weapon = RunData.add_weapon(weapon_to_upgrade_into, player_index)

	new_weapon.tracked_value = removed_weapons_tracked_value

	if is_upgrade:
		new_weapon.dmg_dealt_last_wave = weapon_data.dmg_dealt_last_wave

	_update_stats(player_index)
	_get_shop_items_container(player_index).reload_shop_items()

	weapons_container._elements.add_element(new_weapon)

	if Input.get_mouse_mode() == Input.MOUSE_MODE_HIDDEN:
		weapons_container._elements.focus_element(new_weapon)

	SoundManager.play(Utils.get_rand_element(combine_sounds), 0, 0.1, true)


func _on_item_discard_button_pressed(weapon_data: WeaponData, player_index: int) -> void :
	if RunData.get_player_effect_bool("lock_current_weapons", player_index):
		return

	_popup_manager.reset_focus(player_index)
	RunData.add_recycled(player_index)

	var weapons_container: = _get_gear_container(player_index).weapons_container
	weapons_container._elements.remove_element(weapon_data, 1, true)

	var _weapon = RunData.remove_weapon(weapon_data, player_index)
	var base_recycling_value = weapon_data.value
	var specific_recycling_price_factor = 1.0

	for specific_item_price in RunData.get_player_effect("specific_items_price", player_index):
		if specific_item_price[0] in weapon_data.my_id:
			specific_recycling_price_factor = specific_item_price[1]
			break

	base_recycling_value *= specific_recycling_price_factor

	var recycling_value = ItemService.get_recycling_value(RunData.current_wave, base_recycling_value, player_index, true)
	RunData.add_gold(recycling_value, player_index)
	RunData.update_recycling_tracking_value(weapon_data, player_index)

	var nb_coupons = RunData.get_nb_item("item_coupon", player_index)

	if nb_coupons > 0:
		var base_value = ItemService.get_recycling_value(RunData.current_wave, weapon_data.value, player_index, true, false)
		var actual_value = ItemService.get_recycling_value(RunData.current_wave, weapon_data.value, player_index, true)
		var val_lost = (base_value - actual_value) as int
		RunData.add_tracked_value(player_index, "item_coupon", - val_lost)

	_update_stats(player_index)
	_get_shop_items_container(player_index).reload_shop_items()
	var reroll_button = _get_reroll_button(player_index)
	reroll_button.set_color_from_currency(RunData.get_player_gold(player_index))
	SoundManager.play(Utils.get_rand_element(recycle_sounds), 0, 0.1, true)


func _on_item_cancel_button_pressed(item_data: ItemParentData, player_index: int) -> void :
	_popup_manager.reset_focus(player_index)
	if $Content.visible:
		var inventory_container
		if item_data is WeaponData:
			inventory_container = _get_gear_container(player_index).weapons_container
		else:
			inventory_container = _get_gear_container(player_index).items_container
		inventory_container._elements.focus_element(item_data)


func get_coupon_value(player_index: int) -> int:
	var coupon_value = 0
	var items = RunData.get_player_items(player_index)
	for item in items:
		if item.my_id == "item_coupon":
			coupon_value = abs(item.effects[0].value)
			break
	return coupon_value


func unlock_all_shop_items_visually() -> void :
	for player_index in RunData.get_player_count():
		var shop_items_container = _get_shop_items_container(player_index)
		shop_items_container.unlock_all_shop_items_visually()


func on_mouse_hovered_category(shop_item: ShopItem) -> void :
	show_shop_item_synergies(shop_item)


func on_mouse_exited_category(shop_item: ShopItem) -> void :
	hide_synergies(shop_item)


func on_shop_item_deactivated(shop_item: ShopItem, player_index: int) -> void :
	var focused_shop_item = _focused_shop_item[player_index]
	if focused_shop_item == null or shop_item == focused_shop_item:
		Utils.focus_player_control(_get_default_focus_control(player_index), player_index)


func _get_default_focus_control(player_index: int) -> Control:
	var shop_items_container = _get_shop_items_container(player_index)
	var shop_item = shop_items_container.get_focus_control(_latest_focused_shop_item[player_index])
	if shop_item != null:
		return shop_item
	
	
	if _reroll_price[player_index] == 0 or (RunData.is_coop_run and _reroll_price[player_index] <= RunData.get_player_gold(player_index)):
		return _get_reroll_button(player_index)
	return _get_go_button(player_index)


func show_shop_item_synergies(shop_item: ShopItem) -> void :
	if shop_item.item_data is WeaponData:
		_synergy_popup.show()
		
		_synergy_popup.set_synergies_text(shop_item.item_data, 0)
		_synergy_popup.set_pos_from(shop_item)


func hide_synergies(shop_item: ShopItem) -> void :
	if shop_item.item_data is WeaponData:
		_synergy_popup.hide()


func _on_gold_changed(new_value: int, player_index: int) -> void :
	var gold_label = _get_gold_label(player_index)
	gold_label.update_value(new_value)


func _on_shop_item_focused(shop_item: ShopItem, player_index: int) -> void :
	_focused_shop_item[player_index] = shop_item
	_latest_focused_shop_item[player_index] = shop_item


func _on_shop_item_unfocused(shop_item: ShopItem, player_index: int) -> void :
	if _focused_shop_item[player_index] == shop_item:
		_focused_shop_item[player_index] = null


func _on_tree_exited() -> void :
	for player_index in range(RunData.get_player_count()):
		var curse_locked_items: int = RunData.get_player_effect("curse_locked_items", player_index)
		var has_cursed_an_item = false
		var nb_locked_items_that_didnt_get_cursed: int = 0
		var locked_items: Array = RunData.locked_shop_items[player_index]
		var randomized_positions = []

		for i in locked_items.size():
			randomized_positions.push_back(i)

		randomized_positions.shuffle()

		for i in randomized_positions:
			if not locked_items[i][0].is_cursed and Utils.get_chance_success((RunData.players_data[player_index].curse_locked_shop_items_pity + curse_locked_items) / 100.0):
				for dlc_id in RunData.enabled_dlcs:
					var dlc_data = ProgressData.get_dlc_data(dlc_id)
					if dlc_data and dlc_data.has_method("curse_item"):
						has_cursed_an_item = true
						RunData.players_data[player_index].curse_locked_shop_items_pity = 0
						RunData.set_tracked_value(player_index, "item_fish_hook", RunData.players_data[player_index].curse_locked_shop_items_pity)
						locked_items[i][0] = dlc_data.curse_item(locked_items[i][0], player_index)
			elif not locked_items[i][0].is_cursed:
				nb_locked_items_that_didnt_get_cursed += 1

		if curse_locked_items > 0 and locked_items.size() > 0 and not has_cursed_an_item and nb_locked_items_that_didnt_get_cursed > 0:
			RunData.players_data[player_index].curse_locked_shop_items_pity += int(nb_locked_items_that_didnt_get_cursed * (curse_locked_items / 4.0))
			RunData.set_tracked_value(player_index, "item_fish_hook", RunData.players_data[player_index].curse_locked_shop_items_pity)


func _on_element_focused(_element: InventoryElement, _player_index: int) -> void :
	pass


func _on_element_unfocused(_element: InventoryElement, _player_index: int) -> void :
	pass


func _on_element_pressed(_element: InventoryElement, _player_index: int, _popup_focused: bool) -> void :
	pass


func _update_stats(_player_index: = - 1) -> void :
	
	pass


func _find_nodes() -> void :
	
	pass


func _get_shop_items_container(_player_index: int) -> ShopItemsContainer:
	
	return null


func _get_gear_container(_player_index: int) -> PlayerGearContainer:
	
	return null


func _get_gold_label(_player_index: int) -> Control:
	
	return null


func _get_flasher(_player_index: int) -> Flasher:
	
	return null


func _get_checkmark(_player_index: int) -> Control:
	
	return null


func _get_reroll_button(_player_index: int) -> Control:
	
	return null


func _get_go_button(_player_index: int) -> Control:
	
	return null


func _get_item_popup(_player_index: int) -> ItemPopup:
	
	return null


func _get_elite_info_panel(_player_index: int) -> EliteInfoPanel:
	
	return null


func _get_elite_container(_player_index: int) -> Container:
	
	return null


func add_floating_text(instance: Node) -> void :
	_floating_texts.add_child(instance)
