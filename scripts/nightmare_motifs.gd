extends RefCounted

# Background decoration only: muted colors and no collision or gameplay signals.
static func eye(canvas: CanvasItem, at: Vector2, span: float, color: Color, tilt: float = 0.0) -> void:
	var outline := PackedVector2Array()
	for index in range(33):
		var angle := TAU * index / 32.0
		var offset := Vector2(cos(angle) * span, sin(angle) * span * 0.34)
		outline.append(at + offset.rotated(tilt))
	canvas.draw_colored_polygon(outline, Color("0c101b"))
	canvas.draw_polyline(outline, color, 2.0, true)
	canvas.draw_circle(at, span * 0.23, color)
	canvas.draw_line(at + Vector2(0, -span * 0.19).rotated(tilt), at + Vector2(0, span * 0.19).rotated(tilt), Color("090c16"), maxf(2.0, span * 0.1), true)
	for index in range(5):
		var x := float(index - 2) * span * 0.3
		var start := Vector2(x, -span * 0.34 * sqrt(1.0 - pow(x / span, 2)))
		canvas.draw_line(at + start.rotated(tilt), at + (start + Vector2(x * 0.15, -span * 0.22)).rotated(tilt), color, 1.5, true)

static func tree(canvas: CanvasItem, at: Vector2, height: float, lean: float) -> void:
	var trunk := PackedVector2Array([
		at + Vector2(-height * 0.15, 5), at + Vector2(-height * 0.045, -height * 0.38),
		at + Vector2(lean - height * 0.05, -height * 0.73), at + Vector2(lean * 0.7, -height),
		at + Vector2(lean + height * 0.045, -height * 0.68), at + Vector2(height * 0.055, -height * 0.35),
		at + Vector2(height * 0.2, 9),
	])
	canvas.draw_colored_polygon(trunk, Color("10121f"))
	canvas.draw_polyline(PackedVector2Array([trunk[1], trunk[2], trunk[3]]), Color("344151"), 3.0, true)
	for side in [-1.0, 1.0]:
		var branch := PackedVector2Array([
			at + Vector2(lean * 0.7, -height * 0.58),
			at + Vector2(side * height * 0.29, -height * 0.72),
			at + Vector2(side * height * 0.34, -height * 0.95),
			at + Vector2(side * height * 0.22, -height * 1.07),
		])
		canvas.draw_polyline(branch, Color("111522"), height * 0.045, true)
		canvas.draw_polyline(PackedVector2Array([branch[1], branch[1] + Vector2(side * height * 0.19, -height * 0.05), branch[1] + Vector2(side * height * 0.26, -height * 0.19)]), Color("111522"), height * 0.028, true)
		canvas.draw_line(at, at + Vector2(side * height * 0.35, height * 0.12), Color("121724"), height * 0.03, true)
	eye(canvas, at + Vector2(lean * 0.5, -height * 0.48), height * 0.07, Color("526271"), -0.12)

static func spiral(canvas: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(97):
		var progress := float(index) / 96.0
		points.append(at + Vector2.from_angle(progress * TAU * 2.5) * radius * progress)
	canvas.draw_polyline(points, color, 2.0, true)

static func watcher(canvas: CanvasItem, at: Vector2, height: float, gaze: float = 0.0) -> void:
	var width := height * 0.18
	canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-width, 0), at + Vector2(-width * 0.6, -height * 0.7), at + Vector2(0, -height), at + Vector2(width * 0.6, -height * 0.7), at + Vector2(width, 0)]), Color("080b11"))
	canvas.draw_line(at + Vector2(-width * 0.45, -height * 0.66), at + Vector2(-width * 1.55, -height * 0.17), Color("0a0d13"), width * 0.35, true)
	canvas.draw_line(at + Vector2(width * 0.45, -height * 0.66), at + Vector2(width * 1.8, -height * 0.05), Color("0a0d13"), width * 0.3, true)
	var face := at + Vector2(gaze * 3.0, -height * 0.77)
	canvas.draw_colored_polygon(PackedVector2Array([face + Vector2(-width * 0.33, -height * 0.075), face + Vector2(width * 0.33, -height * 0.085), face + Vector2(width * 0.2, height * 0.08), face + Vector2(0, height * 0.13), face + Vector2(-width * 0.2, height * 0.07)]), Color("34373e"))
	for side in [-1.0, 1.0]:
		canvas.draw_line(face + Vector2(side * width * 0.18, -height * 0.01), face + Vector2(side * width * 0.12, height * 0.04), Color("08090f"), width * 0.12, true)
	canvas.draw_line(face + Vector2(0, height * 0.04), face + Vector2(0, height * 0.1), Color("090a10"), width * 0.1, true)
