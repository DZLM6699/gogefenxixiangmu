extends Label


func add_color_override(name: String, color: Color) -> void :
	if name == "font_color":
		
		return
	.add_color_override(name, color)


func add_font_override(name: String, font: Font) -> void :
	if name == "font":
		
		return
	.add_font_override(name, font)
