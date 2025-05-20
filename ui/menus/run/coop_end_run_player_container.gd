class_name EndRunPlayerContainer
extends Container

export (Resource) var small_label_theme

export (int) var player_index: = 0 setget _set_player_index
func _set_player_index(v: int) -> void :
	player_index = v
	if not is_inside_tree() or player_index >= RunData.get_player_count():
		return
	carousel.player_index = player_index
	toggle_popup_hint.player_index = player_index
	for stats_container in [primary_stats_container, secondary_stats_container]:
		stats_container.update_player_stats(player_index)
	_update_stylebox()

onready var carousel = $"%Carousel"
onready var primary_stats_container = $"%PrimaryStatsContainer"
onready var secondary_stats_container = $"%SecondaryStatsContainer"
onready var weapons_container: InventoryContainer = $"%WeaponsContainer"
onready var items_container: InventoryContainer = $"%ItemsContainer"
onready var toggle_popup_hint: ScrollContainer = $"%TogglePopupHint"


var _resume_element_control_focus = null


func _ready() -> void :
	_set_player_index(player_index)


func focus() -> void :
	if carousel.index == 0:
		if _resume_element_control_focus:
			Utils.focus_player_control(_resume_element_control_focus, player_index)
		else:
			Utils.focus_player_control(items_container.get_element(0), player_index)
	elif carousel.index == 1:
		
		
		Utils.focus_player_control(primary_stats_container.general_stats[0], player_index)
	else:
		
		Utils.get_focus_emulator(player_index).focused_control = null


func _update_stylebox() -> void :
	var stylebox = get_stylebox("panel").duplicate()
	CoopService.change_stylebox_for_player(stylebox, player_index)
	stylebox.draw_center = true
	add_stylebox_override("panel", stylebox)


func _on_Carousel_index_changed(index: int) -> void :
	if not carousel.are_trigger_buttons_active():
		
		return
	var focused_control = Utils.get_player_focused_control(self, player_index)
	if focused_control and carousel.get_content_element(0).is_a_parent_of(focused_control):
		_resume_element_control_focus = focused_control
	focus()
	if index == 0:
		_resume_element_control_focus = null
