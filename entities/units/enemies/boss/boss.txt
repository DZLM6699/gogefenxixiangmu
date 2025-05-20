class_name Boss
extends Enemy

export (bool) var is_elite: = true

var change_state_sound = load("res://entities/units/enemies/boss/zombie_voice_general_emote_05.wav")

var _states: = []
var _current_state: = - 1
var elapsed_time = 0

onready var _states_container = $States
onready var life_bar: TextureProgress = $LifeBar
onready var _check_state_timer: Timer = $"%CheckStateTimer"


func init(zone_min_pos: Vector2, zone_max_pos: Vector2, players_ref: Array = [], entity_spawner_ref = null) -> void :
	.init(zone_min_pos, zone_max_pos, players_ref, entity_spawner_ref)

	for state in _states_container.get_children():
		state.movement_behavior.init(self)
		state.attack_behavior.init(self)
		_states.push_back([state.hp_start, state.timer_start, state.movement_behavior, state.attack_behavior])
		register_attack_behavior(state.attack_behavior)

	if not ProgressData.settings.hp_bar_on_bosses:
		life_bar.hide()

	var _error_hp_lifebar = connect("health_updated", self, "on_health_updated")

	if RunData.sum_all_player_effects("stronger_elites_on_kill") > 0:
		var factor = RunData.sum_all_player_effects("stronger_elites_on_kill")
		var nb_of_elites_and_bosses_killed = RunData.elites_killed_this_run.size() + RunData.bosses_killed_this_run.size()
		var bonus_health = factor * nb_of_elites_and_bosses_killed
		var bonus_damage = (factor * nb_of_elites_and_bosses_killed) / 2.0
		reset_health_stat(bonus_health)
		reset_damage_stat(bonus_damage)

	if RunData.current_wave <= 8:
		max_stats.health = round(max_stats.health * 0.5) as int
		current_stats.health = max_stats.health
	elif (RunData.sum_all_player_effects("double_boss") > 0 and RunData.current_wave == RunData.nb_of_waves) or RunData.current_wave <= 12:
		max_stats.health = round(max_stats.health * 0.75) as int
		current_stats.health = max_stats.health
	elif RunData.current_wave == RunData.nb_of_waves and RunData.current_difficulty <= 0 and RunData.current_zone != 0:
		max_stats.health = round(max_stats.health * 0.9) as int
		current_stats.health = max_stats.health


func respawn() -> void :
	assert (false, "Bosses can't be respawned")


func take_damage(value: int, args: TakeDamageArgs) -> Array:
	var from_player_index = args.from_player_index

	var dmg_value = value
	var damage_against_bosses = RunData.get_player_effect("damage_against_bosses", from_player_index)
	if damage_against_bosses > 0:
		dmg_value = int(value * (1.0 + (Utils.get_stat("damage_against_bosses", from_player_index) / 100.0)))

	return .take_damage(dmg_value, args)


func _get_health_effect_percent_factor() -> float:
	return 1000.0


func die(args: = Entity.DieArgs.new()) -> void :
	.die(args)
	life_bar.hide()
	_check_state_timer.stop()

	if not args.cleaning_up:
		if elapsed_time <= ChallengeService.get_chal("chal_giant_slayer").value:
			ChallengeService.complete_challenge("chal_giant_slayer")

		if is_elite:
			RunData.elites_killed_this_run.push_back(enemy_id)
		else:
			RunData.bosses_killed_this_run.push_back(enemy_id)


func death_animation_finished() -> void :
	
	queue_free()


func _on_CheckStateTimer_timeout() -> void :
	elapsed_time += 1
	for i in _states.size():
		if _current_state < i and (current_stats.health <= (max_stats.health * _states[i][0]) or elapsed_time >= _states[i][1]):
			SoundManager.play(change_state_sound, 0, 0, true)
			_current_state = i
			_current_movement_behavior = _states[i][2]
			_current_attack_behavior = _states[i][3]
			on_state_changed(i)


func on_state_changed(_new_state: int) -> void :
	_can_move = true
	emit_signal("state_changed", self)


func on_health_updated(_unit: Unit, current_val: int, max_val: int) -> void :
	if ProgressData.settings.hp_bar_on_bosses:
		if not life_bar.visible:
			life_bar.show()

		life_bar.update_value(current_val, max_val)
	elif life_bar.visible:
		life_bar.hide()
