class_name Inventory
extends GridContainer

signal focus_lost
signal elements_changed
signal element_pressed(element)
signal element_hovered(element)
signal element_unhovered(element)
signal element_focused(element)
signal element_unfocused(element)

enum FocusNeighbourStrategy{SAME_LINE, SCROLL_THROUGH}

export (PackedScene) var element_scene = null
export (FocusNeighbourStrategy) var focus_neighbour_strategy = FocusNeighbourStrategy.SCROLL_THROUGH
export (bool) var set_neighbour_top: = false
export (bool) var set_neighbour_bottom: = false
export (bool) var set_neighbour_left: = false
export (bool) var set_neighbour_right: = false


export (Vector2) var element_size: = preload("res://singletons/utils.gd").BASE_INVENTORY_ELEMENT_SIZE

var mouse_focus_enabled: = true setget _set_mouse_focus_enabled
func _set_mouse_focus_enabled(v: bool) -> void :
	mouse_focus_enabled = v
	_update_mouse_focus_for_control(self)
	for child in get_children():
		_update_mouse_focus_for_control(child)


var element_font = preload("res://resources/fonts/actual/base/font_40_outline_thick.tres")
var element_font_small = preload("res://resources/fonts/actual/base/font_26_outline.tres")
var locked_icon = load("res://items/global/locked_icon.png")
var category: int
var _reversed_order: = false
var _focused_element: InventoryElement = null
var __set_focus_neighbours_queued: = false


func set_elements(elements: Array, reverse_order: bool = false, replace: bool = true, prioritize_gameplay_elements: bool = false) -> void :
	if replace:
		clear_elements()

	if reverse_order:
		_reversed_order = true

	
	var check_for_duplicates = elements.size() >= 2 and elements[1].get_category() == Category.ITEM
	if check_for_duplicates:
		for element_with_count in get_elements_with_count(elements):
			var element = element_with_count[0]
			var count = element_with_count[1]
			if element.is_locked:
				add_special_element(locked_icon, false, 0.5, element)
			elif element.is_cursed:
				add_element(element)
			else:
				add_element_with_count(element, count)

	else:
		for element in elements:
			if element.is_locked:
				add_special_element(locked_icon, false, 0.5, element)
			else:
				add_element(element, check_for_duplicates)

	if prioritize_gameplay_elements:
		var element_instances = get_children()

		for element_instance in element_instances:
			if element_instance.item is CharacterData or "item_builder_turret" in element_instance.item.my_id:
				move_child(element_instance, 0)


func get_elements_with_count(elements: Array) -> Array:
	var element_index = {}
	var element_list = []
	for element in elements:
		if element.is_cursed:
			element_list.append([element, 1])
		else:
			var index = element_index.get(element.my_id)
			if index:
				element_list[index][1] += 1
			else:
				element_index[element.my_id] = element_list.size()
				element_list.append([element, 1])
	return element_list


func clear_elements() -> void :
	for n in get_children():
		remove_child(n)
		n.queue_free()
	emit_signal("elements_changed")


func focus_element_index(index: int) -> void :
	get_child(index).call_deferred("grab_focus")


func focus_element(element: ItemParentData) -> void :
	for child in get_children():
		if child.item == element:
			child.call_deferred("grab_focus")
			break


func add_element(element: ItemParentData, check_for_duplicates: bool = false) -> void :
	if check_for_duplicates and not element.is_cursed:
		var children = get_children()
		for child in children:
			if child.item != null and child.item.my_id == element.my_id and not child.item.is_cursed:
				child.add_to_number()
				return

	var _instance = _spawn_element(element)


func add_element_with_count(element: Resource, count: int):
	var instance = _spawn_element(element)
	if count > 1:
		instance.add_to_number(count - 1)


func remove_element(element: ItemParentData, nb_to_remove: int = 1, deep_comparison: bool = false) -> void :
	var children = get_children()
	var index = 0
	var removed = 0

	for i in children.size():
		var is_same_element = children[i].item == element if deep_comparison else children[i].item.my_id == element.my_id
		if is_same_element and not children[i].is_queued_for_deletion():
			if children[i].current_number > 1:
				children[i].remove_from_number()
			else:
				children[i].queue_free()
			index = i
			removed += 1
			if removed == nb_to_remove:
				break

	if removed > 0:
		emit_signal("elements_changed")

	if get_child_count() > 1:
		if index == 0:
			focus_element_index(1)
		else:
			focus_element_index(0)
	else:
		emit_signal("focus_lost")


func _spawn_element(element: Resource) -> Resource:
	var instance = element_scene.instance()
	instance.call_deferred("set_font", element_font)

	if element_size != Utils.BASE_INVENTORY_ELEMENT_SIZE:
		instance.set_element_size(element_size)
		if element_size.x <= 80 and element_size.y <= 80:
			instance.call_deferred("set_font", element_font_small)

	add_child(instance)
	_update_mouse_focus_for_control(instance)
	instance.set_element(element)

	if _reversed_order:
		move_child(instance, 0)

	connect_signals(instance)
	emit_signal("elements_changed")

	return instance


func connect_signals(instance: InventoryElement) -> void :
	var _error_hover = instance.connect("element_hovered", self, "on_element_hovered")
	var _error_unhover = instance.connect("element_unhovered", self, "on_element_unhovered")
	var _error_focus = instance.connect("element_focused", self, "on_element_focused")
	var _error_unfocus = instance.connect("element_unfocused", self, "on_element_unfocused")
	var _error_pressed = instance.connect("element_pressed", self, "on_element_pressed")


func add_special_element(p_icon: Texture, p_is_random: bool = false, p_alpha: float = 1, p_item: Resource = null) -> void :
	var instance = element_scene.instance()
	add_child(instance)
	_update_mouse_focus_for_control(instance)
	instance.is_special = true
	instance.is_random = p_is_random
	instance.modulate.a = p_alpha
	instance.set_icon(p_icon)
	instance.item = p_item
	instance.set_element_size(element_size)
	connect_signals(instance)
	emit_signal("elements_changed")


func queue_set_focus_neighbours() -> void :
	if not __set_focus_neighbours_queued:
		__set_focus_neighbours_queued = true
		call_deferred("__set_focus_neighbours")


func __set_focus_neighbours() -> void :
	__set_focus_neighbours_queued = false
	var elements: Array = Utils.filter_out_freed_objects(get_children())
	var elements_per_row: int = columns
	var last_row_start: = (elements.size() - 1) / elements_per_row * elements_per_row

	var element: Control
	var first_element_in_row: Control
	var last_element_in_row: Control
	for element_idx in elements.size():
		element = elements[element_idx]
		for margin in [MARGIN_LEFT, MARGIN_TOP, MARGIN_RIGHT, MARGIN_BOTTOM]:
			element.set_focus_neighbour(margin, NodePath(""))

		if set_neighbour_top and element_idx < elements_per_row:
			var top_neighbour_idx: int
			
			if element_idx + last_row_start < elements.size():
				top_neighbour_idx = element_idx + last_row_start
			else:
				top_neighbour_idx = - 1
			_inherit_or_set_neighbour(element, MARGIN_TOP, elements[top_neighbour_idx])

		if set_neighbour_bottom and element_idx >= last_row_start:
			_inherit_or_set_neighbour(element, MARGIN_BOTTOM, elements[element_idx % elements_per_row])

		if focus_neighbour_strategy == FocusNeighbourStrategy.SCROLL_THROUGH:
			if set_neighbour_left and element_idx % elements_per_row == 0:
				_inherit_or_set_neighbour(element, MARGIN_LEFT, elements[element_idx - 1])
			if set_neighbour_right and element_idx == elements.size() - 1:
				_inherit_or_set_neighbour(element, MARGIN_RIGHT, elements[0])
			elif set_neighbour_right and element_idx % elements_per_row == elements_per_row - 1:
				_inherit_or_set_neighbour(element, MARGIN_RIGHT, elements[element_idx + 1])

		if focus_neighbour_strategy == FocusNeighbourStrategy.SAME_LINE:
			if element_idx % elements_per_row == 0:
				first_element_in_row = elements[element_idx]
			if element_idx % elements_per_row == elements_per_row - 1 or element_idx == elements.size() - 1:
				last_element_in_row = elements[element_idx]
				if set_neighbour_left:
					_inherit_or_set_neighbour(first_element_in_row, MARGIN_LEFT, last_element_in_row)
				if set_neighbour_right:
					_inherit_or_set_neighbour(last_element_in_row, MARGIN_RIGHT, first_element_in_row)


func _inherit_or_set_neighbour(element: Control, side: int, neighbour: Control) -> void :
	var neighbour_to_inherit: = get_focus_neighbour(side)
	if neighbour_to_inherit:
		var neighbour_node: = get_node(neighbour_to_inherit)
		element.set_focus_neighbour(side, element.get_path_to(neighbour_node))
	else:
		element.set_focus_neighbour(side, element.get_path_to(neighbour))


func _update_mouse_focus_for_control(control: Control) -> void :
	control.mouse_filter = MOUSE_FILTER_PASS if mouse_focus_enabled else MOUSE_FILTER_IGNORE


func on_element_hovered(element: InventoryElement) -> void :
	emit_signal("element_hovered", element)


func on_element_unhovered(element: InventoryElement) -> void :
	emit_signal("element_unhovered", element)


func on_element_focused(element: InventoryElement) -> void :
	_focused_element = element
	emit_signal("element_focused", element)


func on_element_unfocused(element: InventoryElement) -> void :
	if _focused_element == element:
		_focused_element = null
	emit_signal("element_unfocused", element)


func on_element_pressed(element: InventoryElement) -> void :
	emit_signal("element_pressed", element)


func _on_elements_changed() -> void :
	queue_set_focus_neighbours()
