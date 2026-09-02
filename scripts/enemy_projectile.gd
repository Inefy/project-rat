extends Area2D

var velocity := Vector2.ZERO
var damage := 10.0
var life := 4.0
var projectile_kind := "feather"
var tint := Color("ff8dc7")

func setup(origin: Vector2, direction: Vector2, shot_speed: float, shot_damage: float, kind: String = "feather") -> void:
	global_position = origin
	velocity = direction.normalized() * shot_speed
	damage = shot_damage
	projectile_kind = kind
	rotation = direction.angle()
	if kind == "sonic":
		tint = Color("ffb23e")

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0 if projectile_kind == "sonic" else 6.0
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
	if body.has_method("take_player_damage"):
		body.take_player_damage(damage, velocity.normalized() * 170.0)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 14.0, Color(tint, 0.11))
	if projectile_kind == "sonic":
		draw_arc(Vector2.ZERO, 9.0, 0.0, TAU, 24, tint, 3.0, true)
		draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
	else:
		var points := PackedVector2Array([Vector2(-10, 0), Vector2(6, -5), Vector2(10, 0), Vector2(6, 5)])
		draw_colored_polygon(points, tint)
		draw_line(Vector2(-8, 0), Vector2(8, 0), Color.WHITE, 1.5, true)

