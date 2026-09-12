extends Node2D

const Motifs = preload("res://scripts/nightmare_motifs.gd")
var age := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("run_entities")
	z_index = 3

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _draw() -> void:
	# All atmosphere sits under actors, hazards and the player's light trail.
	for i in range(9):
		var points := PackedVector2Array()
		for x in range(-1200, 1240, 40):
			points.append(Vector2(x, -630 + i * 155 + sin(x * 0.004 + age * 0.12 + i) * 42))
		draw_polyline(points, Color(0.26, 0.31, 0.35, 0.045), 46, true)
	for i in range(6):
		var at := Vector2(-960 + i * 380, -380 if i % 2 == 0 else 520)
		Motifs.watcher(self, at, 230 + i % 3 * 55, sin(age * 0.17 + i))
	for i in range(5):
		var at := Vector2(-880 + i * 420, 250 if i % 2 == 0 else -230)
		var drift := Vector2(sin(age * 0.2 + i) * 8, cos(age * 0.13 + i) * 5)
		Motifs.eye(self, at + drift, 34, Color("3e414d"), sin(age * 0.12 + i) * 0.2)
