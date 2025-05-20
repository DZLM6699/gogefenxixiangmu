class_name ItemAttractArea
extends Area2D

const BASE_RADIUS = 150

func apply_pickup_range_effect(pickup_range: int) -> void :
	$CollisionShape2D.shape.radius = max(30, BASE_RADIUS * (1.0 + (pickup_range / 100.0)))
