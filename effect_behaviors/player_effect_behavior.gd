class_name PlayerEffectBehavior
extends UnitEffectBehavior

var _player_index: int = - 1


func init(parent: Player) -> PlayerEffectBehavior:
	_parent = parent
	_player_index = _parent.player_index
	return self


func on_moved(_delta_position: Vector2) -> void :
	pass
