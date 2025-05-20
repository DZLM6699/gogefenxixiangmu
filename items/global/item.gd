class_name Item
extends Area2D

const INITIAL_ATTRACT_SPEED: float = 500.0
const ATTRACT_ACCELERATION: float = 20.0

signal picked_up(item, player_index)

var push_back: = true
var push_back_destination: = Vector2(0, 0)
var attracted_by: Node2D
var idle_time_after_pushed_back: = 10.0

var _push_back_speed: = 5
var _current_speed: = INITIAL_ATTRACT_SPEED

onready var sprite = $Sprite as Sprite


func _ready() -> void :
	reset()


func reset() -> void :
	hide()
	set_deferred("monitorable", false)
	set_physics_process(false)
	scale = Vector2(1.0, 1.0)
	push_back = true
	push_back_destination = Vector2(0, 0)
	attracted_by = null
	idle_time_after_pushed_back = 10.0
	_push_back_speed = 5
	_current_speed = INITIAL_ATTRACT_SPEED


func drop(pos: Vector2, p_rotation: float, p_push_back_destiation: Vector2) -> void :
	global_position = pos
	rotation = p_rotation
	push_back_destination = p_push_back_destiation
	show()
	set_physics_process(true)


func set_texture(texture: Resource) -> void :
	if sprite != null:
		sprite.texture = texture


func _physics_process(delta: float) -> void :
	if push_back and global_position.distance_to(push_back_destination) > 20:
		global_position = global_position.linear_interpolate(push_back_destination, delta * _push_back_speed)
	elif idle_time_after_pushed_back > 0:
		if not monitorable:
			monitorable = true
		push_back = false
		idle_time_after_pushed_back -= Utils.physics_one(delta)
	elif attracted_by != null:
		if "dead" in attracted_by and attracted_by.dead:
			attracted_by = null
			_current_speed = INITIAL_ATTRACT_SPEED
		else:
			global_position = global_position.move_toward(attracted_by.global_position, delta * _current_speed)
			_current_speed += ATTRACT_ACCELERATION


func pickup(player_index: int) -> void :
	emit_signal("picked_up", self, player_index)
	reset()
