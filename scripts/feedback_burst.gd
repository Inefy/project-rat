extends Node2D

var tint := Color.WHITE
var kind := "pickup"
var elapsed := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("run_entities")
	z_index = 35

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= 0.85:
		queue_free()

func _draw() -> void:
	var t := clampf(elapsed / 0.85, 0, 1)
	var alpha := pow(1.0 - t, 1.5)
	var radius := 28.0 + sqrt(t) * (100.0 if kind == "pickup" else 82.0)
	draw_circle(Vector2.ZERO, 50 + t * 24, Color(tint, alpha * 0.18))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(tint, alpha * 0.85), 5.0 * (1.0 - t) + 1.0, true)
	draw_arc(Vector2.ZERO, radius * 0.68, 0, TAU, 64, Color(tint.lightened(0.5), alpha * 0.65), 2.5, true)
	for i in range(12):
		var direction := Vector2.from_angle(TAU * i / 12.0 + 0.15)
		var at := direction * radius
		if kind == "pickup":
			at.y -= t * 60.0
			var span := (1.0 - t) * 8.0
			draw_line(at - Vector2(span, 0), at + Vector2(span, 0), Color(tint.lightened(0.6), alpha), 2, true)
			draw_line(at - Vector2(0, span), at + Vector2(0, span), Color(tint.lightened(0.6), alpha), 2, true)
		else:
			draw_line(direction * radius * 0.68, direction * (radius + 20.0 * (1.0 - t)), Color(tint, alpha), 4, true)
