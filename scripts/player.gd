extends CharacterBody2D

signal died
signal health_changed(current: float, maximum: float)
signal shot_fired(position: Vector2)
signal pickup_collected(title: String, color: Color)
signal autofire_changed(enabled: bool)

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

var aim_direction := Vector2.RIGHT
var shot_cooldown := 0.0
var rapid_until := 0
var triple_until := 0
var power_until := 0
var haste_until := 0
var pierce_until := 0
var invulnerable_until := 0
var hit_flash_until := 0
var knockback_velocity := Vector2.ZERO
var alive := true
var anim_time := 0.0
var distance_walked := 0.0

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
	var speed_multiplier := 1.38 if now < haste_until else 1.0
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
	var directions: Array[float] = [0.0]
	if now < triple_until:
		directions = [-0.17, 0.0, 0.17]
	var damage := base_damage * (1.75 if now < power_until else 1.0)
	var shot_pierce := base_pierce + (2 if now < pierce_until else 0)
	var color := Color("ffe66d") if now < power_until else Color("62fff1")
	for offset in directions:
		var direction := aim_direction.rotated(offset)
		var bullet := BulletScript.new()
		bullet.setup(global_position + direction * 30.0, direction, bullet_speed, damage, bullet_radius, shot_pierce, color)
		get_parent().add_child(bullet)
	shot_fired.emit(global_position + aim_direction * 25.0)

func take_player_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if not alive or Time.get_ticks_msec() < invulnerable_until:
		return
	if shield_charges > 0:
		shield_charges -= 1
		invulnerable_until = Time.get_ticks_msec() + 650
		hit_flash_until = invulnerable_until
		knockback_velocity += knockback * 0.45
		pickup_collected.emit("SHIELD BLOCK", Color("6ef7ff"))
		queue_redraw()
		return
	health = max(0.0, health - amount)
	invulnerable_until = Time.get_ticks_msec() + 720
	hit_flash_until = Time.get_ticks_msec() + 180
	knockback_velocity += knockback
	health_changed.emit(health, max_health)
	if health <= 0.0:
		alive = false
		velocity = Vector2.ZERO
		died.emit()
	queue_redraw()

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
	return buffs

func _draw() -> void:
	var now := Time.get_ticks_msec()
	var flash := now < hit_flash_until
	var body_color := Color.WHITE if flash else Color("aab6d5")
	var outline := Color("ff5b9e") if flash else Color("e6f4ff")
	var moving_bob := sin(anim_time * 12.0) * 1.8 if velocity.length() > 30.0 else sin(anim_time * 4.0) * 0.8

	# Neon aura and shield rings.
	draw_circle(Vector2.ZERO, 34.0, Color(0.20, 0.95, 0.93, 0.055))
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

