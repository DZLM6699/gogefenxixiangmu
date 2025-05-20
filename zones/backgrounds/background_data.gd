class_name BackgroundData
extends Resource

export (String) var name = ""
export (Resource) var icon = null
export (Color) var outline_color = Color.white
export (Resource) var tiles_sprite = null


func get_tiles_sprite() -> Resource:
				return SkinManager.get_skin(tiles_sprite)
