class_name MyTileMap
extends TileMap

onready var outline = $Outline


func init(zone: ZoneData) -> void :
	outline.rect_size = Vector2(Utils.TILE_SIZE * (zone.width + 2), Utils.TILE_SIZE * (zone.height + 2))
	for i in zone.width:
		for j in zone.height:
			my_set_cell(i, j)


func my_set_cell(x: int, y: int) -> void :
	set_cell(x, y, 0, false, false, false, get_subtile_with_priority())


func get_subtile_with_priority() -> Vector2:
	var rect = tile_set.tile_get_region(0)
	var size_x = rect.size.x / tile_set.autotile_get_size(0).x
	var size_y = rect.size.y / tile_set.autotile_get_size(0).y
	var tile_array = []

	for x in size_x:
		for y in size_y:
			var priority = tile_set.autotile_get_subtile_priority(0, Vector2(x, y))
			for p in priority:
				tile_array.append(Vector2(x, y))

	return tile_array[Utils.randi() % tile_array.size()]
