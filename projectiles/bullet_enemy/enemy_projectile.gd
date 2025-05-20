class_name EnemyProjectile
extends Projectile


func _ready() -> void :
	shoot()


func shoot() -> void :
	.shoot()

	if not _sprite.material and ProgressData.settings.projectile_highlighting:
		_sprite.material = Utils.projectile_outline_shadermat
		_sprite.material.set_shader_param("texture_size", _sprite.texture.get_size())


func _on_Hitbox_hit_something(_thing_hit: Node, _damage_dealt: int) -> void :
	stop()
