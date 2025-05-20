class_name WaveManager
extends Node2D

signal group_spawn_timing_reached(group_data)

enum {DATA, REPEATING, REPEATING_INTERVAL, REDUCE_REPEATING_INTERVAL, MIN_REPEATING_INTERVAL, NEXT_REPEAT}

export (Array, Resource) var debug_groups
export (Resource) var elite_group

var wave_timer: Timer
var current_zone_data: Resource
var current_wave_data: Resource

var _groups_to_remove: = []
var _groups_to_repeat: = []
var _repeat_groups_to_remove: = []
var _last_time_checked: = 0

var _is_elite_wave: = false
var _elite_spawn_data: = []


func init(p_wave_timer: Timer, zone_data: ZoneData, wave_data: Resource) -> void :
	wave_timer = p_wave_timer
	current_zone_data = zone_data
	current_wave_data = wave_data

	if DebugService.no_enemies:
		current_wave_data.groups_data = []

	if DebugService.spawn_debug_enemies:
		current_wave_data.groups_data.append_array(debug_groups)
		debug_groups[0].wave_units_data = DebugService.debug_enemies

	for group_data in zone_data.groups_data_in_all_waves:
		var group_data_to_add = group_data.duplicate()

		if group_data_to_add.is_loot and group_data_to_add.wave_units_data.size() > 0:
			var new_loot_unit_data = group_data_to_add.wave_units_data[0].duplicate()
			var total_chance_change: float = RunData.sum_all_player_effects("loot_alien_chance") / 100.0
			new_loot_unit_data.spawn_chance = min(1.0, new_loot_unit_data.spawn_chance * (1.0 + total_chance_change))
			group_data_to_add.wave_units_data[0] = new_loot_unit_data

		current_wave_data.groups_data.push_back(group_data_to_add)

	for player_index in RunData.get_player_count():
		var effects = RunData.get_player_effects(player_index)

		var extra_loot_alien_groups = effects["extra_loot_aliens_next_wave"] + effects["extra_loot_aliens"]

		for i in extra_loot_alien_groups:
			for group in zone_data.loot_alien_groups:
				var new_group = group.duplicate()
				new_group.spawn_timing = rand_range(5, wave_timer.time_left - 10)
				current_wave_data.groups_data.push_back(new_group)
		effects["extra_loot_aliens_next_wave"] = 0

	var groups_to_add = []

	for group_data in wave_data.groups_data:
		if group_data.is_boss:
			var units_data = []
			
			if RunData.current_wave == RunData.nb_of_waves:
				if DebugService.spawn_specific_boss:
					var wave_unit_data = create_boss_wave_unit_data(DebugService.spawn_specific_boss)
					units_data.push_back(wave_unit_data)
				else:
					for boss_id in RunData.bosses_spawn:
						var wave_unit_data = create_boss_wave_unit_data(boss_id)
						units_data.push_back(wave_unit_data)
			
			elif RunData.current_wave > RunData.nb_of_waves:
				var local_elite_group = init_elite_group()
				groups_to_add.push_back(local_elite_group)

				for boss_id in RunData.get_bosses_to_spawn(true):
					var wave_unit_data = create_boss_wave_unit_data(boss_id)
					units_data.push_back(wave_unit_data)

			group_data.wave_units_data = units_data

	
	for player_index in RunData.get_player_count():
		var effects = RunData.get_player_effects(player_index)
		for effect in effects["extra_enemies_next_wave"]:
			var group_data = load(effect[0])
			var group_count = effect[1]
			for _i in range(group_count):
				var new_group = group_data
				if group_data.is_boss:
					new_group = init_elite_group([effect[2]])
				groups_to_add.push_back(new_group)
		effects["extra_enemies_next_wave"] = []

	for group_array in wave_data.conditional_groups_data:
		groups_to_add.push_back(Utils.get_rand_element(group_array))

	if RunData.elites_spawn.size() > 0 and DebugService.spawn_specific_elite == "":
		for elite_spawn in RunData.elites_spawn:
			if RunData.current_wave == (elite_spawn[0] as int):
				_is_elite_wave = true
				_elite_spawn_data = elite_spawn

				if elite_spawn[1] == EliteType.ELITE:
					var local_elite_group = init_elite_group([elite_spawn[2]])
					groups_to_add.push_back(local_elite_group)
				elif elite_spawn[1] == EliteType.HORDE:
					for group_data in zone_data.horde_groups:
						if RunData.current_wave >= group_data.min_wave and RunData.current_wave <= group_data.max_wave:
							groups_to_add.push_back(group_data)
				break
	elif DebugService.spawn_specific_elite != "":
		var local_elite_group = init_elite_group([DebugService.spawn_specific_elite])
		groups_to_add.push_back(local_elite_group)

	for dlc_data in ProgressData.available_dlcs:
		if RunData.enabled_dlcs.has(dlc_data.my_id):
			for group_in_all_zones in dlc_data.groups_in_all_zones:
				groups_to_add.push_back(group_in_all_zones)

	for group_to_add in groups_to_add:
		current_wave_data.groups_data.push_back(group_to_add)


func create_boss_wave_unit_data(boss_id: String) -> WaveUnitData:
	var wave_unit_data = WaveUnitData.new()
	var boss = ItemService.get_element(ItemService.bosses, boss_id)
	wave_unit_data.type = EntityType.BOSS
	wave_unit_data.unit_scene = boss.scene
	return wave_unit_data


func _physics_process(_delta: float) -> void :
	if wave_timer == null or current_wave_data == null:
		return

	if wave_timer.time_left as int != _last_time_checked:
		_last_time_checked = wave_timer.time_left as int

		for group_data in current_wave_data.groups_data:
			var spawn_start_wave = group_data.is_boss or (group_data.is_neutral and RunData.sum_all_player_effects("trees_start_wave") > 0 and wave_timer.time_left >= wave_timer.wait_time - 5)
			var wave_time_elapsed: = wave_timer.wait_time - wave_timer.time_left
			if RunData.current_difficulty >= group_data.min_difficulty and (group_data.spawn_timing <= wave_time_elapsed or spawn_start_wave):
				if Utils.get_chance_success(group_data.spawn_chance):
					emit_signal("group_spawn_timing_reached", group_data)

				if group_data.repeating > 0:
					add_group_to_repeat(group_data)

				_groups_to_remove.push_back(group_data)

		if _groups_to_repeat.size() > 0:
			for group in _groups_to_repeat:
				if wave_timer.time_left <= group[NEXT_REPEAT]:
					emit_and_update_repeat_group(group)

		remove_groups()
		remove_repeat_groups()


func init_elite_group(elites_to_spawn: Array = [], add_endless_elites: bool = true) -> WaveGroupData:
	var local_elite_group = elite_group.duplicate()

	if add_endless_elites:
		elites_to_spawn.append_array(RunData.get_additional_elites_endless())

	for elite_to_spawn in elites_to_spawn:
		for elite in ItemService.elites:
			if elite_to_spawn == elite.my_id:
				var unit = WaveUnitData.new()
				unit.type = EntityType.BOSS
				unit.unit_scene = elite.scene
				local_elite_group.wave_units_data.push_back(unit)

	return local_elite_group


func add_group_to_repeat(group_data: WaveGroupData) -> void :
	var next_spawn_timing = wave_timer.wait_time - group_data.spawn_timing - group_data.repeating_interval
	_groups_to_repeat.push_back(
		[
			group_data, 
			group_data.repeating, 
			group_data.repeating_interval, 
			group_data.reduce_repeating_interval, 
			group_data.min_repeating_interval, 
			next_spawn_timing
		]
	)


func emit_and_update_repeat_group(group: Array) -> void :
	emit_signal("group_spawn_timing_reached", group[DATA])
	group[REPEATING] -= 1

	if group[REPEATING] <= 0:
		_repeat_groups_to_remove.push_back(group)

	group[REPEATING_INTERVAL] = max(group[MIN_REPEATING_INTERVAL], group[REPEATING_INTERVAL] - group[REDUCE_REPEATING_INTERVAL])
	group[NEXT_REPEAT] -= group[REPEATING_INTERVAL]


func add_groups(groups: Array) -> void :
	current_wave_data.groups_data.append_array(groups)


func remove_groups() -> void :
	if _groups_to_remove.size() > 0:
		for group_to_remove in _groups_to_remove:
			current_wave_data.groups_data.erase(group_to_remove)

		_groups_to_remove.clear()


func remove_repeat_groups() -> void :
	if _repeat_groups_to_remove.size() > 0:
		for group_to_remove in _repeat_groups_to_remove:
			_groups_to_repeat.erase(group_to_remove)

		_repeat_groups_to_remove.clear()


func clean_up_room() -> void :
	set_physics_process(false)
	_groups_to_remove.clear()
	_groups_to_repeat.clear()
	_repeat_groups_to_remove.clear()
