class_name BurningParticles
extends CPUParticles2D

export (Resource) var red_gradient
export (Resource) var blue_gradient

onready var _collision = $SpreadArea / CollisionShape2D

var burning_data: BurningData
var bodies = []
var emit_remaining: = 0.0


func _physics_process(delta: float) -> void :
	
	
	
	if visible and not emitting:
		if emit_remaining == 0.0:
			emit_remaining = lifetime * 1.2
		else:
			emit_remaining -= delta
			if emit_remaining < 0.0:
				emit_remaining = 0.0
				visible = false
	else:
		emit_remaining = 0.0

	if _collision.disabled: return

	if burning_data != null and burning_data.spread > 0 and bodies.size() > 0:
		for body in bodies:
			if is_instance_valid(body) and not body.dead and not body._is_burning:
				burning_data.spread = max(0, burning_data.spread - 1) as int
				body.apply_burning(burning_data)
				burning_data.spread = 0
				deactivate_spread()
				break


func start_emitting() -> void :
	emitting = true
	visible = true
	_update_color()


func _update_color() -> void :
	if burning_data != null:
		var first_scaling_stat = Utils.get_first_scaling_stat(burning_data.scaling_stats)
		if first_scaling_stat == "stat_elemental_damage":
			color_ramp = red_gradient
		if first_scaling_stat == "stat_engineering":
			color_ramp = blue_gradient


func activate_spread() -> void :
	_collision.set_deferred("disabled", false)


func deactivate_spread() -> void :
	_collision.set_deferred("disabled", true)


func _on_SpreadArea_body_entered(body: Node) -> void :
	if is_instance_valid(body) and not body.dead and body != get_parent():
		bodies.push_back(body)


func _on_SpreadArea_body_exited(body: Node) -> void :
	bodies.erase(body)
