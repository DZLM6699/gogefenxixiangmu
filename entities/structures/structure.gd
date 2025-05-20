class_name Structure
extends Entity

signal wanted_to_spawn_fruit(pos)

export (Resource) var curse_particles
export (bool) var to_be_removed_in_priority = false

onready var _muzzle = $Animation / Muzzle

var base_stats: Resource
var stats: Resource
var effects: Array = []
var player_index = - 1
var is_cursed: = false
var curse_particle_instance


func _ready() -> void :
	if is_cursed:
		add_curse_particles()


func respawn() -> void :
	.respawn()
	if is_cursed:
		add_curse_particles()


func set_data(data: Resource) -> void :
	base_stats = data.stats
	effects = data.effects
	reload_data()

	is_cursed = data.is_cursed


func reload_data() -> void :
	var args: = WeaponServiceInitStatsArgs.new()
	args.effects = effects
	stats = WeaponService.init_structure_stats(base_stats, player_index, args)


func add_curse_particles() -> void :
	curse_particle_instance = curse_particles.instance()
	_muzzle.add_child(curse_particle_instance)


func die(args: = DieArgs.new()) -> void :
	if curse_particle_instance:
		curse_particle_instance.queue_free()
	.die(args)
