
extends TempStats

var update_for_player_every_half_sec: = [false, false, false, false]
var update_for_player_on_gold_change: = [[], [], [], []]
var update_for_player_on_enemy_change: = [false, false, false, false]
var update_for_player_on_neutral_change: = [false, false, false, false]


func reset() -> void :
	for player_index in RunData.get_player_count():
		reset_player(player_index)


func reset_player(player_index: int) -> void :
	.reset_player(player_index)

	update_for_player_every_half_sec[player_index] = false
	update_for_player_on_gold_change[player_index].clear()
	update_for_player_on_enemy_change[player_index] = false
	update_for_player_on_neutral_change[player_index] = false

	var actual_nb_scaled_cache = {}

	var effects = RunData.get_player_effects(player_index)
	for linked_stat in effects["stat_links"]:
		var stat_to_tweak = linked_stat[0]
		var nb_stat_to_tweak = linked_stat[1]
		var stat_scaled = linked_stat[2]
		var nb_stat_scaled = linked_stat[3]
		var perm_stats_only = linked_stat[4]

		var actual_nb_scaled = 0.0
		actual_nb_scaled = actual_nb_scaled_cache.get(stat_scaled)
		if not actual_nb_scaled:
			if stat_scaled == "materials":
				actual_nb_scaled = RunData.get_player_gold(player_index)
				update_for_player_on_gold_change[player_index].append(linked_stat[3] as int)
			elif stat_scaled == "structure":
				actual_nb_scaled = RunData.get_nb_structures(player_index)
			elif stat_scaled == "burning_enemy":
				actual_nb_scaled = RunData.current_burning_enemies
				update_for_player_every_half_sec[player_index] = true
			elif stat_scaled == "living_enemy":
				actual_nb_scaled = RunData.current_living_enemies
				update_for_player_on_enemy_change[player_index] = true
			elif stat_scaled == "living_tree":
				actual_nb_scaled = RunData.current_living_trees
				update_for_player_on_neutral_change[player_index] = true
			elif stat_scaled == "percent_player_missing_health":
				var current_health = RunData.get_player_current_health(player_index)
				var max_health = RunData.get_player_max_health(player_index)
				actual_nb_scaled = WeaponService.apply_inverted_health_bonus(1, 1, current_health, max_health)
				update_for_player_every_half_sec[player_index] = true
			elif stat_scaled == "different_item":
				actual_nb_scaled = RunData.get_nb_different_items_of_tier( - 1, player_index)
			elif stat_scaled == "common_item":
				actual_nb_scaled = RunData.get_nb_different_items_of_tier(Tier.COMMON, player_index)
			elif stat_scaled == "legendary_item":
				actual_nb_scaled = RunData.get_nb_different_items_of_tier(Tier.LEGENDARY, player_index)
			elif stat_scaled == "duplicate_item":
				actual_nb_scaled = RunData.get_duplicate_items_count(player_index)
			elif stat_scaled.begins_with("item_"):
				actual_nb_scaled = RunData.get_nb_item(stat_scaled, player_index)
			elif stat_scaled == "free_weapon_slots":
				actual_nb_scaled = RunData.get_free_weapon_slots(player_index)
			else:
				if effects.has(stat_scaled):
					if perm_stats_only == true:
						actual_nb_scaled = RunData.get_stat(stat_scaled, player_index)
					else:
						actual_nb_scaled = RunData.get_stat(stat_scaled, player_index) + TempStats.get_stat(stat_scaled, player_index)
				else:
					continue
			actual_nb_scaled_cache[stat_scaled] = actual_nb_scaled

		var amount_to_add = int(floor(nb_stat_to_tweak * (actual_nb_scaled / nb_stat_scaled)))

		add_stat(stat_to_tweak, amount_to_add, player_index)


func should_update_on_gold_change(player_index: int, old_value: int, new_value: int) -> bool:
	for change in update_for_player_on_gold_change[player_index]:
		if new_value / change != old_value / change:
			return true
	return false
