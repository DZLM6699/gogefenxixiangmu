tool 
extends EditorPlugin

var brotatools_ui: BrotatoolsUI


func _enter_tree() -> void :
	brotatools_ui = preload("res://addons/brotatools/brotatools_ui.tscn").instance()
	add_control_to_bottom_panel(brotatools_ui, "Brotatools")


func _exit_tree() -> void :
	remove_control_from_bottom_panel(brotatools_ui)
	brotatools_ui.queue_free()
