class_name PercentDamageTakenEnemyEffectBehavior
extends EnemyEffectBehavior

var _current_stacks: int = 0
var _percent_damage_taken: int = 0

var _active_effects: Array = []
var _effects_proc_count: Dictionary = {}


class ActiveEffect:
	var duration_secs: float = 0.0
	var timer: float = 0.0
	var source_id: String = ""
	var current_stacks: int = 1
	var max_stacks: int = 1
	var total_percent_damage_added: int = 0
	var percent_damage: int = 0
	var outline_color: Color


func _process(delta):
	for active_effect in _active_effects:
		active_effect.timer -= delta
		if active_effect.timer <= 0.0:
			on_active_effect_timer_timed_out(active_effect)


func should_add_on_spawn() -> bool:
	for player_index in RunData.get_player_count():
		if RunData.get_player_effect("enemy_percent_damage_taken", player_index).size() > 0:
			return true

	if RunData.existing_weapon_has_effect("enemy_percent_damage_taken"):
		return true

	return false


func on_hurt(hitbox: Hitbox) -> void :
	var from = hitbox.from

	if (is_instance_valid(from) and not "player_index" in from) or not is_instance_valid(from):
		return

	var from_player_index = from.player_index
	var effects = []
	var item_effects = RunData.get_player_effect("enemy_percent_damage_taken", from_player_index)

	effects.append_array(item_effects)

	for effect in hitbox.effects:
		if effect.custom_key == "enemy_percent_damage_taken":
			effects.push_back(effect.to_array())

	try_add_effects(effects, hitbox.scaling_stats)


func on_burned(burning_data: BurningData, from_player_index: int) -> void :
	var effects = RunData.get_player_effect("enemy_percent_damage_taken", from_player_index)
	try_add_effects(effects, burning_data.scaling_stats)


func try_add_effects(effects: Array, scaling_stats: Array) -> void :
	for effect in effects:
		if WeaponService.find_scaling_stat(effect[1], scaling_stats) or effect[1] == "stat_all":
			add_active_effect(effect)


func add_active_effect(from_percent_damage_effect: Array) -> void :

	var source_id = from_percent_damage_effect[0]
	var percent_damage = from_percent_damage_effect[2]
	var duration = from_percent_damage_effect[3]
	var max_stacks = from_percent_damage_effect[4]
	var max_procs = from_percent_damage_effect[5]
	var outline_color = from_percent_damage_effect[6]

	if max_procs != - 1 and _effects_proc_count.has(source_id) and _effects_proc_count[source_id] >= max_procs:
		return

	var already_exists: bool = false
	var active_effect: ActiveEffect = null

	for existing_active_effect in _active_effects:
		if existing_active_effect.source_id == source_id:
			already_exists = true
			active_effect = existing_active_effect
			break

	if already_exists:
		active_effect.max_stacks = max(active_effect.max_stacks, max_stacks) as int
		active_effect.duration_secs = max(active_effect.duration_secs, duration)
		active_effect.percent_damage = max(active_effect.percent_damage, percent_damage) as int
		active_effect.timer = active_effect.duration_secs

		if active_effect.current_stacks >= active_effect.max_stacks:
			return

		active_effect.current_stacks += 1
		_percent_damage_taken += active_effect.percent_damage
		active_effect.total_percent_damage_added += active_effect.percent_damage
		_effects_proc_count[source_id] += 1
	else:
		active_effect = ActiveEffect.new()

		active_effect.source_id = source_id
		active_effect.timer = duration
		active_effect.duration_secs = duration
		active_effect.max_stacks = max_stacks
		active_effect.outline_color = Color(outline_color)
		active_effect.percent_damage = percent_damage

		_active_effects.push_back(active_effect)

		if not _parent.has_outline(active_effect.outline_color):
			_parent.add_outline(active_effect.outline_color, 1.0, 0.0)

		_percent_damage_taken += active_effect.percent_damage
		active_effect.total_percent_damage_added += active_effect.percent_damage
		_effects_proc_count[source_id] = 1


func on_active_effect_timer_timed_out(active_effect: ActiveEffect):
	_percent_damage_taken -= active_effect.total_percent_damage_added

	for i in _active_effects.size():
		if _active_effects[i].source_id == active_effect.source_id:
			_active_effects.remove(i)
			break

	var remove_outline = true

	for remaining_active_effect in _active_effects:
		if remaining_active_effect.outline_color == active_effect.outline_color:
			remove_outline = false
			break

	if remove_outline:
		_parent.remove_outline(active_effect.outline_color)


func get_bonus_damage(_hitbox: Hitbox, _from_player_index: int) -> int:
	return _percent_damage_taken
