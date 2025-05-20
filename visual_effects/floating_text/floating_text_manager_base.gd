class_name FloatingTextManagerBase
extends Node2D

export (PackedScene) var _floating_text

export (Array, Resource) var stat_pos_sounds: Array
export (Array, Resource) var stat_neg_sounds: Array
export (Array, Resource) var harvest_pos_sounds: Array
export (Array, Resource) var harvest_neg_sounds: Array
export  var direction: = Vector2(0, - 80)
export  var duration: = 0.5
export  var spread = PI / 4
export (Array, String) var ignored_stats: Array

const MAX_TEXTS = 100

var current_nb_of_texts: int = 0


func display_icon(value: int, icon: Resource, pos_sounds: Array, neg_sounds: Array, pos: Vector2, p_direction: Vector2 = direction, db_mod: float = 0.0) -> void :
	if value > 0:
		display("+" + str(value), pos, Utils.GOLD_COLOR, icon, duration * 2, false, p_direction, false)

		if pos_sounds.size() > 0:
			SoundManager.play(Utils.get_rand_element(pos_sounds), - 3 + db_mod, 0.2, true)
	else:
		display(str(value), pos, Color.red, icon, duration * 2, false, p_direction, false)

		if neg_sounds.size() > 0:
			SoundManager.play(Utils.get_rand_element(neg_sounds), - 8 + db_mod, 0.2, true)


func display(value: String, text_pos: Vector2, color: Color = Color.white, icon: Resource = null, p_duration: float = duration, always_display: bool = false, p_direction: Vector2 = direction, need_translate: bool = true, icon_scale: Vector2 = Vector2(0.5, 0.5)) -> void :
	if current_nb_of_texts > MAX_TEXTS and not always_display:
		return

	var floating_text: = get_floating_text()
	current_nb_of_texts += 1
	floating_text.rect_position = text_pos - floating_text.rect_size / 2

	floating_text.set_message_translation(need_translate)
	floating_text.display(value, p_direction, p_duration, spread, color, true)
	if icon:
		floating_text.set_icon(icon, icon_scale)


func get_floating_text() -> FloatingText:
	return create_floating_text()


func on_floating_text_available(_instance: FloatingText) -> void :
	current_nb_of_texts -= 1


func create_floating_text() -> FloatingText:
	var active_scene: Node = Utils.get_scene_node()
	var instance = _floating_text.instance()
	instance.hide()
	instance.connect("available", self, "on_floating_text_available")
	active_scene.add_floating_text(instance)
	return instance
