class_name PlayerProjectile
extends Projectile

const PROJECTILE_ADDITIONAL_DISTANCE = 100

export (int) var rotation_speed = 0

var spawn_position: Vector2



var _weapon_stats: Resource
var _piercing: = 0
var _bounce: = 0
var _max_range: = 0


var player_index: int setget _set_player_index, _get_player_index
func _get_player_index() -> int:
	return _hitbox.from.player_index
func _set_player_index(_v: int) -> void :
	printerr("player_index is readonly")


func _physics_process(_delta: float) -> void :

	var add_dist = PROJECTILE_ADDITIONAL_DISTANCE

	if ProgressData.is_manual_aim(player_index):
		add_dist = PROJECTILE_ADDITIONAL_DISTANCE / 2.0

	if (global_position - spawn_position).length() > _max_range + add_dist:
		stop()

	if rotation_speed != 0:
		rotation_degrees += 25


func shoot() -> void :
	.shoot()
	global_position = spawn_position
	_sprite.modulate.a = ProgressData.settings.projectile_opacity


func set_effects(effects: Array) -> void :
	_hitbox.effects = effects

	_hitbox.projectiles_on_hit = []
	for effect in effects:
		if effect is ProjectilesOnHitEffect:
			_hitbox.projectiles_on_hit = _hitbox.from._hitbox.projectiles_on_hit


func set_weapon_stats(p_weapon_stats: WeaponStats) -> void :
	_weapon_stats = p_weapon_stats
	_piercing = _weapon_stats.piercing
	_bounce = _weapon_stats.bounce
	_max_range = _weapon_stats.max_range


func _on_Hitbox_hit_something(thing_hit: Node, damage_dealt: int) -> void :
	emit_signal("hit_something", thing_hit, damage_dealt)
	RunData.manage_life_steal(_weapon_stats, _get_player_index())

	_hitbox.ignored_objects.append(thing_hit)

	if _bounce > 0:
		bounce(thing_hit)
	elif _piercing <= 0:
		stop()
	else:
		_piercing -= 1
		if _hitbox.damage > 0:
			_hitbox.damage = max(1, _hitbox.damage - (_hitbox.damage * _weapon_stats.piercing_dmg_reduction))


func bounce(thing_hit: Node) -> void :
	_bounce -= 1
	var target = thing_hit._entity_spawner_ref.get_rand_enemy()
	var direction = (target.global_position - global_position).angle() if target != null else rand_range( - PI, PI)
	velocity = Vector2.RIGHT.rotated(direction) * velocity.length()
	rotation = velocity.angle()
	_max_range = 99999
	set_knockback_vector(Vector2.ZERO, 0.0, 0.0)
	if _hitbox.damage > 0:
		_hitbox.damage = max(1, _hitbox.damage - (_hitbox.damage * _weapon_stats.bounce_dmg_reduction))


func _on_Hitbox_critically_hit_something(_thing_hit: Node, _damage_dealt: int) -> void :
	var remove_effects = []

	for effect in _hitbox.effects:
		if effect.key == "bounce_on_crit":

			_bounce += 1
			effect.value -= 1

			if effect.value <= 0:
				remove_effects.push_back(effect)
		elif effect.key == "pierce_on_crit":

			_piercing += 1
			effect.value -= 1

			if effect.value <= 0:
				remove_effects.push_back(effect)

	for effect in remove_effects:
		_hitbox.effects.erase(effect)
