extends RefCounted

# Health thresholds change the move set. Every attack locks its aim before firing,
# and every sequence ends with a vulnerable recovery; transitions never block damage.
var body
var attack := ""
var cycle := 0
var chain_left := 0
var volleys_left := 0
var volley_index := 0
var shot_clock := 0.0
var locked_direction := Vector2.RIGHT
var ring_angle := 0.0

func _init(enemy: CharacterBody2D) -> void:
	body = enemy

func change_phase() -> void:
	attack = ""
	cycle = 0
	chain_left = 0
	volleys_left = 0
	body.ranged_windup = false
	body.state = "phase_shift"
	body.state_clock = 1.0
	body.velocity = Vector2.ZERO
	body.knockback_velocity = Vector2.ZERO

func update(delta: float, direction: Vector2, distance: float) -> void:
	body.state_clock -= delta
	match body.state:
		"stalk":
			var wanted: Vector2 = direction * body.move_speed
			if body.enemy_kind == "barn_owl":
				wanted = direction.rotated(PI * 0.5) * body.move_speed
				if distance > 420.0:
					wanted += direction * body.move_speed
				elif distance < 240.0:
					wanted -= direction * body.move_speed
			body.velocity = body.velocity.move_toward(wanted, 500.0 * delta)
			if body.state_clock <= 0.0 and distance < 780.0:
				_begin_cycle(direction)
		"phase_shift", "recover":
			body.velocity = body.velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
			if body.state_clock <= 0.0:
				body.state = "stalk"
				body.state_clock = 0.35
		"telegraph":
			body.velocity = body.velocity.move_toward(Vector2.ZERO, 1200.0 * delta)
			if body.state_clock > 0.22 and attack != "ring":
				locked_direction = direction
				body.pounce_direction = direction
			if body.state_clock <= 0.0:
				_release_attack()
		"pounce", "charge":
			# Bounces update pounce_direction in the enemy's movement controller.
			body.velocity = body.pounce_direction * _rush_speed()
			if attack == "charge" and body.boss_phase == 3:
				shot_clock -= delta
				if shot_clock <= 0.0:
					shot_clock += 0.18
					for side in [-1.0, 1.0]:
						_shoot(body.pounce_direction.rotated(side * PI * 0.5), 210.0, "bone")
			if body.state_clock <= 0.0:
				_finish_rush(direction)
		"burst":
			body.velocity = Vector2.ZERO
			shot_clock -= delta
			if shot_clock <= 0.0:
				var sweep := -0.6 + volley_index * 0.3
				_fan(locked_direction.rotated(sweep), 3, 0.16, 345.0)
				volley_index += 1
				volleys_left -= 1
				shot_clock += 0.24
				if volleys_left <= 0:
					_recover()

func _begin_cycle(direction: Vector2) -> void:
	cycle += 1
	match body.enemy_kind:
		"alpha_cat":
			chain_left = body.boss_phase
			_windup("pounce", direction, 0.7)
		"junkyard_dog":
			_windup("charge", direction, 0.85)
		"barn_owl":
			if body.boss_phase == 1:
				_windup("fan", direction, 0.7)
			elif body.boss_phase == 2:
				_windup("sweep" if cycle % 2 == 1 else "fan", direction, 0.8)
			else:
				match cycle % 3:
					1: _windup("sweep", direction, 0.8)
					2: _begin_rings(direction, 3)
					0: _windup("dive", direction, 0.75)

func _windup(kind: String, direction: Vector2, duration: float) -> void:
	attack = kind
	locked_direction = direction
	body.pounce_direction = direction
	body.state = "telegraph"
	body.state_clock = duration
	body.velocity = Vector2.ZERO

func _rush_speed() -> float:
	if attack == "charge":
		return 590.0 + body.boss_phase * 25.0
	return 650.0 + body.boss_phase * 25.0

func _rush_duration() -> float:
	return 0.8 if attack == "charge" else 0.48

func _release_attack() -> void:
	match attack:
		"pounce", "dive", "charge":
			body.state = "charge" if attack == "charge" else "pounce"
			body.state_clock = _rush_duration()
			body.velocity = locked_direction * _rush_speed()
			shot_clock = 0.18
		"fan":
			_fan(locked_direction, 5 if body.boss_phase == 1 else 7, 0.15, 330.0)
			_recover()
		"sweep":
			body.state = "burst"
			volleys_left = 5
			volley_index = 0
			shot_clock = 0.0
		"ring":
			_fire_ring()
			volleys_left -= 1
			if volleys_left > 0:
				ring_angle += 0.3
				_windup("ring", Vector2.from_angle(ring_angle), 0.65)
			else:
				_recover()

func _finish_rush(direction: Vector2) -> void:
	if body.enemy_kind == "alpha_cat":
		chain_left -= 1
		if chain_left > 0:
			_windup("pounce", direction, 0.55)
		elif body.boss_phase >= 2:
			_begin_rings(direction, 1)
		else:
			_recover()
	elif body.enemy_kind == "junkyard_dog" and body.boss_phase >= 2:
		_begin_rings(direction, body.boss_phase)
	else:
		_recover()

func _begin_rings(direction: Vector2, count: int) -> void:
	volleys_left = count
	# The gap starts toward the player, then rotates predictably between pulses.
	ring_angle = direction.angle()
	_windup("ring", direction, 0.8)

func _fire_ring() -> void:
	var count := 18 if body.boss_phase == 3 else 14
	var kind := "bone" if body.enemy_kind == "junkyard_dog" else "sonic"
	for i in range(count):
		var angle := TAU * float(i) / count + ring_angle
		if absf(angle_difference(ring_angle, angle)) < 0.62:
			continue
		_shoot(Vector2.from_angle(angle), 235.0, kind)

func _fan(direction: Vector2, count: int, spread: float, speed: float) -> void:
	for i in range(count):
		_shoot(direction.rotated((i - (count - 1) * 0.5) * spread), speed, "feather")

func _shoot(direction: Vector2, speed: float, kind: String) -> void:
	body.projectile_requested.emit(body.global_position + direction * (body.radius + 12.0), direction, speed, body.contact_damage * 0.45, kind)

func _recover() -> void:
	body.state = "recover"
	body.state_clock = 0.9 if body.enemy_kind != "junkyard_dog" else 1.15
	body.velocity = Vector2.ZERO

func draw_warnings(canvas: CanvasItem) -> void:
	if body.state == "phase_shift":
		canvas.draw_arc(Vector2.ZERO, body.radius + 25.0, 0, TAU, 48, Color("df5144"), 5.0, true)
		return
	if body.state != "telegraph":
		return
	var locked: bool = body.state_clock <= 0.22
	var color := Color("df5144") if locked else Color("f6c53f")
	var aim: Vector2 = locked_direction.rotated(-body.rotation)
	canvas.draw_arc(Vector2.ZERO, body.radius + 14.0, 0, TAU, 48, color, 3.0, true)
	if attack == "ring":
		var start: float = ring_angle - body.rotation + 0.62
		for radius in [90.0, 120.0]:
			canvas.draw_arc(Vector2.ZERO, radius, start, start + TAU - 1.24, 64, color, 4.0, true)
	elif attack in ["pounce", "charge", "dive"]:
		var reach: float = _rush_speed() * _rush_duration() / body.scale.x
		var side: Vector2 = aim.orthogonal() * body.radius
		canvas.draw_colored_polygon(PackedVector2Array([side, aim * reach + side, aim * reach - side, -side]), Color(color, 0.13))
		canvas.draw_line(aim * (body.radius + 10.0), aim * reach, color, 6.0 if locked else 3.0, true)
		if attack == "charge" and body.boss_phase == 3:
			for i in range(1, 5):
				var at: Vector2 = aim * reach * float(i) / 5.0
				canvas.draw_line(at - side * 2.0, at + side * 2.0, color, 2.0, true)
	else:
		var spread := 0.78 if attack == "sweep" else (0.3 if body.boss_phase == 1 else 0.45)
		for offset in [-spread, 0.0, spread]:
			var ray := aim.rotated(offset)
			canvas.draw_line(ray * (body.radius + 10.0), ray * 310.0, color, 3.0, true)
