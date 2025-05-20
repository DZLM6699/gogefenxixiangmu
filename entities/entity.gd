class_name Entity
extends RigidBody2D

signal died(entity, die_args)
signal stats_boosted(entity)

export (bool) var can_be_boosted: = false
export (ShaderMaterial) var outline_material
export (bool) var get_entity_spawner_ref_on_spawn: = false

var entity_spawner
var dead: = false
var cleaning_up: = false
var is_boosted: = false
var _outline_colors: Array = []
var _boosted_args: BoostArgs
var _current_material_alpha = 1.0
var _current_material_desaturation = 0.0

var _min_pos: Vector2
var _max_pos: Vector2

onready var sprite: = $Animation / Sprite as Sprite
onready var _animation_player: = $AnimationPlayer as AnimationPlayer
onready var _animation: = $Animation as Node2D
onready var _collision: = $Collision as CollisionShape2D


func init(zone_min_pos: Vector2, zone_max_pos: Vector2, _p_players_ref: Array = [], _entity_spawner_ref = null) -> void :

	_min_pos = Vector2(
		zone_min_pos.x + sprite.texture.get_width() / 2.0, 
		zone_min_pos.y + sprite.texture.get_height() / 2.0
	)

	_max_pos = Vector2(
		zone_max_pos.x - sprite.texture.get_width() / 2.0, 
		zone_max_pos.y - sprite.texture.get_height() / 2.0
	)


func respawn() -> void :
	show()
	_animation_player.play("idle")
	dead = false
	sleeping = false
	call_deferred("set_physics_process", true)


class DieArgs:
	var knockback_vector: = Vector2.ZERO
	var cleaning_up: = false
	var enemy_killed_by_player: = true
	var killed_by_player_index: = - 1
	var killing_blow_dmg_value: = 0



func die(args: = DieArgs.new()) -> void :
	assert ( not dead)
	cleaning_up = args.cleaning_up
	_animation_player.playback_speed = 1
	dead = true
	_animation_player.play("death")
	emit_signal("died", self, args)


func death_animation_finished() -> void :
	is_boosted = false
	_outline_colors.clear()
	sprite.material = null
	_current_material_alpha = 1.0
	_current_material_desaturation = 0.0
	_boosted_args = null
	sleeping = true
	hide()
	call_deferred("set_physics_process", false)

	_animation_player.play("RESET")
	_animation_player.advance(1.0)
	Utils.get_scene_node().add_node_to_pool(self)


func stop_burning() -> void :
	pass


func boost(boost_args: BoostArgs) -> void :
	if can_be_boosted:
		is_boosted = true
		_boosted_args = boost_args
		if boost_args.show_outline:
			add_outline(Utils.BOOST_COLOR)


func boost_ended() -> void :
	is_boosted = false
	_boosted_args = null
	remove_outline(Utils.BOOST_COLOR)


func has_outline(color: Color) -> bool:
	for outline in _outline_colors:
		if outline == color:
			return true
	return false


func add_outline(color: Color, alpha: float = 1.0, desaturation: float = 0.0) -> void :
	assert (_outline_colors.size() <= 4, "No more outlines can be supported. Adapt shader to support it")
	if _outline_colors.has(color):
		return
	_outline_colors.append(color)
	_set_outlines(alpha, desaturation)


func remove_outline(color: Color) -> void :
	_outline_colors.erase(color)
	_set_outlines()


func _set_outlines(alpha: float = 1.0, desaturation: float = 0.0) -> void :
	if not _outline_colors:
		sprite.material = null
		return

	sprite.material = ShaderMaterial.new()
	sprite.material.shader = outline_material.shader

	sprite.material.set_shader_param("texture_size", sprite.texture.get_size())

	if alpha < 1.0:
		_current_material_alpha = alpha
		sprite.material.set_shader_param("alpha", alpha)
	else:
		sprite.material.set_shader_param("alpha", _current_material_alpha)

	if desaturation > 0.0:
		_current_material_desaturation = desaturation
		sprite.material.set_shader_param("desaturation", desaturation)
	else:
		sprite.material.set_shader_param("desaturation", _current_material_desaturation)

	for i in range(_outline_colors.size()):
		sprite.material.set_shader_param("outline_color_%s" % i, _outline_colors[i])
