class_name Landmine
extends Structure

export (Resource) var pressed_sprite = null
export (Array, Resource) var pressed_sounds

onready var _sprite = $Animation / Sprite
onready var _original_texture = _sprite.texture


func respawn() -> void :
	.respawn()
	_sprite.texture = _original_texture


func _on_Area2D_body_entered(_body: Node) -> void :

	if dead or _sprite.texture == pressed_sprite: return

	SoundManager2D.play(Utils.get_rand_element(pressed_sounds), global_position, 5, 0.2)
	_sprite.texture = pressed_sprite


func _on_Area2D_body_exited(_body: Node) -> void :
	if dead or effects.size() <= 0: return

	var explosion_effect = effects[0]
	var args: = WeaponServiceExplodeArgs.new()
	args.pos = global_position
	args.damage = stats.damage
	args.accuracy = stats.accuracy
	args.crit_chance = stats.crit_chance
	args.crit_damage = stats.crit_damage
	args.burning_data = stats.burning_data
	args.scaling_stats = stats.scaling_stats
	args.from_player_index = player_index
	args.damage_tracking_key = explosion_effect.tracking_key
	args.from = self
	var _inst = WeaponService.explode(explosion_effect, args)
	die()


func boost(boost_args: BoostArgs) -> void :
	if can_be_boosted:
		.boost(boost_args)
		stats.damage *= 1.0 + boost_args.damage_boost / 100.0

		var new_explosion_effect = effects[0].duplicate()
		new_explosion_effect.scale *= 1.0 + boost_args.range_boost / 100.0
		effects = [new_explosion_effect]
