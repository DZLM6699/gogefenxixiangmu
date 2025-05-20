class_name EntitySpawner
extends Node2D

signal enemy_number_updated(nb_of_enemies, nb_of_births)
signal players_spawned(players)
signal enemy_spawned(enemy)
signal enemy_respawned(enemy)
signal neutral_spawned(neutral)
signal neutral_respawned(neutral)
signal structure_spawned(structure)

export (PackedScene) var player_scene
export (PackedScene) var entity_birth_scene

const MAX_STRUCTURES = 100
const INITIAL_MIN_DIST_FROM_PLAYER = 300
const SPAWN_DELAY = 3
const QUEUE_LIMIT = 100

var cur_spawn_delay: = 0

var _cleaning_up = false

var active_births: = 0
var enemies: = []
var bosses: = []
var neutrals: = []
var structures: = []
var structures_to_remove_in_priority: = []
var queue_to_spawn: = []
var queue_to_spawn_trees: = []
var queue_to_spawn_summons: = []
var queue_to_spawn_bosses: = []
var queues_to_spawn_structures: = [[], [], [], []]
var enemies_removed_for_perf = 0
var enemies_to_remove_in_priority: = []
var charmed_enemies: = []

var _base_structures_spawned = false

var _players: = []
var _zone_min_pos: Vector2
var _zone_max_pos: Vector2
var _current_wave_data: WaveData
var _wave_timer: Timer

var _possible_edge_spawns: = [Direction.TOP, Direction.LEFT, Direction.BOTTOM, Direction.RIGHT]

var _main

onready var _structure_timer = $StructureTimer


func init(
		zone_min_pos: Vector2, 
		zone_max_pos: Vector2, 
		current_wave_data: WaveData, 
		wave_timer: Timer
	) -> void :

	_main = Utils.get_scene_node()

	_current_wave_data = current_wave_data
	_zone_min_pos = zone_min_pos
	_zone_max_pos = zone_max_pos
	_wave_timer = wave_timer

	for player_index in RunData.get_player_count():
		var position: Vector2
		if RunData.get_player_count() > 1:
			position = Vector2(
				zone_max_pos.x / 2 - 100 + (player_index % 2) * 100, 
				zone_max_pos.y / 2 + ((player_index / 2) % 2) * 100
			)
		else:
			position = Vector2(zone_max_pos.x / 2, zone_max_pos.y / 2)
		var args: = SpawnEntityArgs.new(position, EntityType.PLAYER)
		args.player_index = player_index
		var player = spawn_entity(player_scene, args)
		if RunData.is_coop_run:
			player._movement_behavior.device = CoopService.connected_players[player_index][0]
		_players.push_back(player)

		_restrict_turret_count(player_index)

	for player in _players:
		for weapon in player.current_weapons:
			weapon.connect("wanted_to_reset_turrets_cooldown", self, "on_weapon_wanted_to_reset_turrets_cooldown")

	emit_signal("players_spawned", _players)


func _physics_process(_delta: float) -> void :
	if _cleaning_up:
		return

	cur_spawn_delay += 1

	if cur_spawn_delay >= SPAWN_DELAY:
		for player_index in Utils.shuffled_range(queues_to_spawn_structures.size()):
			var queue = queues_to_spawn_structures[player_index]
			if queue.size() > 0:
				spawn(queue, player_index)
				break
		spawn(queue_to_spawn_trees)
		spawn(queue_to_spawn_bosses)
		spawn(queue_to_spawn_summons)

		var nb_to_spawn = 1

		if queue_to_spawn.size() >= QUEUE_LIMIT:
			nb_to_spawn = int(clamp((queue_to_spawn.size() - QUEUE_LIMIT) / 10.0, 1, 2))

		for i in nb_to_spawn:
			spawn(queue_to_spawn)

		cur_spawn_delay = 0


func on_group_spawn_timing_reached(group_data: WaveGroupData) -> void :
	if _cleaning_up:
		return

	var max_enemies = int(_current_wave_data.max_enemies + ((RunData.get_player_count() - 1) * (_current_wave_data.max_enemies / 8.0)))

	if enemies.size() > max_enemies:
		var nb_to_remove = enemies.size() - max_enemies

		for i in nb_to_remove:
			var array_from = enemies

			if enemies_to_remove_in_priority.size() > 0:
				array_from = enemies_to_remove_in_priority

			var en = Utils.get_rand_element(array_from)

			en.can_drop_loot = false
			en.die()
			enemies_removed_for_perf += 1

	var group_pos: Vector2 = get_group_pos(group_data)
	group_pos = get_group_pos_away_from_players(group_pos, group_data)

	var units_data = group_data.wave_units_data
	var coop_factor = (RunData.get_player_count() - 1) * CoopService.additional_enemies_per_coop_player
	var enemy_modifier = (RunData.sum_all_player_effects("number_of_enemies") / 100.0)
	var tree_modifier = RunData.sum_all_player_effects("trees")

	for unit_wave_data in units_data:
		var number: float = Utils.randi_range(unit_wave_data.min_number, unit_wave_data.max_number) as float
		number *= DebugService.nb_enemies_mult

		if unit_wave_data.type == EntityType.ENEMY and not group_data.is_loot:
			number += number * coop_factor
			number = max(1.0, number + number * enemy_modifier)
		elif unit_wave_data.type == EntityType.NEUTRAL:
			number += tree_modifier

		var number_total: float = number * unit_wave_data.spawn_chance
		var number_floored: = int(number_total)
		var residual_chance: = number_total - number_floored
		var spawn_count: = (number_floored + 1) if Utils.get_chance_success(residual_chance) else number_floored

		for i in spawn_count:
			var spawn_pos = get_spawn_pos_in_area(group_pos, group_data.area, group_data.spawn_dist_away_from_edges, group_data.spawn_edge_of_map)
			spawn_pos = get_spawn_pos_away_from_players(spawn_pos, group_pos, group_data, unit_wave_data)
			if group_data.is_boss:
				queue_to_spawn_bosses.push_back([unit_wave_data.type, unit_wave_data.unit_scene, spawn_pos])
			elif unit_wave_data.type == EntityType.ENEMY:
				queue_to_spawn.push_back([unit_wave_data.type, unit_wave_data.unit_scene, spawn_pos])
			elif unit_wave_data.type == EntityType.NEUTRAL:
				queue_to_spawn_trees.push_back([unit_wave_data.type, unit_wave_data.unit_scene, spawn_pos])


func get_spawn_pos_away_from_players(spawn_pos: Vector2, group_pos: Vector2, group_data: WaveGroupData, unit_data: WaveUnitData) -> Vector2:
	var min_dist_from_player: int = INITIAL_MIN_DIST_FROM_PLAYER + unit_data.additional_min_distance_from_player

	while distance_squared_to_closest_player(spawn_pos) < min_dist_from_player * min_dist_from_player:
		spawn_pos = get_spawn_pos_in_area(group_pos, group_data.area, group_data.spawn_dist_away_from_edges, group_data.spawn_edge_of_map)
		min_dist_from_player = max(25, min_dist_from_player - 5) as int
		if min_dist_from_player == 25:
			break

	return spawn_pos


func distance_squared_to_closest_player(from_pos: Vector2) -> float:
	var dist = Utils.LARGE_NUMBER

	for player in _players:
		var dist_to_player = from_pos.distance_squared_to(player.global_position)
		if dist_to_player < dist:
			dist = dist_to_player

	return dist


func get_group_pos(group_data: WaveGroupData) -> Vector2:

	var base_pos: Vector2
	var d = group_data.spawn_dist_away_from_edges

	if group_data.area != - 1:
		base_pos = ZoneService.get_rand_pos(group_data.area / 2 + d)
	else:
		base_pos = ZoneService.get_rand_pos(d)

	return base_pos


func get_group_pos_away_from_players(group_pos: Vector2, group_data: WaveGroupData) -> Vector2:
	
	
	
	var min_dist_from_player: int = INITIAL_MIN_DIST_FROM_PLAYER + group_data.area / 2

	
	
	
	var zone_size: Vector2 = ZoneService.get_current_zone_rect().size
	var half_zone_size: float = max(zone_size.x, zone_size.y) / 2.0
	min_dist_from_player = min(min_dist_from_player, half_zone_size) as int

	while distance_squared_to_closest_player(group_pos) < min_dist_from_player * min_dist_from_player:
		group_pos = get_group_pos(group_data)
		min_dist_from_player = max(25, min_dist_from_player - 5) as int
		if min_dist_from_player == 25:
			break

	return group_pos


func spawn(queue_from: Array, player_index: = - 1) -> void :
	if _cleaning_up:
		return

	if queue_from.size() == 0:
		return

	var entity_to_spawn = queue_from.pop_back()
	var data = null
	var source = null
	var charmed_by = - 1

	if entity_to_spawn.size() > 3:
		data = entity_to_spawn[3]

	if entity_to_spawn.size() > 4:
		source = entity_to_spawn[4]

	if entity_to_spawn.size() > 5:
		charmed_by = entity_to_spawn[5]

	spawn_entity_birth(entity_to_spawn[0], entity_to_spawn[1], entity_to_spawn[2], data, player_index, source, charmed_by)

func spawn_entity_birth(type: int, scene: PackedScene, pos: Vector2, data: Resource = null, player_index: = - 1, source = null, charmed_by: = - 1) -> void :
	var entity_birth = _main.get_node_from_pool(entity_birth_scene.resource_path)
	if entity_birth == null:
		entity_birth = entity_birth_scene.instance()
		_main.add_birth(entity_birth)
		entity_birth.connect("birth_timeout", self, "on_entity_birth_timeout")

	if type == EntityType.STRUCTURE and structures.size() > MAX_STRUCTURES:
		var nb_to_remove = structures.size() - MAX_STRUCTURES

		for i in nb_to_remove:
			var array_from = structures

			if structures_to_remove_in_priority.size() > 0:
				array_from = structures_to_remove_in_priority

			var st = Utils.get_rand_element(array_from)
			st.die()

	entity_birth.start(type, scene, pos, data, player_index, source, charmed_by)
	active_births += 1


func on_entity_birth_timeout(birth: EntityBirth) -> void :
	active_births -= 1

	if _cleaning_up:
		return

	var args = SpawnEntityArgs.new(birth.global_position, birth.type)
	args.player_index = birth.player_index
	var _entity = spawn_entity(birth.scene, args, birth.data, birth.source, birth.charmed_by)

	_main.add_node_to_pool(birth)


class SpawnEntityArgs:
	
	var position: Vector2
	
	var player_index: = - 1
	var type: = EntityType.PLAYER

	func _init(p_position: Vector2, p_type: int):
		position = p_position
		type = p_type


func spawn_entity(scene: PackedScene, args: SpawnEntityArgs, data: Resource = null, source = null, charmed_by: int = - 1) -> KinematicBody2D:
	var type = args.type
	if type == EntityType.PLAYER:
		DebugService.handle_player_spawn_debug_options(args.player_index)

	var entity = _main.get_node_from_pool(scene.resource_path)
	if entity != null:
		entity.respawn()

	else:
		entity = scene.instance()
		if type == EntityType.PLAYER:
			entity.player_index = args.player_index

		_main.add_entity(entity)

		entity.init(_zone_min_pos, _zone_max_pos, _players, self)

		if entity.get_entity_spawner_ref_on_spawn:
			entity.entity_spawner = self

		if type == EntityType.ENEMY:
			entity.connect("died", self, "_on_enemy_died")
			entity.connect("wanted_to_spawn_an_enemy", self, "on_enemy_wanted_to_spawn_an_enemy")
			entity.connect("charmed", self, "on_enemy_charmed")
			emit_signal("enemy_spawned", entity)
		elif type == EntityType.BOSS:
			entity.connect("died", self, "_on_boss_died")
			entity.connect("wanted_to_spawn_an_enemy", self, "on_enemy_wanted_to_spawn_an_enemy")
			emit_signal("enemy_spawned", entity)
		elif type == EntityType.NEUTRAL:
			entity.connect("died", self, "_on_neutral_died")
			emit_signal("neutral_spawned", entity)
		elif type == EntityType.STRUCTURE:
			entity.connect("died", self, "_on_structure_died")
			emit_signal("structure_spawned", entity)

	entity.global_position = args.position

	if type == EntityType.PLAYER:
		entity.apply_items_effects()
	elif type == EntityType.BOSS:
		bosses.push_back(entity)
	elif type == EntityType.ENEMY:
		entity.set_source(source)
		if charmed_by != - 1:
			entity.set_charmed(charmed_by)

		enemies.push_back(entity)
		if entity.to_be_removed_in_priority:
			enemies_to_remove_in_priority.push_back(entity)
		emit_signal("enemy_respawned", entity)

	elif type == EntityType.NEUTRAL:
		neutrals.push_back(entity)
		emit_signal("neutral_respawned", entity)

	elif type == EntityType.STRUCTURE:
		entity.player_index = args.player_index
		entity.set_data(data)

		structures.push_back(entity)
		if entity.to_be_removed_in_priority:
			structures_to_remove_in_priority.push_back(entity)

	return entity


func on_enemy_wanted_to_spawn_an_enemy(enemy_scene: PackedScene, at_position: Vector2, source, charmed_by: int) -> void :
	if not _cleaning_up:
		queue_to_spawn_summons.push_back([EntityType.ENEMY, enemy_scene, at_position, null, source, charmed_by])


func on_enemy_charmed(enemy: Entity) -> void :
	charmed_enemies.push_back(enemy)


func _on_boss_died(boss: Node2D, _args: Entity.DieArgs) -> void :
	if not _cleaning_up:
		bosses.erase(boss)


func _on_enemy_died(enemy: Node2D, _args: Entity.DieArgs) -> void :
	if not _cleaning_up:
		enemies.erase(enemy)
		enemies_to_remove_in_priority.erase(enemy)
		charmed_enemies.erase(enemy)
		emit_signal("enemy_number_updated", enemies.size(), active_births)


func _on_neutral_died(neutral: Node2D, _args: Entity.DieArgs) -> void :
	if not _cleaning_up:
		neutrals.erase(neutral)


func _on_structure_died(structure: Node2D, _args: Entity.DieArgs) -> void :
	if not _cleaning_up:
		structures_to_remove_in_priority.erase(structure)
		structures.erase(structure)


func get_spawn_pos_in_area(base_pos: Vector2, area: int, spawn_dist_from_edges: int = 0, spawn_edge_of_map: bool = false) -> Vector2:

	var d = spawn_dist_from_edges
	if spawn_edge_of_map:
		var spawn_direction = _possible_edge_spawns[Utils.randi() % _possible_edge_spawns.size()]
		return Utils.get_rand_pos_from_direction_at_distance(spawn_direction, _zone_min_pos, _zone_max_pos, Utils.EDGE_MAP_DIST)
	elif area == - 1:
		return Vector2(rand_range(_zone_min_pos.x + d, _zone_max_pos.x - d), rand_range(_zone_min_pos.y + d, _zone_max_pos.y - d))
	else:
		return ZoneService.get_rand_pos_in_area(base_pos, area)


func get_rand_enemy(ignore_unit: Node2D = null) -> Node2D:
	if enemies.size() <= 0 or (enemies.size() <= 1 and ignore_unit != null):
		return null

	var unit = Utils.get_rand_element(enemies)

	if ignore_unit != null and enemies.size() > 1:
		while unit == ignore_unit:
			unit = Utils.get_rand_element(enemies)

	return unit


func get_number_of_burning_enemies() -> int:
	var nb = 0

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy._is_burning:
			nb += 1

	return nb


func get_all_enemies(include_charmed: bool = true) -> Array:

	var all_enemies = enemies + bosses

	if not include_charmed:
		for charmed_enemy in charmed_enemies:
			all_enemies.erase(charmed_enemy)

	return all_enemies


func _restrict_turret_count(player_index: int) -> void :
	var player_effects: Dictionary = RunData.get_player_effects(player_index)

	var new_player_structures: = []
	var turrets: = []
	for structure in player_effects["structures"]:
		if EntityService.is_considered_turret(structure):
			turrets.append(structure)
		else:
			new_player_structures.append(structure)
	turrets.sort_custom(EntityService, "sort_turrets_by_strength")

	var max_turret_count: int = RunData.get_player_effect("max_turret_count", player_index)
	new_player_structures.append_array(turrets.slice(0, max_turret_count - 1))
	player_effects["structures"] = new_player_structures

	ChallengeService.try_complete_challenge("chal_turrets", turrets.size())


func _on_StructureTimer_timeout() -> void :
	if _cleaning_up: return

	var cur_time = (_wave_timer.wait_time - _wave_timer.time_left) as int
	for player_index in RunData.get_player_count():
		var player_structures = RunData.get_player_effect("structures", player_index)
		if player_structures.empty() or _players[player_index].dead:
			continue

		var group_structures = RunData.get_player_effect_bool("group_structures", player_index)
		var base_pos = ZoneService.get_rand_pos_in_area_around_center((ZoneService.get_current_zone_rect().size.x / 3) as int)
		var spawn_radius = min(600, 400 + player_structures.size() * 10)

		for struct in player_structures:
			var spawn_cd = WeaponService.apply_structure_attack_speed_effects(struct.spawn_cooldown, player_index)
			if (spawn_cd != - 1 and cur_time % spawn_cd == 0) or not _base_structures_spawned:
				for _i in struct.value:
					var pos = get_spawn_pos_in_area(base_pos, spawn_radius) if group_structures and struct.can_be_grouped else ZoneService.get_rand_pos((Utils.EDGE_MAP_DIST * 2.5) as int)

					if struct.spawn_around_player != - 1:
						pos = get_spawn_pos_in_area(_players[player_index].global_position, struct.spawn_around_player)
					elif struct.spawn_in_center != - 1:
						pos = get_spawn_pos_in_area(ZoneService.get_map_center(), struct.spawn_in_center)

					queues_to_spawn_structures[player_index].push_back([EntityType.STRUCTURE, struct.scene, pos, struct])

	_base_structures_spawned = true


func on_weapon_wanted_to_reset_turrets_cooldown() -> void :
	for structure in structures:
		if EntityService.is_offensive(structure):
			structure.set_instant_shoot()


func get_nb_bosses_and_elites_alive() -> int:
	return bosses.size()


func clean_up_room() -> void :
	_cleaning_up = true
	_structure_timer.stop()

	queue_to_spawn.clear()
	queue_to_spawn_bosses.clear()
	queue_to_spawn_summons.clear()
	queue_to_spawn_trees.clear()
	for queue in queues_to_spawn_structures:
		queue.clear()

	var die_args: = Entity.DieArgs.new()
	die_args.cleaning_up = true

	for boss in bosses:
		boss.die(die_args)

	for enemy in enemies:
		enemy.die(die_args)

	for neutral in neutrals:
		neutral.die(die_args)

	for structure in structures:
		structure.die(die_args)
