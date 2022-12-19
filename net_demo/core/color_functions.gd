static func get_color(p_x: float) -> Color:
	var r: float = 0.0
	var g: float = 0.0
	var b: float = 1.0
	if (p_x >= 0.0 and p_x < 0.2):
		p_x = p_x / 0.2
		r = 0.0
		g = p_x
		b = 1.0
	elif (p_x >= 0.2 and p_x < 0.4):
		p_x = (p_x - 0.2) / 0.2
		r = 0.0
		g = 1.0
		b = 1.0 - p_x
	elif (p_x >= 0.4 and p_x < 0.6):
		p_x = (p_x - 0.4) / 0.2
		r = p_x
		g = 1.0
		b = 0.0
	elif (p_x >= 0.6 and p_x < 0.8):
		p_x = (p_x - 0.6) / 0.2
		r = 1.0
		g = 1.0 - p_x
		b = 0.0
	elif (p_x >= 0.8 and p_x <= 1.0):
		p_x = (p_x - 0.8) / 0.2
		r = 1.0
		g = 0.0
		b = p_x
	return Color(r, g, b);

static func get_list_of_colors(p_count: int) -> PackedColorArray:
	var colors: PackedColorArray = PackedColorArray()
	if (p_count < 2):
		return PackedColorArray([Color(0.0, 0.0, 1.0)])
	var dx: float = 1.0 / float(p_count - 1)
	for i in range(0, p_count + 1):
		var color: Color = get_color(i * dx)
		assert(colors.append(color) == false)
		
	return colors
