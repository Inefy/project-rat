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
	var color := Color("ffe66d") if now < power_until else Color("62fff1")
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
		pickup_collected.emit("SHIELD BLOCK", Color("6ef7ff"))
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
			fire_interval = maxf(0.105, fire_interval * 0.88)
		"heavy_seeds":
			base_damage += 4.5
		"fleet_feet":
			move_speed = minf(455.0, move_speed + 24.0)
		"thick_fur":
			max_health += 20.0
			health = minf(max_health, health + 32.0)
			health_changed.emit(health, max_health)
		"long_teeth":
			base_pierce += 1
		"big_paws":
			bullet_radius = minf(9.0, bullet_radius + 1.15)
		"lucky_tail":
			drop_luck = minf(0.18, drop_luck + 0.035)
		"extra_pocket":
			permanent_projectiles = mini(4, permanent_projectiles + 1)
		"cheese_magnet":
			magnet_radius = minf(360.0, magnet_radius + 65.0)
	queue_redraw()

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func can_take_upgrade(kind: String) -> bool:
	match kind:
		"quick_whiskers":
			return fire_interval > 0.11
		"fleet_feet":
			return move_speed < 450.0
		"big_paws":
			return bullet_radius < 8.9
		"lucky_tail":
			return drop_luck < 0.175
		"extra_pocket":
			return permanent_projectiles < 4
		"cheese_magnet":
			return magnet_radius < 355.0
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
			health = min(max_health, health + 32.0)
			health_changed.emit(health, max_health)
			pickup_collected.emit("CHEESE +32 HP", Color("ffe66d"))
		"rapid":
			rapid_until = max(rapid_until, now) + 11000
			fire_interval = max(0.17, fire_interval * 0.975)
			pickup_collected.emit("RAPID CLAWS", Color("ff75bd"))
		"triple":
			triple_until = max(triple_until, now) + 12000
			pickup_collected.emit("TRIPLE SEED", Color("a58bff"))
		"power":
			power_until = max(power_until, now) + 11000
			base_damage += 0.75
			pickup_collected.emit("POWER NIBBLE", Color("ff9f43"))
		"haste":
			haste_until = max(haste_until, now) + 10000
			move_speed = min(390.0, move_speed + 2.0)
			pickup_collected.emit("SUGAR RUSH", Color("6dff95"))
		"shield":
			shield_charges = min(3, shield_charges + 1)
			pickup_collected.emit("TIN-CAN SHIELD", Color("6ef7ff"))
		"pierce":
			pierce_until = max(pierce_until, now) + 10000
			pickup_collected.emit("NEEDLE TEETH", Color("f1f6ff"))
	queue_redraw()

func get_active_buffs() -> Array[String]:
	var now := Time.get_ticks_msec()
	var buffs: Array[String] = []
	var mutation_count := 0
	for level in upgrade_levels.values():
		mutation_count += int(level)
	if mutation_count > 0:
		buffs.append("MUTATIONS x%d" % mutation_count)
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
	var body_color := Color.WHITE if flash else Color("aab6d5")
	var outline := Color("ff5b9e") if flash else Color("e6f4ff")
	var moving_bob := sin(anim_time * 12.0) * 1.8 if velocity.length() > 30.0 else sin(anim_time * 4.0) * 0.8

	# Neon aura and shield rings.
	draw_circle(Vector2.ZERO, 34.0, Color(0.20, 0.95, 0.93, 0.055))
	if now < dash_until:
		for streak in range(4):
			var trail_start := Vector2(-30.0 - streak * 14.0, (streak - 1.5) * 7.0)
			draw_line(trail_start, trail_start - Vector2(28.0, 0.0), Color(0.38, 1.0, 0.95, 0.65 - streak * 0.11), 3.0, true)
	if shield_charges > 0:
		for ring in range(shield_charges):
			draw_arc(Vector2.ZERO, 31.0 + ring * 4.0, anim_time + ring, anim_time + ring + 4.7, 36, Color(0.35, 0.95, 1.0, 0.75), 2.0, true)

	# Tail curls behind the rat.
	var tail := PackedVector2Array()
	for i in range(13):
		var t := float(i) / 12.0
		tail.append(Vector2(-20.0 - t * 35.0, 7.0 + sin(t * PI * 1.7) * 13.0))
	draw_polyline(tail, Color("ff85ba"), 5.0, true)
	draw_polyline(tail, Color(1.0, 0.75, 0.87, 0.75), 1.5, true)

	# Feet, body, ears, muzzle.
	draw_circle(Vector2(-9.0, 18.0 + moving_bob), 7.0, Color("ff85ba"))
	draw_circle(Vector2(10.0, 18.0 - moving_bob), 7.0, Color("ff85ba"))
	draw_circle(Vector2(-4.0, moving_bob), 23.0, outline)
	draw_circle(Vector2(-4.0, moving_bob), 19.5, body_color)
	draw_circle(Vector2(-8.0, -18.0 + moving_bob), 10.0, outline)
	draw_circle(Vector2(-8.0, -18.0 + moving_bob), 6.5, Color("ff91bd"))
	draw_circle(Vector2(9.0, -15.0 + moving_bob), 9.0, outline)
	draw_circle(Vector2(9.0, -15.0 + moving_bob), 5.5, Color("ff91bd"))
	draw_circle(Vector2(16.0, 2.0 + moving_bob), 13.0, body_color)
	var snout := PackedVector2Array([Vector2(18, -5 + moving_bob), Vector2(34, 2 + moving_bob), Vector2(18, 8 + moving_bob)])
	draw_colored_polygon(snout, body_color)
	draw_circle(Vector2(34.0, 2.0 + moving_bob), 4.0, Color("ff5b9e"))
	draw_circle(Vector2(15.0, -4.0 + moving_bob), 3.5, Color("081126"))
	draw_circle(Vector2(16.0, -5.0 + moving_bob), 1.2, Color.WHITE)
	# Whiskers.
	draw_line(Vector2(23, 4 + moving_bob), Vector2(42, 12 + moving_bob), Color(0.85, 0.95, 1.0, 0.8), 1.2, true)
	draw_line(Vector2(23, 2 + moving_bob), Vector2(44, 2 + moving_bob), Color(0.85, 0.95, 1.0, 0.8), 1.2, true)
	draw_line(Vector2(23, 0 + moving_bob), Vector2(41, -8 + moving_bob), Color(0.85, 0.95, 1.0, 0.8), 1.2, true)
