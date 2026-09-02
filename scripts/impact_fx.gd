extends Node2D

var tint := Color.WHITE
var duration := 0.45
var elapsed := 0.0
var size := 32.0
var spokes := 9
var seed_value := 0

func setup(at: Vector2, color: Color, effect_size: float = 32.0, effect_duration: float = 0.45) -> void:
	global_position = at
	tint = color
	size = effect_size
	duration = effect_duration
	seed_value = int(at.x * 13.0 + at.y * 7.0) & 0xffff

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		queue_free()

func _draw() -> void:
	var t: float = clampf(elapsed / duration, 0.0, 1.0)
	var alpha: float = (1.0 - t) * (1.0 - t)
	draw_circle(Vector2.ZERO, size * t, Color(tint, alpha * 0.08))
	draw_arc(Vector2.ZERO, size * t, 0.0, TAU, 32, Color(tint, alpha * 0.7), 3.0 * (1.0 - t) + 0.5, true)
	for i in range(spokes):
		var angle := TAU * float(i) / float(spokes) + float(seed_value % 17) * 0.1
		var inner: Vector2 = Vector2.from_angle(angle) * size * t * 0.25
		var outer: Vector2 = Vector2.from_angle(angle) * size * t * (0.75 + float((i * 7) % 5) * 0.08)
		draw_line(inner, outer, Color(tint, alpha), 2.0, true)
