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
	draw_rect(Rect2(Vector2.ZERO, view), Color("101211"))
	# An off-center eclipse gives the title its own quiet, readable space.
	var moon := Vector2(view.x * 0.735, view.y * 0.40)
	var radius := view.y * 0.265
	draw_circle(moon, radius, Color("a44c3f"))
	draw_circle(moon + Vector2(-27, -17), radius - 10, Color("101211"))
	draw_arc(moon, radius + 19, -0.9, 1.5, 96, Color("514035"), 1.0, true)
	# Dry hatch marks and distant trunks, kept behind the illustration.
	for i in range(32):
		var x := view.x * 0.50 + i * 22
		var height := 60.0 + fmod(float(i * 79), 160.0)
		draw_line(Vector2(x, view.y - 130), Vector2(x - 15, view.y - 130 - height), Color("242921"), 1, true)
	for i in range(5):
		var at := Vector2(view.x * 0.60 + i * 108, view.y - 125)
		Motifs.tree(self, at, 190 + i % 3 * 54, -40)
	Motifs.watcher(self, Vector2(view.x * 0.775, view.y - 110), 335, sin(age * 0.18) * 0.25)
	# A single red registration mark anchors the title column.
	draw_line(Vector2(88, 116), Vector2(128, 116), Color("bb5545"), 3, true)
