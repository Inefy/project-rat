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
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("enemy_projectiles")
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
		body.take_player_damage(damage, velocity.normalized() * 170.0, projectile_kind)
		set_deferred("monitoring", false)
		call_deferred("queue_free")

func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, Color(tint, 0.25))
	var texture: Texture2D = preload("res://scripts/model_sprites.gd").FRAMES[projectile_kind][0]
	draw_texture_rect(texture, Rect2(-18, -18, 36, 36), false)
