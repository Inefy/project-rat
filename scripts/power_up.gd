extends Area2D

signal collected(kind: String, position: Vector2, color: Color)

const DEFINITIONS := {
	"cheese": {"color": Color("f2c14e"), "letter": "+", "name": "Cheese"},
	"rapid": {"color": Color("ef6f6c"), "letter": "R", "name": "Rapid Claws"},
	"triple": {"color": Color("8d79ad"), "letter": "3", "name": "Triple Seed"},
	"power": {"color": Color("e89b4f"), "letter": "P", "name": "Power Nibble"},
	"haste": {"color": Color("79a85b"), "letter": ">", "name": "Sugar Rush"},
	"shield": {"color": Color("8fa7b3"), "letter": "S", "name": "Tin-lid Shield"},
	"pierce": {"color": Color("f4d7a1"), "letter": "!", "name": "Needle Teeth"},
}

var kind := "cheese"
var tint := Color("f2c14e")
var age := 0.0
var life := 16.0
var collected_already := false
var magnet_target: Node2D
var magnetized := false

func setup(power_kind: String, at: Vector2, player: Node2D) -> void:
	kind = power_kind
	global_position = at
	magnet_target = player
	var data: Dictionary = DEFINITIONS.get(kind, DEFINITIONS["cheese"])
	tint = data["color"]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	collision_layer = 16
	collision_mask = 1
	monitoring = true
	monitorable = false
	add_to_group("pickups")
	z_index = 15
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 19.0
	collision.shape = circle
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if collected_already:
		return
	age += delta
	life -= delta
	rotation += delta * 0.7
	if is_instance_valid(magnet_target):
		var delta_to_player := magnet_target.global_position - global_position
		var magnet_radius: float = float(magnet_target.get("magnet_radius"))
		if delta_to_player.length() < magnet_radius:
			magnetized = true
		if magnetized:
			# Once reached, treats follow through a dash and cannot expire in transit.
			life = maxf(life, 1.0)
			var chase_speed := maxf(720.0, magnet_target.velocity.length() + 180.0)
			global_position = global_position.move_toward(magnet_target.global_position, chase_speed * delta)
			if global_position.distance_to(magnet_target.global_position) < 30.0:
				_on_body_entered(magnet_target)
	if life <= 0.0:
		queue_free()
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if collected_already or not body.has_method("apply_powerup"):
		return
	collected_already = true
	body.apply_powerup(kind)
	collected.emit(kind, global_position, tint)
	set_deferred("monitoring", false)
	call_deferred("queue_free")

func _draw() -> void:
	var pulse := 1.0 + sin(age * 5.0) * 0.08
	var warning_alpha: float = 0.22 if life > 4.0 else 0.08 + absf(sin(age * 10.0)) * 0.18
	draw_circle(Vector2(4, 7), 22.0 * pulse, Color(0.24, 0.19, 0.24, 0.18))
	draw_circle(Vector2.ZERO, 28.0 * pulse, Color(tint, warning_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * pulse)
	draw_circle(Vector2.ZERO, 22.0, Color("321f2b"))
	draw_circle(Vector2.ZERO, 17.5, Color("fff0bf"))
	preload("res://scripts/model_sprites.gd").paint(self, kind, rotation, 44.0, age, 0.8, pulse)

func _draw_cheese() -> void:
	var wedge := PackedVector2Array([Vector2(-13, 10), Vector2(13, 8), Vector2(7, -12), Vector2(-10, -7)])
	draw_colored_polygon(wedge, tint)
	draw_polyline(PackedVector2Array([wedge[0], wedge[1], wedge[2], wedge[3], wedge[0]]), Color("321f2b"), 2.5, true)
	for hole in [Vector2(-5, 2), Vector2(5, 4), Vector2(3, -5)]:
		draw_circle(hole, 2.2, Color("b77928"))

func _draw_pepper() -> void:
	var pepper := PackedVector2Array([Vector2(-10, -7), Vector2(8, -10), Vector2(12, -2), Vector2(2, 13), Vector2(-8, 7)])
	draw_colored_polygon(pepper, Color("321f2b"))
	var inset := PackedVector2Array([Vector2(-7, -5), Vector2(6, -7), Vector2(8, -2), Vector2(1, 9), Vector2(-5, 5)])
	draw_colored_polygon(inset, tint)
	draw_line(Vector2(-2, -8), Vector2(-7, -15), Color("4d8b49"), 4.0, true)

func _draw_triple_peas() -> void:
	draw_line(Vector2(-12, 8), Vector2(11, -9), Color("321f2b"), 9.0, true)
	draw_line(Vector2(-11, 7), Vector2(10, -8), Color("62a55a"), 5.0, true)
	for pea in [Vector2(-8, 5), Vector2(0, 0), Vector2(8, -5)]:
		draw_circle(pea, 5.0, Color("321f2b"))
		draw_circle(pea, 3.0, Color("a0cf5d"))

func _draw_acorn() -> void:
	draw_circle(Vector2(0, 4), 10.0, Color("321f2b"))
	draw_circle(Vector2(0, 4), 7.0, Color("bd743b"))
	draw_arc(Vector2(0, -2), 9.0, PI, TAU, 12, Color("321f2b"), 6.0, true)
	draw_arc(Vector2(0, -2), 9.0, PI, TAU, 12, Color("81502f"), 3.0, true)
	draw_line(Vector2(2, -10), Vector2(7, -15), Color("321f2b"), 3.0, true)

func _draw_sugar_cube() -> void:
	draw_rect(Rect2(-10, -9, 20, 20), Color("321f2b"), true)
	draw_rect(Rect2(-7, -7, 14, 14), Color("ffffff"), true)
	for grain in [Vector2(-3, -2), Vector2(3, 2), Vector2(-2, 5)]:
		draw_circle(grain, 1.2, Color("c9d9c8"))
	draw_line(Vector2(11, -8), Vector2(16, -8), tint, 2.5, true)
	draw_line(Vector2(12, 0), Vector2(18, 0), tint, 2.5, true)

func _draw_lid() -> void:
	draw_circle(Vector2.ZERO, 13.0, Color("321f2b"))
	draw_circle(Vector2.ZERO, 10.0, Color("8fa7b3"))
	draw_circle(Vector2.ZERO, 4.0, Color("321f2b"))
	draw_circle(Vector2.ZERO, 2.0, Color("d3ddd8"))
	draw_arc(Vector2(-2, -2), 7.0, 3.4, 5.4, 10, Color(1, 1, 1, 0.45), 2.0, true)

func _draw_needle() -> void:
	draw_line(Vector2(-12, 10), Vector2(11, -11), Color("321f2b"), 6.0, true)
	draw_line(Vector2(-11, 9), Vector2(10, -10), Color("d8ded4"), 2.8, true)
	draw_circle(Vector2(-12, 10), 4.5, Color("321f2b"))
	draw_circle(Vector2(-12, 10), 2.0, Color("fff0bf"))
