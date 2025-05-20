extends DelayedPlayerProjectile


onready var slow_hitbox: Area2D = $"%SlowHitbox"


func shoot() -> void :
	slow_hitbox.enable()
	.shoot()


func _return_to_pool() -> void :
	slow_hitbox.disable()
	._return_to_pool()


func _on_SlowHitbox_hit_something(thing_hit: Node, _damage_dealt: int) -> void :
	thing_hit.add_decaying_speed( - 200)
