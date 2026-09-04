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
	# Comic-book impact burst with dust puffs instead of a neon shock ring.
	for puff in range(5):
		var puff_angle := TAU * float(puff) / 5.0 + float(seed_value % 9) * 0.08
		var puff_at := Vector2.from_angle(puff_angle) * size * t * 0.42
		draw_circle(puff_at, size * (0.18 - t * 0.08), Color(tint.lightened(0.28), alpha * 0.55))
	for i in range(spokes):
		var angle := TAU * float(i) / float(spokes) + float(seed_value % 17) * 0.1
		var inner: Vector2 = Vector2.from_angle(angle) * size * t * 0.25
		var outer: Vector2 = Vector2.from_angle(angle) * size * t * (0.75 + float((i * 7) % 5) * 0.08)
		draw_line(inner, outer, Color("40354f", alpha), 4.0, true)
		draw_line(inner, outer, Color(tint, alpha), 2.0, true)
