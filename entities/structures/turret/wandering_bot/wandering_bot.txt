class_name WanderingBot
extends Turret

var distance = rand_range(100, 200)
var rotation_speed = rand_range(2, 2.5)

var _players: = []
var _angle = rand_range(0, 2 * PI)

export (Resource) var slow_sound


func init(zone_min_pos: Vector2, zone_max_pos: Vector2, players_ref: Array = [], _entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, players_ref, _entity_spawner_ref)
	_players = players_ref


func _physics_process(delta: float) -> void :
	_angle += delta * rotation_speed
	var player_position = _players[player_index].global_position
	global_position = Vector2(player_position.x + cos(_angle) * distance, player_position.y + sin(_angle) * distance)


func _on_SlowHitbox_hit_something(thing_hit: Node, _damage_dealt: int) -> void :
	SoundManager2D.play(slow_sound, thing_hit.global_position, - 5, 0.2)
	thing_hit.add_decaying_speed( - 250)
