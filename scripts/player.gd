extends CharacterBody2D

signal died
signal health_changed(current: float, maximum: float)
signal shot_fired(position: Vector2, powered: bool)
signal pickup_collected(title: String, color: Color)
signal autofire_changed(enabled: bool)
signal dash_started(position: Vector2)
signal damage_feedback(position: Vector2, blocked: bool)

const BulletScript = preload("res://scripts/bullet.gd")
const LightTrailScript = preload("res://scripts/light_trail.gd")
const ARENA := Rect2(-1200.0, -700.0, 2400.0, 1400.0)
const RAPID_INTERVAL_MULTIPLIER := 0.68
const POWER_DAMAGE_MULTIPLIER := 1.35

var max_health := 100.0
var health := 100.0
var move_speed := 350.0
# Faster, lighter seeds keep the starting weapon active without increasing its sustained damage.
var base_damage := 11.5
var fire_interval := 0.15
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
var active_time := 0.0
var using_directional_aim := false
var last_damage_source := "garden raider"
var dash_count := 0
var orbit_until := 0
var orbit_hit_cooldown := 0.0
var aim_assist := false
var dash_buffer_until := -1

func game_time_ms() -> int:
	return int(active_time * 1000.0)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
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
	if event is InputEventMouseMotion and event.relative.length_squared() > 1.0:
		using_directional_aim = false
	if event is InputEventKey and event.pressed and not event.echo:
		for action in ["aim_left", "aim_right", "aim_up", "aim_down"]:
			if event.is_action_pressed(action):
				# Keep short taps even when press and release land between physics ticks.
				_update_aim(Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down"))
				break
	if event.is_action_pressed("toggle_autofire"):
		autofire = not autofire
		autofire_changed.emit(autofire)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	active_time += delta
	anim_time += delta
	_update_orbit(delta)
	var directional_aim := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
	_update_aim(directional_aim, delta)
	var move_input := _get_move_input()
	var now := game_time_ms()
	_update_dash(move_input, Input.is_action_just_pressed("dash"))
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
	rotation = aim_direction.angle()

	shot_cooldown -= delta
	var wants_to_fire := autofire or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("ui_accept") or directional_aim.length() > 0.28
	if wants_to_fire and shot_cooldown <= 0.0:
		fire()
		var rapid_multiplier := RAPID_INTERVAL_MULTIPLIER if now < rapid_until else 1.0
		shot_cooldown = fire_interval * rapid_multiplier
	queue_redraw()

func _update_dash(move_input: Vector2, pressed: bool) -> void:
	var now := game_time_ms()
	if pressed:
		dash_buffer_until = now + 140
	if now <= dash_buffer_until and now >= dash_ready_at:
		dash_buffer_until = -1
		dash_direction = move_input.normalized() if move_input.length_squared() > 0.01 else aim_direction
		dash_until = now + 190
		dash_ready_at = now + dash_cooldown_ms
		invulnerable_until = maxi(invulnerable_until, dash_until + 90)
		dash_count += 1
		dash_started.emit(global_position)

func _get_move_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func _update_aim(directional_aim: Vector2, _delta: float = 0.0) -> void:
	if directional_aim.length() > 0.28:
		using_directional_aim = true
		aim_direction = directional_aim.normalized()
	elif not using_directional_aim:
		var mouse_delta := get_global_mouse_position() - global_position
		if mouse_delta.length() > 4.0:
			aim_direction = mouse_delta.normalized()
	if aim_assist:
		var best_angle := 0.22
		var assisted := aim_direction
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.dying or global_position.distance_to(enemy.global_position) > 650.0:
				continue
			var toward: Vector2 = global_position.direction_to(enemy.global_position)
			var angle := absf(aim_direction.angle_to(toward))
			if angle < best_angle:
				best_angle = angle
				assisted = toward
		aim_direction = aim_direction.lerp(assisted, 0.35).normalized()

func fire() -> void:
	var now := game_time_ms()
	var projectile_count := permanent_projectiles
	if now < triple_until:
		projectile_count = mini(projectile_count + 2, 6)
	var damage := base_damage * (POWER_DAMAGE_MULTIPLIER if now < power_until else 1.0)
	var shot_pierce := base_pierce + (2 if now < pierce_until else 0)
	var color := Color("e98b43") if now < power_until else Color("fff1bf")
	for index in range(projectile_count):
		var offset := (float(index) - float(projectile_count - 1) * 0.5) * 0.17
		var direction := aim_direction.rotated(offset)
		var bullet := BulletScript.new()
		bullet.setup(global_position + direction * 30.0, direction, bullet_speed, damage, bullet_radius, shot_pierce, color)
		_configure_bullet(bullet)
		bullet.bounces_left = int(upgrade_levels.get("pinball", 0))
		bullet.split_on_bounce = upgrade_levels.get("split_acorns", 0) > 0
		get_parent().add_child(bullet)
	shot_fired.emit(global_position + aim_direction * 25.0, now < power_until)

func _configure_bullet(_bullet: Area2D) -> void:
	pass

func take_player_damage(amount: float, knockback: Vector2 = Vector2.ZERO, source: String = "garden raider") -> void:
	if not alive or game_time_ms() < invulnerable_until:
		return
	if shield_charges > 0:
		shield_charges -= 1
		invulnerable_until = game_time_ms() + 650
		hit_flash_until = invulnerable_until
		knockback_velocity += knockback * 0.45
		pickup_collected.emit("TIN LID BLOCK", Color("8fa7b3"))
		damage_feedback.emit(global_position, true)
		queue_redraw()
		return
	last_damage_source = source
	health = max(0.0, health - amount)
	invulnerable_until = game_time_ms() + 720
	hit_flash_until = game_time_ms() + 180
	knockback_velocity += knockback
	health_changed.emit(health, max_health)
	damage_feedback.emit(global_position, false)
	if health <= 0.0:
		alive = false
		velocity = Vector2.ZERO
		died.emit()
	queue_redraw()

func apply_upgrade(kind: String) -> void:
	if not can_take_upgrade(kind):
		return
	upgrade_levels[kind] = int(upgrade_levels.get(kind, 0)) + 1
	match kind:
		"light_trail":
			var trail := LightTrailScript.new()
			trail.owner_player = self
			get_parent().add_child(trail)
		"snack_orbit":
			orbit_until = game_time_ms() + 6500
		"quick_whiskers":
			fire_interval = maxf(0.09, fire_interval * 0.90)
		"heavy_seeds":
			base_damage += 3.5
		"fleet_feet":
			move_speed = minf(470.0, move_speed + 20.0)
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
		"pinball", "scurry_bomb", "snack_orbit", "split_acorns", "dash_refund", "orbit_feast", "light_trail":
			var requires := {"split_acorns": "pinball", "dash_refund": "scurry_bomb", "orbit_feast": "snack_orbit"}
			return level < 1 and (not requires.has(kind) or upgrade_levels.get(requires[kind], 0) > 0)
		"quick_whiskers":
			return level < 7 and fire_interval > 0.091
		"heavy_seeds":
			return level < 9
		"fleet_feet":
			return level < 6 and move_speed < 469.0
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
	return false

func get_dash_charge() -> float:
	var now := game_time_ms()
	if now >= dash_ready_at:
		return 1.0
	return clampf(1.0 - float(dash_ready_at - now) / float(dash_cooldown_ms), 0.0, 1.0)

func apply_powerup(kind: String) -> void:
	if upgrade_levels.get("snack_orbit", 0) > 0:
		orbit_until = _extend_buff(orbit_until, 4000, 8000)
	if (kind == "cheese" and health >= max_health) or (kind == "shield" and shield_charges >= 2):
		power_until = _extend_buff(power_until, 2000, 9000)
		pickup_collected.emit("SPARE SNACK: +2s POWER (9s MAX)", Color("f2c14e"))
		return
	match kind:
		"cheese":
			health = min(max_health, health + 24.0)
			health_changed.emit(health, max_health)
			pickup_collected.emit("MYSTERY CHEESE +24 HP", Color("f2c14e"))
		"rapid":
			rapid_until = _extend_buff(rapid_until, 6000, 9000)
			pickup_collected.emit("CAFFEINATED CLAWS", Color("ef6f6c"))
		"triple":
			triple_until = _extend_buff(triple_until, 7000, 10000)
			pickup_collected.emit("THREE PEAS, ONE PLAN", Color("8d79ad"))
		"power":
			power_until = _extend_buff(power_until, 6000, 9000)
			pickup_collected.emit("ABSURD ACORN", Color("e89b4f"))
		"haste":
			haste_until = _extend_buff(haste_until, 6000, 9000)
			pickup_collected.emit("SUGAR-POWERED LEGS", Color("79a85b"))
		"shield":
			shield_charges = mini(2, shield_charges + 1)
			pickup_collected.emit("BIN LID OF DESTINY", Color("8fa7b3"))
		"pierce":
			pierce_until = _extend_buff(pierce_until, 6000, 9000)
			pickup_collected.emit("DENTIST'S NIGHTMARE", Color("f4d7a1"))
	queue_redraw()

func _extend_buff(expires_at: int, duration_ms: int, reserve_ms: int) -> int:
	# Banked loot and repeated pickups can top up a burst, never stockpile minutes.
	var now := game_time_ms()
	return mini(maxi(expires_at, now) + duration_ms, now + reserve_ms)

func get_active_buffs() -> Array[String]:
	var now := game_time_ms()
	var buffs: Array[String] = []
	var mutation_count := 0
	for level in upgrade_levels.values():
		mutation_count += int(level)
	if mutation_count > 0:
		buffs.append("PERKS x%d" % mutation_count)
	if orbit_until > now:
		buffs.append("ORBIT %ds" % int(ceil((orbit_until - now) / 1000.0)))
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

func get_build_description() -> String:
	var lines: Array[String] = []
	for id in upgrade_levels:
		if get_parent().UPGRADES.has(id):
			lines.append("%s Lv.%d" % [get_parent().UPGRADES[id]["title"], upgrade_levels[id]])
	return " / ".join(lines) if not lines.is_empty() else "First wave cleared: choose your build."

func _update_orbit(delta: float) -> void:
	orbit_hit_cooldown -= delta
	if game_time_ms() >= orbit_until or orbit_hit_cooldown > 0.0:
		return
	orbit_hit_cooldown = 0.22
	var count := 5 if upgrade_levels.get("orbit_feast", 0) > 0 else 3
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dying:
			continue
		for index in range(count):
			var point := global_position + Vector2.from_angle(anim_time * 3.2 + TAU * index / count) * 90.0
			if point.distance_to(enemy.global_position) < enemy.radius + 14.0:
				enemy.take_damage(base_damage * 0.65, global_position.direction_to(enemy.global_position) * 80.0)
				break

func _draw() -> void:
	# Recharge stays close to the rat so dodging never requires looking at the HUD.
	var charge := get_dash_charge()
	var start := -PI * 0.5 - rotation
	draw_arc(Vector2.ZERO, 40.0, start, start + TAU, 40, Color(0.20, 0.12, 0.17, 0.35), 3.0, true)
	draw_arc(Vector2.ZERO, 40.0, start, start + TAU * maxf(0.001, charge), 40, Color("fff0bf") if charge >= 1.0 else Color("f6c53f"), 3.0, true)
	if game_time_ms() < orbit_until:
		var count := 5 if upgrade_levels.get("orbit_feast", 0) > 0 else 3
		for index in range(count):
			var point := Vector2.from_angle(anim_time * 3.2 + TAU * index / count - rotation) * 90.0
			draw_circle(point, 12.0, Color("321f2b"))
			draw_texture_rect(preload("res://assets/sprites/seed_0.png"), Rect2(point - Vector2(14, 14), Vector2(28, 28)), false)
	var now := game_time_ms()
	var flash := now < hit_flash_until

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

	preload("res://scripts/model_sprites.gd").paint(self, "rat", rotation, 92.0, anim_time, 1.8 if velocity.length() > 30.0 else 0.5, 1.0, flash)
