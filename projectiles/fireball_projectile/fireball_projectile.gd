class_name FireballProjectile
extends PlayerProjectile

onready var burning_particles = $BurningParticles


func stop() -> void :
	.stop()

	burning_particles.emitting = false
