extends Node

const DIST_TO_EDGE_MAX_FACTOR: float = 0.2

export (Array, Resource) var zones = null
export (Array, Resource) var endless_groups
export (Array, Resource) var endless_unit_groups
export (Array, Resource) var extra_enemy_scenes

var current_zone: ZoneData
var current_zone_min_position: Vector2 = Vector2.ZERO
var current_zone_max_position: Vector2 = Vector2.ZERO


func get_zone_data(my_id: int) -> Resource:
	return zones[my_id]


func get_wave_data(my_id: int, index: int) -> Resource:
	var zone = zones[my_id].duplicate()
	var wave = 0

	if index > zone.waves_data.size():

		if not current_zone:
			current_zone = get_zone_data(RunData.current_zone)

		var wave_index = (index - 1) % zone.waves_data.size()

		if wave_index < 10:
			wave_index += 10

		wave = zone.waves_data[wave_index].duplicate()
		wave.max_enemies *= 1.25 + (wave_index * 0.01)
		wave.wave_duration = 60

		var nb = int((index / 10.0) * 2)
		var additional_groups = get_additional_groups(nb, 60, nb / 5.0)

		wave.groups_data.append_array(additional_groups)

	else:
		wave = zone.waves_data[index - 1].duplicate()

	for player_index in RunData.get_player_count():
		if RunData.get_player_effect_bool("upgraded_baits", player_index):
			var nb_baits = RunData.get_nb_item("item_bait", player_index)
			if nb_baits > 0:
				var nb_additional_groups: = max(1, (nb_baits / 10.0) as int) as int
				var wave_duration: = 60
				var bonus_enemies_per_group: = max(0, (nb_baits / 15.0) as int) as int
				var min_spawn_timing: = 15
				var additional_groups = get_additional_groups(nb_additional_groups, wave_duration, bonus_enemies_per_group, extra_enemy_scenes, min_spawn_timing)
				wave.groups_data.append_array(additional_groups)

	return wave


func get_additional_groups(nb_additional_groups: int, wave_duration: int = 60, bonus_enemies_per_group: int = 1, enemy_scenes: Array = current_zone.endless_enemy_scenes, min_spawn_timing: int = 0) -> Array:
	var groups = []

	for i in nb_additional_groups:
		var group_to_add = Utils.get_rand_element(endless_groups).duplicate()

		group_to_add.spawn_timing = max(min_spawn_timing, ((i * ((wave_duration - 10.0) / nb_additional_groups)) + 1.0)) as int

		var spawn_edge_of_map_rand = randf()
		var area_rand = randf()

		group_to_add.spawn_edge_of_map = spawn_edge_of_map_rand > 0.5
		group_to_add.area = - 1 if area_rand > 0.5 else int(rand_range(200, 300))
		group_to_add.repeating_interval = int(round(rand_range(6, 8)))

		var unit_group = Utils.get_rand_element(endless_unit_groups).duplicate()

		unit_group.unit_scene = Utils.get_rand_element(enemy_scenes)
		unit_group.min_number = int(1 + bonus_enemies_per_group)
		unit_group.max_number = int(round(rand_range(unit_group.min_number, unit_group.min_number + 1)) + bonus_enemies_per_group)

		group_to_add.wave_units_data.push_back(unit_group)
		groups.push_back(group_to_add)


	return groups


func get_rand_pos(edge: int = Utils.EDGE_MAP_DIST) -> Vector2:
	edge = _limit_dist_to_edge(edge)

	var min_x = min((current_zone_min_position.x) + edge, (current_zone_max_position.x / 2) - 1)
	var max_x = max((current_zone_max_position.x) - edge, (current_zone_max_position.x / 2) + 1)
	var min_y = min((current_zone_min_position.y) + edge, (current_zone_max_position.y / 2) - 1)
	var max_y = max((current_zone_max_position.y) - edge, (current_zone_max_position.y / 2) + 1)
	return Vector2(rand_range(min_x, max_x), rand_range(min_y, max_y))


func get_rand_pos_in_area_around_center(area: int) -> Vector2:
	var pos = get_map_center()
	return get_rand_pos_in_area(pos, area)


func get_map_center() -> Vector2:
	return Vector2(current_zone_max_position.x / 2.0, current_zone_max_position.y / 2.0)


func get_rand_pos_in_area(base_pos: Vector2, area: float, edge: int = Utils.EDGE_MAP_DIST) -> Vector2:
	edge = _limit_dist_to_edge(edge)

	var min_x = current_zone_min_position.x + edge + area / 2
	var max_x = current_zone_max_position.x - edge - area / 2
	var min_y = current_zone_min_position.y + edge + area / 2
	var max_y = current_zone_max_position.y - edge - area / 2
	var pos = Vector2(clamp(base_pos.x, min_x, max_x), clamp(base_pos.y, min_y, max_y))
	return Vector2(rand_range(pos.x - area / 2, pos.x + area / 2), rand_range(pos.y - area / 2, pos.y + area / 2))


func _limit_dist_to_edge(edge: int) -> int:
	var rect = get_current_zone_rect()
	var smaller_side: = min(rect.size.x, rect.size.y)
	if edge / smaller_side > DIST_TO_EDGE_MAX_FACTOR:
		return int(smaller_side * DIST_TO_EDGE_MAX_FACTOR)
	return edge


func get_current_zone_rect() -> Rect2:
	var position: = current_zone_min_position
	var size: = current_zone_max_position - current_zone_min_position
	return Rect2(position, size)


func reset() -> void :
	current_zone_min_position = Vector2.ZERO
	current_zone_max_position = Vector2.ZERO
