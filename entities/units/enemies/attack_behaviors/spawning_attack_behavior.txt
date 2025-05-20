class_name SpawningAttackBehavior
extends AttackBehavior

signal wanted_to_spawn_an_enemy(enemy_scene, position)

export (PackedScene) var enemy_to_spawn = null
export (float) var cooldown = 60.0
export (int) var max_cd_randomization = 10
export (float) var attack_anim_speed = 1.0
export (int) var nb_to_spawn = 1
export (bool) var spawn_at_random_pos = false
export (int) var spawn_in_radius_around_unit = - 1
export (int) var max_nb_of_spawns = - 1

var _current_nb_of_spawns: int = 0
var _current_cd: float = cooldown


func _ready() -> void :
	_current_cd = Utils.LARGE_NUMBER as float if max_nb_of_spawns == 0 else get_cd()


func reset() -> void :
	_current_cd = get_cd()
	_current_nb_of_spawns = 0


func physics_process(delta: float) -> void :
	_current_cd = max(_current_cd - Utils.physics_one(delta), 0)

	if _current_cd <= 0 and (max_nb_of_spawns == - 1 or _current_nb_of_spawns < max_nb_of_spawns):
		_parent._animation_player.playback_speed = attack_anim_speed
		_parent._animation_player.play(_parent.shoot_animation_name)


func shoot() -> void :
	var spawns = nb_to_spawn

	if _parent != null and is_instance_valid(_parent) and _parent is Boss:
		spawns = max(1, round(nb_to_spawn * (1.0 + RunData.sum_all_player_effects("number_of_enemies") / 100.0)))

	for i in spawns:
		var pos = _parent.global_position

		if spawn_at_random_pos:
			pos = ZoneService.get_rand_pos()
		elif spawn_in_radius_around_unit != - 1:
			pos = ZoneService.get_rand_pos_in_area(_parent.global_position, spawn_in_radius_around_unit)

		emit_signal("wanted_to_spawn_an_enemy", enemy_to_spawn, pos)

		_current_nb_of_spawns += 1


func animation_finished(anim_name: String) -> void :
	if _parent.is_shooting_anim(anim_name):
		if max_nb_of_spawns != - 1 and _current_nb_of_spawns >= max_nb_of_spawns:
			_current_cd = Utils.LARGE_NUMBER
		else:
			_current_cd = get_cd()


func get_cd() -> float:
	return rand_range(max(1, cooldown - max_cd_randomization), cooldown + max_cd_randomization)
