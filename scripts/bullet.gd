extends Area2D

var velocity := Vector2.ZERO
var damage := 10.0
var life := 1.4
var pierce := 0
var radius := 5.0
var tint := Color("fff1bf")
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
	# A chunky sunflower seed replaces the old neon bolt.
	draw_circle(Vector2(-10.0, 0.0), radius * 0.8, Color(1.0, 0.95, 0.78, 0.28))
	var outline := PackedVector2Array([Vector2(-radius * 1.45, 0), Vector2(-radius * 0.35, -radius), Vector2(radius * 1.35, 0), Vector2(-radius * 0.35, radius)])
	draw_colored_polygon(outline, Color("40354f"))
	var seed := PackedVector2Array([Vector2(-radius * 1.05, 0), Vector2(-radius * 0.25, -radius * 0.62), Vector2(radius * 0.95, 0), Vector2(-radius * 0.25, radius * 0.62)])
	draw_colored_polygon(seed, tint)
	draw_line(Vector2(-radius * 0.5, -radius * 0.25), Vector2(radius * 0.55, 0), Color(1, 1, 1, 0.65), 1.3, true)
