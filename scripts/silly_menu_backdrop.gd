extends Control

const Motifs = preload("res://scripts/nightmare_motifs.gd")
var age := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if is_visible_in_tree():
		age += delta
		queue_redraw()

func _draw() -> void:
	var view := size
	var center := Vector2(view.x * 0.5, view.y * 0.45)
	draw_rect(Rect2(Vector2.ZERO, view), Color("06090f"))
	# An eclipse hangs over a corridor with no consistent vanishing point.
	for ring in range(18, 0, -1):
		draw_circle(Vector2(center.x, 130), 98 + ring * 6, Color(0.24, 0.12, 0.18, 0.015))
	draw_circle(Vector2(center.x, 130), 96, Color("7a555b"))
	draw_circle(Vector2(center.x - 4, 123), 94, Color("06090f"))
	Motifs.eye(self, Vector2(center.x, 132), 45, Color("856969"), -0.04)
	for side in [-1.0, 1.0]:
		for i in range(7):
			var x: float = center.x + side * (100 + i * 87)
			var top := Vector2(x, -40)
			var bottom := Vector2(x + side * (30 + i * 11), view.y)
			draw_line(top, bottom, Color("10131c"), 20 + i * 8, true)
			draw_line(top + Vector2(side * 12, 0), bottom + Vector2(side * 12, 0), Color("23202b"), 1, true)
		for i in range(6):
			var end := Vector2(center.x + side * (90 + i * 145), view.y)
			draw_line(center + Vector2(side * 25, 100), end, Color("1e1b25"), 1, true)
	for i in range(12):
		var y := 420.0 + pow(float(i) / 11.0, 1.6) * 300
		draw_line(Vector2(0, y), Vector2(view.x, y - 12), Color("171923"), 1, true)
	Motifs.watcher(self, Vector2(160, view.y - 35), 410, sin(age * 0.22))
	Motifs.watcher(self, Vector2(view.x - 150, view.y - 25), 480, -sin(age * 0.19))
	for side in [-1.0, 1.0]:
		for i in range(4):
			var at := Vector2(center.x + side * (380 + i * 72), view.y + 25)
			Motifs.tree(self, at, 230 + i * 48, -side * 75)
	# Thin hanging threads move slowly; the controls remain still and unobscured.
	for i in range(13):
		var x := 40.0 + i * (view.x - 80) / 12.0
		if absf(x - center.x) < 220:
			continue
		var end := Vector2(x + sin(age * 0.26 + i) * 9, 100 + posmod(i * 97, 200))
		draw_line(Vector2(x, 0), end, Color("3a303a"), 1, true)
		Motifs.eye(self, end, 11 + i % 3 * 4, Color("62535e"), sin(age * 0.15 + i) * 0.2)
	for i in range(7):
		var y := view.y * 0.65 + i * 27 + sin(age * 0.17 + i) * 14
		var fog := PackedVector2Array()
		for x in range(-30, int(view.x) + 60, 32):
			fog.append(Vector2(x, y + sin(x * 0.006 + age * 0.12 + i) * 24))
		draw_polyline(fog, Color(0.35, 0.39, 0.43, 0.025), 36, true)
	for edge in range(10):
		var inset := float(edge * 6)
		draw_rect(Rect2(inset, inset, view.x - inset * 2, view.y - inset * 2), Color(0, 0, 0, 0.08), false, 12)
