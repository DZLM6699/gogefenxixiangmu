class_name CharacterSelection
extends BaseSelection

var _player_characters: = [null, null, null, null]

var __restore_player0_element = null

onready var _back_button: Button = $"%BackButton"
onready var _run_options_panel: PanelContainer = $"%RunOptionsPanel"
onready var _endless_button: CheckButton = $"%EndlessButton"
onready var _coop_button: CheckButton = $"%CoopButton"
onready var _info_panel: PanelContainer = $"%InfoPanel"
onready var _coop_join_instructions: Control = $"%CoopJoinInstructions"
onready var _inventories: Control = $"%Inventories"
onready var _zone_selection_button: OptionButton = $"%ZoneSelectionButton"
onready var _coop_join_panel1: Container = $"%CoopJoinPanel1"
onready var _coop_join_panel2: Container = $"%CoopJoinPanel2"
onready var _coop_join_panel3: Container = $"%CoopJoinPanel3"
onready var _coop_join_panel4: Container = $"%CoopJoinPanel4"
onready var _locked_panel1: Container = $"%LockedPanel1"
onready var _locked_panel2: Container = $"%LockedPanel2"
onready var _locked_panel3: Container = $"%LockedPanel3"
onready var _locked_panel4: Container = $"%LockedPanel4"


func _ready() -> void :
	var selected_zone = ProgressData.settings.zone_selected

	if selected_zone >= ZoneService.zones.size():
		selected_zone = 0
	_zone_selection_button.selected = selected_zone

	var first_run_option = _zone_selection_button
	if _zone_selection_button.get_item_count() <= 1:
		_zone_selection_button.hide()
		first_run_option = _endless_button

	for margin in [MARGIN_LEFT, MARGIN_TOP]:
		_back_button.set_focus_neighbour(margin, _back_button.get_path_to(_back_button))
	for margin in [MARGIN_RIGHT, MARGIN_BOTTOM]:
		_back_button.set_focus_neighbour(margin, _back_button.get_path_to(first_run_option))

	_on_ZoneSelectionButton_item_selected(selected_zone)
	init_coop_service()


func init_coop_service() -> void :
	var _e = _coop_button.connect("coop_initialized", self, "_on_coop_initialized", [false])
	_e = CoopService.connect("connected_players_updated", self, "_on_connected_players_updated", [false])
	_e = CoopService.connect("connection_progress_updated", self, "_on_connection_progress_updated")
	_on_coop_initialized(ProgressData.settings.coop_mode_toggled, true)
	_update_character_selection_player_count_ui()
	_coop_button.init()
	_run_options_panel.init()
	CoopService.set_process_input(true)


func _exit_tree() -> void :
	CoopService.set_process_input(false)


func _input(event: InputEvent) -> void :
	var focus_owner = get_focus_owner()
	if RunData.is_coop_run and RunData.get_player_count() == 0 and focus_owner == null and event.is_action_pressed("ui_up"):
		
		_coop_button.call_deferred("grab_focus")


func _init_players() -> void :
	if not ProgressData.settings.coop_mode_toggled:
		._init_players()
		return
	
	_on_connected_players_updated(CoopService.connected_players, true)


func _go_back() -> void :
	RunData.reload_music = false
	var _error = get_tree().change_scene(MenuData.title_screen_scene)


func _get_unlocked_elements(player_index: int) -> Array:
	if DebugService.unlock_all_chars:
		var all_unlocked: = []
		for element in _get_all_possible_elements(player_index):
			all_unlocked.push_back(element.my_id)
		return all_unlocked

	return ProgressData.characters_unlocked


func _get_all_possible_elements(_player_index: int) -> Array:
	
	var elements: = []
	for character in ItemService.characters:
		var element = character.duplicate()
		var diff_info = ProgressData.get_character_difficulty_info(element.my_id, RunData.current_zone)
		if diff_info.max_difficulty_beaten.difficulty_value == 0:
			element.tier = Tier.DANGER_0
		elif diff_info.max_difficulty_beaten.difficulty_value > 0:
			element.tier = diff_info.max_difficulty_beaten.difficulty_value
		elements.push_back(element)
	return elements


func _get_reward_type() -> int:
	return RewardType.CHARACTER


func _on_element_pressed(element: InventoryElement, _inventory_player_index: int) -> void :
	var inventory_player_index = FocusEmulatorSignal.get_player_index(element)
	if inventory_player_index < 0:
		return

	if element.is_random:
		var available_elements: = []
		
		for element in displayed_elements[0]:
			if not element.is_locked:
				available_elements.push_back(element)
		var character = Utils.get_rand_element(available_elements)
		_player_characters[inventory_player_index] = character
	elif element.is_special:
		return
	else:
		_player_characters[inventory_player_index] = element.item

	_set_selected_element(inventory_player_index)


func _on_selections_completed() -> void :
	for player_index in RunData.get_player_count():
		var character = _player_characters[player_index]
		RunData.add_character(character, player_index)

	if RunData.some_player_has_weapon_slots():
		_change_scene(MenuData.weapon_selection_scene)
	else:
		_change_scene(MenuData.difficulty_selection_scene)


func _on_coop_initialized(active: bool, initialize: bool) -> void :
	RunData.is_coop_run = active
	CoopService.listening_for_inputs = active
	_info_panel.visible = false
	_coop_join_instructions.visible = active
	_inventories.visible = not active
	__restore_player0_element = null

	if not initialize:
		CoopService.clear_coop_players()

		var player_count = 0 if active else 1
		_update_player_count(player_count, initialize)

		if active:
			
			var focus_owner = get_focus_owner()
			if focus_owner != null:
				focus_owner.release_focus()
		else:
			_get_inventories()[0].focus_element_index(0)


func _on_connected_players_updated(connected_players: Array, initialize: bool) -> void :
	var player_count = connected_players.size()
	var is_new_player = player_count > RunData.get_player_count()
	_update_player_count(player_count, initialize)

	if player_count > 0 and is_new_player:
		var new_player_index = player_count - 1
		var element = _get_inventories()[0].get_child(0)
		Utils.focus_player_control(element, new_player_index)


func _on_connection_progress_updated(progress_values: Array) -> void :
	for coop_join_panel in _get_coop_join_panels():
		coop_join_panel.update_indicators(CoopService.connected_players, progress_values)


func _update_player_count(count: int, initialize: bool) -> void :
	RunData.set_player_count(count)
	_set_base_ui_player_count(count, ProgressData.settings.coop_mode_toggled, initialize)
	if not initialize:
		
		_update_character_selection_player_count_ui()



func _update_character_selection_player_count_ui() -> void :
	var player_count = RunData.get_player_count()
	_coop_join_instructions.visible = ProgressData.settings.coop_mode_toggled and player_count == 0
	_inventories.visible = player_count > 0
	if player_count == 0:
		__restore_player0_element = null
	var coop_join_panels: = _get_coop_join_panels()
	var locked_panels: = _get_locked_panels()
	for player_index in CoopService.MAX_PLAYER_COUNT:
		var is_player_connected = player_index < player_count
		var coop_join_panel = coop_join_panels[player_index]
		coop_join_panel.visible = ProgressData.settings.coop_mode_toggled and not is_player_connected
		coop_join_panel.update_indicators(CoopService.connected_players, CoopService.connection_progress)
		var locked_panel = locked_panels[player_index]
		if not is_player_connected:
			
			locked_panel.hide()


func _get_coop_join_panels() -> Array:
	return [_coop_join_panel1, _coop_join_panel2, _coop_join_panel3, _coop_join_panel4]


func _get_locked_panels() -> Array:
	return [_locked_panel1, _locked_panel2, _locked_panel3, _locked_panel4]


func _on_element_focused(element: InventoryElement, inventory_player_index: int) -> void :
	var player_index = FocusEmulatorSignal.get_player_index(element)
	if player_index < 0:
		push_error("Focus emulator signal not triggered")
		return

	if player_index == 0 and __restore_player0_element != null:
		if __restore_player0_element.is_visible_in_tree():
			Utils.call_deferred("focus_player_control", __restore_player0_element, player_index)
		__restore_player0_element = null
		return

	._on_element_focused(element, inventory_player_index)

	if player_index >= 0:
		_player_characters[player_index] = null
		_clear_selected_element(player_index)

		
		CoopService.listening_for_inputs = RunData.is_coop_run

	var locked_panel = _get_locked_panels()[player_index]
	locked_panel.visible = not element.is_random and element.is_special
	if locked_panel.visible:
		locked_panel.player_color_index = player_index if RunData.is_coop_run else - 1
		locked_panel.set_element(element.item, _get_reward_type())

	_info_panel.visible = not RunData.is_coop_run and not element.is_random and not element.is_special
	if _info_panel.visible:
		update_info_panel(element.item)


func reload_info_panel() -> void :

	if _info_panel.character_currently_displayed == "":
		return

	var item_info

	for element in _get_all_possible_elements(0):
		if element.my_id == _info_panel.character_currently_displayed:
			item_info = element
			break

	if item_info:
		update_info_panel(item_info)
		var panel = _get_panels()[0]
		panel.set_data(item_info, 0)


func update_info_panel(item_info: ItemParentData) -> void :
	_info_panel.set_element(item_info.my_id)

	var stylebox_color = _info_panel.get_stylebox("panel").duplicate()
	ItemService.change_panel_stylebox_from_tier(stylebox_color, item_info.tier)
	_info_panel.add_stylebox_override("panel", stylebox_color)


func _on_ZoneSelectionButton_item_selected(index: int) -> void :
	RunData.current_zone = _zone_selection_button.get_item_id(index)
	ProgressData.settings.zone_selected = RunData.current_zone
	RunData.reset_background()
	_background.texture = ZoneService.get_zone_data(RunData.current_zone).ui_background
	_inventory1.update_elements_color(RunData.current_zone)
	reload_info_panel()


func _on_BackButton_pressed():
	ProgressData.save()
	_manage_back()


func _on_CoopButton_focus_entered():
	var player_index = FocusEmulatorSignal.get_player_index(_coop_button)
	if player_index < 0:
		push_error("Focus emulator signal not triggered")
		return
	assert (player_index == 0, "only player 0 should be able to focus run options")
	__restore_player0_element = _latest_focused_element[player_index]
