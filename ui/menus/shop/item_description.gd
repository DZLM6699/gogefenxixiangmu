class_name ItemDescription
extends VBoxContainer

const SCROLL_SPEED: = 600.0

signal mouse_hovered_category
signal mouse_exited_category

export (bool) var expand_indefinitely = true
export (bool) var show_details = true

var item: ItemParentData
onready var icon_panel: Panel = $HBoxContainer / IconPanel

onready var _icon = $HBoxContainer / IconPanel / Icon as TextureRect
onready var _name = $"%Name"
onready var _category = $"%Category"

onready var _vbox_container = $VBoxContainer
onready var _effects = $VBoxContainer / Effects as RichTextLabel
onready var _weapon_stats = $VBoxContainer / WeaponStats as RichTextLabel

onready var _scroll_container = $ScrollContainer as ScrollContainer
onready var _effects_scrolled = $ScrollContainer / VBoxContainer / Effects as RichTextLabel
onready var _weapon_stats_scrolled = $ScrollContainer / VBoxContainer / WeaponStats as RichTextLabel

var _player_index: = 0


func _ready() -> void :
	_vbox_container.visible = show_details and expand_indefinitely
	_scroll_container.visible = show_details and not expand_indefinitely
	set_process_input(false)

func _process(delta: float) -> void :
	_scroll_container.scroll_vertical += Utils.get_player_rjoy_vector(_player_index).y * SCROLL_SPEED * delta

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		set_process(_scroll_container.visible)

func set_item(item_data: ItemParentData, player_index: int, item_count: = 1) -> void :
	item = item_data
	_player_index = player_index
	icon_panel.set_count(item_count)

	_category.show()

	if item_data is WeaponData:
		get_weapon_stats().show()
		get_weapon_stats().bbcode_text = item_data.get_weapon_stats_text(player_index)
		_category.text = tr(ItemService.get_weapon_sets_text(item_data.sets))
	else:
		get_weapon_stats().hide()
		if item_data is CharacterData:
			_category.text = tr("CHARACTER")
		elif item_data is UpgradeData:
			_category.text = tr("UPGRADE")
		elif item_data is DifficultyData:
			_category.text = tr("DIFFICULTY")
		else:
			if item_data.max_nb == 1:
				_category.text = tr("UNIQUE")
			elif item_data.max_nb != - 1 and item_data.max_nb != 0:
				_category.text = Text.text("LIMITED", [str(RunData.get_nb_item(item_data.my_id, player_index)), str(item_data.max_nb)])
			else:
				_category.text = tr("ITEM")

	_name.text = item_data.get_name_text()
	_icon.texture = item_data.get_icon()
	_name.modulate = ItemService.get_color_from_tier(item_data.tier)

	icon_panel._update_stylebox(item_data.is_cursed)

	if item_data is DifficultyData and item_data.effects.size() == 0:
		get_effects().bbcode_text = item_data.description
	else:
		get_effects().bbcode_text = item_data.get_effects_text(player_index)
	get_effects().visible = not get_effects().bbcode_text.empty()



func set_custom_data(name: String, icon: Resource) -> void :
	_name.text = name
	_name.modulate = Color.white
	_icon.texture = icon
	_category.hide()
	get_weapon_stats().hide()
	get_effects().hide()
	item = null


func get_weapon_stats() -> Node2D:
	return _weapon_stats if expand_indefinitely else _weapon_stats_scrolled


func get_effects() -> Node2D:
	return _effects if expand_indefinitely else _effects_scrolled


func _on_Category_mouse_entered() -> void :
	emit_signal("mouse_hovered_category")


func _on_Category_mouse_exited() -> void :
	emit_signal("mouse_exited_category")
