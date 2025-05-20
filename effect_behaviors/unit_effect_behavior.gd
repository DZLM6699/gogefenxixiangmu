class_name UnitEffectBehavior
extends Node2D

var _parent: Unit = null


func should_add_on_spawn() -> bool:
	return false


func get_gold_value_modifier() -> float:
	return 0.0


func on_hurt(_hitbox: Hitbox) -> void :
	pass


func on_taken_damage(_args: TakeDamageArgs) -> int:
	return HitType.NORMAL


func on_death(_die_args: Entity.DieArgs) -> void :
	pass
