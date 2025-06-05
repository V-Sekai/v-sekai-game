extends TextureRect


func start_tween():
	var tween = self.create_tween()

	tween.tween_property(self, "rotation_degrees", rotation_degrees + 180, 8.0).set_trans(
		Tween.TRANS_QUAD
	)

	tween.chain().tween_property(self, "rotation_degrees", rotation_degrees + 360, 8.0).set_trans(
		Tween.TRANS_QUAD
	)

	tween.set_speed_scale(1.0)

	# infinite
	tween.finished.connect(start_tween)


func _ready():
	pivot_offset = (size / 2) + Vector2(0, 30)
	start_tween()

# DEBUG PIVOT: Draw red dot
#func _draw():
#	var pivot_pos = pivot_offset
#		draw_circle(pivot_pos, 3, Color(1, 0, 0))
