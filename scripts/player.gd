extends CharacterBody2D

signal died
signal health_changed(current: float, maximum: float)
signal shot_fired(position: Vector2, powered: bool)
signal pickup_collected(title: String, color: Color)
signal autofire_changed(enabled: bool)
signal dash_started(position: Vector2)
signal damage_feedback(position: Vector2, blocked: bool)

const BulletScript = preload("res://scripts/bullet.gd")
const ARENA := Rect2(-1200.0, -700.0, 2400.0, 1400.0)

var max_health := 100.0
var health := 100.0
var move_speed := 315.0
var base_damage := 18.0
var fire_interval := 0.27
var bullet_speed := 920.0
var bullet_radius := 4.5
var base_pierce := 0
var shield_charges := 0
var autofire := true
var permanent_projectiles := 1
var drop_luck := 0.0
var magnet_radius := 150.0
var dash_cooldown_ms := 1350

var aim_direction := Vector2.RIGHT
var shot_cooldown := 0.0
var rapid_until := 0
var triple_until := 0
var power_until := 0
var haste_until := 0
var pierce_until := 0
var invulnerable_until := 0
var hit_flash_until := 0
var dash_ready_at := 0
var dash_until := 0
var dash_direction := Vector2.RIGHT
var knockback_velocity := Vector2.ZERO
var alive := true
var anim_time := 0.0
var distance_walked := 0.0
var upgrade_levels: Dictionary = {}

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 20
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 21.0
	collision.shape = circle
	add_child(collision)

	var camera := Camera2D.new()
	camera.name = "ArenaCamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.ignore_rotation = true
	camera.limit_left = -1200
	camera.limit_right = 1200
	camera.limit_top = -700
	camera.limit_bottom = 700
	add_child(camera)

	health_changed.emit(health, max_health)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not alive:
		return
	if event.is_action_pressed("toggle_autofire"):
		autofire = not autofire
		autofire_changed.emit(autofire)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	anim_time += delta
	var move_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var now := Time.get_ticks_msec()
	if Input.is_action_just_pressed("dash") and now >= dash_ready_at:
		dash_direction = move_input.normalized() if move_input.length_squared() > 0.01 else aim_direction
		dash_until = now + 190
		dash_ready_at = now + dash_cooldown_ms
		invulnerable_until = maxi(invulnerable_until, dash_until + 90)
		dash_started.emit(global_position)
	var speed_multiplier := 1.38 if now < haste_until else 1.0
	if now < dash_until:
		velocity = dash_direction * 790.0 + knockback_velocity * 0.15
	else:
		velocity = move_input * move_speed * speed_multiplier + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 950.0 * delta)
	move_and_slide()
	global_position.x = clamp(global_position.x, ARENA.position.x + 30.0, ARENA.end.x - 30.0)
	global_position.y = clamp(global_position.y, ARENA.position.y + 30.0, ARENA.end.y - 30.0)
	if move_input.length_squared() > 0.01:
		distance_walked += velocity.length() * delta

	var stick_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	if stick_aim.length() > 0.28:
		aim_direction = stick_aim.normalized()
	else:
		var mouse_delta := get_global_mouse_position() - global_position
		if mouse_delta.length() > 4.0:
			aim_direction = mouse_delta.normalized()
	rotation = aim_direction.angle()

	shot_cooldown -= delta
	var wants_to_fire := autofire or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("ui_accept") or stick_aim.length() > 0.28
	if wants_to_fire and shot_cooldown <= 0.0:
		fire()
		var rapid_multiplier := 0.48 if now < rapid_until else 1.0
		shot_cooldown = fire_interval * rapid_multiplier
	queue_redraw()

func fire() -> void:
	var now := Time.get_ticks_msec()
	var projectile_count := permanent_projectiles
	if now < triple_until:
		projectile_count = maxi(projectile_count, 3)
	var damage := base_damage * (1.75 if now < power_until else 1.0)
	var shot_pierce := base_pierce + (2 if now < pierce_until else 0)
	var color := Color("e98b43") if now < power_until else Color("fff1bf")
	for index in range(projectile_count):
		var offset := (float(index) - float(projectile_count - 1) * 0.5) * 0.17
		var direction := aim_direction.rotated(offset)
		var bullet := BulletScript.new()
		bullet.setup(global_position + direction * 30.0, direction, bullet_speed, damage, bullet_radius, shot_pierce, color)
		get_parent().add_child(bullet)
	shot_fired.emit(global_position + aim_direction * 25.0, now < power_until)

func take_player_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if not alive or Time.get_ticks_msec() < invulnerable_until:
		return
	if shield_charges > 0:
		shield_charges -= 1
		invulnerable_until = Time.get_ticks_msec() + 650
		hit_flash_until = invulnerable_until
		knockback_velocity += knockback * 0.45
		pickup_collected.emit("TIN LID BLOCK", Color("8fa7b3"))
		damage_feedback.emit(global_position, true)
		queue_redraw()
		return
	health = max(0.0, health - amount)
	invulnerable_until = Time.get_ticks_msec() + 720
	hit_flash_until = Time.get_ticks_msec() + 180
	knockback_velocity += knockback
	health_changed.emit(health, max_health)
	damage_feedback.emit(global_position, false)
	if health <= 0.0:
		alive = false
		velocity = Vector2.ZERO
		died.emit()
	queue_redraw()

func apply_upgrade(kind: String) -> void:
	upgrade_levels[kind] = int(upgrade_levels.get(kind, 0)) + 1
	match kind:
		"quick_whiskers":
			fire_interval = maxf(0.13, fire_interval * 0.90)
		"heavy_seeds":
			base_damage += 3.5
		"fleet_feet":
			move_speed = minf(420.0, move_speed + 20.0)
		"thick_fur":
			max_health += 16.0
			health = minf(max_health, health + 20.0)
			health_changed.emit(health, max_health)
		"long_teeth":
			base_pierce += 1
		"big_paws":
			bullet_radius = minf(8.25, bullet_radius + 1.0)
		"lucky_tail":
			drop_luck = minf(0.12, drop_luck + 0.03)
		"extra_pocket":
			permanent_projectiles = mini(4, permanent_projectiles + 1)
		"cheese_magnet":
			magnet_radius = minf(330.0, magnet_radius + 55.0)
	queue_redraw()

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func can_take_upgrade(kind: String) -> bool:
	var level := int(upgrade_levels.get(kind, 0))
	match kind:
		"quick_whiskers":
			return level < 7 and fire_interval > 0.131
		"heavy_seeds":
			return level < 9
		"fleet_feet":
			return level < 6 and move_speed < 419.0
		"thick_fur":
			return level < 6
		"long_teeth":
			return level < 4
		"big_paws":
			return level < 4 and bullet_radius < 8.2
		"lucky_tail":
			return level < 4 and drop_luck < 0.119
		"extra_pocket":
			return permanent_projectiles < 4
		"cheese_magnet":
			return level < 4 and magnet_radius < 329.0
	return true

func get_dash_charge() -> float:
	var now := Time.get_ticks_msec()
	if now >= dash_ready_at:
		return 1.0
	return clampf(1.0 - float(dash_ready_at - now) / float(dash_cooldown_ms), 0.0, 1.0)

func apply_powerup(kind: String) -> void:
	var now := Time.get_ticks_msec()
	match kind:
		"cheese":
			health = min(max_health, health + 24.0)
			health_changed.emit(health, max_health)
			pickup_collected.emit("CHEESE +24 HP", Color("f2c14e"))
		"rapid":
			rapid_until = max(rapid_until, now) + 11000
			pickup_collected.emit("RAPID CLAWS", Color("ef6f6c"))
		"triple":
			triple_until = max(triple_until, now) + 12000
			pickup_collected.emit("TRIPLE SEED", Color("8d79ad"))
		"power":
			power_until = max(power_until, now) + 11000
			pickup_collected.emit("POWER NIBBLE", Color("e89b4f"))
		"haste":
			haste_until = max(haste_until, now) + 10000
			pickup_collected.emit("SUGAR RUSH", Color("79a85b"))
		"shield":
			shield_charges = mini(2, shield_charges + 1)
			pickup_collected.emit("TIN-LID SHIELD", Color("8fa7b3"))
		"pierce":
			pierce_until = max(pierce_until, now) + 10000
			pickup_collected.emit("NEEDLE TEETH", Color("f4d7a1"))
	queue_redraw()

func get_active_buffs() -> Array[String]:
	var now := Time.get_ticks_msec()
	var buffs: Array[String] = []
	var mutation_count := 0
	for level in upgrade_levels.values():
		mutation_count += int(level)
	if mutation_count > 0:
		buffs.append("PERKS x%d" % mutation_count)
	if rapid_until > now:
		buffs.append("RAPID %ds" % int(ceil((rapid_until - now) / 1000.0)))
	if triple_until > now:
		buffs.append("TRIPLE %ds" % int(ceil((triple_until - now) / 1000.0)))
	if power_until > now:
		buffs.append("POWER %ds" % int(ceil((power_until - now) / 1000.0)))
	if haste_until > now:
		buffs.append("HASTE %ds" % int(ceil((haste_until - now) / 1000.0)))
	if pierce_until > now:
		buffs.append("PIERCE %ds" % int(ceil((pierce_until - now) / 1000.0)))
	if shield_charges > 0:
		buffs.append("SHIELD x%d" % shield_charges)
	if permanent_projectiles > 1:
		buffs.append("MULTISHOT x%d" % permanent_projectiles)
	return buffs

func _draw() -> void:
	var now := Time.get_ticks_msec()
	var flash := now < hit_flash_until
	var body_color := Color.WHITE if flash else Color("aaa69f")
	var outline := Color("d95863") if flash else Color("40354f")
	var moving_bob := sin(anim_time * 12.0) * 1.8 if velocity.length() > 30.0 else sin(anim_time * 4.0) * 0.8

	# Soft shadow and little dust puffs make the rat feel like a chunky cartoon toy.
	draw_set_transform(Vector2(0, 18), 0.0, Vector2(1.0, 0.42))
	draw_circle(Vector2.ZERO, 27.0, Color(0.24, 0.19, 0.24, 0.2))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if now < dash_until:
		for streak in range(4):
			var trail_start := Vector2(-30.0 - streak * 14.0, (streak - 1.5) * 7.0)
			draw_circle(trail_start - Vector2(20.0, 0.0), 7.0 - streak, Color(1.0, 0.94, 0.75, 0.62 - streak * 0.1))
	if shield_charges > 0:
		for ring in range(shield_charges):
			draw_arc(Vector2.ZERO, 31.0 + ring * 5.0, anim_time + ring, anim_time + ring + 4.7, 30, Color("40354f"), 5.0, true)
			draw_arc(Vector2.ZERO, 31.0 + ring * 5.0, anim_time + ring, anim_time + ring + 4.7, 30, Color("8fa7b3"), 2.5, true)

	# Tail curls behind the rat.
	var tail := PackedVector2Array()
	for i in range(13):
		var t := float(i) / 12.0
		tail.append(Vector2(-20.0 - t * 35.0, 7.0 + sin(t * PI * 1.7) * 13.0))
	draw_polyline(tail, outline, 8.0, true)
	draw_polyline(tail, Color("d98b91"), 4.0, true)

	# Feet, body, ears, muzzle.
	draw_circle(Vector2(-9.0, 18.0 + moving_bob), 9.0, outline)
	draw_circle(Vector2(-9.0, 18.0 + moving_bob), 6.0, Color("d98b91"))
	draw_circle(Vector2(10.0, 18.0 - moving_bob), 9.0, outline)
	draw_circle(Vector2(10.0, 18.0 - moving_bob), 6.0, Color("d98b91"))
	draw_circle(Vector2(-4.0, moving_bob), 23.0, outline)
	draw_circle(Vector2(-4.0, moving_bob), 19.0, body_color)
	draw_circle(Vector2(-8.0, -18.0 + moving_bob), 11.5, outline)
	draw_circle(Vector2(-8.0, -18.0 + moving_bob), 7.5, Color("d98b91"))
	draw_circle(Vector2(9.0, -15.0 + moving_bob), 10.5, outline)
	draw_circle(Vector2(9.0, -15.0 + moving_bob), 6.5, Color("d98b91"))
	draw_circle(Vector2(16.0, 2.0 + moving_bob), 15.5, outline)
	draw_circle(Vector2(16.0, 2.0 + moving_bob), 12.0, body_color.lightened(0.12))
	var snout := PackedVector2Array([Vector2(18, -5 + moving_bob), Vector2(34, 2 + moving_bob), Vector2(18, 8 + moving_bob)])
	draw_colored_polygon(snout, body_color.lightened(0.12))
	draw_circle(Vector2(34.0, 2.0 + moving_bob), 5.5, outline)
	draw_circle(Vector2(34.0, 2.0 + moving_bob), 3.5, Color("b85d68"))
	draw_circle(Vector2(15.0, -4.0 + moving_bob), 4.3, outline)
	draw_circle(Vector2(16.0, -5.0 + moving_bob), 1.2, Color.WHITE)
	# Whiskers.
	draw_line(Vector2(23, 4 + moving_bob), Vector2(43, 12 + moving_bob), outline, 1.8, true)
	draw_line(Vector2(23, 2 + moving_bob), Vector2(45, 2 + moving_bob), outline, 1.8, true)
	draw_line(Vector2(23, 0 + moving_bob), Vector2(42, -8 + moving_bob), outline, 1.8, true)
