extends Boss

onready var _spawning_shooting_behavior = $SpawningShootingBehavior


func _ready() -> void :
	_spawning_shooting_behavior.init(self)
	_all_attack_behaviors.push_back(_spawning_shooting_behavior)


func shoot() -> void :
	.shoot()

	if _current_state == 0:
		_spawning_shooting_behavior.shoot()
