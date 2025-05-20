class_name EnemyEffectBehavior
extends UnitEffectBehavior


func init(parent: Enemy) -> EnemyEffectBehavior:
	_parent = parent
	return self


func on_burned(_burning_data: BurningData, _from_player_index: int) -> void :
	pass


func get_bonus_damage(_hitbox: Hitbox, _from_player_index: int) -> int:
	return 0


func update_target() -> void :
	pass
