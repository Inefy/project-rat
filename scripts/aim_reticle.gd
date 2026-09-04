extends Node2D

var enabled := false
var pulse := 0.0

func _process(delta: float) -> void:
	pulse += delta
	visible = enabled
	if enabled:
		global_position = get_global_mouse_position()
		queue_redraw()

func _draw() -> void:
	var gap := 8.0 + sin(pulse * 5.0) * 1.5
	var color := Color("d95863")
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color("fff4d6"), 4.0, true)
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, color, 2.0, true)
	for pair in [[Vector2(-gap - 7, 0), Vector2(-gap, 0)], [Vector2(gap, 0), Vector2(gap + 7, 0)], [Vector2(0, -gap - 7), Vector2(0, -gap)], [Vector2(0, gap), Vector2(0, gap + 7)]]:
		draw_line(pair[0], pair[1], Color("40354f"), 4.5, true)
		draw_line(pair[0], pair[1], color, 2.0, true)
	draw_circle(Vector2.ZERO, 2.4, Color("40354f"))
