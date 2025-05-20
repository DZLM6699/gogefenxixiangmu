class_name Hitbox
extends Area2D

signal critically_hit_something(thing_hit, damage_dealt)
signal hit_something(thing_hit, damage_dealt)
signal killed_something(thing_killed)
signal added_gold_on_crit(gold_added)

export  var deals_damage: = true

var damage: = 1
var knockback_direction: = Vector2.ZERO
var knockback_amount: = 0.0
var knockback_piercing: = 0.0
var crit_chance: = 0.0
var crit_damage: = 1.0
var effect_scale: = 1.0
var burning_data: BurningData = null
var active = true
var accuracy = 1.0
var is_healing: = false
var projectiles_on_hit: Array = []
var ignored_objects: Array = []
var effects: Array = []
var speed_percent_modifier: = 0
var from = null
var damage_tracking_key = ""
var scaling_stats: Array = []




var player_attack_id: = - 1

onready var _collision: = $Collision as CollisionShape2D

class HitboxArgs:
	var scaling_stats: Array = []
	var accuracy: float = 1.0
	var crit_chance: float = 0.0
	var crit_damage: float = 0.0
	var burning_data: BurningData = BurningData.new()
	var is_healing: bool = false

	func set_from_weapon_stats(weapon_stats: WeaponStats) -> Hitbox.HitboxArgs:
		return _set_from(weapon_stats)

	func set_from_explode_args(explode_args: WeaponServiceExplodeArgs) -> Hitbox.HitboxArgs:
		return _set_from(explode_args)

	func _set_from(source: Reference) -> Hitbox.HitboxArgs:
		scaling_stats = source.scaling_stats
		accuracy = source.accuracy
		crit_chance = source.crit_chance
		crit_damage = source.crit_damage
		burning_data = source.burning_data
		is_healing = source.is_healing
		return self


func set_damage(p_value: int, args: HitboxArgs = HitboxArgs.new()) -> void :
	damage = p_value
	scaling_stats = args.scaling_stats
	accuracy = args.accuracy
	crit_chance = args.crit_chance
	crit_damage = args.crit_damage
	burning_data = args.burning_data
	is_healing = args.is_healing


func hit_something(thing_hit: Node, damage_dealt: int) -> void :
	emit_signal("hit_something", thing_hit, damage_dealt)

	if is_instance_valid(from) and "player_index" in from and damage_tracking_key != "":
		RunData.add_tracked_value(from.player_index, damage_tracking_key, damage_dealt)


func killed_something(thing_killed: Node) -> void :
	emit_signal("killed_something", thing_killed)


func critically_hit_something(thing_hit: Node, damage_dealt: int) -> void :
	emit_signal("critically_hit_something", thing_hit, damage_dealt)


func added_gold_on_crit(gold_added: int) -> void :
	emit_signal("added_gold_on_crit", gold_added)


func set_knockback(direction: Vector2, amount: float, piercing: float) -> void :
	knockback_direction = direction
	knockback_amount = amount
	knockback_piercing = piercing


func is_disabled() -> bool:
	return _collision.disabled


func enable() -> void :
	_collision.set_deferred("disabled", false)


func disable() -> void :
	_collision.set_deferred("disabled", true)
