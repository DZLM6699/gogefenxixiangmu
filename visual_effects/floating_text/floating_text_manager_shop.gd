class_name FloatingTextManagerShop
extends FloatingTextManagerBase

export (Resource) var caught_sound


func stat_added(stat: String, value: int, db_mod: float, position: Vector2, pos_sounds: Array = stat_pos_sounds, neg_sounds: Array = stat_neg_sounds) -> void :
	display_icon(value, ItemService.get_stat_icon(stat), pos_sounds, neg_sounds, position, direction, db_mod)


func display_shop_icon(icon: Resource, pos: Vector2, p_direction: Vector2) -> void :
	display("", pos, Color.white, icon, duration * 2, true, p_direction, false, Vector2.ONE)
	SoundManager.play(caught_sound, - 2, 0.2, true)
