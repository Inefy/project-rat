extends CharacterBody2D

signal died(enemy: Node, death_position: Vector2, points: int, color: Color)
signal projectile_requested(origin: Vector2, direction: Vector2, speed: float, damage: float, kind: String)
signal hit(position: Vector2)

const ARENA := Rect2(-1200.0, -700.0, 2400.0, 1400.0)

var enemy_kind := "bird"
var target: Node2D
var wave := 1
var max_health := 20.0
var health := 20.0
var move_speed := 180.0
var contact_damage := 9.0
var score_value := 100
var radius := 18.0
var tint := Color("ff77b7")
var age := 0.0
var contact_cooldown := 0.0
var attack_cooldown := 2.0
var hit_flash := 0.0
var knockback_velocity := Vector2.ZERO
var dying := false
var state := "stalk"
var state_clock := 1.0
var pounce_direction := Vector2.ZERO
var spawn_scale := 0.0
var elite := false

func setup(kind: String, target_player: Node2D, wave_number: int, is_elite: bool = false) -> void:
	enemy_kind = kind
	target = target_player
	wave = wave_number
	elite = is_elite
	var health_scale := 1.0 + float(wave - 1) * 0.105
	var damage_scale := 1.0 + float(wave - 1) * 0.045
	match enemy_kind:
		"bird":
			max_health = 22.0 * health_scale
			move_speed = min(350.0, 205.0 + wave * 3.0)
			contact_damage = 8.0 * damage_scale
			score_value = 90 + wave * 4
			radius = 16.0
			tint = Color("ff71b6")
			state_clock = 0.7
		"cat":
			max_health = 68.0 * health_scale
			move_speed = min(180.0, 92.0 + wave * 1.7)
			contact_damage = 17.0 * damage_scale
			score_value = 220 + wave * 8
			radius = 27.0
			tint = Color("ff9f43")
			state_clock = 1.1 + randf() * 1.0
		"owl":
			max_health = 48.0 * health_scale
			move_speed = min(145.0, 75.0 + wave * 1.3)
			contact_damage = 12.0 * damage_scale
			score_value = 180 + wave * 7
			radius = 23.0
			tint = Color("a58bff")
			attack_cooldown = 1.6 + randf() * 0.8
		"snake":
			max_health = 40.0 * health_scale
			move_speed = min(225.0, 132.0 + wave * 2.0)
			contact_damage = 11.0 * damage_scale
			score_value = 165 + wave * 7
			radius = 20.0
			tint = Color("63f58d")
			attack_cooldown = 1.3 + randf() * 1.0
		"alpha_cat":
			max_health = (430.0 + wave * 25.0) * health_scale
			move_speed = min(175.0, 105.0 + wave)
			contact_damage = 26.0 * damage_scale
			score_value = 1800 + wave * 80
			radius = 39.0
			tint = Color("ff4d5f")
			state_clock = 1.3
			scale = Vector2.ONE * 1.22
	if elite and enemy_kind != "alpha_cat":
		max_health *= 2.2
		contact_damage *= 1.35
		score_value *= 3
		move_speed *= 1.08
		scale *= 1.15
	health = max_health

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	add_to_group("enemies")
	z_index = 10
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	collision.shape = circle
	add_child(collision)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dying or not is_instance_valid(target) or not target.get("alive"):
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
		move_and_slide()
		return
	age += delta
	spawn_scale = move_toward(spawn_scale, 1.0, delta * 4.5)
	contact_cooldown = max(0.0, contact_cooldown - delta)
	hit_flash = max(0.0, hit_flash - delta)
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var direction := to_target.normalized() if distance > 0.1 else Vector2.RIGHT

	match enemy_kind:
		"bird":
			_update_bird(delta, direction)
		"cat", "alpha_cat":
			_update_cat(delta, direction)
		"owl":
			_update_owl(delta, direction, distance)
		"snake":
			_update_snake(delta, direction, distance)

	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 720.0 * delta)
	move_and_slide()
	rotation = lerp_angle(rotation, velocity.angle(), min(1.0, delta * 8.0)) if velocity.length() > 5.0 else rotation

	if enemy_kind in ["cat", "alpha_cat"] and state == "pounce":
		_bounce_inside_arena()
	else:
		global_position.x = clamp(global_position.x, ARENA.position.x + radius, ARENA.end.x - radius)
		global_position.y = clamp(global_position.y, ARENA.position.y + radius, ARENA.end.y - radius)

	if distance < radius + 23.0 and contact_cooldown <= 0.0:
		target.take_player_damage(contact_damage, direction * 240.0)
		contact_cooldown = 0.82 if enemy_kind != "bird" else 1.15
	queue_redraw()

func _update_bird(delta: float, direction: Vector2) -> void:
	var weave := sin(age * 8.5 + float(get_instance_id() % 13)) * 0.48
	var wanted := direction.rotated(weave) * move_speed
	velocity = velocity.move_toward(wanted, 510.0 * delta)

func _update_cat(delta: float, direction: Vector2) -> void:
	state_clock -= delta
	match state:
		"stalk":
			var tangent := direction.rotated(PI * 0.5) * sin(age * 2.1 + float(get_instance_id() % 7)) * 0.35
			velocity = velocity.move_toward((direction + tangent).normalized() * move_speed, 360.0 * delta)
			if state_clock <= 0.0:
				state = "telegraph"
				state_clock = 0.58 if enemy_kind == "cat" else 0.72
		"telegraph":
			velocity = velocity.move_toward(Vector2.ZERO, 680.0 * delta)
			pounce_direction = direction
			if state_clock <= 0.0:
				state = "pounce"
				state_clock = 0.72 if enemy_kind == "cat" else 0.95
				velocity = pounce_direction * (520.0 if enemy_kind == "cat" else 590.0)
		"pounce":
			velocity = velocity.move_toward(pounce_direction * (420.0 if enemy_kind == "cat" else 480.0), 80.0 * delta)
			if state_clock <= 0.0:
				if enemy_kind == "alpha_cat":
					for i in range(8):
						projectile_requested.emit(global_position, Vector2.from_angle(TAU * i / 8.0), 235.0, contact_damage * 0.42, "sonic")
				state = "recover"
				state_clock = 0.42
		"recover":
			velocity = velocity.move_toward(Vector2.ZERO, 900.0 * delta)
			if state_clock <= 0.0:
				state = "stalk"
				state_clock = (1.2 + randf() * 1.0) if enemy_kind == "cat" else (1.45 + randf() * 0.7)

func _update_owl(delta: float, direction: Vector2, distance: float) -> void:
	var desired := Vector2.ZERO
	if distance > 520.0:
		desired = direction * move_speed
	elif distance < 335.0:
		desired = -direction * move_speed
	else:
		desired = direction.rotated(PI * 0.5) * move_speed * 0.7
	velocity = velocity.move_toward(desired, 250.0 * delta)
	attack_cooldown -= delta
	if attack_cooldown <= 0.0 and distance < 760.0:
		var projectile_damage := 8.0 + wave * 0.55
		for spread in [-0.12, 0.0, 0.12]:
			projectile_requested.emit(global_position + direction * 18.0, direction.rotated(spread), 330.0 + wave * 2.0, projectile_damage, "feather")
		attack_cooldown = max(1.15, 2.45 - wave * 0.025)

func _update_snake(delta: float, direction: Vector2, distance: float) -> void:
	var slither := sin(age * 6.5 + float(get_instance_id() % 11)) * 0.72
	var desired_direction := direction.rotated(slither)
	if distance < 240.0:
		desired_direction = -direction.rotated(slither * 0.45)
	velocity = velocity.move_toward(desired_direction * move_speed, 340.0 * delta)
	attack_cooldown -= delta
	if attack_cooldown <= 0.0 and distance < 590.0:
		projectile_requested.emit(global_position + direction * 20.0, direction, 255.0 + wave * 2.0, 10.0 + wave * 0.5, "venom")
		attack_cooldown = maxf(1.25, 2.25 - wave * 0.02)

func _bounce_inside_arena() -> void:
	var bounced := false
	if global_position.x < ARENA.position.x + radius or global_position.x > ARENA.end.x - radius:
		velocity.x *= -1.0
		pounce_direction.x *= -1.0
		bounced = true
	if global_position.y < ARENA.position.y + radius or global_position.y > ARENA.end.y - radius:
		velocity.y *= -1.0
		pounce_direction.y *= -1.0
		bounced = true
	global_position.x = clamp(global_position.x, ARENA.position.x + radius, ARENA.end.x - radius)
	global_position.y = clamp(global_position.y, ARENA.position.y + radius, ARENA.end.y - radius)
	if bounced:
		state_clock += 0.18

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if dying:
		return
	health -= amount
	hit.emit(global_position)
	hit_flash = 0.11
	knockback_velocity += knockback * (0.22 if enemy_kind == "alpha_cat" else 1.0)
	if health <= 0.0:
		dying = true
		set_deferred("collision_layer", 0)
		died.emit(self, global_position, score_value, tint)
		call_deferred("queue_free")
	queue_redraw()

func _draw() -> void:
	var visual_scale: float = maxf(0.05, spawn_scale)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * visual_scale)
	if hit_flash > 0.0:
		draw_circle(Vector2.ZERO, radius + 12.0, Color(1.0, 1.0, 1.0, hit_flash * 3.5))
	match enemy_kind:
		"bird":
			_draw_bird()
		"cat", "alpha_cat":
			_draw_cat()
		"owl":
			_draw_owl()
		"snake":
			_draw_snake()
	if elite:
		draw_arc(Vector2.ZERO, radius + 9.0, age * 1.8, age * 1.8 + 4.9, 36, Color("ffe66d"), 3.0, true)
		for spark in range(3):
			var spark_angle := -age * 2.2 + TAU * spark / 3.0
			draw_circle(Vector2.from_angle(spark_angle) * (radius + 10.0), 2.7, Color.WHITE)
	if health < max_health and not dying:
		var width := radius * 2.1
		draw_rect(Rect2(-width * 0.5, -radius - 13.0, width, 4.0), Color(0.04, 0.06, 0.13, 0.9), true)
		draw_rect(Rect2(-width * 0.5, -radius - 13.0, width * clamp(health / max_health, 0.0, 1.0), 4.0), tint, true)

func _draw_bird() -> void:
	var wing := sin(age * 18.0) * 8.0
	draw_circle(Vector2.ZERO, 27.0, Color(tint, 0.07))
	var left_wing := PackedVector2Array([Vector2(-3, 0), Vector2(-12, -12 - wing), Vector2(-27, -4), Vector2(-13, 7)])
	var right_wing := PackedVector2Array([Vector2(-3, 0), Vector2(-12, 12 + wing), Vector2(-27, 4), Vector2(-13, -7)])
	draw_colored_polygon(left_wing, Color(tint, 0.78))
	draw_colored_polygon(right_wing, Color(tint, 0.78))
	draw_circle(Vector2(2, 0), 11.5, Color("2b315d"))
	draw_arc(Vector2(2, 0), 11.5, 0.0, TAU, 24, tint, 2.5, true)
	var beak := PackedVector2Array([Vector2(11, -5), Vector2(24, 0), Vector2(11, 5)])
	draw_colored_polygon(beak, Color("ffe66d"))
	draw_circle(Vector2(7, -4), 2.0, Color.WHITE)

func _draw_cat() -> void:
	var hop: float = absf(sin(age * 7.0)) * 4.0 if state == "pounce" else sin(age * 4.0)
	var cat_color := Color.WHITE if hit_flash > 0.0 else tint
	draw_circle(Vector2.ZERO, radius + 13.0, Color(tint, 0.065))
	# Spring trail makes the bounce/pounce readable.
	if state in ["telegraph", "pounce"]:
		var arc_color := Color(tint, 0.85 if state == "telegraph" else 0.38)
		draw_arc(Vector2(-radius - 8, 0), 11.0 + sin(age * 14.0) * 2.0, 0.0, TAU, 20, arc_color, 3.0, true)
	draw_circle(Vector2(-5, hop), radius * 0.8, Color("202850"))
	draw_arc(Vector2(-5, hop), radius * 0.8, 0.0, TAU, 28, cat_color, 3.0, true)
	var head := Vector2(radius * 0.48, hop)
	draw_circle(head, radius * 0.62, Color("343b69"))
	draw_arc(head, radius * 0.62, 0.0, TAU, 24, cat_color, 3.0, true)
	var ear_top: float = -radius * 0.78 + hop
	var ear_a := PackedVector2Array([Vector2(radius * 0.25, -radius * 0.35 + hop), Vector2(radius * 0.35, ear_top), Vector2(radius * 0.65, -radius * 0.45 + hop)])
	var ear_b := PackedVector2Array([Vector2(radius * 0.65, -radius * 0.4 + hop), Vector2(radius * 0.92, ear_top + 3), Vector2(radius * 0.98, -radius * 0.15 + hop)])
	draw_colored_polygon(ear_a, cat_color)
	draw_colored_polygon(ear_b, cat_color)
	draw_circle(Vector2(radius * 0.68, -5 + hop), 3.0, Color("ffe66d"))
	draw_circle(Vector2(radius * 0.69, -5 + hop), 1.0, Color("071020"))
	draw_line(Vector2(radius * 0.95, 4 + hop), Vector2(radius * 1.48, -3 + hop), cat_color, 1.3, true)
	draw_line(Vector2(radius * 0.95, 7 + hop), Vector2(radius * 1.5, 11 + hop), cat_color, 1.3, true)
	if enemy_kind == "alpha_cat":
		draw_arc(Vector2.ZERO, radius + 7.0, age, age + 4.8, 32, Color("ffdc73"), 3.0, true)

func _draw_owl() -> void:
	var flap := sin(age * 7.0) * 4.0
	draw_circle(Vector2.ZERO, 36.0, Color(tint, 0.07))
	draw_circle(Vector2(-3, 0), 22.0, Color("252b58"))
	draw_arc(Vector2(-3, 0), 22.0, 0.0, TAU, 28, tint, 3.0, true)
	var wing_left := PackedVector2Array([Vector2(-8, -8), Vector2(-28, -19 - flap), Vector2(-23, 4), Vector2(-8, 12)])
	var wing_right := PackedVector2Array([Vector2(-8, 8), Vector2(-28, 19 + flap), Vector2(-23, -4), Vector2(-8, -12)])
	draw_colored_polygon(wing_left, Color(tint, 0.65))
	draw_colored_polygon(wing_right, Color(tint, 0.65))
	draw_circle(Vector2(7, -8), 8.0, Color("eaf2ff"))
	draw_circle(Vector2(7, 8), 8.0, Color("eaf2ff"))
	draw_circle(Vector2(10, -7), 3.0, Color("0a102b"))
	draw_circle(Vector2(10, 7), 3.0, Color("0a102b"))
	var beak := PackedVector2Array([Vector2(14, -4), Vector2(25, 0), Vector2(14, 4)])
	draw_colored_polygon(beak, Color("ffe66d"))

func _draw_snake() -> void:
	draw_circle(Vector2.ZERO, 32.0, Color(tint, 0.065))
	var points := PackedVector2Array()
	for segment in range(8):
		var x := -34.0 + segment * 8.0
		var y := sin(age * 8.0 - segment * 0.85) * 8.0
		points.append(Vector2(x, y))
	draw_polyline(points, Color("183c43"), 15.0, true)
	draw_polyline(points, tint, 4.0, true)
	draw_circle(Vector2(18, sin(age * 8.0 - 6.0) * 7.0), 12.0, Color("193b45"))
	draw_arc(Vector2(18, sin(age * 8.0 - 6.0) * 7.0), 12.0, 0.0, TAU, 20, tint, 2.5, true)
	draw_circle(Vector2(24, -4 + sin(age * 8.0 - 6.0) * 7.0), 2.2, Color("ffe66d"))
	draw_line(Vector2(29, sin(age * 8.0 - 6.0) * 7.0), Vector2(40, sin(age * 8.0 - 6.0) * 7.0), Color("ff6b9f"), 2.0, true)
