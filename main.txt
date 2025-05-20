class_name Main
extends Node

export (PackedScene) var gold_bag_scene: PackedScene
export (PackedScene) var gold_scene: PackedScene
export (PackedScene) var consumable_scene: PackedScene
export (Resource) var turret_effect: Resource
export (Resource) var landmines_effect: Resource
export (Array) var gold_sprites: Array
export (Array, Resource) var gold_pickup_sounds: Array
export (Array, Resource) var gold_alt_pickup_sounds: Array
export (Resource) var level_up_sound: Resource
export (Array, Resource) var run_won_sounds: Array
export (Array, Resource) var run_lost_sounds: Array
export (Array, Resource) var end_wave_sounds: Array

func show_manual_cursor() -> bool:
	return ProgressData.is_manual_aim(0) and not _cleaning_up

const EDGE_SIZE = 96
const MAX_GOLDS = 50
const MIN_GOLD_CHANCE = 0.5
const MIN_MAP_SIZE = 12

const MOUSE_DIST_FROM_PLAYER_MANUAL_AIM = 200

var _cleaning_up: = false
var _active_golds: = []
var _consumables: = []
var _upgrades_to_process: = [[], [], [], []]
var _consumables_to_process: = [[], [], [], []]

var _end_wave_timer_timedout: = false

var _players: = []
var _next_gold_player: int
var _players_ui: = []
var _things_to_process_player_containers: = []

var _is_run_lost: bool
var _is_run_won: bool
var _gold_bag: Node

var _is_chal_ui_displayed = false

var _proj_on_death_stat_caches: = [{}, {}, {}, {}]
var _items_spawned_this_wave: = 0
var _player_is_under_half_health: = [false, false, false, false]

var _update_stats_on_enemies_changed_timer: Timer = null
var _last_gold_amount_used_to_reload_stats: = [0, 0, 0, 0]
var _is_horde_wave: = false
var _is_elite_wave: = false
var _elite_killed_bonus: = 0
var override_gold_bag_pos: = Vector2.ZERO

var _convert_stats_half_wave_proced: = false
var _pool: = {}
var _skip_pause_check = false

onready var _entities_container: YSort = $"%Entities"
onready var _entity_spawner = $EntitySpawner
onready var _effects_manager = $EffectsManager
onready var _wave_manager = $WaveManager
onready var _floating_text_manager = $FloatingTextManager
onready var _effect_behaviors: = $EffectBehaviors
onready var _camera: MyCamera = $Camera
onready var _screenshaker = $Camera / Screenshaker
onready var _materials_container: Node2D = $"%Materials"
onready var _consumables_container: Node2D = $"%Consumables"
onready var _births_container: Node2D = $"%Births"
onready var _pause_menu = $UI / PauseMenu
onready var _end_wave_timer = $EndWaveTimer
onready var _upgrades_ui: UpgradesUI = $UI / UpgradesUI
onready var _coop_upgrades_ui: UpgradesUI = $UI / CoopUpgradesUI
onready var _wave_timer = $WaveTimer

onready var _wave_cleared_label = $UI / WaveClearedLabel
onready var _hud = $UI / HUD
onready var _ui_bonus_gold = $UI / HUD / LifeContainerP1 / UIBonusGold
onready var _ui_bonus_gold_pos = $UI / HUD / LifeContainerP1 / UIBonusGold / Position2D
onready var _current_wave_label = $UI / HUD / WaveContainer / CurrentWaveLabel
onready var _wave_timer_label = $UI / HUD / WaveContainer / WaveTimerLabel
onready var _ui_wave_container = $UI / HUD / WaveContainer
onready var _ui_things_to_process_margin_container: MarginContainer = $"%ThingsToProcessMarginContainer"
onready var _ui_dim_screen = $UI / DimScreen
onready var _tile_map = $TileMap
onready var _tile_map_limits = $TileMapLimits
onready var _background = $CanvasLayer / Background
onready var _harvesting_timer = $HarvestingTimer
onready var _challenge_completed_ui = $UI / ChallengeCompletedUI
onready var _retry_wave = $UI / RetryWave

onready var _damage_vignette = $UI / DamageVignette
onready var _info_popup = $UI / InfoPopup
onready var _fps_label = $"%FPSLabel"
onready var _explosions: Node2D = $"Explosions"
onready var _effects: Node2D = $"Effects"
onready var _floating_texts: Node2D = $"%FloatingTexts"
onready var _player_projectiles: Node2D = $"%PlayerProjectiles"
onready var _enemy_projectiles: Node2D = $"%EnemyProjectiles"


func _ready() -> void :
	if DebugService.display_fps:
		_fps_label.show()

	var _e = _entity_spawner.connect("players_spawned", self, "_on_EntitySpawner_players_spawned")

	MusicManager.tween(0)
	_pause_menu.enabled = true
	if DebugService.hide_wave_timer: _ui_wave_container.hide()

	RunData.on_wave_start()
	_convert_stats_half_wave_proced = false
	_next_gold_player = Utils.randi() % RunData.get_player_count()

	var _popup = _challenge_completed_ui.connect("started", self, "on_chal_popup")
	var _popout = _challenge_completed_ui.connect("finished", self, "on_chal_popout")

	_background.texture.gradient.colors[1] = ItemService.get_background_gradient_color()
	_tile_map.tile_set.tile_set_texture(0, RunData.get_background().get_tiles_sprite())
	_tile_map.outline.modulate = RunData.get_background().outline_color

	TempStats.reset()

	var _stats = RunData.connect("stats_updated", self, "on_stats_updated")

	_gold_bag = Utils.instance_scene_on_main(gold_bag_scene, get_gold_bag_pos())
	var current_zone = ZoneService.get_zone_data(RunData.current_zone).duplicate()
	var current_wave_data = ZoneService.get_wave_data(RunData.current_zone, RunData.current_wave)

	var map_size_coef = (1 + (RunData.sum_all_player_effects("map_size") / 100.0))

	current_zone.width = max(MIN_MAP_SIZE, (current_zone.width * map_size_coef)) as int
	current_zone.height = max(MIN_MAP_SIZE, (current_zone.height * map_size_coef)) as int

	_tile_map.init(current_zone)
	_tile_map_limits.init(current_zone)

	ZoneService.current_zone = current_zone
	ZoneService.current_zone_max_position = Vector2(current_zone.width * Utils.TILE_SIZE, current_zone.height * Utils.TILE_SIZE)

	_current_wave_label.text = Text.text("WAVE", [str(RunData.current_wave)]).to_upper()

	_wave_timer.wait_time = 1 if RunData.instant_waves else current_wave_data.wave_duration

	if DebugService.custom_wave_duration != - 1:
		_wave_timer.wait_time = DebugService.custom_wave_duration

	_wave_timer.start()
	_wave_timer_label.wave_timer = _wave_timer
	var _error_wave_timer = _wave_timer.connect("tick_started", self, "on_tick_started")

	var _error_group_spawn = _wave_manager.connect("group_spawn_timing_reached", _entity_spawner, "on_group_spawn_timing_reached")
	_wave_manager.init(_wave_timer, current_zone, current_wave_data)

	var _error_connect = _coop_upgrades_ui.connect("upgrade_selected", self, "on_upgrade_selected")
	_error_connect = _coop_upgrades_ui.connect("item_take_button_pressed", self, "on_item_box_take_button_pressed")
	_error_connect = _coop_upgrades_ui.connect("item_discard_button_pressed", self, "on_item_box_discard_button_pressed")

	_error_connect = _upgrades_ui.connect("upgrade_selected", self, "on_upgrade_selected")
	_error_connect = _upgrades_ui.connect("item_take_button_pressed", self, "on_item_box_take_button_pressed")
	_error_connect = _upgrades_ui.connect("item_discard_button_pressed", self, "on_item_box_discard_button_pressed")

	var _error_level_up = RunData.connect("levelled_up", self, "on_levelled_up")
	var _error_level_up_floating_text = RunData.connect("levelled_up", _floating_text_manager, "on_levelled_up")
	var _error_xp_added = RunData.connect("xp_added", self, "on_xp_added")
	var _error_gold_changed = RunData.connect("gold_changed", self, "on_gold_changed")
	var _error_bonus_gold_ui = RunData.connect("bonus_gold_changed", _ui_bonus_gold, "update_value")
	var _error_bonus_gold = RunData.connect("bonus_gold_changed", self, "on_bonus_gold_changed")
	on_bonus_gold_changed(RunData.bonus_gold)
	var _error_damage_effect = RunData.connect("damage_effect", self, "on_damage_effect")
	var _error_lifesteal_effect = RunData.connect("lifesteal_effect", self, "on_lifesteal_effect")
	var _error_healing_effect = RunData.connect("healing_effect", self, "on_healing_effect")
	var _error_heal_over_time_effect = RunData.connect("heal_over_time_effect", self, "on_heal_over_time_effect")

	var _error_gamepad = InputService.connect("game_lost_focus", self, "_on_game_lost_focus")

	
	var max_bounds = ZoneService.get_current_zone_rect().grow_individual(EDGE_SIZE, EDGE_SIZE * 2, EDGE_SIZE, EDGE_SIZE)
	_camera.init(max_bounds, float(EDGE_SIZE))
	on_lock_coop_camera_changed(ProgressData.settings.lock_coop_camera)

	_ui_dim_screen.color.a = 0

	if ProgressData.settings.manual_aim:
		InputService.hide_mouse = false

	var _error_options_1 = _pause_menu.menu_gameplay_options.connect("character_highlighting_changed", self, "on_character_highlighting_changed")
	var _error_options_2 = _pause_menu.menu_gameplay_options.connect("hp_bar_on_character_changed", self, "on_hp_bar_on_character_changed")
	var _error_options_3 = _pause_menu.menu_gameplay_options.connect("weapon_highlighting_changed", self, "on_weapon_highlighting_changed")
	var _error_options_4 = _pause_menu.menu_gameplay_options.connect("darken_screen_changed", self, "on_darken_screen_changed")
	var _error_options_5 = _pause_menu.menu_gameplay_options.connect("lock_coop_camera_changed", self, "on_lock_coop_camera_changed")

	for player_index in CoopService.MAX_PLAYER_COUNT:
		var player_idx_string = str(player_index + 1)
		var things_to_process_player_container = get_node("%%UIThingsToProcessPlayerContainer%s" % player_idx_string)
		
		things_to_process_player_container.hide()
		if not RunData.is_coop_run:
			
			things_to_process_player_container.horizontal_alignment = UIThingsToProcessPlayerContainer.Alignment.END
		_things_to_process_player_containers.push_back(things_to_process_player_container)

	_is_horde_wave = RunData.is_elite_wave(EliteType.HORDE)
	_is_elite_wave = RunData.is_elite_wave(EliteType.ELITE)

	if not RunData.is_coop_run:
		
		
		_ui_things_to_process_margin_container.add_constant_override("margin_right", 0)

	for effect_behavior_data in EffectBehaviorService.scene_effect_behaviors:
		var effect_behavior: SceneEffectBehavior = effect_behavior_data.scene.instance()
		_effect_behaviors.add_child(effect_behavior.init(_entity_spawner, _wave_manager))

	
	_entity_spawner.init(
		ZoneService.current_zone_min_position, 
		ZoneService.current_zone_max_position, 
		current_wave_data, 
		_wave_timer
	)

	EntityService.reset_cache()
	InputService.set_gamepad_echo_processing(false)
	_coop_upgrades_ui.propagate_call("set_process_input", [false])


func add_timer(cooldown: int) -> Timer:
	var timer = Timer.new()
	timer.wait_time = cooldown
	add_child(timer)
	timer.start()
	return timer


func on_ui_element_mouse_entered(ui_element: Node, text: String) -> void :
	if _cleaning_up:
		_info_popup.display(ui_element, tr(text))


func on_ui_element_mouse_exited(_ui_element: Node) -> void :
	_info_popup.hide()


func on_character_highlighting_changed(_value: bool) -> void :
	for player in _players:
		if not is_instance_valid(player) or not player.is_inside_tree():
			continue
		player.update_highlight()


func on_weapon_highlighting_changed(_value: bool) -> void :
	for player in _players:
		if not is_instance_valid(player) or not player.is_inside_tree():
			continue
		player.update_weapon_highlighting()


func on_darken_screen_changed(_value: int) -> void :
	_damage_vignette.update_from_hp()


func on_lock_coop_camera_changed(value: int) -> void :
	_camera.dynamic_camera_enabled = not value


func on_hp_bar_on_character_changed(_value: int) -> void :
	for i in _players.size():
		if not is_instance_valid(_players[i]) or not _players[i].is_inside_tree(): return
		_on_player_health_updated(_players[i], _players[i].current_stats.health, _players[i].max_stats.health)


func on_stats_updated(player_index: int) -> void :
	reload_stats(player_index)


func reload_stats(player_index: int) -> void :
	if _cleaning_up:
		return

	_players[player_index].update_player_stats()
	LinkedStats.reset_player(player_index)

	for weapon in _players[player_index].current_weapons:
		if is_instance_valid(weapon):
			weapon.init_stats(false)

	var struct_cache = {}
	for struct in _entity_spawner.structures:
		if not is_instance_valid(struct) or struct.player_index != player_index:
			continue

		if struct.is_cursed:
			struct.reload_data()
		else:
			if struct_cache.has(struct.filename):
				var max_range = struct.stats.max_range
				struct.stats = struct_cache[struct.filename]
				if max_range != struct.stats.max_range and struct._range_shape:
					struct._range_shape.shape.radius = struct.stats.max_range
			else:
				struct.reload_data()
				struct_cache[struct.filename] = struct.stats

	_proj_on_death_stat_caches[player_index].clear()


func reload_all_player_stats() -> void :
	for player_index in RunData.get_player_count():
		reload_stats(player_index)


func _process(_delta: float) -> void :
	if DebugService.enable_time_scale_buttons:
		if Input.is_physical_key_pressed(KEY_1):
			Engine.time_scale = 0.5
		if Input.is_physical_key_pressed(KEY_2):
			Engine.time_scale = 1.0
		if Input.is_physical_key_pressed(KEY_3):
			Engine.time_scale = 2.0

	_handle_mouse_visibility()

	_check_for_pause()


func _handle_mouse_visibility() -> void :
	if _cleaning_up or RunData.is_coop_run:
		return

	if ProgressData.settings.manual_aim or ProgressData.settings.mouse_only:
		InputService.hide_mouse = false
	elif ProgressData.settings.manual_aim_on_mouse_press:
		if InputService.using_gamepad:
			var rjoy = Input.get_vector("rjoy_left", "rjoy_right", "rjoy_up", "rjoy_down")
			InputService.hide_mouse = rjoy == Vector2.ZERO
		else:
			InputService.hide_mouse = not Input.is_mouse_button_pressed(BUTTON_LEFT)
	else:
		InputService.hide_mouse = true


func _check_for_pause() -> void :
	if _skip_pause_check:
		_skip_pause_check = false
		return

	if RunData.is_coop_run:
		for player_index in RunData.get_player_count():
			var remapped_device = CoopService.get_remapped_player_device(player_index)
			if Input.is_action_just_pressed("ui_pause_%s" % remapped_device):
				_pause_menu.pause(player_index)
				break
	else:
		if Input.is_action_just_pressed("ui_pause"):
			_pause_menu.pause(0)


func _physics_process(_delta: float) -> void :
	if _cleaning_up:
		_gold_bag.global_position = get_gold_bag_pos()

	for player_index in RunData.get_player_count():
		var life_bar_effects = _players[player_index].life_bar_effects()
		var player_ui: PlayerUIElements = _players_ui[player_index]
		player_ui.life_bar.update_color_from_effects(life_bar_effects)
		player_ui.player_life_bar.update_color_from_effects(life_bar_effects)

	if not _cleaning_up:
		for player_index in RunData.get_player_count():
			if not ProgressData.is_manual_aim(player_index) or not Utils.is_player_using_gamepad(player_index):
				continue
			var rjoy = Utils.get_player_rjoy_vector(player_index)
			if rjoy != Vector2.ZERO:
				_players[player_index].gamepad_attack_vector = rjoy.normalized()
		if not RunData.is_coop_run and ProgressData.is_manual_aim(0) and Utils.is_player_using_gamepad(0):
			
			var player_pos = _players[0].get_global_transform_with_canvas().origin
			player_pos.y -= 32
			get_viewport().warp_mouse(player_pos + MOUSE_DIST_FROM_PLAYER_MANUAL_AIM * _players[0].gamepad_attack_vector)

	if not _convert_stats_half_wave_proced and _wave_timer.time_left <= _wave_timer.wait_time / 2.0:
		_convert_stats_half_wave_proced = true
		for player_index in RunData.get_player_count():
			Utils.convert_stats(RunData.get_player_effect("convert_stats_half_wave", player_index), player_index, false)


func on_tick_started() -> void :
	_wave_timer_label.modulate = Color.red


func on_bonus_gold_changed(value: int) -> void :
	if value == 0:
		_ui_bonus_gold.hide()


func _on_player_died(p_player: Player, _args: Entity.DieArgs) -> void :
	var player_ui: PlayerUIElements = _players_ui[p_player.player_index]
	player_ui.player_life_bar.hide()
	if RunData.is_coop_run:
		player_ui.life_bar.set_value(100)
		player_ui.life_bar.progress_color = Color.white
		player_ui.life_bar.hide_with_flash()

	p_player.highlight.hide()

	var all_players_dead: = true

	for player in _players:
		if not player.dead:
			all_players_dead = false
			break

	if not all_players_dead:
		return

	if RunData.current_wave <= RunData.nb_of_waves and not RunData.all_last_wave_bosses_killed:
		_is_run_lost = true
	else:
		_is_run_won = true
	clean_up_room(false, _is_run_lost, _is_run_won)
	_end_wave_timer.start()

	ProgressData.reset_and_save_new_run_state()

	ChallengeService.complete_challenge("chal_rookie")


func _on_enemy_died(enemy: Enemy, args: Entity.DieArgs) -> void :
	RunData.current_living_enemies -= 1

	if _update_stats_on_enemies_changed_timer != null and _update_stats_on_enemies_changed_timer.is_stopped():
		for player_index in RunData.get_player_count():
			if not LinkedStats.update_for_player_on_enemy_change[player_index]:
				continue
			reload_stats(player_index)
		_update_stats_on_enemies_changed_timer.start()

	if not _cleaning_up and args.enemy_killed_by_player:
		if enemy is Boss:

			
			if _entity_spawner.get_nb_bosses_and_elites_alive() <= 1 and RunData.current_wave == RunData.nb_of_waves:

				if RunData.is_endless_run:
					var additional_groups = ZoneService.get_additional_groups(int((RunData.current_wave / 10.0) * 3), 90)
					for i in additional_groups.size():
						additional_groups[i].spawn_timing = _wave_timer.wait_time - _wave_timer.time_left + i
					_wave_manager.add_groups(additional_groups)
					RunData.all_last_wave_bosses_killed = true

				else:
					_wave_timer.wait_time = 0.1
					_wave_timer.start()

		var live_players: = _get_shuffled_live_players()

		for player in live_players:
			var player_index = player.player_index
			var dmg_when_death = RunData.get_player_effect("dmg_when_death", player_index)
			if dmg_when_death.size() > 0:
				var _dmg_taken = handle_stat_damages(dmg_when_death, player_index)

		for player in live_players:
			var player_index = player.player_index
			var projectiles_on_death = RunData.get_player_effect("projectiles_on_death", player_index)
			for proj_on_death_effect in projectiles_on_death:
				for i in proj_on_death_effect[0]:
					var stats = proj_on_death_effect[1]
					var proj_on_death_stat_cache = _proj_on_death_stat_caches[player_index]
					if proj_on_death_stat_cache.has(i):
						stats = proj_on_death_stat_cache[i]
					else:
						stats = WeaponService.init_ranged_stats(proj_on_death_effect[1], player_index, true)
						proj_on_death_stat_cache[i] = stats

					var auto_target_enemy: bool = proj_on_death_effect[2]
					var from = player
					var spawn_projectile_args: = WeaponServiceSpawnProjectileArgs.new()
					spawn_projectile_args.damage_tracking_key = "item_baby_with_a_beard"
					spawn_projectile_args.from_player_index = player_index
					var _projectile = WeaponService.manage_special_spawn_projectile(
						enemy, 
						stats, 
						rand_range( - PI, PI), 
						auto_target_enemy, 
						_entity_spawner, 
						from, 
						spawn_projectile_args
					)

		for player in live_players:
			var player_index = player.player_index
			RunData.handle_explode_effect("explode_on_death", enemy.global_position, player_index)

		spawn_loot(enemy, EntityType.ENEMY, args)

		ProgressData.increment_stat("enemies_killed")


func _on_enemy_took_damage(enemy: Enemy, _value: int, _knockback_direction: Vector2, _is_crit: bool, _is_dodge: bool, _is_protected: bool, _armor_did_something: bool, args: TakeDamageArgs, _hit_type: int) -> void :
	if enemy.dead and WeaponService.should_spawn_landmines_on_enemy_death(args.hitbox, args.is_burning, args.from_player_index):
		var pos = _entity_spawner.get_spawn_pos_in_area(enemy.global_position, 200)
		var queue = _entity_spawner.queues_to_spawn_structures[args.from_player_index]
		queue.push_back([EntityType.STRUCTURE, landmines_effect.scene, pos, landmines_effect])


func _on_neutral_died(neutral: Neutral, args: Entity.DieArgs) -> void :
	RunData.current_living_trees -= 1

	for player_index in RunData.get_player_count():
		if LinkedStats.update_for_player_on_neutral_change[player_index]:
			reload_stats(player_index)

	if not _cleaning_up:
		spawn_loot(neutral, EntityType.NEUTRAL, args)

		for player in _get_shuffled_live_players():
			var player_index = player.player_index
			for _i in RunData.get_player_effect("tree_turrets", player_index):
				var pos = _entity_spawner.get_spawn_pos_in_area(neutral.global_position, 200)
				var queue = _entity_spawner.queues_to_spawn_structures[player_index]
				queue.push_back([EntityType.STRUCTURE, turret_effect.scene, pos, turret_effect])


func on_player_wanted_to_spawn_gold(value: int, pos: Vector2, spread: int) -> void :
	var actual_value = get_gold_value(EntityType.NEUTRAL, Entity.DieArgs.new(), value)
	spawn_gold(actual_value, pos, spread)


func spawn_loot(unit: Unit, entity_type: int, args: Entity.DieArgs) -> void :
	if not unit.can_drop_loot:
		return

	if unit.stats.can_drop_consumables:
		spawn_consumables(unit)

	var wave_factor = RunData.current_wave * 0.015
	var spawn_chance = 1.0 if RunData.current_wave < 5 else max(0.5, (1.0 - wave_factor))

	if _is_horde_wave:
		spawn_chance *= 0.65

	if unit.stats.always_drop_consumables:
		spawn_chance = 1.0

	if entity_type == EntityType.ENEMY and not Utils.get_chance_success(spawn_chance):
		return

	var pos: Vector2 = unit.global_position
	var value: float = get_gold_value(entity_type, args, unit.stats.value, unit)
	var gold_spread = clamp((value - 1) * 25, unit.stats.gold_spread, 200)

	spawn_gold(value, pos, gold_spread)


func spawn_consumables(unit: Unit) -> void :
	var luck: = 0.0

	for player_index in RunData.get_player_count():
		luck += Utils.get_stat("stat_luck", player_index) / 100.0

	var item_chance: float = (unit.stats.item_drop_chance * (1.0 + luck)) / (1.0 + _items_spawned_this_wave)

	var total_chance_change: float = RunData.sum_all_player_effects("crate_chance") / 100.0
	item_chance = item_chance + item_chance * total_chance_change

	if unit.stats.always_drop_consumables and unit.stats.item_drop_chance >= 1.0 and RunData.current_wave <= RunData.nb_of_waves:
		item_chance = 1.0

	var consumable_to_spawn: ConsumableData = ItemService.get_consumable_to_drop(unit, item_chance)
	if consumable_to_spawn != null:
		if consumable_to_spawn.my_id == "consumable_item_box" or consumable_to_spawn.my_id == "consumable_legendary_item_box":
			_items_spawned_this_wave += 1

		var consumable: Consumable = get_node_from_pool(consumable_scene.resource_path)
		if consumable == null:
			consumable = consumable_scene.instance()
			_consumables_container.call_deferred("add_child", consumable)
			var _error = consumable.connect("picked_up", self, "on_consumable_picked_up")
			yield(consumable, "ready")

		consumable.consumable_data = consumable_to_spawn
		consumable.set_texture(consumable_to_spawn.icon)
		var pos: = unit.global_position
		var dist: = rand_range(50, 100 + unit.stats.gold_spread)
		var push_back_destination: Vector2 = ZoneService.get_rand_pos_in_area(pos, dist, 0)
		consumable.drop(pos, 0, push_back_destination)
		_consumables.push_back(consumable)


func on_consumable_picked_up(consumable: Node, player_index: int) -> void :
	_consumables.erase(consumable)
	add_node_to_pool(consumable)

	var item_box_gold_effect = RunData.get_player_effect("item_box_gold", player_index)
	if (consumable.consumable_data.my_id == "consumable_item_box" or consumable.consumable_data.my_id == "consumable_legendary_item_box") and item_box_gold_effect != 0:
		RunData.add_gold(item_box_gold_effect, player_index)
		RunData.add_tracked_value(player_index, "item_bag", item_box_gold_effect)

	var consumable_data = consumable.consumable_data
	if consumable_data.to_be_processed_at_end_of_wave:
		var consumable_to_process = UpgradesUI.ConsumableToProcess.new()
		consumable_to_process.consumable_data = consumable_data

		var player_index_to_add_to = player_index

		if ProgressData.settings.share_coop_loot:

			player_index_to_add_to = randi() % RunData.get_player_count()

			for i in RunData.get_player_count():
				if _consumables_to_process[i].size() < _consumables_to_process[player_index_to_add_to].size():
					player_index_to_add_to = i

		consumable_to_process.player_index = player_index_to_add_to
		_consumables_to_process[player_index_to_add_to].push_back(consumable_to_process)
		_things_to_process_player_containers[player_index_to_add_to].consumables.add_element(consumable_data)

	_players[player_index].on_consumable_picked_up(consumable_data)

	if not _cleaning_up:
		RunData.handle_explode_effect("explode_on_consumable", consumable.global_position, player_index)
		RunData.handle_explode_effect("explode_on_consumable_burning", consumable.global_position, player_index)

	RunData.apply_item_effects(consumable.consumable_data, player_index)


func spawn_gold(value: float, pos: Vector2, spread: int) -> void :
	var value_floored: = int(value)
	var residual_chance: = value - value_floored
	var spawn_count: = (value_floored + 1) if Utils.get_chance_success(residual_chance) else value_floored
	for _i in range(spawn_count):

		if _active_golds.size() >= MAX_GOLDS:
			var gold_boosted = Utils.get_rand_element(_active_golds)
			gold_boosted.value += Gold.INITIAL_VALUE
			gold_boosted.scale = Vector2(
				min(gold_boosted.scale.x + Gold.INITIAL_VALUE * 0.05, Gold.MAX_SIZE), 
				min(gold_boosted.scale.y + Gold.INITIAL_VALUE * 0.05, Gold.MAX_SIZE)
			)
			continue

		var gold = get_node_from_pool(gold_scene.resource_path)
		if gold == null:
			gold = gold_scene.instance()
			_materials_container.call_deferred("add_child", gold)
			var _error = gold.connect("picked_up", self, "on_gold_picked_up")
			var _error_effects = gold.connect("picked_up", _effects_manager, "on_gold_picked_up")
			var _error_floating_text = gold.connect("picked_up", _floating_text_manager, "on_gold_picked_up")
			yield(gold, "ready")

		if RunData.bonus_gold > 0:
			var gold_value = gold.value
			gold.value += min(gold.value, RunData.bonus_gold)
			gold.boosted = 2
			gold.scale.x = 1.25
			gold.scale.y = 1.25
			RunData.remove_bonus_gold(gold_value)

		gold.set_texture(gold_sprites.pick_random())
		var dist = rand_range(50, 100 + spread)
		var push_back_destination = ZoneService.get_rand_pos_in_area(pos, dist, 0)
		gold.drop(pos, rand_range(0, 2 * PI), push_back_destination)
		_active_golds.push_back(gold)

		for player in _get_shuffled_live_players():
			var player_index = player.player_index
			var instant_gold_attracting = RunData.get_player_effect("instant_gold_attracting", player_index)
			if instant_gold_attracting != 0 and randf() < instant_gold_attracting / 100.0:
				gold.attracted_by = player
				break


func get_gold_value(entity_type: int, args: Entity.DieArgs, base_value: float, unit: Unit = null) -> float:
	var value = base_value
	var coop_factor: float = CoopService.get_coop_materials_factor()
	value += value * coop_factor

	var nb_players = RunData.get_player_count()
	var gold_drops: int = RunData.sum_all_player_effects("gold_drops") / nb_players
	var enemy_gold_drops: int = RunData.sum_all_player_effects("enemy_gold_drops") / nb_players
	var neutral_gold_drops: int = RunData.sum_all_player_effects("neutral_gold_drops") / nb_players

	if entity_type == EntityType.ENEMY:
		var total_effect: = gold_drops + enemy_gold_drops
		value += value * total_effect / 100.0

	elif entity_type == EntityType.NEUTRAL:
		var total_effect: = gold_drops + neutral_gold_drops
		value += value * total_effect / 100.0

	else:
		value += value * gold_drops / 100.0

	value = max(value, MIN_GOLD_CHANCE * base_value)

	if not unit:
		return value

	var value_modifier_from_effect_behaviors = 0.0
	for effect_behavior in unit.effect_behaviors.get_children():
		value_modifier_from_effect_behaviors += effect_behavior.get_gold_value_modifier()
	value *= 1.0 + value_modifier_from_effect_behaviors

	if args.killed_by_player_index >= 0 and args.killed_by_player_index < _players.size() and is_instance_valid(_players[args.killed_by_player_index]):
		var scale_gold_effect: Array = RunData.get_player_effect("scale_materials_with_distance", args.killed_by_player_index)
		if entity_type != EntityType.NEUTRAL and args.enemy_killed_by_player and scale_gold_effect.size() > 0:
			var dist_to_player: = unit.global_position.distance_to(_players[args.killed_by_player_index].global_position)
			var scaling_percentage: int = scale_gold_effect[0].get_scaling_value(dist_to_player)
			value *= 1.0 + scaling_percentage / 100.0

	return value


func on_gold_picked_up(gold: Node, player_index: int) -> void :
	_active_golds.erase(gold)
	add_node_to_pool(gold)

	if ProgressData.settings.alt_gold_sounds:
		SoundManager.play(Utils.get_rand_element(gold_alt_pickup_sounds), - 5, 0.2)
	else:
		SoundManager.play(Utils.get_rand_element(gold_pickup_sounds), 0, 0.2)

	if player_index >= 0:
		var increase_effect: int = RunData.get_player_effect("increase_material_value", player_index)
		var value = gold.value
		value += value * (increase_effect / 100.0)

		var boost = RunData.apply_common_gold_pickup_effects(gold.value, player_index)
		value *= boost
		gold.boosted *= boost

		if Utils.get_chance_success(RunData.get_player_effect("heal_when_pickup_gold", player_index) / 100.0):
			RunData.emit_signal("healing_effect", 1, player_index, "item_cute_monkey")

		var dmg_when_pickup_gold_effect = RunData.get_player_effect("dmg_when_pickup_gold", player_index)
		if dmg_when_pickup_gold_effect.size() > 0:
			var _dmg_taken = handle_stat_damages(dmg_when_pickup_gold_effect, player_index)

		var highest_cd_weapon_that_should_reload = null

		for weapon in _players[player_index].current_weapons:
			for effect in weapon.effects:
				if effect.key == "reload_when_pickup_gold":
					if not weapon._is_shooting and (highest_cd_weapon_that_should_reload == null or weapon._current_cooldown > highest_cd_weapon_that_should_reload._current_cooldown):
						highest_cd_weapon_that_should_reload = weapon

		if highest_cd_weapon_that_should_reload:
			highest_cd_weapon_that_should_reload._current_cooldown = 0

		for structure in _entity_spawner.structures:
			if structure is BuilderTurret:
				for effect in structure.effects:
					if effect.key == "reload_when_pickup_gold":
						structure._cooldown = 0

		if RunData.get_player_effect_bool("reload_when_pickup_gold", player_index):
			for weapon in _players[player_index].current_weapons:
				weapon._current_cooldown = 0


		
		var player_gold: = [0, 0, 0, 0]
		var player_xp: = [0, 0, 0, 0]
		while value > 0:
			player_gold[_next_gold_player] += 1
			player_xp[_next_gold_player] += 1
			value -= 1
			_next_gold_player = (_next_gold_player + 1) % RunData.get_player_count()

		for i in RunData.get_player_count():
			RunData.add_gold(player_gold[i], i)
			RunData.add_xp(player_xp[i], i)

		ProgressData.increment_stat("materials_collected")
		return

	RunData.add_bonus_gold(gold.value)


func on_levelled_up(player_index: int) -> void :
	SoundManager.play(level_up_sound, 0, 0, true)
	var level = RunData.get_player_level(player_index)
	_things_to_process_player_containers[player_index].upgrades.add_element(ItemService.get_icon("icon_upgrade_to_process"), level)

	var upgrade_to_process = UpgradesUI.UpgradeToProcess.new()
	upgrade_to_process.level = level
	upgrade_to_process.player_index = player_index
	_upgrades_to_process[player_index].push_back(upgrade_to_process)

	_players_ui[player_index].update_level_label()

	RunData.add_stat("stat_max_hp", 1, player_index)
	for stat_level_up in RunData.get_player_effect("stats_on_level_up", player_index):
		RunData.add_stat(stat_level_up[0], stat_level_up[1], player_index)

		if stat_level_up[0] == "stat_lifesteal":
			RunData.add_tracked_value(player_index, "item_decomposing_flesh", stat_level_up[1])
		elif stat_level_up[0] == "stat_hp_regeneration":
			RunData.add_tracked_value(player_index, "item_baby_squid", stat_level_up[1])
		elif stat_level_up[0] == "stat_curse":
			var val = stat_level_up[1]

			if RunData.get_player_character(player_index).my_id == "character_creature":
				val -= 1

			if val > 0:
				RunData.add_tracked_value(player_index, "item_barnacle", 1)

	RunData.emit_stats_updated()
	RunData.emit_signal("healing_effect", 1, player_index)


func on_xp_added(current_xp: float, max_xp: float, player_index: int) -> void :
	var player_ui: PlayerUIElements = _players_ui[player_index]
	var display_xp = int(current_xp) % int(ceil(max_xp))
	player_ui.xp_bar.update_value(display_xp, int(max_xp))


func connect_visual_effects(unit: Unit) -> void :
	var _error_effects = unit.connect("took_damage", _effects_manager, "_on_unit_took_damage")
	var _error_floating_text = unit.connect("took_damage", _floating_text_manager, "_on_unit_took_damage")


func clean_up_room(is_last_wave: bool, is_run_lost: bool, is_run_won: bool) -> void :

	if is_run_lost:
		DebugService.log_data("is_run_lost")
		_wave_timer_label.is_run_lost = true
		_wave_timer.stop()
		_wave_timer.tick_timer.stop()
		if ProgressData.settings.retry_wave and RunData.current_wave > 1:
			_end_wave_timer.wait_time = 1.5
		else:
			_end_wave_timer.wait_time = 2.5
		SoundManager.play(Utils.get_rand_element(run_lost_sounds), - 5, 0, true)
		_ui_dim_screen.dim()
		MusicManager.tween( - 20)
	elif is_run_won:
		apply_run_won()

	if RunData.is_endless_run:

		if RunData.current_wave % 10 == 0 and RunData.current_wave >= 20:
			RunData.init_elites_spawn(RunData.current_wave, 0.0)

		DebugService.log_data("is_endless_run")

		if RunData.current_wave >= 20:
			for player_index in RunData.get_player_count():
				var character_difficulty = ProgressData.get_character_difficulty_info(RunData.players_data[player_index].current_character.my_id, RunData.current_zone)

				character_difficulty.max_endless_wave_beaten.set_info(
					RunData.current_difficulty, 
					RunData.current_wave, 
					RunData.current_run_accessibility_settings.health, 
					RunData.current_run_accessibility_settings.damage, 
					RunData.current_run_accessibility_settings.speed, 
					RunData.retries, 
					RunData.is_coop_run, 
					true
				)

	ProgressData.save()

	SoundManager.play(Utils.get_rand_element(end_wave_sounds))
	_cleaning_up = true
	_effects_manager.clean_up_room()
	_floating_text_manager.clean_up_room()

	DebugService.log_data("attract bonus_gold and consumables...")
	if _active_golds.size() > 0:
		var attracted_by = null

		_ui_bonus_gold.show()
		attracted_by = _gold_bag

		for player in _players:
			player.disable_gold_pickup()

		var nb_builders = 0
		var indexes_builder = []

		for player_id in RunData.players_data.size():
			if RunData.get_player_character(player_id).my_id == "character_builder":
				nb_builders += 1
				indexes_builder.push_back(player_id)

		if nb_builders > 0:
			for structure in _entity_spawner.structures:
				if structure is BuilderTurret:
					override_gold_bag_pos = structure.global_position
					var _e = RunData.connect("bonus_gold_converted", structure, "on_bonus_gold_converted")
					_e = structure.connect("stat_added", _floating_text_manager, "on_turret_stat_added")
					structure.main_ref = self

		if ProgressData.settings.optimize_end_waves:
			var bonus_gold_value = 0
			var player_count = RunData.get_player_count()
			for i in _active_golds.size():
				var gold = _active_golds[i]
				var player_index = i % player_count
				var boost = RunData.apply_common_gold_pickup_effects(gold.value, player_index)
				bonus_gold_value += gold.value * boost
				gold.boosted *= boost
				gold.visible = false

			RunData.add_bonus_gold(bonus_gold_value)
		else:
			for gold in _active_golds:
				gold.collision_layer = Utils.BONUS_GOLD_BIT
				gold.attracted_by = attracted_by

	var live_players: = _get_shuffled_live_players()
	if not live_players.empty():
		for i in _consumables.size():
			var player = live_players[i % live_players.size()]
			var consumable: Consumable = _consumables[i]
			if not consumable.has_damage_effect():
				consumable.attracted_by = player

	DebugService.log_data("clean_up other objects...")
	_entity_spawner.clean_up_room()
	_wave_manager.clean_up_room()

	for player in _players:
		if is_instance_valid(player):
			player.on_room_cleanup()

	DebugService.log_data("start wave_cleared_label...")
	_wave_cleared_label.start(is_last_wave, is_run_lost, is_run_won)
	DebugService.log_data("wave_cleared_label started...")


func get_gold_bag_pos() -> Vector2:

	if override_gold_bag_pos != Vector2.ZERO:
		return override_gold_bag_pos

	return get_viewport().get_canvas_transform().affine_inverse().xform(_ui_bonus_gold_pos.global_position)


func _on_EndWaveTimer_timeout() -> void :
	_coop_upgrades_ui.propagate_call("set_process_input", [true])
	DebugService.log_data("_on_EndWaveTimer_timeout")
	SoundManager.clear_queue()
	SoundManager2D.clear_queue()
	InputService.set_gamepad_echo_processing(true)

	_end_wave_timer_timedout = true

	if _is_run_lost and ProgressData.settings.retry_wave and RunData.current_wave > 1:
		_retry_wave.show()
		_pause_menu.enabled = false
		return

	_ui_dim_screen.dim()
	_wave_cleared_label.hide()
	_wave_timer_label.hide()

	_camera.move_speed_factor = 0.0
	_camera.zoom_in_speed_factor = 0.0
	_camera.zoom_out_speed_factor = 0.0

	RunData.on_wave_end()
	LinkedStats.reset()

	var scene: String
	if _is_run_lost or RunData.is_last_wave() or _is_run_won:
		DebugService.log_data("end run...")
		RunData.run_won = not _is_run_lost
		scene = RunData.get_end_run_scene_path()
	else:
		DebugService.log_data("process consumables and upgrades...")
		MusicManager.tween( - 8)

		if RunData.is_coop_run:
			
			_hud.hide()
			if _coop_upgrades_ui.show_options(_consumables_to_process, _upgrades_to_process):
				yield(_coop_upgrades_ui, "options_processed")
			_coop_upgrades_ui.hide()
		else:
			if _upgrades_ui.show_options(_consumables_to_process, _upgrades_to_process):
				var things_to_process_player_container = _things_to_process_player_containers[0]
				var ui_consumables_to_process = things_to_process_player_container.consumables
				var ui_upgrades_to_process = things_to_process_player_container.upgrades
				while not ui_consumables_to_process.is_empty():
					var consumable = yield(_upgrades_ui, "consumable_selected")
					ui_consumables_to_process.remove_element(consumable.consumable_data)
				while not ui_upgrades_to_process.is_empty():
					var args = yield(_upgrades_ui, "upgrade_selected")
					var upgrade = args[1]
					ui_upgrades_to_process.remove_element(upgrade.level)
				yield(_upgrades_ui, "options_processed")
			_upgrades_ui.hide()

		DebugService.log_data("display challenge ui...")
		if _is_chal_ui_displayed:
			yield(_challenge_completed_ui, "finished")

		scene = RunData.get_shop_scene_path()

	_change_scene(scene)


func on_upgrade_selected(upgrade_data: UpgradeData, upgrade: UpgradesUI.UpgradeToProcess) -> void :
	RunData.apply_item_effects(upgrade_data, upgrade.player_index)


func on_item_box_take_button_pressed(item_data: ItemParentData, consumable: UpgradesUI.ConsumableToProcess) -> void :
	RunData.add_item(item_data, consumable.player_index)


func on_item_box_discard_button_pressed(item_data: ItemParentData, consumable: UpgradesUI.ConsumableToProcess) -> void :
	var player_index = consumable.player_index
	var value = ItemService.get_recycling_value(RunData.current_wave, item_data.value, player_index)
	RunData.add_gold(value, player_index)
	RunData.update_recycling_tracking_value(item_data, player_index)


func _on_PauseMenu_paused() -> void :
	reload_all_player_stats()
	InputService.set_gamepad_echo_processing(true)


func _on_PauseMenu_unpaused() -> void :
	_skip_pause_check = true

	if not _end_wave_timer_timedout:
		InputService.set_gamepad_echo_processing(false)

	elif _upgrades_ui.visible:
		
		
		_upgrades_ui.focus()


func _on_WaveTimer_timeout() -> void :
	DebugService.log_run_info(_upgrades_to_process, _consumables_to_process)

	var is_last_wave = RunData.is_last_wave()

	if not _is_run_lost and is_last_wave:
		_is_run_won = true

	ChallengeService.check_counted_challenges()

	for player_index in RunData.get_player_count():
		if _players[player_index] != null and is_instance_valid(_players[player_index]) and _players[player_index].current_stats.health == ChallengeService.get_chal("chal_reckless").value:
			ChallengeService.complete_challenge("chal_reckless")
			break

	if _entity_spawner.neutrals.size() >= ChallengeService.get_chal("chal_forest").value:
		ChallengeService.complete_challenge("chal_forest")

	for player_index in RunData.get_player_count():
		var stats_end_of_wave = RunData.get_player_effect("stats_end_of_wave", player_index)
		for stat_end_of_wave in stats_end_of_wave:
			RunData.add_stat(stat_end_of_wave[0], stat_end_of_wave[1], player_index)

			if stat_end_of_wave[0] == "stat_percent_damage":
				RunData.add_tracked_value(player_index, "item_vigilante_ring", stat_end_of_wave[1])
			elif stat_end_of_wave[0] == "stat_max_hp":
				var leaf_value = 0
				var items = RunData.get_player_items(player_index)
				for item in items:
					if item.my_id == "item_grinds_magical_leaf":
						for effect in item.effects:
							if effect.key != "stat_curse":
								leaf_value += effect.value
				RunData.add_tracked_value(player_index, "item_grinds_magical_leaf", leaf_value)
			elif stat_end_of_wave[0] == "stat_melee_damage":
				var robot_arm_value = 0
				var items = RunData.get_player_items(player_index)
				for item in items:
					if item.my_id == "item_robot_arm":
						for effect in item.effects:
							if effect.key != "stat_curse" and effect.value > 0:
								robot_arm_value += effect.value
				RunData.add_tracked_value(player_index, "item_robot_arm", robot_arm_value)
			elif stat_end_of_wave[0] == "xp_gain" and stat_end_of_wave[1] > 0:
				RunData.add_tracked_value(player_index, "item_celery_tea", stat_end_of_wave[1])
			elif stat_end_of_wave[0] == "stat_armor" and stat_end_of_wave[1] < 0:
				RunData.add_tracked_value(player_index, "item_ashes", abs(stat_end_of_wave[1]) as int)


	RunData.emit_stats_updated()

	for player_index in RunData.get_player_count():
		Utils.convert_stats(RunData.get_player_effect("convert_stats_end_of_wave", player_index), player_index)

	manage_harvesting()

	DebugService.log_data("start clean_up_room...")
	clean_up_room(is_last_wave, false, _is_run_won)

	if _is_run_won:
		apply_run_won()

	_end_wave_timer.start()
	TempStats.reset()
	InputService.hide_mouse = true


func apply_run_won() -> void :
	_wave_timer.stop()
	_wave_timer.tick_timer.stop()
	_end_wave_timer.wait_time = 3
	_ui_dim_screen.dim()
	SoundManager.play(Utils.get_rand_element(run_won_sounds), - 5, 0, true)
	RunData.apply_run_won()


func manage_harvesting() -> void :
	for player_index in RunData.get_player_count():
		var pacifist_effect = RunData.get_player_effect("pacifist", player_index)
		var cryptid_effect = RunData.get_player_effect("cryptid", player_index)
		var materials_per_living_enemy_effect = RunData.get_player_effect("materials_per_living_enemy", player_index)
		var charmed_enemy_bonus = 0

		for enemy in _entity_spawner.enemies:
			if enemy.get_charmed_by_player_index() != - 1:
				charmed_enemy_bonus += get_gold_value(EntityType.ENEMY, Entity.DieArgs.new(), enemy.stats.value)

		if Utils.get_stat("stat_harvesting", player_index) != 0 or pacifist_effect != 0 or _elite_killed_bonus != 0\
		or (cryptid_effect != 0 and RunData.current_living_trees != 0) or materials_per_living_enemy_effect != 0 or charmed_enemy_bonus > 0:
			var pacifist_bonus = round((_entity_spawner.get_all_enemies().size() + _entity_spawner.enemies_removed_for_perf) * (pacifist_effect / 100.0))
			var cryptid_bonus = RunData.current_living_trees * cryptid_effect
			var living_enemy_bonus = _entity_spawner.enemies.size() * materials_per_living_enemy_effect

			if _is_horde_wave:
				pacifist_bonus = (pacifist_bonus / 2) as int

			var val = Utils.get_stat("stat_harvesting", player_index) + pacifist_bonus + cryptid_bonus + _elite_killed_bonus + living_enemy_bonus + charmed_enemy_bonus

			if val >= 0:
				RunData.add_gold(val, player_index)
				RunData.add_xp(val, player_index)
			else:
				RunData.remove_gold(abs(val) as int, player_index)

			_floating_text_manager.on_harvested(val, player_index)

			if Utils.get_stat("stat_harvesting", player_index) > 0:
				_harvesting_timer.start()

			RunData.add_xp(0, player_index)




func _get_shuffled_live_players() -> Array:
	var live_players: = []
	for player in _players:
		if not player.dead:
			live_players.append(player)

	live_players.shuffle()
	return live_players



func _change_scene(path: String) -> void :
	var _error = get_tree().change_scene(path)


func _on_UIBonusGold_mouse_entered() -> void :
	if _cleaning_up:
		_info_popup.display(_ui_bonus_gold, Text.text("INFO_BONUS_GOLD", [str(RunData.bonus_gold)]))


func _on_UIBonusGold_mouse_exited() -> void :
	_info_popup.hide()


func _on_EntitySpawner_players_spawned(players: Array) -> void :
	_players = players
	_camera.targets = players
	_floating_text_manager.players = _players

	
	EffectBehaviorService.update_active_effect_behaviors()

	if _players.size() > 1:
		_damage_vignette.active = false

	_players_ui.clear()
	for i in _players.size():
		var effects = RunData.get_player_effects(i)

		var player_ui: = PlayerUIElements.new()
		var player_idx_string = str(i + 1)

		player_ui.player_index = i
		player_ui.player_life_bar = get_node("%%PlayerLifeBarContainerP%s/PlayerLifeBarP%s" % [player_idx_string, player_idx_string])
		player_ui.player_life_bar_container = get_node("%%PlayerLifeBarContainerP%s" % player_idx_string)
		player_ui.hud_container = get_node("%%LifeContainerP%s" % player_idx_string)
		player_ui.life_bar = get_node("%%UILifeBarP%s" % player_idx_string)
		player_ui.life_label = get_node("%%UILifeBarP%s/MarginContainer/LifeLabel" % player_idx_string)
		player_ui.xp_bar = get_node("%%UIXPBarP%s" % player_idx_string)
		player_ui.level_label = get_node("%%UIXPBarP%s/MarginContainer/LevelLabel" % player_idx_string)
		player_ui.gold = get_node("%%UIGoldP%s" % player_idx_string)

		
		player_ui.life_label.set_message_translation(false)
		player_ui.level_label.set_message_translation(false)

		_players_ui.push_back(player_ui)

		player_ui.update_hud(_players[i])
		player_ui.hud_visible = true
		player_ui.set_hud_position(i)

		_players[i].get_life_bar_remote_transform().remote_path = player_ui.player_life_bar_container.get_path()
		_players[i].current_stats.health = max(1, _players[i].max_stats.health * (effects["hp_start_wave"] / 100.0)) as int

		if effects["hp_start_next_wave"] != 100:
			_players[i].current_stats.health = max(1, _players[i].max_stats.health * (effects["hp_start_next_wave"] / 100.0)) as int
			effects["hp_start_next_wave"] = 100

		_players[i].check_hp_regen()

		_on_player_health_updated(_players[i], _players[i].current_stats.health, _players[i].max_stats.health)

		var _error_player_hp = _players[i].connect("health_updated", self, "_on_player_health_updated")
		var _error_hp_text = _players[i].connect("healed", _floating_text_manager, "_on_player_healed")
		var _error_died = _players[i].connect("died", self, "_on_player_died")
		var _error_took_damage = _players[i].connect("took_damage", _screenshaker, "_on_player_took_damage")
		var _error_on_healed = _players[i].connect("healed", self, "on_player_healed")
		var _error_on_wanted_to_spawn_gold = _players[i].connect("wanted_to_spawn_gold", self, "on_player_wanted_to_spawn_gold")

		var things_to_process_player_container: UIThingsToProcessPlayerContainer = _things_to_process_player_containers[i]
		things_to_process_player_container.show()
		var _error_ui_upgrades_mouse_entered = things_to_process_player_container.upgrades.connect("ui_element_mouse_entered", self, "on_ui_element_mouse_entered")
		var _error_ui_upgrades_mouse_exited = things_to_process_player_container.upgrades.connect("ui_element_mouse_exited", self, "on_ui_element_mouse_exited")
		var _error_ui_consumables_mouse_entered = things_to_process_player_container.consumables.connect("ui_element_mouse_entered", self, "on_ui_element_mouse_entered")
		var _error_ui_consumables_mouse_exited = things_to_process_player_container.consumables.connect("ui_element_mouse_exited", self, "on_ui_element_mouse_exited")

		connect_visual_effects(_players[i])

		var pct_val = RunData.get_player_effect("gain_pct_gold_start_wave", i)
		var apply_pct_gold_wave = (pct_val > 0 and RunData.current_wave <= RunData.nb_of_waves) or pct_val < 0

		
		
		if pct_val < 0 and RunData.current_wave > RunData.nb_of_waves:
			pct_val = - 100.0

		if apply_pct_gold_wave:
			var val = RunData.get_player_gold(i) * (pct_val / 100.0)
			RunData.add_gold(val, i)

			if pct_val > 0:
				RunData.add_tracked_value(i, "item_piggy_bank", val)

		for stat_link in RunData.get_player_effect("stat_links", i):
			if stat_link[2] == "living_enemy":
				_update_stats_on_enemies_changed_timer = Timer.new()
				_update_stats_on_enemies_changed_timer.wait_time = 1.0
				_update_stats_on_enemies_changed_timer.one_shot = true
				add_child(_update_stats_on_enemies_changed_timer)

	var temp_stats_updated: = false
	for player_index in _players.size():
		var effects = RunData.get_player_effects(player_index)
		if effects["stats_next_wave"].size() > 0:
			for stat_next_wave in effects["stats_next_wave"]:
				TempStats.add_stat(stat_next_wave[0], stat_next_wave[1], player_index)
				temp_stats_updated = true
			effects["stats_next_wave"].clear()

		if check_half_health_stats(player_index):
			temp_stats_updated = true

	if temp_stats_updated:
		RunData.emit_stats_updated()

	DebugService.log_run_info()
	RunData.reset_weapons_dmg_dealt()
	RunData.reset_weapons_tracked_value_this_wave()
	RunData.reset_wave_caches()


func _on_EntitySpawner_enemy_spawned(enemy: Enemy) -> void :
	var _error_died = enemy.connect("died", self, "_on_enemy_died")
	var _error_took_damage = enemy.connect("took_damage", self, "_on_enemy_took_damage")
	_error_took_damage = enemy.connect("took_damage", _screenshaker, "_on_unit_took_damage")
	var _error_stats_boost = enemy.connect("stats_boosted", _effects_manager, "on_unit_stats_boost")
	var _error_heal = enemy.connect("healed", _effects_manager, "on_enemy_healed")
	var _error_speed_removed = enemy.connect("speed_removed", _effects_manager, "on_enemy_speed_removed")
	var _error_state_changed = enemy.connect("state_changed", _floating_text_manager, "on_enemy_state_changed")
	connect_visual_effects(enemy)


func _on_EntitySpawner_enemy_respawned(_enemy: Enemy) -> void :
	RunData.current_living_enemies += 1

	if _update_stats_on_enemies_changed_timer != null and _update_stats_on_enemies_changed_timer.is_stopped():
		for player_index in RunData.get_player_count():
			if not LinkedStats.update_for_player_on_enemy_change[player_index]:
				continue
			reload_stats(player_index)
		_update_stats_on_enemies_changed_timer.start()


func _on_EntitySpawner_neutral_spawned(neutral: Neutral) -> void :
	var _error_died = neutral.connect("died", self, "_on_neutral_died")
	var _error_took_damage = neutral.connect("took_damage", _screenshaker, "_on_unit_took_damage")
	connect_visual_effects(neutral)


func _on_EntitySpawner_neutral_respawned(_neutral: Neutral) -> void :
	RunData.current_living_trees += 1
	for player_index in RunData.get_player_count():
		if LinkedStats.update_for_player_on_neutral_change[player_index]:
			reload_stats(player_index)


func _on_EntitySpawner_structure_spawned(structure: Structure) -> void :
	var _error_fruit = structure.connect("wanted_to_spawn_fruit", self, "on_structure_wanted_to_spawn_fruit")


func on_structure_wanted_to_spawn_fruit(pos: Vector2) -> void :
	var consumable_to_spawn = ItemService.get_consumable_for_tier(Tier.COMMON)

	var consumable: Consumable = get_node_from_pool(consumable_scene.resource_path)
	if consumable == null:
		consumable = consumable_scene.instance()
		_consumables_container.call_deferred("add_child", consumable)
		var _error = consumable.connect("picked_up", self, "on_consumable_picked_up")
		yield(consumable, "ready")

	consumable.consumable_data = consumable_to_spawn
	consumable.set_texture(consumable_to_spawn.icon)
	var dist = rand_range(100, 150)
	var push_back_destination = Vector2(rand_range(pos.x - dist, pos.x + dist), rand_range(pos.y - dist, pos.y + dist))
	consumable.drop(pos, 0, push_back_destination)
	_consumables.push_back(consumable)


func _on_HarvestingTimer_timeout() -> void :
	for player_index in RunData.get_player_count():
		var harvesting_stat = Utils.get_stat("stat_harvesting", player_index)
		if harvesting_stat <= 0:
			continue
		if RunData.current_wave > RunData.nb_of_waves:
			var val = ceil(harvesting_stat * (RunData.ENDLESS_HARVESTING_DECREASE / 100.0))
			RunData.remove_stat("stat_harvesting", val, player_index)
		else:
			var harvesting_growth = RunData.get_player_effect("harvesting_growth", player_index)
			var val = ceil(harvesting_stat * (harvesting_growth / 100.0))

			var has_crown = false
			var crown_value = 0

			var items = RunData.get_player_items(player_index)
			for item in items:
				if item.my_id == "item_crown":
					has_crown = true
					crown_value = item.effects[0].value
					break

			if has_crown:
				RunData.add_tracked_value(player_index, "item_crown", ceil(harvesting_stat * (crown_value / 100.0)) as int)

			if val > 0:
				RunData.add_stat("stat_harvesting", val, player_index)
	RunData.emit_stats_updated()


func on_player_healed(_value: int, player_index: int) -> void :
	var dmg_when_heal_effect = RunData.get_player_effect("dmg_when_heal", player_index)
	var _dmg_taken = handle_stat_damages(dmg_when_heal_effect, player_index)


func handle_stat_damages(stat_damages: Array, player_index: int) -> Array:
	var total_dmg_to_deal = 0
	var dmg_taken = [0, 0]
	var tracking_values: Dictionary = {}

	if stat_damages.empty():
		return dmg_taken

	var include_charmed_enemies = false
	var enemies: Array = _entity_spawner.get_all_enemies(include_charmed_enemies)
	var other_enemy = Utils.get_rand_element(enemies)
	if other_enemy == null or not is_instance_valid(other_enemy) or other_enemy.current_stats.health == 0:
		return dmg_taken

	var stat_dict = {}
	var percent_dmg_bonus = 1 + Utils.get_stat("stat_percent_damage", player_index) / 100.0
	for stat_dmg in stat_damages:

		if randf() >= stat_dmg[2] / 100.0:
			continue

		var dmg_dict = stat_dict.get(stat_dmg[0])
		if not dmg_dict:
			dmg_dict = {"stat": Utils.get_stat(stat_dmg[0], player_index)}
			stat_dict[stat_dmg[0]] = dmg_dict
		var dmg = dmg_dict.get(stat_dmg[1])
		if not dmg:
			var base_dmg: = floor(max(1, stat_dmg[1] / 100.0 * dmg_dict["stat"]))
			dmg = round(base_dmg * percent_dmg_bonus) as int
			dmg_dict[stat_dmg[1]] = dmg
		total_dmg_to_deal += dmg

		var tracking_key: String = stat_dmg[3] if stat_dmg.size() == 4 else ""
		if tracking_key != "":
			if tracking_key in tracking_values:
				tracking_values[tracking_key] += dmg
			else:
				tracking_values[tracking_key] = dmg

	if total_dmg_to_deal <= 0:
		return dmg_taken

	var args = TakeDamageArgs.new(player_index)
	dmg_taken = other_enemy.take_damage(total_dmg_to_deal, args)

	var remaining_damage_to_track: int = dmg_taken[1]
	for tracking_key in tracking_values.keys():
		var tracking_value = tracking_values[tracking_key]

		if tracking_value <= remaining_damage_to_track:
			RunData.add_tracked_value(player_index, tracking_key, tracking_value)
			remaining_damage_to_track -= tracking_value

		else:
			RunData.add_tracked_value(player_index, tracking_key, remaining_damage_to_track)
			break

	return dmg_taken


func check_half_health_stats(player_index: int) -> bool:
	var stats_below_half_health = RunData.get_player_effect("stats_below_half_health", player_index)
	if stats_below_half_health.size() == 0:
		return false

	var current_val = _players[player_index].current_stats.health
	var max_val = _players[player_index].max_stats.health
	var stats_updated: = false
	if current_val < (max_val / 2.0) and not _player_is_under_half_health[player_index]:
		_player_is_under_half_health[player_index] = true
		for stat in stats_below_half_health:
			TempStats.add_stat(stat[0], stat[1], player_index)
			RunData.emit_signal("stat_added", stat[0], stat[1], 0.0, player_index)
			stats_updated = true
	elif current_val >= max_val / 2.0 and _player_is_under_half_health[player_index]:
		_player_is_under_half_health[player_index] = false
		for stat in stats_below_half_health:
			TempStats.remove_stat(stat[0], stat[1], player_index)
			RunData.emit_signal("stat_removed", stat[0], stat[1], 0.0, player_index)
			stats_updated = true
	return stats_updated


func _on_player_health_updated(player: Player, current_val: int, max_val: int) -> void :
	var player_index = player.player_index
	RunData.players_data[player_index].current_health = current_val

	if player.player_index == 0 and not RunData.is_coop_run:
		_damage_vignette.update_from_hp(current_val, max_val)

	if check_half_health_stats(player_index):
		RunData.emit_stats_updated()

	var player_ui: PlayerUIElements = _players_ui[player_index]
	var life_bar = player_ui.life_bar
	life_bar.update_value(current_val, max_val)

	var player_life_bar = player_ui.player_life_bar
	player_life_bar.visible = ProgressData.settings.hp_bar_on_character and current_val != max_val and not player.dead
	if player_life_bar.visible:
		player_life_bar.update_value(current_val, max_val)

	player_ui.update_life_label(player)


func on_gold_changed(new_value: int, player_index: int) -> void :
	var player_ui: PlayerUIElements = _players_ui[player_index]
	player_ui.gold.update_value(new_value)

	if LinkedStats.should_update_on_gold_change(player_index, _last_gold_amount_used_to_reload_stats[player_index], new_value):
		reload_stats(player_index)
		_last_gold_amount_used_to_reload_stats[player_index] = new_value


func on_damage_effect(value: int, player_index: int, armor_applied: bool, dodgeable: bool) -> void :
	_players[player_index].on_damage_effect(value, armor_applied, dodgeable)


func on_lifesteal_effect(value: int, player_index: int) -> void :
	var player: Player = _players[player_index]
	player.on_lifesteal_effect(value)


func on_healing_effect(value: int, player_index: int, tracking_key: String = "") -> void :
	_players[player_index].on_healing_effect(value, tracking_key)


func on_heal_over_time_effect(total_healing: int, duration: int, player_index: int) -> void :
	_players[player_index].on_heal_over_time_effect(total_healing, duration)


func on_chal_popup() -> void :
	_is_chal_ui_displayed = true


func on_chal_popout() -> void :
	_is_chal_ui_displayed = false


func _on_HalfSecondTimer_timeout() -> void :
	for player_index in RunData.players_data.size():
		if LinkedStats.update_for_player_every_half_sec[player_index]:
			LinkedStats.reset_player(player_index)
			RunData.emit_stats_updated()

	ChallengeService.try_complete_challenge("chal_barbecue", _entity_spawner.get_number_of_burning_enemies())


func _on_game_lost_focus() -> void :
	if not _retry_wave.visible:
		_pause_menu.on_game_lost_focus()


func get_node_from_pool(filename: String) -> Node:
	if _pool.has(filename):
		return _pool[filename].pop_back()
	else:
		_pool[filename] = []
		return null


func add_node_to_pool(node: Node) -> void :
	if _pool.has(node.filename):
		call_deferred("_add_node_to_pool", node)
	else:
		node.queue_free()



func _add_node_to_pool(node: Node) -> void :
	_pool[node.filename].push_back(node)


func add_explosion(instance: PlayerExplosion) -> void :
	_explosions.add_child(instance)


func add_effect(instance: Node) -> void :
	_effects.add_child(instance)


func add_floating_text(instance: FloatingText) -> void :
	_floating_texts.add_child(instance)


func add_player_projectile(instance: PlayerProjectile) -> void :
	_player_projectiles.add_child(instance)


func add_enemy_projectile(instance: Projectile) -> void :
	_enemy_projectiles.add_child(instance)


func add_birth(instance: EntityBirth) -> void :
	_births_container.add_child(instance)


func add_entity(instance: Entity) -> void :
	_entities_container.add_child(instance)


func _exit_tree() -> void :
	InputService.set_gamepad_echo_processing(true)
