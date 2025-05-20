class_name Flasher
extends Node

export (Array, NodePath) var node_paths
export (bool) var hide_after_flash: = false
export (int) var flash_count: = 12

var _timer: Timer
var _count: = 0
var _node_alphas: = []


func _ready() -> void :
	_timer = Timer.new()
	_timer.wait_time = 0.05
	add_child(_timer)
	var _error_timeout = _timer.connect("timeout", self, "_on_flash_timer_timeout")
	for node in _get_nodes():
		_node_alphas.push_back(node.modulate.a)


func flash() -> void :
	_count = 0
	_timer.start()


func _on_flash_timer_timeout() -> void :
	var nodes: = _get_nodes()
	if _count > flash_count:
		_timer.stop()
		for i in nodes.size():
			var node = nodes[i]
			node.modulate.a = _node_alphas[i]
			if hide_after_flash:
				node.hide()
		return
	for i in nodes.size():
		var node = nodes[i]
		if node.modulate.a == 0.0:
			node.modulate.a = _node_alphas[i]
		else:
			node.modulate.a = 0.0
	_count += 1


func _get_nodes() -> Array:
	var nodes: = []
	for node_path in node_paths:
		nodes.push_back(get_node(node_path))
	return nodes
