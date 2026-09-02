extends Area2D

var velocity := Vector2.ZERO
var damage := 10.0
var life := 1.4
var pierce := 0
var radius := 5.0
var tint := Color("62fff1")
var hit_ids: Dictionary = {}
var spent := false

func setup(origin: Vector2, direction: Vector2, shot_speed: float, shot_damage: float, shot_radius: float, shot_pierce: int, color: Color) -> void:
	global_position = origin
	velocity = direction.normalized() * shot_speed
	damage = shot_damage
	radius = shot_radius
	pierce = shot_pierce
	tint = color
	rotation = direction.angle()

func _ready() -> void:
	add_to_group("run_entities")
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius + 2.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += velocity * delta
	life -= delta
	if life <= 0.0 or abs(global_position.x) > 1500.0 or abs(global_position.y) > 1000.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if spent or not body.has_method("take_damage") or hit_ids.has(body.get_instance_id()):
		return
	hit_ids[body.get_instance_id()] = true
	body.take_damage(damage, velocity.normalized() * 75.0)
	if pierce <= 0:
		spent = true
		set_deferred("monitoring", false)
		call_deferred("queue_free")
	else:
		pierce -= 1

func _draw() -> void:
	draw_line(Vector2(-18.0, 0.0), Vector2.ZERO, Color(tint, 0.16), radius * 2.8, true)
	draw_circle(Vector2.ZERO, radius * 2.0, Color(tint, 0.12))
	draw_circle(Vector2.ZERO, radius, tint)
	draw_circle(Vector2(radius * 0.25, -radius * 0.25), radius * 0.36, Color.WHITE)
