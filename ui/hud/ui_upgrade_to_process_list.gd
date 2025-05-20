class_name UIUpgradeToProcessList
extends UIItemList


func add_element(icon: Resource, level: int) -> void :
	var node = element_scene.instance()
	node.set_data(icon, level)
	_elements.push_back(level)
	_add_ui_node(node)


func remove_element(level: int) -> void :
	_elements.erase(level)
	var elements_nodes = get_children()
	for node in elements_nodes:
		if node.level == level:
			_remove_ui_node(node)
			break


func _get_info_text() -> String:
	return "INFO_LEVEL_UP"
