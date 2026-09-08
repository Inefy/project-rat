extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("BALANCE FAIL: " + message)

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999
	game.settings.cozy = false
	paused = true
	var rat = game.player
	rat.autofire = false
	rat.active_time = 10.0
	rat.apply_upgrade("snack_orbit")
	# A heap of banked loot must not buy permanent weapon buffs or orbit uptime.
	for i in range(40):
		for kind in game.POWER_TYPES:
			rat.apply_powerup(kind)
	var now: int = rat.game_time_ms()
	check(rat.rapid_until == now + 9000 and rat.power_until == now + 9000, "damage buffs cannot bank beyond nine seconds")
	check(rat.triple_until == now + 10000 and rat.pierce_until == now + 9000 and rat.haste_until == now + 9000, "all weapon and speed buffs have bounded reserves")
	check(rat.orbit_until == now + 8000 and rat.shield_charges == 2, "orbit and shields stay bounded after excess loot")
	rat.active_time += 11.0
	check(not rat.get_active_buffs().any(func(label: String): return label.begins_with("POWER") or label.begins_with("RAPID") or label.begins_with("TRIPLE") or label.begins_with("ORBIT")), "stockpiled buffs actually expire on the gameplay clock")
	rat.apply_powerup("rapid")
	check(rat.rapid_until == rat.game_time_ms() + 6000, "a pickup after expiry grants a fresh burst")

	for wave in [1, 5, 10, 15, 30]:
		check(game.get_regular_enemy_count(wave) > game.get_enemy_cap(wave), "wave %d has reserves beyond the crowd cap" % wave)
		check(game.get_enemy_cap(wave) <= 42, "crowd cap stays bounded in overtime")
	check(game.get_regular_enemy_count(10) >= 70 and game.get_enemy_cap(15) >= 36, "mid and late runs sustain substantially larger crowds")
	game.current_wave = 10
	for recipe in ["BIRD SWARM", "CAT PINCER", "RANGED SIEGE", "ELITE HUNT"]:
		game.encounter = recipe
		check(game._encounter_enemy(4) == "raccoon" and game._encounter_enemy(9) == "fox", "late archetypes remain in " + recipe)
	var normal_interval: float = game.get_spawn_interval(10)
	var normal_count: int = game.get_regular_enemy_count(10)
	var normal_cap: int = game.get_enemy_cap(10)
	game.settings.cozy = true
	check(game.get_spawn_interval(10) > normal_interval and game.get_regular_enemy_count(10) < normal_count and game.get_enemy_cap(10) < normal_cap, "Cozy eases pacing and density")
	game.settings.cozy = false
	# Exercise the actual director: it fills the cap, stops, then replaces a kill.
	game.current_wave = 9
	game._begin_next_wave()
	for i in range(normal_cap + 5):
		game.spawn_cooldown = 0
		paused = false
		game._physics_process(0)
		paused = true
	check(game._living_enemy_count() == normal_cap, "director fills the larger cap without exceeding it")
	get_nodes_in_group("enemies").front().queue_free()
	await process_frame
	game.spawn_cooldown = 0
	paused = false
	game._physics_process(0)
	paused = true
	check(game._living_enemy_count() == normal_cap, "director replenishes a cleared slot")
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	await process_frame
	game.wave_active = false
	game.intermission = 999

	# Greedy but attainable builds at each story boss. Every pellet hits here,
	# making this an optimistic damage benchmark, not an automated playtest.
	for wave in [5, 10, 15]:
		var shooter = load("res://scripts/player.gd").new()
		game.add_child(shooter)
		shooter.autofire = false
		var upgrades: Array[String] = ["pinball", "extra_pocket", "extra_pocket", "heavy_seeds"]
		if wave >= 10:
			upgrades.append_array(["extra_pocket", "quick_whiskers", "quick_whiskers", "heavy_seeds", "heavy_seeds", "quick_whiskers"])
		if wave >= 15:
			upgrades.append_array(["quick_whiskers", "quick_whiskers", "quick_whiskers", "heavy_seeds", "heavy_seeds", "heavy_seeds"])
		for id in upgrades:
			shooter.apply_upgrade(id)
		var boss = load("res://scripts/enemy.gd").new()
		boss.setup(game.get_boss_kind(wave), shooter, wave)
		game.add_child(boss)
		for kind in ["rapid", "triple", "power"]:
			shooter.apply_powerup(kind)
		var seconds := 0.0
		while not boss.dying and seconds < 90.0:
			shooter.active_time = seconds
			shooter.fire()
			for bullet in get_nodes_in_group("player_bullets"):
				if not bullet.is_queued_for_deletion():
					bullet._on_body_entered(boss)
					bullet.queue_free()
			seconds += shooter.fire_interval * (shooter.RAPID_INTERVAL_MULTIPLIER if shooter.game_time_ms() < shooter.rapid_until else 1.0)
		check(boss.dying and seconds >= 6.0 and seconds < 45.0, "wave %d boss survives burst damage but remains killable (%.1fs)" % [wave, seconds])
		print("BOSS BENCHMARK wave %d: %.1fs with every pellet landing" % [wave, seconds])
		shooter.queue_free()
		boss.queue_free()
		await process_frame

	for kind in ["alpha_cat", "junkyard_dog", "barn_owl", "cat"]:
		var enemy = load("res://scripts/enemy.gd").new()
		enemy.setup(kind, rat, 15)
		game.add_child(enemy)
		check(not enemy.is_enraged(), "full-health enemies start calm")
		enemy.armour = 0
		enemy.take_damage(enemy.max_health * 0.51)
		check(enemy.is_enraged() == (kind != "cat"), "only bosses enrage below half health")
		if kind == "alpha_cat":
			enemy.state = "recover"
			enemy.state_clock = 0
			enemy._update_cat(0.01, Vector2.RIGHT)
			check(enemy.state_clock < 0.5, "enraged cat returns to its pounce sooner")
		elif kind == "junkyard_dog":
			enemy.state = "recover"
			enemy.state_clock = 0
			enemy._update_dog(0.01, Vector2.RIGHT)
			check(enemy.state_clock <= 0.5, "enraged dog returns to its charge sooner")
		elif kind == "barn_owl":
			enemy.ranged_windup = true
			enemy.ranged_clock = 0
			enemy._update_owl(0.01, Vector2.RIGHT, 400)
			check(enemy.attack_cooldown < 0.8, "enraged owl fires volleys more often")
		enemy.queue_free()
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("BALANCE PASS: buff reserves, crowd pressure, boss durability and enrage")
	quit(0 if failures.is_empty() else 1)
