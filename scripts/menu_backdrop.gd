extends Control

# Quiet scenery behind the title character; never competes with menu labels.
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var s := size / Vector2(1280, 720)
	draw_rect(Rect2(Vector2(690, 0) * s, Vector2(590, 720) * s), Color("141f23"))
	for path in [
		[Vector2(1160, 720), Vector2(1144, 508), Vector2(1214, 330), Vector2(1180, 136), Vector2(1220, 0)],
		[Vector2(1214, 330), Vector2(1080, 220), Vector2(1030, 40)],
		[Vector2(1144, 508), Vector2(1280, 420)],
		[Vector2(760, 0), Vector2(790, 110), Vector2(720, 230)],
	]:
		var points := PackedVector2Array()
		for point in path:
			points.append(point * s)
		draw_polyline(points, Color("203036"), 12.0 * s.x, true)
	draw_line(Vector2(710, 609) * s, Vector2(1216, 609) * s, Color("3a4a4c"), 1.0, true)
