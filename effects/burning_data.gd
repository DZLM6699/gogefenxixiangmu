class_name BurningData
extends Resource

export (float) var chance: = 0.0
export (int) var damage: = 0
export (int) var duration: = 0
export (int) var spread: = 0
export (Array, Array) var scaling_stats = [["stat_elemental_damage", 1.0]]
export (bool) var is_global_burn: = false

var from: Node = null


func merge(p_burning_data: BurningData) -> void :
	chance += p_burning_data.chance
	damage += p_burning_data.damage
	duration = int(max(duration, p_burning_data.duration))
	spread += p_burning_data.spread


func remove(p_burning_data: BurningData) -> void :
	chance -= p_burning_data.chance
	damage -= p_burning_data.damage
	duration -= p_burning_data.duration
	spread -= p_burning_data.spread


func serialize() -> Dictionary:
	return {
		"chance": chance, 
		"damage": damage, 
		"duration": duration, 
		"spread": spread, 
		"scaling_stats": scaling_stats, 
		"is_global_burn": is_global_burn
	}


func deserialize_and_merge(serialized: Dictionary) -> void :
	chance = serialized.chance
	damage = serialized.damage as int
	duration = serialized.duration as int
	spread = serialized.spread as int
	scaling_stats = serialized.get("scaling_stats", [])
	is_global_burn = serialized.get("is_global_burn", false)

	if scaling_stats.size() == 0:
		_convert_burning_type_to_scaling_stats(serialized)


func _convert_burning_type_to_scaling_stats(serialized: Dictionary) -> void :
	
	var burning_type_elemental = 0
	var burning_type_engineering = 1
	var type = serialized.get("type")
	if type == burning_type_elemental:
		scaling_stats = [["stat_elemental_damage", 1.0]]
	if type == burning_type_engineering:
		scaling_stats = [["stat_engineering", 0.33]]


func is_not_burning() -> bool:
	return chance == 0.0 and damage == 0 and duration == 0 and spread == 0


func duplicate(subresources: = false) -> Resource:
	var duplication: = .duplicate(subresources)
	duplication.from = self.from
	return duplication
