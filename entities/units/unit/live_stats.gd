class_name LiveStats

var health: int
var speed: int
var damage: int
var armor: int = 0
var dodge: float = 0.0


func copy(live_stats: LiveStats, set_health: bool = true) -> void :
	if set_health: health = live_stats.health
	speed = live_stats.speed
	damage = live_stats.damage
	armor = live_stats.armor
	dodge = live_stats.dodge


func copy_stats(stats: Stats) -> void :
	health = stats.health
	speed = stats.speed
	damage = stats.damage
