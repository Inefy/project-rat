extends Control

var age := 0.0

const INK := Color("321f2b")
const NIGHT_GRASS := Color("29452e")
const MOSS := Color("3f6538")
const CREAM := Color("fff0bf")
const CHEESE := Color("f6c53f")
const TOMATO := Color("df5144")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _draw() -> void:
	var view := size
	draw_rect(Rect2(Vector2.ZERO, view), NIGHT_GRASS, true)
	# Crooked mowing stripes and a warm spotlight make the title feel like a poster.
	for index in range(9):
		var x := -90.0 + index * (view.x + 180.0) / 8.0
		var stripe := PackedVector2Array([
			Vector2(x, 0), Vector2(x + 115, 0),
			Vector2(x + 250, view.y), Vector2(x + 90, view.y),
		])
		draw_colored_polygon(stripe, Color(0.38, 0.58, 0.27, 0.13 if index % 2 == 0 else 0.06))
	draw_circle(Vector2(view.x * 0.5, 250), 390.0, Color(0.85, 0.70, 0.30, 0.07))

	# The wonky signboard sits behind the live title copy.
	var sign := PackedVector2Array([
		Vector2(view.x * 0.5 - 390, 118), Vector2(view.x * 0.5 + 370, 105),
		Vector2(view.x * 0.5 + 405, 345), Vector2(view.x * 0.5 - 375, 362),
	])
	draw_colored_polygon(sign, Color(0.08, 0.05, 0.06, 0.35))
	draw_set_transform(Vector2(0, -9), 0.0, Vector2.ONE)
	draw_colored_polygon(sign, Color("8b542f"))
	draw_polyline(PackedVector2Array([sign[0], sign[1], sign[2], sign[3], sign[0]]), INK, 8.0, true)
	for y in [168.0, 235.0, 305.0]:
		draw_line(Vector2(view.x * 0.5 - 355, y), Vector2(view.x * 0.5 + 355, y - 9), Color(0.23, 0.10, 0.08, 0.28), 5.0, true)
	for nail in [Vector2(view.x * 0.5 - 342, 144), Vector2(view.x * 0.5 + 338, 132), Vector2(view.x * 0.5 - 330, 326), Vector2(view.x * 0.5 + 350, 315)]:
		draw_circle(nail, 7.0, INK)
		draw_circle(nail - Vector2(2, 2), 3.0, Color("c9b38b"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	_draw_trash_can(Vector2(105, view.y - 56), -0.12)
	_draw_cheese(Vector2(view.x - 110, view.y - 82), 1.18)
	_draw_splat(Vector2(180, 105), 34.0, Color(0.18, 0.11, 0.08, 0.42))
	_draw_splat(Vector2(view.x - 170, 82), 24.0, Color(0.18, 0.11, 0.08, 0.32))

	# Two orbiting flies are a tiny, intentionally stupid bit of motion.
	for index in range(2):
		var angle := age * (2.2 + index * 0.35) + index * PI
		var fly := Vector2(view.x - 110, view.y - 150) + Vector2(cos(angle) * 42.0, sin(angle * 1.3) * 18.0)
		draw_circle(fly, 3.0, INK)
		draw_circle(fly + Vector2(-4, -3), 3.0, Color(1, 1, 1, 0.45))
		draw_circle(fly + Vector2(4, -3), 3.0, Color(1, 1, 1, 0.45))

	# The actual Blender cast welcomes the player from the lawn edges.
	for entry in [["rat", Vector2(150, view.y * 0.50), 220.0], ["raccoon", Vector2(view.x - 135, view.y * 0.50), 195.0]]:
		var texture: Texture2D = preload("res://scripts/model_sprites.gd").FRAMES[entry[0]][2]
		var span: float = entry[2]
		var at: Vector2 = entry[1]
		draw_texture_rect(texture, Rect2(at - Vector2.ONE * span * 0.5 + Vector2(0, sin(age * 3.0) * 3.0), Vector2.ONE * span), false)

	# Heavy vignette keeps the readable centre bright.
	draw_rect(Rect2(0, 0, view.x, 18), INK, true)
	draw_rect(Rect2(0, view.y - 18, view.x, 18), INK, true)
	draw_rect(Rect2(0, 0, 18, view.y), INK, true)
	draw_rect(Rect2(view.x - 18, 0, 18, view.y), INK, true)

func _draw_trash_can(at: Vector2, tilt: float) -> void:
	draw_set_transform(at, tilt, Vector2.ONE)
	_draw_flat_ellipse(Vector2(5, 10), Vector2(65, 22), Color(0.05, 0.03, 0.04, 0.35))
	draw_set_transform(at, tilt, Vector2.ONE)
	var body := PackedVector2Array([Vector2(-45, -92), Vector2(44, -92), Vector2(32, 4), Vector2(-30, 4)])
	draw_colored_polygon(body, INK)
	var inset := PackedVector2Array([Vector2(-38, -86), Vector2(37, -86), Vector2(26, -3), Vector2(-24, -3)])
	draw_colored_polygon(inset, Color("70827b"))
	for x in [-20.0, 0.0, 20.0]:
		draw_line(Vector2(x, -78), Vector2(x * 0.72, -10), Color(0.20, 0.28, 0.25, 0.42), 5.0, true)
	draw_line(Vector2(-55, -95), Vector2(55, -95), INK, 14.0, true)
	draw_line(Vector2(-48, -98), Vector2(48, -98), Color("9eaa96"), 7.0, true)
	# A suspicious pair of eyes lives in the bin.
	for eye_x in [-15.0, 13.0]:
		draw_circle(Vector2(eye_x, -76), 10.0, CREAM)
		draw_circle(Vector2(eye_x + 3, -75), 4.0, INK)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_cheese(at: Vector2, scale_factor: float) -> void:
	draw_set_transform(at, 0.12, Vector2.ONE * scale_factor)
	var wedge := PackedVector2Array([Vector2(-60, 20), Vector2(48, 27), Vector2(30, -42), Vector2(-42, -25)])
	draw_colored_polygon(PackedVector2Array([wedge[0] + Vector2(7, 9), wedge[1] + Vector2(7, 9), wedge[2] + Vector2(7, 9), wedge[3] + Vector2(7, 9)]), INK)
	draw_colored_polygon(wedge, CHEESE)
	draw_polyline(PackedVector2Array([wedge[0], wedge[1], wedge[2], wedge[3], wedge[0]]), INK, 6.0, true)
	for hole in [Vector2(-24, -9), Vector2(11, -19), Vector2(20, 10), Vector2(-42, 9)]:
		draw_circle(hole, 7.0, Color("c88b2e"))
		draw_circle(hole - Vector2(2, 2), 4.0, Color("e5a936"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_splat(at: Vector2, radius: float, color: Color) -> void:
	draw_circle(at, radius, color)
	for index in range(7):
		var angle := TAU * index / 7.0 + 0.2
		var blob_at := at + Vector2.from_angle(angle) * radius * (0.85 + (index % 3) * 0.16)
		draw_circle(blob_at, radius * (0.20 + (index % 2) * 0.08), color)

func _draw_flat_ellipse(at: Vector2, ellipse_size: Vector2, color: Color) -> void:
	draw_set_transform(at, 0.0, Vector2(ellipse_size.x / ellipse_size.y, 1.0))
	draw_circle(Vector2.ZERO, ellipse_size.y, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
