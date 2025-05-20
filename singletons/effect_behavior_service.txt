extends Node

export (Array, Resource) var scene_effect_behaviors
export (Array, Resource) var enemy_effect_behaviors
export (Array, Resource) var player_effect_behaviors

var active_enemy_effect_behavior_data: = []


func _ready() -> void :
	reset()


func reset() -> void :
	active_enemy_effect_behavior_data = enemy_effect_behaviors.duplicate()


func update_active_effect_behaviors():
	active_enemy_effect_behavior_data.clear()
	for behavior_data in enemy_effect_behaviors:
		var instance = behavior_data.scene.instance()
		if instance.should_add_on_spawn():
			active_enemy_effect_behavior_data.push_back(behavior_data)
		instance.queue_free()
