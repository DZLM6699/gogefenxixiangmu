class_name DifficultyScore
extends Reference

var difficulty_value: = - 1
var wave_number: = - 1
var enemy_health: = 1.0
var enemy_damage: = 1.0
var enemy_speed: = 1.0
var retries: = 0
var is_coop: = false


func _init(
	p_difficulty_value: int = - 1, 
	p_wave_number: int = - 1, 
	p_enemy_health: int = 1.0, 
	p_enemy_damage: int = 1.0, 
	p_enemy_speed: int = 1.0, 
	p_retries: int = 0, 
	p_is_coop: bool = false
) -> void :
	difficulty_value = p_difficulty_value
	wave_number = p_wave_number
	enemy_health = p_enemy_health
	enemy_damage = p_enemy_damage
	enemy_speed = p_enemy_speed
	retries = p_retries
	is_coop = p_is_coop


func set_info(
	p_difficulty_value: int, 
	p_wave_number: int, 
	p_enemy_health: float, 
	p_enemy_damage: float, 
	p_enemy_speed: float, 
	p_retries: int, 
	p_is_coop: bool = false, 
	is_endless: bool = false, 
	replace_only_if_above: bool = true
) -> void :

	if replace_only_if_above and not is_difficulty_above(p_difficulty_value, p_wave_number, p_enemy_health, p_enemy_damage, p_enemy_speed, p_retries, p_is_coop, is_endless):
		return

	if is_endless:
		RunData.max_endless_wave_record_beaten = RunData.current_wave

	difficulty_value = p_difficulty_value
	wave_number = p_wave_number
	enemy_health = p_enemy_health
	enemy_damage = p_enemy_damage
	enemy_speed = p_enemy_speed
	retries = p_retries
	is_coop = p_is_coop


func is_difficulty_above(
	new_difficulty_value: int, 
	new_wave_number: int, 
	new_enemy_health: float, 
	new_enemy_damage: float, 
	new_enemy_speed: float, 
	p_retries: int, 
	p_is_coop: bool, 
	is_endless: bool
) -> bool:

	var is_above = false
	var current_accesssibility = ((enemy_health + enemy_damage + enemy_speed) * 100) as int
	var new_accessibility = ((new_enemy_health + new_enemy_damage + new_enemy_speed) * 100) as int
	var diff_and_acc_are_same = new_difficulty_value == difficulty_value and new_accessibility == current_accesssibility
	var less_retries = p_retries < retries
	var changed_from_coop_to_single_player = p_is_coop == false and is_coop
	var diff_or_acc_is_higher = new_difficulty_value > difficulty_value or (new_difficulty_value == difficulty_value and new_accessibility > current_accesssibility)
	var same_diff_and_acc_but_wave_is_higher = (new_difficulty_value == difficulty_value and new_accessibility == current_accesssibility and new_wave_number > wave_number)

	if not is_endless:
		is_above = diff_or_acc_is_higher or (diff_and_acc_are_same and (less_retries or changed_from_coop_to_single_player))
	elif ProgressData.settings.endless_score_storing == EndlessScoreStoring.HIGHEST_WAVE:
		is_above = new_wave_number > wave_number or (new_wave_number == wave_number and diff_or_acc_is_higher)
	elif ProgressData.settings.endless_score_storing == EndlessScoreStoring.HIGHEST_DIFFICULTY:
		is_above = diff_or_acc_is_higher or same_diff_and_acc_but_wave_is_higher

	return is_above


func serialize() -> Dictionary:
	return {
		"difficulty_value": difficulty_value, 
		"wave_number": wave_number, 
		"enemy_health": enemy_health, 
		"enemy_damage": enemy_damage, 
		"enemy_speed": enemy_speed, 
		"retries": retries, 
		"is_coop": is_coop
	}


func deserialize_and_merge(from_json: Dictionary) -> void :
	difficulty_value = from_json.difficulty_value
	wave_number = from_json.wave_number
	enemy_health = from_json.enemy_health
	enemy_damage = from_json.enemy_damage
	enemy_speed = from_json.enemy_speed
	retries = from_json.retries if "retries" in from_json else 0
	is_coop = from_json.is_coop if "is_coop" in from_json else false
