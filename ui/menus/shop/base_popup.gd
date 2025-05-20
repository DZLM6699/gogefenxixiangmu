class_name BasePopup
extends Control

const DIST = 10

export (NodePath) var parent_node_path


export  var anchor_to_panel: = true

var _attachment: Control
var _anchor_panel: Control


func _process(_delta) -> void :
	
	_reposition()



func hide(_player_index: = - 1) -> void :
	.hide()


func set_pos_from(control: Control, panel: Node) -> void :
	if not is_instance_valid(control) or not is_instance_valid(panel):
		return

	_attachment = control
	_anchor_panel = panel

	var min_width = min(_get_parent_rect().size.x * _get_popup_width_factor(), 350)
	rect_min_size = Vector2(min_width, 0)
	_reposition()


func _reposition() -> void :
	rect_size = rect_min_size
	rect_global_position = _get_new_position(_attachment, _anchor_panel)


func _get_new_position(control: Control, panel: Node) -> Vector2:
	if not is_instance_valid(control) or not is_instance_valid(panel) or not control.is_inside_tree() or not panel.is_inside_tree():
		return rect_global_position

	var control_pos: Vector2 = control.rect_global_position
	var pos: = control_pos

	var parent_rect: = _get_parent_rect()
	
	var anchor_top: = control_pos.y >= parent_rect.position.y + parent_rect.size.y / 2
	
	var anchor_right: = control_pos.x >= parent_rect.position.x + parent_rect.size.x / 2

	if control.rect_size.x > rect_size.x:
		anchor_right = true

	var anchor_node = panel if anchor_to_panel else self
	if anchor_right:
		pos.x = min(control_pos.x, parent_rect.position.x + parent_rect.size.x) + control.rect_size.x - anchor_node.rect_size.x
	else:
		pos.x = control_pos.x

	if anchor_top:
		pos.y = min(control_pos.y, parent_rect.position.y + parent_rect.size.y) - rect_size.y - DIST
	else:
		pos.y = control_pos.y + control.rect_size.y + DIST

	
	if pos.x < parent_rect.position.x:
		pos.x = parent_rect.position.x
	elif pos.x + rect_size.x > parent_rect.position.x + parent_rect.size.x:
		pos.x = parent_rect.position.x + parent_rect.size.x - rect_size.x

	if pos.y < parent_rect.position.y:
		pos.y = parent_rect.position.y
	elif pos.y + rect_size.y > parent_rect.position.y + parent_rect.size.y:
		pos.y = parent_rect.position.y + parent_rect.size.y - rect_size.y

	if Rect2(pos, rect_size).intersects(Rect2(control.rect_global_position, control.rect_size)):
		if control is ButtonWithIcon:
			
			var offset: = 100
			if pos.x - parent_rect.position.x >= 0.9 * offset:
				pos.x -= offset
		else:
			
			var offset: = control.rect_size.x + DIST
			if anchor_right and pos.x - parent_rect.position.x >= offset:
				pos.x -= offset
			elif not anchor_right and parent_rect.end.x - (pos.x + rect_size.x) >= offset:
				pos.x += offset

	return pos


func _get_parent_rect() -> Rect2:
	if not parent_node_path:
		return Rect2(0, 0, Utils.project_width, Utils.project_height)
	var parent = get_node(parent_node_path)
	var style = parent.get_stylebox("normal")
	return Rect2(parent.rect_global_position + style.get_offset(), parent.rect_size - style.get_minimum_size())


func _get_popup_width_factor() -> float:
	return 1.0
