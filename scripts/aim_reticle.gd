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
	var color := Color("62fff1")
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color(color, 0.55), 1.5, true)
	draw_line(Vector2(-gap - 7, 0), Vector2(-gap, 0), color, 2.0, true)
	draw_line(Vector2(gap, 0), Vector2(gap + 7, 0), color, 2.0, true)
	draw_line(Vector2(0, -gap - 7), Vector2(0, -gap), color, 2.0, true)
	draw_line(Vector2(0, gap), Vector2(0, gap + 7), color, 2.0, true)
	draw_circle(Vector2.ZERO, 2.0, Color.WHITE)

