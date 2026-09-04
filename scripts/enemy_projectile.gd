extends Area2D

var velocity := Vector2.ZERO
var damage := 10.0
var life := 4.0
var projectile_kind := "feather"
var tint := Color("8d79ad")
var spent := false

func setup(origin: Vector2, direction: Vector2, shot_speed: float, shot_damage: float, kind: String = "feather") -> void:
	global_position = origin
	velocity = direction.normalized() * shot_speed
	damage = shot_damage
	projectile_kind = kind
	rotation = direction.angle()
	if kind == "sonic":
		tint = Color("e89b4f")
	elif kind == "venom":
		tint = Color("79a85b")
	elif kind == "bone":
		tint = Color("fff4d6")

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 10.0 if projectile_kind == "venom" else (8.0 if projectile_kind in ["sonic", "bone"] else 6.0)
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	rotation += delta * 7.0
	life -= delta
	if life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if not spent and body.has_method("take_player_damage"):
		spent = true
		body.take_player_damage(damage, velocity.normalized() * 170.0)
		set_deferred("monitoring", false)
		call_deferred("queue_free")

func _draw() -> void:
	draw_circle(Vector2(3, 4), 10.0, Color(0.24, 0.19, 0.24, 0.14))
	if projectile_kind == "sonic":
		draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, Color("40354f"), 5.0, true)
		draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, tint, 2.5, true)
		draw_circle(Vector2.ZERO, 3.0, Color("fff4d6"))
	elif projectile_kind == "venom":
		draw_circle(Vector2.ZERO, 12.0, Color("40354f"))
		draw_circle(Vector2.ZERO, 9.0, tint)
		draw_circle(Vector2(2, -3), 3.0, Color("dff0b2"))
	elif projectile_kind == "bone":
		draw_line(Vector2(-8, 0), Vector2(8, 0), Color("40354f"), 7.0, true)
		draw_line(Vector2(-8, 0), Vector2(8, 0), tint, 4.0, true)
		for end_x in [-9.0, 9.0]:
			draw_circle(Vector2(end_x, -3), 4.0, Color("40354f"))
			draw_circle(Vector2(end_x, 3), 4.0, Color("40354f"))
			draw_circle(Vector2(end_x, -3), 2.5, tint)
			draw_circle(Vector2(end_x, 3), 2.5, tint)
	else:
		var outline := PackedVector2Array([Vector2(-12, 0), Vector2(6, -7), Vector2(12, 0), Vector2(6, 7)])
		draw_colored_polygon(outline, Color("40354f"))
		var feather := PackedVector2Array([Vector2(-9, 0), Vector2(6, -4), Vector2(9, 0), Vector2(6, 4)])
		draw_colored_polygon(feather, tint)
		draw_line(Vector2(-8, 0), Vector2(8, 0), Color("fff4d6"), 1.5, true)
