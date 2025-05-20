class_name Gold
extends Item

const INITIAL_VALUE: int = 1
const MAX_SIZE: float = 2.0

var boosted: = 1
var value: = INITIAL_VALUE


func reset() -> void :
	.reset()
	value = INITIAL_VALUE
	boosted = 1
