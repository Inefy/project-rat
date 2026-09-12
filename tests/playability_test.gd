extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("PLAYABILITY FAIL: " + message)

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.settings.cozy = false
	game.intermission = 999
	game.player.autofire = false
	# Drive clocks explicitly so input windows are independent of machine speed.
	paused = true
	var rat = game.player
	rat.active_time = 1.0
	rat.dash_ready_at = 1100
	rat._update_dash(Vector2.UP, true)
	check(rat.dash_count == 0, "early press waits for recharge")
	rat.active_time = 1.11
	rat._update_dash(Vector2.UP, false)
	check(rat.dash_count == 1 and rat.dash_direction == Vector2.UP, "buffered press dashes when recharge completes")
	rat._update_dash(Vector2.UP, false)
	check(rat.dash_count == 1, "buffered input is consumed once")
	var hp: float = rat.health
	rat.take_player_damage(20)
	check(rat.health == hp, "buffered dash protects against damage")
	rat.active_time = 3.0
	rat.dash_ready_at = 3300
	rat._update_dash(Vector2.LEFT, true)
	rat.active_time = 3.31
	rat._update_dash(Vector2.LEFT, false)
	check(rat.dash_count == 1, "expired buffer cannot cause a surprise dash")
	rat.yaw = PI
	rat._update_aim(Vector2.ZERO)
	rat._update_dash(Vector2.ZERO, true)
	check(rat.dash_direction.is_equal_approx(Vector2.DOWN), "stationary dash uses this frame's aiming direction")

	rat.apply_upgrade("snack_orbit")
	check(rat.orbit_until > rat.game_time_ms(), "wizard starts with a working orbit before finding a treat")
	game._spawn_powerup("rapid", rat.position + Vector2(140, 0))
	var pickup = get_nodes_in_group("pickups").back()
	pickup._physics_process(0.01)
	rat.position += Vector2(350, 0)
	rat.velocity = Vector2(790, 0)
	pickup.life = 0.01
	var distance_before: float = pickup.position.distance_to(rat.position)
	pickup._physics_process(0.05)
	check(pickup.magnetized and pickup.position.distance_to(rat.position) < distance_before, "attracted pickup follows beyond magnet range")
	check(not pickup.is_queued_for_deletion(), "attracted pickup cannot expire during escape")
	for i in range(20):
		pickup._physics_process(0.05)
	var rapid: int = rat.rapid_until
	pickup._on_body_entered(rat)
	check(pickup.collected_already and rapid > rat.game_time_ms() and rat.rapid_until == rapid, "homing pickup is collected exactly once")

	game.current_wave = 1
	game._spawn_enemy("bird")
	var bird = get_nodes_in_group("enemies").back()
	bird.take_damage(rat.base_damage)
	check(bird.dying, "opening bird drops in one accurate seed")
	game.wave_active = true
	game.combo = 8
	game.combo_expires = 1000
	game.run_clock = 1.1
	game._update_combo_decay()
	check(game.combo == 7, "missing a beat loses one multiplier instead of the entire streak")
	game.run_clock = 6
	game._update_combo_decay()
	check(game.combo == 1, "an abandoned streak fully decays")
	game.wave_active = false
	game.combo = 5
	game.combo_expires = 8000
	game._update_combo_decay(0.5)
	check(game.combo == 5 and game.combo_expires == 8500, "intermission preserves the streak window")
	game.combo = 7
	game.combo_expires = 9000
	game.streak_rewarded = false
	game._spawn_enemy("cat")
	var enemy = get_nodes_in_group("enemies").back()
	rapid = rat.rapid_until
	game.kills_without_treat = 11
	enemy.take_damage(99999)
	check(game.streak_rewarded and rat.rapid_until > rapid, "max streak awards Rapid Claws")
	check(game.kills_without_treat == 0, "twelve kills without a treat guarantee a drop")
	rapid = rat.rapid_until
	game._spawn_enemy("cat")
	get_nodes_in_group("enemies").back().take_damage(99999)
	check(rat.rapid_until == rapid, "streak reward happens only once per wave")

	game.game_state = "upgrade"
	var banked: int = game.pending_treats.size()
	var pickup_count := get_nodes_in_group("pickups").size()
	game._spawn_powerup("power", Vector2.ZERO)
	check(game.pending_treats.size() == banked + 1 and get_nodes_in_group("pickups").size() == pickup_count, "late wave-clear loot banks instead of spawning into a paused draft")
	game.game_state = "playing"
	game._begin_next_wave()
	check(not game.streak_rewarded and game.pending_treats.is_empty(), "new wave resets reward and activates banked treats")
	game._spawn_enemy("owl")
	var owl = get_nodes_in_group("enemies").back()
	owl.cleanup = true
	owl.attack_cooldown = 99
	owl._update_owl(1, Vector2.LEFT, 600)
	check(owl.velocity.length() >= 220, "ranged straggler closes the gap promptly")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	await process_frame
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("PLAYABILITY PASS: dash timing, pickup pursuit, starting power, streaks, loot and cleanup")
	quit(0 if failures.is_empty() else 1)
