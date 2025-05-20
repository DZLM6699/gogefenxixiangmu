class_name UIConsumableToProcessList
extends UIItemList


func add_element(item_data: ItemParentData) -> void :
	var node = element_scene.instance()
	node.set_item_data(item_data)
	_elements.push_back(item_data)
	_add_ui_node(node)


func remove_element(item_data: ItemParentData) -> void :
	_elements.erase(item_data)
	var elements_nodes = get_children()
	for node in elements_nodes:
		if node.item_data == item_data:
			_remove_ui_node(node)
			break


func _get_info_text() -> String:
	return "INFO_ITEM_BOX"
