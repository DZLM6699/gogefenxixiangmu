class_name UIItemList
extends HBoxContainer

const COOP_ELEMENT_SCALE: = 0.77

signal ui_element_mouse_entered(ui_element, text)
signal ui_element_mouse_exited(ui_element)

export (PackedScene) var element_scene = null

var _elements: = []


func is_empty() -> bool:
	return _elements.empty()


func on_ui_element_mouse_entered(ui_element: Node) -> void :
	emit_signal("ui_element_mouse_entered", ui_element, _get_info_text())


func on_ui_element_mouse_exited(ui_element: Node) -> void :
	emit_signal("ui_element_mouse_exited", ui_element)


func _add_ui_node(node: Node) -> void :
	if RunData.is_coop_run:
		node.rect_min_size *= COOP_ELEMENT_SCALE
	add_child(node)
	var _error_mouse_entered = node.connect("ui_element_mouse_entered", self, "on_ui_element_mouse_entered")
	var _error_mouse_exited = node.connect("ui_element_mouse_exited", self, "on_ui_element_mouse_exited")


func _remove_ui_node(node: Node) -> void :
	remove_child(node)
	node.queue_free()
	node.disconnect("ui_element_mouse_entered", self, "on_ui_element_mouse_entered")
	node.disconnect("ui_element_mouse_exited", self, "on_ui_element_mouse_exited")


func _get_info_text() -> String:
	return ""
