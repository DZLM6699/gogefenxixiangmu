class_name Pursuer
extends Enemy

export (Resource) var boost_sound
export (float) var boost_cooldown = 1.0
export (int) var max_boosts = 10
export (int) var speed_on_boost = 0
export (int) var damage_on_boost = 0
export (float) var size_on_boost = 0.0
export (int) var change_movement_behavior_after_x_boosts = - 1
export (int) var bonus_speed_on_change_movement_behavior = 0
export (bool) var reset_nb_times_boosted_on_hit = true

var nb_times_boosted = 0
var movement_behavior_on_boost: Node2D
var movement_behavior_changed = false

onready var _boost_timer: Timer = $BoostTimer

var initial_data: Dictionary = {
	"sprite_scale": Vector2.ZERO, 
	"sprite_position": Vector2.ZERO, 
	"collision_scale": Vector2.ZERO, 
	"hurtbox_scale": Vector2.ZERO, 
	"hitbox_scale": Vector2.ZERO
}

func _ready():
	_boost_timer.wait_time = boost_cooldown

	if change_movement_behavior_after_x_boosts != - 1:
		movement_behavior_on_boost = $MovementBehaviorOnBoost
		movement_behavior_on_boost.init(self)

	initial_data.sprite_scale = Vector2(abs(sprite.scale.x), sprite.scale.y)
	initial_data.sprite_position = sprite.position
	initial_data.collision_scale = _collision.scale
	initial_data.hurtbox_scale = _hurtbox.scale
	initial_data.hitbox_scale = _hitbox.scale


func respawn() -> void :
	.respawn()

	nb_times_boosted = 0
	movement_behavior_changed = false
	_boost_timer.start()


func _on_BoostTimer_timeout() -> void :
	if nb_times_boosted < max_boosts and not dead:
		boost_self()


func boost_self() -> void :
	bonus_speed += speed_on_boost * RunData.current_run_accessibility_settings.speed

	nb_times_boosted += 1

	if damage_on_boost > 0:
		reset_damage_stat(damage_on_boost * nb_times_boosted)

	if size_on_boost > 0.0:
		set_size(size_on_boost)

	emit_signal("stats_boosted", self)
	SoundManager2D.play(boost_sound, global_position, - 10.0, 0.2)

	if change_movement_behavior_after_x_boosts != - 1 and nb_times_boosted >= change_movement_behavior_after_x_boosts and not movement_behavior_changed:
		movement_behavior_changed = true
		_current_movement_behavior = movement_behavior_on_boost
		bonus_speed += bonus_speed_on_change_movement_behavior * RunData.current_run_accessibility_settings.speed


func set_size(p_size_boost: float) -> void :
	var hitbox_scaling = p_size_boost * 0.25
	var scale_sign = sign(sprite.scale.x)
	sprite.scale = Vector2(sprite.scale.x + scale_sign * p_size_boost, sprite.scale.y + p_size_boost)
	sprite.position.y -= p_size_boost * 40.0
	_collision.scale = Vector2(_collision.scale.x + hitbox_scaling, _collision.scale.y + hitbox_scaling)
	_hurtbox.scale = Vector2(_hurtbox.scale.x + hitbox_scaling, _hurtbox.scale.y + hitbox_scaling)
	_hitbox.scale = Vector2(_hitbox.scale.x + hitbox_scaling, _hitbox.scale.y + hitbox_scaling)


func reset_size() -> void :
	var scale_sign = sign(sprite.scale.x)
	sprite.scale = Vector2(initial_data.sprite_scale.x * scale_sign, initial_data.sprite_scale.y)
	sprite.position.y = initial_data.sprite_scale.y
	_collision.scale = initial_data.collision_scale
	_hurtbox.scale = initial_data.hurtbox_scale
	_hitbox.scale = initial_data.hitbox_scale


func _on_hit_something(thing_hit: Node, damage_dealt: int) -> void :
	._on_hit_something(thing_hit, damage_dealt)
	if reset_nb_times_boosted_on_hit:
		nb_times_boosted = 0
		bonus_speed = 0


func get_base_speed_value_for_pct_based_decrease() -> int:
	return current_stats.speed + bonus_speed
