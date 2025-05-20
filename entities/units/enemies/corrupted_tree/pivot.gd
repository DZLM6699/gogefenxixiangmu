class_name Pivot
extends Node2D

export (float) var rotation_speed = PI
export (float) var start_rotation = 0.0

var direction: float


func _ready():
	direction = Utils.get_rand_element([ - 1, 1])
	rotation = deg2rad(start_rotation)


func _physics_process(delta: float) -> void :
	rotation += direction * rotation_speed * RunData.current_run_accessibility_settings.speed * delta


func _on_Enemy_died(_entity, _args: Entity.DieArgs) -> void :
	queue_free()
