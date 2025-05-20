class_name Projectile
extends Node2D

signal hit_something(thing_hit, damage_dealt)

export (bool) var destroy_on_leaving_screen = true
export (float) var stop_delay = 0.0

var velocity = Vector2.ZERO

var _enable_stop_delay: = false
var _elapsed_delay: = 0.0
var _original_collision_layer: int
var _original_hitbox_disabled: bool

onready var _sprite: = $"%Sprite" as Sprite
onready var _hitbox: = $"%Hitbox" as Area2D
onready var _destroy_timer: = $"%DestroyTimer" as Timer
onready var _visibility_notifier: = $"VisibilityNotifier2D"
onready var _animation_player: = $"%AnimationPlayer"


func _ready() -> void :
	_original_collision_layer = _hitbox.collision_layer
	_original_hitbox_disabled = _hitbox.is_disabled()


func _physics_process(delta: float) -> void :
	position += velocity * delta

	if _enable_stop_delay:
		_elapsed_delay += Utils.physics_one(delta)

		if _elapsed_delay >= stop_delay:
			_return_to_pool()


func shoot() -> void :
	show()
	_hitbox.active = true
	if not _original_hitbox_disabled:
		_hitbox.enable()

	if _animation_player.assigned_animation != "":
		_animation_player.play()
	set_physics_process(true)


func stop() -> void :
	_hitbox.active = false
	_hitbox.disable()
	_hitbox.ignored_objects.clear()

	if stop_delay > 0:
		_enable_stop_delay = true
	else:
		_return_to_pool()


func _return_to_pool() -> void :
	hide()
	velocity = Vector2.ZERO
	_hitbox.collision_layer = _original_collision_layer
	_enable_stop_delay = false
	_elapsed_delay = 0
	_sprite.material = null
	_animation_player.stop()
	_destroy_timer.stop()
	set_physics_process(false)

	Utils.disconnect_all_signal_connections(self, "hit_something")
	Utils.disconnect_all_signal_connections(self._hitbox, "killed_something")

	if is_instance_valid(_hitbox.from) and _hitbox.from.has_signal("died") and _hitbox.from.is_connected("died", self, "on_entity_died"):
		_hitbox.from.disconnect("died", self, "on_entity_died")

	var main = Utils.get_scene_node()
	main.add_node_to_pool(self)


func get_damage() -> int:
	return _hitbox.damage


func set_damage(value: float, hitbox_args: Hitbox.HitboxArgs = Hitbox.HitboxArgs.new()) -> void :
	assert (_hitbox)
	_hitbox.set_damage(value, hitbox_args)


func set_damage_tracking_key(damage_tracking_key: String) -> void :
	assert (_hitbox)
	_hitbox.damage_tracking_key = damage_tracking_key


func set_knockback_vector(knockback_direction: Vector2, knockback_amount: float, knockback_piercing: float) -> void :
	assert (_hitbox)
	_hitbox.set_knockback(knockback_direction, knockback_amount, knockback_piercing)


func set_effect_scale(effect_scale: float) -> void :
	assert (_hitbox)
	_hitbox.effect_scale = effect_scale


func set_speed_percent_modifier(speed_percent_modifier: float) -> void :
	assert (_hitbox)
	_hitbox.speed_percent_modifier = speed_percent_modifier


func _on_VisibilityNotifier2D_screen_exited() -> void :
	if visible and _destroy_timer.is_inside_tree() and destroy_on_leaving_screen:
		_destroy_timer.start()


func _on_DestroyTimer_timeout() -> void :
	if visible and not _visibility_notifier.is_on_screen():
		stop()


func set_ignored_objects(objects: Array) -> void :
	_hitbox.ignored_objects = objects


func set_from(from: Node) -> void :
	if _hitbox != null and is_instance_valid(_hitbox):
		_hitbox.from = from


func set_collision_layer(value: int) -> void :
	_hitbox.collision_layer = value


func set_sprite_material(material: ShaderMaterial) -> void :
	_sprite.material = material


func disable_hitbox() -> void :
	_hitbox.disable()


func enable_hitbox() -> void :
	_hitbox.enable()



func on_entity_died(_entity: Entity, _args: Entity.DieArgs) -> void :
	stop()
