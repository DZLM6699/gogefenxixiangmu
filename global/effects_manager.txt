
class_name EffectsManager
extends Node2D

export (PackedScene) var heal_particles
export (PackedScene) var stats_boost_particles
export (PackedScene) var speed_removed_particles
export (PackedScene) var hit_particles
export (PackedScene) var hit_effect
export (PackedScene) var gold_pickup_particles

const MAX_GRAPHICAL_EFFECTS = 100
var current_graphical_effects: int = 0

var _cleaning_up: bool = false
var _main: Main


func _ready() -> void :
	_main = Utils.get_scene_node()


func on_enemy_healed(unit: Unit) -> void :
	play_boost_particles(unit.global_position, heal_particles)


func on_unit_stats_boost(unit: Unit) -> void :
	play_boost_particles(unit.global_position, stats_boost_particles)


func on_enemy_speed_removed(unit: Unit) -> void :
	play_boost_particles(unit.global_position, speed_removed_particles)


func on_gold_picked_up(gold: Gold, _player_index: int) -> void :
	if not _cleaning_up:
		play_gold_pickup_effect(gold.global_position)


func _on_unit_took_damage(unit: Unit, value: int, knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int) -> void :
	if value <= 0 or not ProgressData.settings.visual_effects:
		return
	var effect_distance: float = Utils.get_effect_distance(unit)
	var effect_scale = args.get_effect_scale()
	play_hit_particles(unit.global_position + (knockback_direction * effect_distance), knockback_direction, effect_scale)
	play_hit_effect(unit.global_position + (knockback_direction * effect_distance), knockback_direction, effect_scale)


func play_boost_particles(pos: Vector2, boost_particles: PackedScene) -> void :
	if boost_particles != null:
		play(boost_particles, pos, Vector2.ZERO)


func play_hit_particles(effect_pos: Vector2, direction: Vector2, effect_scale: float) -> void :
	if hit_particles != null:
		play(hit_particles, effect_pos, direction, effect_scale)


func play_gold_pickup_effect(effect_pos: Vector2) -> void :
	if gold_pickup_particles != null:
		play(gold_pickup_particles, effect_pos, Vector2.ZERO)


func play_hit_effect(effect_pos: Vector2, _direction: Vector2, effect_scale: float) -> void :
	if hit_effect != null and randf() < effect_scale:
		play(hit_effect, effect_pos, Vector2(rand_range( - 1, 1), rand_range( - 1, 1)), effect_scale)


func play(scene: PackedScene, effect_pos: Vector2, direction: Vector2, effect_scale: float = 1.0) -> void :
	if effect_scale <= 0 or current_graphical_effects > MAX_GRAPHICAL_EFFECTS:
		return

	var instance = _main.get_node_from_pool(scene.resource_path)
	if instance == null:
		instance = scene.instance()
		_main.add_effect(instance)
		var _destroyed_connect = instance.connect("finished", self, "on_graphical_effect_finished")

	current_graphical_effects += 1

	if instance is CPUParticles2D:
		instance.amount = max(1, instance.amount * effect_scale)
		instance.restart()

	if instance is AnimatedSprite:
		instance.play()

	instance.global_position = effect_pos
	instance.rotation = direction.angle() - PI


func on_graphical_effect_finished(object: Object) -> void :
	current_graphical_effects -= 1
	_main.add_node_to_pool(object)


func clean_up_room() -> void :
	_cleaning_up = true
