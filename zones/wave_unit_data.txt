class_name WaveUnitData
extends Resource

enum Type{PLAYER, ENEMY, NEUTRAL, STRUCTURE, BOSS}

export (Type) var type = Type.ENEMY
export (PackedScene) var unit_scene: PackedScene = null
export (int) var min_number = 1
export (int) var max_number = 1
export (float) var spawn_chance = 1.0
export (float) var additional_min_distance_from_player = 0.0
