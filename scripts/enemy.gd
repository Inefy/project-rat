extends CharacterBody2D

signal died(enemy: Node, death_position: Vector2, points: int, color: Color)
signal projectile_requested(origin: Vector2, direction: Vector2, speed: float, damage: float, kind: String)
signal hit(position: Vector2)

const ARENA := Rect2(-1200.0, -700.0, 2400.0, 1400.0)
const INK := Color("40354f")
const CREAM := Color("fff4d6")
const ARMOUR_COLOR := Color("8fa7b3")

var enemy_kind := "bird"
var target: Node2D
var wave := 1
var max_health := 20.0
var health := 20.0
var max_armour := 0.0
var armour := 0.0
var move_speed := 180.0
var contact_damage := 9.0
var score_value := 100
var radius := 18.0
var tint := Color("e87883")
var age := 0.0
var contact_cooldown := 0.0
var attack_cooldown := 2.0
var hit_flash := 0.0
var armour_flash := 0.0
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
	var health_scale := get_health_scale(wave)
	var damage_scale := get_damage_scale(wave)
	match enemy_kind:
		"bird":
			max_health = 24.0 * health_scale
			move_speed = minf(385.0, 218.0 + wave * 4.0)
			contact_damage = 9.0 * damage_scale
			score_value = 90 + wave * 5
			radius = 16.0
			tint = Color("e96f7c")
			state_clock = 0.7
		"cat":
			max_health = 72.0 * health_scale
			move_speed = minf(215.0, 100.0 + wave * 2.1)
			contact_damage = 18.0 * damage_scale
			score_value = 220 + wave * 9
			radius = 27.0
			tint = Color("e99a4e")
			state_clock = 0.9 + randf() * 0.7
		"owl":
			max_health = 52.0 * health_scale
			move_speed = minf(175.0, 82.0 + wave * 1.7)
			contact_damage = 13.0 * damage_scale
			score_value = 180 + wave * 8
			radius = 23.0
			tint = Color("8d79ad")
			attack_cooldown = 1.35 + randf() * 0.65
		"snake":
			max_health = 44.0 * health_scale
			move_speed = minf(260.0, 142.0 + wave * 2.5)
			contact_damage = 12.0 * damage_scale
			score_value = 165 + wave * 8
			radius = 20.0
			tint = Color("6ea85f")
			attack_cooldown = 1.1 + randf() * 0.8
		"raccoon":
			max_health = 112.0 * health_scale
			max_armour = (58.0 + wave * 3.0) * (1.0 + float(wave - 1) * 0.045)
			move_speed = minf(190.0, 88.0 + wave * 2.2)
			contact_damage = 22.0 * damage_scale
			score_value = 320 + wave * 12
			radius = 30.0
			tint = Color("71828b")
			state_clock = 1.1 + randf() * 0.8
		"fox":
			max_health = 86.0 * health_scale
			move_speed = minf(260.0, 145.0 + wave * 2.5)
			contact_damage = 20.0 * damage_scale
			score_value = 300 + wave * 12
			radius = 24.0
			tint = Color("e26f3f")
			state_clock = 0.8 + randf() * 0.7
		"alpha_cat":
			max_health = (390.0 + wave * 18.0) * health_scale
			move_speed = minf(210.0, 112.0 + wave * 1.6)
			contact_damage = 28.0 * damage_scale
			score_value = 1800 + wave * 90
			radius = 39.0
			tint = Color("c94f57")
			state_clock = 1.1
			scale = Vector2.ONE * 1.22
		"junkyard_dog":
			max_health = (660.0 + wave * 25.0) * health_scale
			max_armour = max_health * 0.38
			move_speed = minf(180.0, 94.0 + wave * 1.6)
			contact_damage = 34.0 * damage_scale
			score_value = 2600 + wave * 115
			radius = 44.0
			tint = Color("9b6d4b")
			state_clock = 1.25
			scale = Vector2.ONE * 1.18
		"barn_owl":
			max_health = (720.0 + wave * 23.0) * health_scale
			move_speed = minf(205.0, 105.0 + wave * 1.8)
			contact_damage = 26.0 * damage_scale
			score_value = 2850 + wave * 120
			radius = 42.0
			tint = Color("76628d")
			attack_cooldown = 1.15
			scale = Vector2.ONE * 1.16
	if elite and enemy_kind not in ["alpha_cat", "junkyard_dog", "barn_owl"]:
		max_health *= 2.15
		max_armour += max_health * 0.24
		contact_damage *= 1.4
		score_value *= 3
		move_speed *= 1.1
		scale *= 1.15
	health = max_health
	armour = max_armour

func get_health_scale(for_wave: int) -> float:
	var ramp := float(maxi(0, for_wave - 1))
	return 1.0 + ramp * 0.11 + ramp * ramp * 0.008

func get_damage_scale(for_wave: int) -> float:
	var ramp := float(maxi(0, for_wave - 1))
	return 1.0 + ramp * 0.055 + ramp * ramp * 0.0018

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
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	armour_flash = maxf(0.0, armour_flash - delta)
	var to_target := target.global_position - global_position
	var distance := to_target.length()
	var direction := to_target.normalized() if distance > 0.1 else Vector2.RIGHT

	match enemy_kind:
		"bird":
			_update_bird(delta, direction)
		"cat", "alpha_cat":
			_update_cat(delta, direction)
		"owl", "barn_owl":
			_update_owl(delta, direction, distance)
		"snake":
			_update_snake(delta, direction, distance)
		"raccoon":
			_update_raccoon(delta, direction)
		"fox":
			_update_fox(delta, direction, distance)
		"junkyard_dog":
			_update_dog(delta, direction)

	velocity += knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 720.0 * delta)
	move_and_slide()
	rotation = lerp_angle(rotation, velocity.angle(), minf(1.0, delta * 8.0)) if velocity.length() > 5.0 else rotation

	if enemy_kind in ["cat", "alpha_cat", "raccoon", "fox", "junkyard_dog"] and state in ["pounce", "charge", "dart"]:
		_bounce_inside_arena()
	else:
		global_position.x = clampf(global_position.x, ARENA.position.x + radius, ARENA.end.x - radius)
		global_position.y = clampf(global_position.y, ARENA.position.y + radius, ARENA.end.y - radius)

	if distance < radius + 23.0 and contact_cooldown <= 0.0:
		target.take_player_damage(contact_damage, direction * 250.0)
		contact_cooldown = 0.9 if enemy_kind != "bird" else 1.08
	queue_redraw()

func _update_bird(delta: float, direction: Vector2) -> void:
	var weave := sin(age * 8.5 + float(get_instance_id() % 13)) * 0.48
	var wanted := direction.rotated(weave) * move_speed
	velocity = velocity.move_toward(wanted, 540.0 * delta)

func _update_cat(delta: float, direction: Vector2) -> void:
	state_clock -= delta
	match state:
		"stalk":
			var tangent := direction.rotated(PI * 0.5) * sin(age * 2.1 + float(get_instance_id() % 7)) * 0.35
			velocity = velocity.move_toward((direction + tangent).normalized() * move_speed, 380.0 * delta)
			if state_clock <= 0.0:
				state = "telegraph"
				state_clock = 0.52 if enemy_kind == "cat" else 0.66
		"telegraph":
			velocity = velocity.move_toward(Vector2.ZERO, 700.0 * delta)
			pounce_direction = direction
			if state_clock <= 0.0:
				state = "pounce"
				state_clock = 0.72 if enemy_kind == "cat" else 0.92
				velocity = pounce_direction * (555.0 if enemy_kind == "cat" else 625.0)
		"pounce":
			velocity = velocity.move_toward(pounce_direction * (450.0 if enemy_kind == "cat" else 510.0), 80.0 * delta)
			if state_clock <= 0.0:
				if enemy_kind == "alpha_cat":
					for i in range(10):
						projectile_requested.emit(global_position, Vector2.from_angle(TAU * i / 10.0), 245.0 + wave * 2.0, contact_damage * 0.4, "sonic")
				state = "recover"
				state_clock = 0.38
		"recover":
			velocity = velocity.move_toward(Vector2.ZERO, 950.0 * delta)
			if state_clock <= 0.0:
				state = "stalk"
				state_clock = (0.95 + randf() * 0.8) if enemy_kind == "cat" else (1.15 + randf() * 0.55)

func _update_owl(delta: float, direction: Vector2, distance: float) -> void:
	var is_boss := enemy_kind == "barn_owl"
	var desired := Vector2.ZERO
	var far_distance := 580.0 if is_boss else 520.0
	var near_distance := 390.0 if is_boss else 335.0
	if distance > far_distance:
		desired = direction * move_speed
	elif distance < near_distance:
		desired = -direction * move_speed
	else:
		desired = direction.rotated(PI * 0.5) * move_speed * (0.85 if is_boss else 0.7)
	velocity = velocity.move_toward(desired, 280.0 * delta)
	attack_cooldown -= delta
	if attack_cooldown <= 0.0 and distance < 820.0:
		if is_boss:
			for spread in [-0.36, -0.24, -0.12, 0.0, 0.12, 0.24, 0.36]:
				projectile_requested.emit(global_position + direction * 28.0, direction.rotated(spread), 345.0 + wave * 2.8, contact_damage * 0.48, "feather")
			attack_cooldown = maxf(0.82, 1.7 - wave * 0.018)
		else:
			for spread in [-0.15, 0.0, 0.15]:
				projectile_requested.emit(global_position + direction * 18.0, direction.rotated(spread), 335.0 + wave * 2.5, contact_damage * 0.62, "feather")
			attack_cooldown = maxf(0.92, 2.2 - wave * 0.032)

func _update_snake(delta: float, direction: Vector2, distance: float) -> void:
	var slither := sin(age * 6.5 + float(get_instance_id() % 11)) * 0.72
	var desired_direction := direction.rotated(slither)
	if distance < 255.0:
		desired_direction = -direction.rotated(slither * 0.45)
	velocity = velocity.move_toward(desired_direction * move_speed, 370.0 * delta)
	attack_cooldown -= delta
	if attack_cooldown <= 0.0 and distance < 620.0:
		projectile_requested.emit(global_position + direction * 20.0, direction, 270.0 + wave * 2.5, contact_damage * 0.82, "venom")
		attack_cooldown = maxf(0.88, 2.0 - wave * 0.028)

func _update_raccoon(delta: float, direction: Vector2) -> void:
	state_clock -= delta
	match state:
		"stalk":
			var zigzag := direction.rotated(sin(age * 2.8) * 0.24)
			velocity = velocity.move_toward(zigzag * move_speed, 330.0 * delta)
			if state_clock <= 0.0:
				state = "brace"
				state_clock = 0.62
		"brace":
			velocity = velocity.move_toward(Vector2.ZERO, 720.0 * delta)
			pounce_direction = direction
			if state_clock <= 0.0:
				state = "charge"
				state_clock = 0.62
				velocity = pounce_direction * 475.0
		"charge":
			velocity = velocity.move_toward(pounce_direction * 390.0, 90.0 * delta)
			if state_clock <= 0.0:
				state = "recover"
				state_clock = 0.52
		"recover":
			velocity = velocity.move_toward(Vector2.ZERO, 920.0 * delta)
			if state_clock <= 0.0:
				state = "stalk"
				state_clock = 1.05 + randf() * 0.7

func _update_fox(delta: float, direction: Vector2, distance: float) -> void:
	state_clock -= delta
	match state:
		"stalk":
			var side := -1.0 if get_instance_id() % 2 == 0 else 1.0
			var tangent := direction.rotated(PI * 0.5 * side)
			var approach := direction * (0.7 if distance > 380.0 else -0.2)
			velocity = velocity.move_toward((tangent + approach).normalized() * move_speed, 460.0 * delta)
			if state_clock <= 0.0:
				state = "telegraph"
				state_clock = 0.38
		"telegraph":
			velocity = velocity.move_toward(Vector2.ZERO, 850.0 * delta)
			pounce_direction = direction
			if state_clock <= 0.0:
				state = "dart"
				state_clock = 0.48
				velocity = pounce_direction * 690.0
		"dart":
			velocity = velocity.move_toward(pounce_direction * 590.0, 120.0 * delta)
			if state_clock <= 0.0:
				state = "recover"
				state_clock = 0.28
		"recover":
			velocity = velocity.move_toward(Vector2.ZERO, 1100.0 * delta)
			if state_clock <= 0.0:
				state = "stalk"
				state_clock = 0.75 + randf() * 0.6

func _update_dog(delta: float, direction: Vector2) -> void:
	state_clock -= delta
	match state:
		"stalk":
			velocity = velocity.move_toward(direction * move_speed, 300.0 * delta)
			if state_clock <= 0.0:
				state = "brace"
				state_clock = 0.82
		"brace":
			velocity = velocity.move_toward(Vector2.ZERO, 780.0 * delta)
			pounce_direction = direction
			if state_clock <= 0.0:
				state = "charge"
				state_clock = 0.9
				velocity = pounce_direction * 570.0
		"charge":
			velocity = velocity.move_toward(pounce_direction * 465.0, 65.0 * delta)
			if state_clock <= 0.0:
				for i in range(12):
					projectile_requested.emit(global_position, Vector2.from_angle(TAU * i / 12.0), 260.0 + wave * 2.0, contact_damage * 0.38, "bone")
				state = "recover"
				state_clock = 0.65
		"recover":
			velocity = velocity.move_toward(Vector2.ZERO, 850.0 * delta)
			if state_clock <= 0.0:
				state = "stalk"
				state_clock = 1.05 + randf() * 0.5

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
	global_position.x = clampf(global_position.x, ARENA.position.x + radius, ARENA.end.x - radius)
	global_position.y = clampf(global_position.y, ARENA.position.y + radius, ARENA.end.y - radius)
	if bounced:
		state_clock += 0.16

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if dying:
		return
	var health_damage := amount
	if armour > 0.0:
		var absorbed := minf(armour, amount)
		armour -= absorbed
		health_damage = maxf(0.0, amount - absorbed) * 0.5
		armour_flash = 0.14
		if armour <= 0.0:
			knockback_velocity += knockback * 0.65
	health -= health_damage
	hit.emit(global_position)
	hit_flash = 0.11 if health_damage > 0.0 else 0.04
	knockback_velocity += knockback * (0.18 if enemy_kind in ["alpha_cat", "junkyard_dog", "barn_owl"] else 1.0)
	if health <= 0.0:
		dying = true
		set_deferred("collision_layer", 0)
		died.emit(self, global_position, score_value, tint)
		call_deferred("queue_free")
	queue_redraw()

func _draw() -> void:
	var visual_scale: float = maxf(0.05, spawn_scale)
	draw_set_transform(Vector2(0, radius * 0.72), 0.0, Vector2(1.0, 0.42) * visual_scale)
	draw_circle(Vector2.ZERO, radius * 0.92, Color(0.24, 0.19, 0.24, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * visual_scale)
	if hit_flash > 0.0:
		draw_circle(Vector2.ZERO, radius + 10.0, Color(1.0, 0.95, 0.75, hit_flash * 2.8))
	match enemy_kind:
		"bird":
			_draw_bird()
		"cat", "alpha_cat":
			_draw_cat()
		"owl", "barn_owl":
			_draw_owl()
		"snake":
			_draw_snake()
		"raccoon":
			_draw_raccoon()
		"fox":
			_draw_fox()
		"junkyard_dog":
			_draw_dog()
	if elite:
		for badge in range(3):
			var badge_angle := -age * 1.8 + TAU * badge / 3.0
			var badge_at := Vector2.from_angle(badge_angle) * (radius + 10.0)
			draw_circle(badge_at, 5.0, INK)
			draw_circle(badge_at, 3.0, Color("f2c14e"))
	if max_armour > 0.0 and armour > 0.0:
		_draw_armour_plates()
	if (health < max_health or max_armour > 0.0) and not dying:
		# Counter the character's facing so combat bars stay easy to read on screen.
		draw_set_transform(Vector2.ZERO, -rotation, Vector2.ONE * visual_scale)
		_draw_health_bars()

func _draw_health_bars() -> void:
	var width := radius * 2.25
	var bar_y := -radius - 17.0
	draw_rect(Rect2(-width * 0.5 - 1.5, bar_y - 1.5, width + 3.0, 7.0), INK, true)
	draw_rect(Rect2(-width * 0.5, bar_y, width, 4.0), Color("eadfbe"), true)
	draw_rect(Rect2(-width * 0.5, bar_y, width * clampf(health / max_health, 0.0, 1.0), 4.0), Color("d95863"), true)
	if max_armour > 0.0:
		var armour_y := bar_y - 7.0
		draw_rect(Rect2(-width * 0.5 - 1.5, armour_y - 1.5, width + 3.0, 6.0), INK, true)
		draw_rect(Rect2(-width * 0.5, armour_y, width * clampf(armour / max_armour, 0.0, 1.0), 3.0), Color.WHITE if armour_flash > 0.0 else ARMOUR_COLOR, true)

func _draw_armour_plates() -> void:
	var armour_tint := Color.WHITE if armour_flash > 0.0 else ARMOUR_COLOR
	for side in [-1.0, 1.0]:
		var plate := PackedVector2Array([Vector2(-8, side * (radius - 2.0)), Vector2(4, side * (radius + 5.0)), Vector2(14, side * (radius - 1.0)), Vector2(9, side * (radius - 10.0))])
		draw_colored_polygon(plate, INK)
		var inset := PackedVector2Array([Vector2(-5, side * (radius - 1.0)), Vector2(4, side * (radius + 1.5)), Vector2(10, side * (radius - 2.0)), Vector2(7, side * (radius - 7.0))])
		draw_colored_polygon(inset, armour_tint)

func _outlined_circle(at: Vector2, size: float, fill: Color, outline_width: float = 3.0) -> void:
	draw_circle(at, size + outline_width, INK)
	draw_circle(at, size, fill)

func _draw_bird() -> void:
	var wing := sin(age * 18.0) * 7.0
	var left_wing := PackedVector2Array([Vector2(-4, -2), Vector2(-13, -11 - wing), Vector2(-28, -5), Vector2(-14, 8)])
	var right_wing := PackedVector2Array([Vector2(-4, 2), Vector2(-13, 11 + wing), Vector2(-28, 5), Vector2(-14, -8)])
	draw_colored_polygon(left_wing, INK)
	draw_colored_polygon(right_wing, INK)
	draw_colored_polygon(left_wing, tint.lightened(0.12))
	draw_colored_polygon(right_wing, tint.lightened(0.12))
	_outlined_circle(Vector2(1, 0), 12.0, tint)
	var beak := PackedVector2Array([Vector2(11, -5), Vector2(25, 0), Vector2(11, 5)])
	draw_colored_polygon(beak, INK)
	draw_colored_polygon(PackedVector2Array([Vector2(12, -3), Vector2(22, 0), Vector2(12, 3)]), Color("f2c14e"))
	_outlined_circle(Vector2(7, -4), 2.2, Color.WHITE, 1.2)
	draw_circle(Vector2(8, -4), 1.0, INK)

func _draw_cat() -> void:
	var hop: float = absf(sin(age * 7.0)) * 4.0 if state == "pounce" else sin(age * 4.0)
	var body_color := Color.WHITE if hit_flash > 0.0 else tint
	if state == "telegraph":
		draw_arc(Vector2.ZERO, radius + 8.0 + sin(age * 15.0) * 2.0, 0.0, TAU, 28, Color("ef6f6c"), 5.0, true)
	_outlined_circle(Vector2(-6, hop), radius * 0.78, body_color.darkened(0.16))
	var head := Vector2(radius * 0.47, hop)
	_outlined_circle(head, radius * 0.63, body_color)
	var ear_a := PackedVector2Array([Vector2(radius * 0.2, -radius * 0.3 + hop), Vector2(radius * 0.3, -radius * 0.85 + hop), Vector2(radius * 0.62, -radius * 0.42 + hop)])
	var ear_b := PackedVector2Array([Vector2(radius * 0.58, -radius * 0.38 + hop), Vector2(radius * 0.9, -radius * 0.82 + hop), Vector2(radius * 1.0, -radius * 0.1 + hop)])
	draw_colored_polygon(ear_a, INK)
	draw_colored_polygon(ear_b, INK)
	draw_colored_polygon(ear_a, body_color)
	draw_colored_polygon(ear_b, body_color)
	_outlined_circle(Vector2(radius * 0.69, -5 + hop), 3.2, Color.WHITE, 1.2)
	draw_circle(Vector2(radius * 0.75, -5 + hop), 1.25, INK)
	draw_circle(Vector2(radius * 0.96, 3 + hop), 2.4, Color("8b4b52"))
	for offset in [-4.0, 4.0]:
		draw_line(Vector2(radius * 0.95, 6 + hop + offset * 0.35), Vector2(radius * 1.48, 6 + hop + offset), INK, 1.6, true)
	if enemy_kind == "alpha_cat":
		var crown := PackedVector2Array([Vector2(0, -radius - 4), Vector2(7, -radius - 16), Vector2(13, -radius - 5), Vector2(22, -radius - 17), Vector2(27, -radius + 1)])
		draw_polyline(crown, INK, 7.0, true)
		draw_polyline(crown, Color("f2c14e"), 3.5, true)

func _draw_owl() -> void:
	var flap := sin(age * 7.0) * 4.0
	var body_size := 34.0 if enemy_kind == "barn_owl" else 22.0
	var wing_left := PackedVector2Array([Vector2(-7, -7), Vector2(-body_size - 7, -18 - flap), Vector2(-body_size, 4), Vector2(-8, 12)])
	var wing_right := PackedVector2Array([Vector2(-7, 7), Vector2(-body_size - 7, 18 + flap), Vector2(-body_size, -4), Vector2(-8, -12)])
	draw_colored_polygon(wing_left, INK)
	draw_colored_polygon(wing_right, INK)
	draw_colored_polygon(wing_left, tint.lightened(0.14))
	draw_colored_polygon(wing_right, tint.lightened(0.14))
	_outlined_circle(Vector2(-3, 0), body_size, tint)
	_outlined_circle(Vector2(8, -9), 8.5 if enemy_kind == "owl" else 11.5, CREAM, 1.8)
	_outlined_circle(Vector2(8, 9), 8.5 if enemy_kind == "owl" else 11.5, CREAM, 1.8)
	draw_circle(Vector2(11, -8), 3.0, INK)
	draw_circle(Vector2(11, 8), 3.0, INK)
	var beak := PackedVector2Array([Vector2(15, -4), Vector2(27, 0), Vector2(15, 4)])
	draw_colored_polygon(beak, INK)
	draw_colored_polygon(PackedVector2Array([Vector2(16, -2), Vector2(24, 0), Vector2(16, 2)]), Color("e3ad3d"))

func _draw_snake() -> void:
	var points := PackedVector2Array()
	for segment in range(9):
		var x := -38.0 + segment * 8.0
		var y := sin(age * 8.0 - segment * 0.85) * 8.0
		points.append(Vector2(x, y))
	draw_polyline(points, INK, 18.0, true)
	draw_polyline(points, tint, 12.0, true)
	draw_polyline(points, tint.lightened(0.24), 3.0, true)
	var head_y := sin(age * 8.0 - 6.2) * 7.0
	_outlined_circle(Vector2(20, head_y), 12.5, tint)
	_outlined_circle(Vector2(25, -4 + head_y), 2.1, Color.WHITE, 1.0)
	draw_circle(Vector2(26, -4 + head_y), 0.9, INK)
	draw_line(Vector2(31, head_y), Vector2(41, head_y), Color("c94f57"), 2.2, true)
	draw_line(Vector2(40, head_y), Vector2(45, head_y - 3), Color("c94f57"), 1.6, true)
	draw_line(Vector2(40, head_y), Vector2(45, head_y + 3), Color("c94f57"), 1.6, true)

func _draw_raccoon() -> void:
	var bob := sin(age * 5.5) * 1.5
	if state == "brace":
		draw_arc(Vector2.ZERO, radius + 9.0, 0.0, TAU, 28, ARMOUR_COLOR, 5.0, true)
	_outlined_circle(Vector2(-7, bob), 24.0, Color("6e777c"))
	draw_arc(Vector2(-25, 5 + bob), 22.0, 1.5, 4.8, 18, INK, 10.0, true)
	draw_arc(Vector2(-25, 5 + bob), 22.0, 1.7, 2.3, 8, Color("d5c9ae"), 5.0, true)
	draw_arc(Vector2(-25, 5 + bob), 22.0, 3.0, 3.55, 8, Color("d5c9ae"), 5.0, true)
	_outlined_circle(Vector2(11, bob), 19.0, Color("a8a79d"))
	draw_line(Vector2(2, -7 + bob), Vector2(20, -7 + bob), INK, 11.0, true)
	_outlined_circle(Vector2(8, -8 + bob), 3.4, Color.WHITE, 1.0)
	_outlined_circle(Vector2(18, -8 + bob), 3.4, Color.WHITE, 1.0)
	draw_circle(Vector2(9, -8 + bob), 1.2, INK)
	draw_circle(Vector2(19, -8 + bob), 1.2, INK)
	_outlined_circle(Vector2(28, 1 + bob), 4.0, Color("513d46"), 1.2)
	draw_circle(Vector2(-2, 15 + bob), 15.0, INK)
	draw_circle(Vector2(-2, 15 + bob), 11.5, ARMOUR_COLOR if armour > 0.0 else Color("b9a787"))
	draw_circle(Vector2(-2, 15 + bob), 3.0, INK)

func _draw_fox() -> void:
	var bob := sin(age * 8.0) * 2.0
	if state == "telegraph":
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 28, Color("ef6f6c"), 4.0, true)
	draw_line(Vector2(-14, 7 + bob), Vector2(-42, 16 + bob), INK, 17.0, true)
	draw_line(Vector2(-14, 7 + bob), Vector2(-42, 16 + bob), tint, 11.0, true)
	draw_line(Vector2(-35, 14 + bob), Vector2(-45, 17 + bob), CREAM, 8.0, true)
	_outlined_circle(Vector2(-2, bob), 21.0, tint)
	var head := PackedVector2Array([Vector2(4, -17 + bob), Vector2(27, bob), Vector2(4, 17 + bob), Vector2(-4, bob)])
	draw_colored_polygon(head, INK)
	var face := PackedVector2Array([Vector2(5, -13 + bob), Vector2(23, bob), Vector2(5, 13 + bob), Vector2(-1, bob)])
	draw_colored_polygon(face, tint.lightened(0.08))
	var muzzle := PackedVector2Array([Vector2(10, -8 + bob), Vector2(24, bob), Vector2(10, 8 + bob)])
	draw_colored_polygon(muzzle, CREAM)
	_outlined_circle(Vector2(27, bob), 3.2, Color("513d46"), 1.0)
	_outlined_circle(Vector2(10, -7 + bob), 2.5, Color.WHITE, 1.0)
	draw_circle(Vector2(11, -7 + bob), 1.0, INK)

func _draw_dog() -> void:
	var bob := sin(age * 4.0) * 1.5
	if state == "brace":
		draw_arc(Vector2.ZERO, radius + 10.0, 0.0, TAU, 32, Color("d95863"), 6.0, true)
	_outlined_circle(Vector2(-8, bob), 37.0, tint.darkened(0.08))
	_outlined_circle(Vector2(20, bob), 28.0, tint)
	draw_line(Vector2(8, -19 + bob), Vector2(-1, -38 + bob), INK, 15.0, true)
	draw_line(Vector2(8, 19 + bob), Vector2(-1, 38 + bob), INK, 15.0, true)
	draw_line(Vector2(8, -19 + bob), Vector2(0, -35 + bob), tint.darkened(0.25), 9.0, true)
	draw_line(Vector2(8, 19 + bob), Vector2(0, 35 + bob), tint.darkened(0.25), 9.0, true)
	_outlined_circle(Vector2(34, bob), 14.0, CREAM)
	_outlined_circle(Vector2(46, bob), 5.0, Color("513d46"), 1.5)
	_outlined_circle(Vector2(25, -10 + bob), 4.3, Color.WHITE, 1.2)
	draw_circle(Vector2(27, -10 + bob), 1.6, INK)
	draw_line(Vector2(1, -27 + bob), Vector2(1, 27 + bob), INK, 9.0, true)
	draw_line(Vector2(1, -25 + bob), Vector2(1, 25 + bob), Color("d95863"), 5.0, true)
	for side in [-1.0, 1.0]:
		draw_circle(Vector2(1, side * 18 + bob), 2.5, Color("f2c14e"))
