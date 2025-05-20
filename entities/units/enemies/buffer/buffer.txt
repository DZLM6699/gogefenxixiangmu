class_name Buffer
extends Enemy

export (Resource) var boost_sound
export (int) var nb_entities_boosted_at_once = 1
export (float) var boost_cooldown = 4.0
export (int) var hp_boost = 150
export (int) var damage_boost = 25
export (int) var speed_boost = 50
export (int) var player_hp_boost = 20
export (int) var player_speed_boost = 20
export (int) var player_attack_speed_boost = 20
export (int) var structure_range_boost = 20
export (int) var structure_damage_boost = 20
export (int) var structure_attack_speed_boost = 20

var entities_in_zone: = []

onready var _boost_zone: Area2D = $"%BoostZone"
onready var _boost_collision: CollisionShape2D = $"%BoostCollision"
onready var _boost_timer: Timer = $"%BoostTimer"


func _on_BoostZone_body_entered(body: Node) -> void :
	if not dead and body.can_be_boosted:
		entities_in_zone.push_back(body)


func respawn() -> void :
	.respawn()
	_boost_collision.set_deferred("disabled", false)


func die(args: = Entity.DieArgs.new()) -> void :
	.die(args)
	_boost_collision.set_deferred("disabled", true)
	entities_in_zone.clear()


func _on_BoostTimer_timeout() -> void :
	var nb_entities_boosted = 0
	entities_in_zone.shuffle()
	for entity in entities_in_zone:
		if is_instance_valid(entity) and entity.can_be_boosted and not entity.is_boosted:
			var boost_args: = BoostArgs.new()
			if entity is Player:
				boost_args.hp_boost = player_hp_boost
				boost_args.speed_boost = player_speed_boost
				boost_args.attack_speed_boost = player_attack_speed_boost

			elif entity is Structure:
				boost_args.damage_boost = structure_damage_boost
				boost_args.range_boost = structure_range_boost
				boost_args.attack_speed_boost = structure_attack_speed_boost

			else:
				boost_args.hp_boost = hp_boost
				boost_args.damage_boost = damage_boost
				boost_args.speed_boost = speed_boost

			entity.boost(boost_args)
			entity.emit_signal("stats_boosted", entity)

			nb_entities_boosted += 1
			if nb_entities_boosted >= nb_entities_boosted_at_once:
				break

	if nb_entities_boosted > 0:
		emit_signal("stats_boosted", self)
		SoundManager2D.play(boost_sound, global_position, 0.0, 0.2)

	_boost_timer.wait_time = boost_cooldown


func _on_BoostZone_body_exited(body: Node) -> void :
	entities_in_zone.erase(body)
