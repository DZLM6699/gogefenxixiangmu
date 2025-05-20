tool 
class_name InventoryContainer
extends VBoxContainer

signal elements_changed

export (Inventory.FocusNeighbourStrategy) var focus_neighbour_strategy: = Inventory.FocusNeighbourStrategy.SCROLL_THROUGH
export (bool) var set_neighbour_top: = false
export (bool) var set_neighbour_bottom: = false
export (bool) var set_neighbour_right: = false
export (bool) var set_neighbour_left: = false

export (int) var reserve_column_count: = 1 setget _set_reserve_column_count
func _set_reserve_column_count(v: int) -> void :
	reserve_column_count = v
	if _elements:
		_elements.columns = reserve_column_count
	if _scroll_size_container:
		_scroll_size_container.rect_min_size.x = _get_scroll_size_for_column_count(reserve_column_count)

export (int) var reserve_row_count: = 2 setget _set_reserve_row_count
func _set_reserve_row_count(v: int) -> void :
	reserve_row_count = v
	if _scroll_size_container:
		_scroll_size_container.rect_min_size.y = _get_scroll_size_for_row_count(reserve_row_count)

export  var auto_add_columns: = false

onready var _scroll_size_container = $"%ScrollSizeContainer"
onready var _scroll_container = $"%ScrollContainer"
onready var _label = $Label
onready var _elements: Inventory = $"%Elements"

var _element_size: = Vector2.ZERO

func _ready() -> void :
	_element_size = _elements.element_size

	
	_set_reserve_column_count(reserve_column_count)
	_set_reserve_row_count(reserve_row_count)

	var _error = _elements.connect("elements_changed", self, "_on_size_changed")
	_error = _scroll_size_container.connect("resized", self, "_on_size_changed")
	set_process(true)

	forward_focus_settings_to_inventory()


func _process(_delta: float) -> void :
	
	call_deferred("_on_size_changed")
	set_process(false)


func get_element_count() -> int:
	var count: = 0
	for element in _elements.get_children():
		if not element.is_queued_for_deletion():
			count += 1
	return count


func get_element(index: int) -> InventoryElement:
	var element = _elements.get_child(index)
	if element and not element.is_queued_for_deletion():
		return element
	return null


func set_label(label: String) -> void :
	_label.text = label


func set_data(label: String, category: int, elements: Array, reverse: bool = false, prioritize_gameplay_elements: bool = false) -> void :
	_label.text = label
	_elements.category = category
	_elements.set_elements(elements, reverse, true, prioritize_gameplay_elements)


func focus_element_index(index: int) -> void :
	_elements.focus_element_index(index)


func forward_focus_settings_to_inventory() -> void :
	
	_elements.focus_neighbour_strategy = focus_neighbour_strategy
	_elements.set_neighbour_top = set_neighbour_top
	_elements.set_neighbour_bottom = set_neighbour_bottom
	_elements.set_neighbour_left = set_neighbour_left
	_elements.set_neighbour_right = set_neighbour_right

	_elements.focus_neighbour_top = _get_path_relative_to_elements(focus_neighbour_top)
	_elements.focus_neighbour_bottom = _get_path_relative_to_elements(focus_neighbour_bottom)
	_elements.focus_neighbour_left = _get_path_relative_to_elements(focus_neighbour_left)
	_elements.focus_neighbour_right = _get_path_relative_to_elements(focus_neighbour_right)

	_elements.queue_set_focus_neighbours()


func _on_size_changed() -> void :
	var capacity = _get_capacity(_scroll_size_container)
	var capacity_x = int(capacity.x)
	var capacity_y = int(capacity.y)
	
	var expands_vertically = size_flags_vertical & SIZE_EXPAND
	_scroll_container.rect_min_size.y = _get_scroll_size_for_row_count(capacity_y if expands_vertically else reserve_row_count)
	if not auto_add_columns:
		return
	var overflow = int(max(0, get_element_count() - capacity_x * capacity_y))
	
	_elements.columns = capacity_x + (overflow + capacity_y - 1) / capacity_y

	if not Engine.editor_hint:
		_elements.queue_set_focus_neighbours()



func _get_capacity(control: Control = self) -> Vector2:
	if _element_size == Vector2.ZERO:
		return Vector2(_elements.columns, _elements.rows)
	var vseparation = _elements.get_constant("vseparation")
	var hseparation = _elements.get_constant("hseparation")

	
	var capacity_rows
	var capacity_columns

	if auto_add_columns:
		capacity_rows = int((control.rect_size.y - vseparation) / (_element_size.y + vseparation))
		capacity_columns = int(control.rect_size.x / (_element_size.x + hseparation))
	else:
		capacity_rows = int(control.rect_size.y / (_element_size.y + vseparation))
		capacity_columns = int((control.rect_size.x - hseparation) / (_element_size.x + hseparation))

	return Vector2(capacity_columns, capacity_rows)


func _get_scroll_size_for_row_count(count: int) -> float:
	var vseparation = _elements.get_constant("vseparation")

	if auto_add_columns:
		return vseparation + (_element_size.y + vseparation) * count
	else:
		
		return (_element_size.y + vseparation) * count - 1


func _get_scroll_size_for_column_count(count: int) -> float:
	var hseparation = _elements.get_constant("hseparation")

	if auto_add_columns:
		return (_element_size.x + hseparation) * count - 1
	else:
		return hseparation + (_element_size.x + hseparation) * count


func _get_path_relative_to_elements(path: NodePath) -> NodePath:
	if path.is_empty():
		return path
	return _elements.get_path_to(get_node(path))


func _on_Elements_elements_changed():
	emit_signal("elements_changed")
