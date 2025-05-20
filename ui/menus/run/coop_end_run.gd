extends BaseEndRun

export (Resource) var small_label_theme

onready var _margin_container = $MarginContainer
onready var _progress_container = $"%ProgressContainer"
onready var _progress_margin_container = $"%ProgressMarginContainer"

onready var _player_container1: EndRunPlayerContainer = $"%PlayerContainer1"
onready var _player_container2: EndRunPlayerContainer = $"%PlayerContainer2"
onready var _player_container3: EndRunPlayerContainer = $"%PlayerContainer3"
onready var _player_container4: EndRunPlayerContainer = $"%PlayerContainer4"

onready var _item_popup1: ItemPopup = $"%ItemPopup1"
onready var _item_popup2: ItemPopup = $"%ItemPopup2"
onready var _item_popup3: ItemPopup = $"%ItemPopup3"
onready var _item_popup4: ItemPopup = $"%ItemPopup4"

onready var _stat_popup1: StatPopup = $"%StatPopup1"
onready var _stat_popup2: StatPopup = $"%StatPopup2"
onready var _stat_popup3: StatPopup = $"%StatPopup3"
onready var _stat_popup4: StatPopup = $"%StatPopup4"

onready var player_containers: = [_player_container1, _player_container2, _player_container3, _player_container4]
onready var item_popups: = [_item_popup1, _item_popup2, _item_popup3, _item_popup4]
onready var stat_popups: = [_stat_popup1, _stat_popup2, _stat_popup3, _stat_popup4]


func _ready() -> void :
	var player_count: int = RunData.get_player_count()

	
	if RunData.get_player_count() == 4:
		_margin_container.add_constant_override("margin_left", 0)
		_margin_container.add_constant_override("margin_right", 0)

	var rewards = []
	if RunData.difficulty_unlocked != - 1:
		var difficulty_data = null
		for difficulty in ItemService.difficulties:
			if difficulty.value == RunData.difficulty_unlocked:
				difficulty_data = difficulty
				break
		rewards.push_back(difficulty_data)
	for chal in RunData.challenges_completed_this_run:
		rewards.push_back(chal.reward)

	_progress_margin_container.visible = not rewards.empty()
	_progress_container.set_data("MENU_PROGRESS", Category.CHALLENGE, rewards)
	_popup_manager.connect_inventory_container(_progress_container)

	for i in CoopService.MAX_PLAYER_COUNT:
		player_containers[i].visible = i < player_count

	for player_index in player_count:
		var player_container = player_containers[player_index]

		var weapons_container = player_container.weapons_container
		var weapons = RunData.get_player_weapons(player_index)
		weapons_container.visible = not weapons.empty()
		weapons_container.set_data("WEAPONS", Category.WEAPON, weapons)

		var items_container = player_container.items_container
		var items = RunData.get_player_items(player_index)
		items_container.set_data("ITEMS", Category.ITEM, items, true, true)

		var item_popup = item_popups[player_index]
		item_popup.connect("popup_toggled", self, "_on_popup_toggled")
		item_popup.player_index = player_index
		item_popup.parent_node_path = player_container.carousel.get_path()
		_popup_manager.add_item_popup(item_popup, player_index)
		_popup_manager.connect_inventory_container(weapons_container)
		_popup_manager.connect_inventory_container(items_container)

		var stat_popup = stat_popups[player_index]
		stat_popup.parent_node_path = player_container.carousel.get_path()
		_popup_manager.add_stat_popup(stat_popup, player_index)
		_popup_manager.connect_stats_container(player_container.primary_stats_container)
		_popup_manager.connect_stats_container(player_container.secondary_stats_container)

		player_container.focus()


func _on_PopupManager_element_pressed(_element: InventoryElement, player_index: int, _popup_focused: bool):
	if player_index == 0:
		Utils.focus_player_control(_new_run_button, player_index)


func _on_popup_toggled(hide_popup: bool, player_index: int) -> void :
	if hide_popup:
		player_containers[player_index].toggle_popup_hint.set_text("COOP_POPUP_ENABLE_HINT")
	else:
		player_containers[player_index].toggle_popup_hint.set_text("COOP_POPUP_DISABLE_HINT")
