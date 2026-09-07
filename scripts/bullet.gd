extends Area2D

var velocity := Vector2.ZERO
var damage := 10.0
var life := 1.4
var pierce := 0
var radius := 5.0
var tint := Color("fff1bf")
var hit_ids: Dictionary = {}
var spent := false
var bounces_left := 0
var split_on_bounce := false
const FENCE := Rect2(-1170, -670, 2340, 1340)

func setup(origin: Vector2, direction: Vector2, shot_speed: float, shot_damage: float, shot_radius: float, shot_pierce: int, color: Color) -> void:
	global_position = origin
	velocity = direction.normalized() * shot_speed
	damage = shot_damage
	radius = shot_radius
	pierce = shot_pierce
	tint = color
	rotation = direction.angle()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("run_entities")
	add_to_group("player_bullets")
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
	if bounces_left > 0 and not FENCE.has_point(global_position):
		if global_position.x < FENCE.position.x or global_position.x > FENCE.end.x:
			velocity.x *= -1.0
		if global_position.y < FENCE.position.y or global_position.y > FENCE.end.y:
			velocity.y *= -1.0
		global_position = global_position.clamp(FENCE.position, FENCE.end)
		bounces_left -= 1
		rotation = velocity.angle()
		life = maxf(life, 0.9)
		if split_on_bounce and get_tree().get_nodes_in_group("player_bullets").size() < 160:
			var child = get_script().new()
			child.setup(global_position, velocity.normalized().rotated(0.3), velocity.length(), damage * 0.6, radius, 0, tint)
			get_parent().add_child(child)
			split_on_bounce = false
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
	draw_circle(Vector2(-10.0, 0.0), radius * 0.8, Color(1.0, 0.95, 0.78, 0.28))
	draw_texture_rect(preload("res://assets/sprites/seed_0.png"), Rect2(-radius * 2.0, -radius * 2.0, radius * 4.0, radius * 4.0), false, tint)
