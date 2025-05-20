class_name TakeDamageArgs
extends Reference

var from_player_index: int setget _set_from_player_index, _get_from_player_index
func _get_from_player_index() -> int:
	return from_player_index
func _set_from_player_index(_v: int) -> void :
	printerr("from_player_index is readonly")

var hitbox: Hitbox setget _set_hitbox, _get_hitbox
func _get_hitbox() -> Hitbox:
	return hitbox
func _set_hitbox(_v: Hitbox) -> void :
	printerr("hitbox is readonly")

var dodgeable: bool = true
var armor_applied: bool = true
var custom_sound: Resource = null
var base_effect_scale: float = 1.0
var bypass_invincibility: bool = false
var is_burning: bool = false


func _init(_from_player_index: int, _hitbox: Hitbox = null) -> void :
	from_player_index = _from_player_index
	hitbox = _hitbox


func get_effect_scale() -> float:
	return hitbox.effect_scale if hitbox else base_effect_scale
