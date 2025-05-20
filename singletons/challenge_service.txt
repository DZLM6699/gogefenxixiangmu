extends Node

signal challenge_completed(challenge)

export (Array, Resource) var challenges

var stat_challenges: = []
var _challenges_completed_map: = {}


func _ready() -> void :
	if DebugService.reinitialize_store_data == false:
		_sync_platform_challenges()
	set_stat_challenges()


func _sync_platform_challenges() -> void :
	for challenge in challenges:
		if is_challenge_completed(challenge.my_id):
			if challenge.description == "CHAL_CHARACTER_DESC":
				_sync_character_challenge(challenge)
				continue

			Platform.complete_challenge(challenge.my_id)


func _sync_character_challenge(challenge: ChallengeData) -> void :
	var char_id = challenge.my_id.replace("chal_", "character_")
	for zone_id in [0, 1]:
		var diff_info = ProgressData.get_character_difficulty_info(char_id, zone_id)
		var diff_score = diff_info.max_difficulty_beaten
		if diff_score.difficulty_value >= 0:
			if Platform.get_type() == PlatformType.STEAM:
				if zone_id == 0:
					Platform.complete_challenge(challenge.my_id)
				elif zone_id == 1:
					Platform.complete_challenge(challenge.my_id + "_abyss")
			else:
				Platform.complete_challenge(challenge.my_id)


func set_stat_challenges() -> void :
	stat_challenges = []
	for chal in challenges:
		if chal.stat != "" and should_add_stat_challenge(chal.my_id):
			stat_challenges.push_back(chal)


func should_add_stat_challenge(chal_id: String) -> bool:
	if is_challenge_completed(chal_id):
		return false

	return (
		chal_id != "chal_advanced_technology"
		and chal_id != "chal_magic_and_machinery"
		and chal_id != "chal_uncorrupted"
	)


func try_complete_challenge(chal_id: String, value: int, check_below: bool = false):
	var chal_data: = get_chal(chal_id)
	if chal_data == null:
		return
	if ( not check_below and value >= chal_data.value) or (check_below and value <= chal_data.value):
		complete_challenge(chal_id)


func complete_challenge(chal_id: String, also_complete_platform_challenge: bool = true) -> void :
	if is_challenge_completed(chal_id):
		return

	var chal_data = get_chal(chal_id)
	if chal_data == null:
		print("challenge data not found for my_id " + str(chal_id))
		return

	ProgressData.challenges_completed.append(chal_id)
	_challenges_completed_map[chal_id] = true
	unlock_reward(chal_data)
	ProgressData.save()

	if also_complete_platform_challenge:
		Platform.complete_challenge(chal_id)

	emit_signal("challenge_completed", chal_data)


func is_challenge_completed(chal_id: String) -> bool:
	update_challenges_completed_map()
	return _challenges_completed_map.has(chal_id)


func update_challenges_completed_map() -> void :
	if _challenges_completed_map.size() == ProgressData.challenges_completed.size():
		return

	_challenges_completed_map.clear()
	for id in ProgressData.challenges_completed:
		_challenges_completed_map[id] = true


func unlock_reward(chal_data: ChallengeData) -> void :
	if not chal_data.reward:
		return

	var list_to_unlock_from: = []
	var list_of_unlocked: = []

	var id_property = "my_id"

	match chal_data.reward_type:
		RewardType.CHARACTER:
			list_to_unlock_from = ItemService.characters
			list_of_unlocked = ProgressData.characters_unlocked
		RewardType.ITEM:
			list_to_unlock_from = ItemService.items
			list_of_unlocked = ProgressData.items_unlocked
		RewardType.WEAPON:
			list_to_unlock_from = ItemService.weapons
			list_of_unlocked = ProgressData.weapons_unlocked
			id_property = "weapon_id"
		RewardType.ZONE:
			list_to_unlock_from = ZoneService.zones
			list_of_unlocked = ProgressData.zones_unlocked
		RewardType.STARTING_WEAPON:
			list_to_unlock_from = ItemService.weapons
			list_of_unlocked = ProgressData.weapons_unlocked
			id_property = "weapon_id"
		RewardType.CONSUMABLE:
			list_to_unlock_from = ItemService.consumables
			list_of_unlocked = ProgressData.consumables_unlocked
		RewardType.UPGRADE:
			list_to_unlock_from = ItemService.upgrades
			list_of_unlocked = ProgressData.upgrades_unlocked
			id_property = "upgrade_id"

	for element in list_to_unlock_from:
		if element[id_property] == chal_data.reward[id_property]:
			if not list_of_unlocked.has(chal_data.reward[id_property]):
				list_of_unlocked.push_back(chal_data.reward[id_property])
				RunData.challenges_completed_this_run.push_back(chal_data)
				break


func find_challenge_from_reward(reward_type: int, reward_data: Resource) -> ChallengeData:
	var challenge_result = null

	for challenge in challenges:
		if challenge.reward_type != reward_type:
			continue

		if challenge.reward.my_id == reward_data.my_id:
			challenge_result = challenge
			break

	return challenge_result


var _challenge_map: = {}

func get_chal(my_id: String) -> ChallengeData:
	if _challenge_map.size() != challenges.size():
		_challenge_map.clear()
		for chal in challenges:
			_challenge_map[chal.my_id] = chal
	return _challenge_map.get(my_id)


func check_counted_challenges() -> void :
	var nb_killed = ProgressData.data.enemies_killed
	var nb_collected = ProgressData.data.materials_collected
	var nb_trees = ProgressData.data.trees_killed
	var nb_killed_far_away = ProgressData.data.enemies_killed_far_away

	for chal in challenges:
		if ((chal.name == "CHAL_SURVIVOR" and nb_killed >= chal.value)
			or (chal.name == "CHAL_GATHERER" and nb_collected >= chal.value)
			or (chal.name == "CHAL_LUMBERJACK" and nb_trees >= chal.value)
			or (chal.name == "CHAL_CAUTIOUS" and nb_killed_far_away >= chal.value)):
			complete_challenge(chal.my_id)


func check_stat_challenges(player_index: int) -> void :
	for chal in stat_challenges:
		var reached_goal = (
			(chal.value < 0 and Utils.get_stat(chal.stat, player_index) <= chal.value)
			or (chal.value > 0 and Utils.get_stat(chal.stat, player_index) >= chal.value)
			or (chal.value == 0 and Utils.get_stat(chal.stat, player_index) == chal.value)
		)
		if reached_goal:
			complete_challenge(chal.my_id)

	_check_struct_challenges(player_index, "chal_advanced_technology", "stat_ranged_damage")
	_check_struct_challenges(player_index, "chal_magic_and_machinery", "stat_elemental_damage")


func _check_struct_challenges(player_index: int, chal_id: String, stat: String):
	if is_challenge_completed(chal_id):
		return

	var chal = get_chal(chal_id)
	if Utils.get_stat(stat, player_index) >= chal.value and RunData.get_player_effect("structures", player_index).size() >= chal.additional_args[0]:
		complete_challenge(chal_id)


func complete_all_challenges() -> void :
	for chal in challenges:
		complete_challenge(chal.my_id)
