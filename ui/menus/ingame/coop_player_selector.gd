extends Carousel


func _ready():
	for child in _headings.get_children():
		if child.player_index >= RunData.get_player_count():
			_headings.remove_child(child)
			child.queue_free()
