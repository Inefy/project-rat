extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	_run()

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("SMOKE FAIL: " + message)

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	check(packed != null, "main scene loads")
	if packed == null:
		quit(1)
		return
	var game: Node = packed.instantiate()
	root.add_child(game)
	await process_frame
	check(game.get_script() != null and game.has_method("start_game"), "main game script compiles")
	if game.get_script() == null or not game.has_method("start_game"):
		game.queue_free()
		quit(1)
		return
	game.start_game()
	await process_frame
	check(game.game_state == "playing", "game enters playing state")
	check(is_instance_valid(game.player), "player spawns")
	check(game.player.health == game.player.max_health, "player starts at full health")
	Input.action_press("dash")
	await physics_frame
	await physics_frame
	Input.action_release("dash")
	check(game.player.get_dash_charge() < 1.0, "dash triggers its recharge cycle")

	game._begin_next_wave()
	game._spawn_enemy("bird")
	game._spawn_enemy("cat")
	game._spawn_enemy("owl")
	game._spawn_enemy("snake")
	game._spawn_enemy("raccoon")
	game._spawn_enemy("fox")
	await physics_frame
	check(game.current_wave == 1, "first wave begins")
	check(game._living_enemy_count() >= 6, "the full regular enemy roster spawns")
	var found_snake := false
	var found_raccoon := false
	for spawned_enemy in get_nodes_in_group("enemies"):
		if spawned_enemy.enemy_kind == "snake":
			found_snake = true
		if spawned_enemy.enemy_kind == "raccoon":
			found_raccoon = true
			var health_before_armour: float = spawned_enemy.health
			var armour_before: float = spawned_enemy.armour
			spawned_enemy.take_damage(10.0)
			check(spawned_enemy.health == health_before_armour, "armour absorbs damage before health")
			check(spawned_enemy.armour < armour_before, "armour loses durability when hit")
	check(found_snake, "snake archetype is active")
	check(found_raccoon, "armoured raccoon archetype is active")
	check(game.get_regular_enemy_count(22) > game.get_regular_enemy_count(10), "late waves contain more enemies")
	check(game.get_spawn_interval(22) < game.get_spawn_interval(10), "late waves spawn enemies faster")
	check(game.get_boss_kind(5) == "alpha_cat", "wave 5 uses the Alpha Cat boss")
	check(game.get_boss_kind(10) == "junkyard_dog", "wave 10 introduces the armoured dog boss")
	check(game.get_boss_kind(15) == "barn_owl", "wave 15 introduces the ranged owl boss")

	game.player.apply_powerup("shield")
	var health_before: float = game.player.health
	game.player.take_player_damage(25.0)
	check(game.player.health == health_before, "shield absorbs one hit")
	var base_interval_before: float = game.player.fire_interval
	var base_damage_before: float = game.player.base_damage
	var base_speed_before: float = game.player.move_speed
	game.player.apply_powerup("rapid")
	game.player.apply_powerup("triple")
	game.player.apply_powerup("power")
	game.player.apply_powerup("haste")
	check(game.player.fire_interval == base_interval_before, "temporary rapid pickup does not permanently raise fire rate")
	check(game.player.base_damage == base_damage_before, "temporary power pickup does not permanently raise damage")
	check(game.player.move_speed == base_speed_before, "temporary haste pickup does not permanently raise speed")
	game.player.fire()
	await physics_frame
	var bullet_count := 0
	for child in game.get_children():
		if child.get_script() != null and child.get_script().resource_path == "res://scripts/bullet.gd":
			bullet_count += 1
	check(bullet_count >= 3, "triple-shot spawns three projectiles")
	game.player.apply_upgrade("extra_pocket")
	game.player.apply_upgrade("heavy_seeds")
	check(game.player.permanent_projectiles == 2, "permanent multishot upgrade applies")
	check(game.player.base_damage > 18.0, "permanent damage upgrade applies")

	var enemies := get_nodes_in_group("enemies")
	if not enemies.is_empty():
		enemies[0].take_damage(999999.0)
	await process_frame
	check(game.kills >= 1, "enemy death advances kill counter")
	check(game.score > 0, "enemy death awards score")

	for kind in game.POWER_TYPES:
		game._spawn_powerup(kind, game.player.global_position + Vector2(260, 0))
	await physics_frame
	check(get_nodes_in_group("pickups").size() == game.POWER_TYPES.size(), "all power-up types instantiate")

	game._open_upgrade_draft()
	check(game.game_state == "upgrade", "wave mutation draft pauses the run")
	check(game.current_upgrade_ids.size() == 3, "mutation draft offers three choices")
	if not game.current_upgrade_ids.is_empty():
		game._on_upgrade_selected(game.current_upgrade_ids[0])
	check(game.game_state == "playing" and not paused, "choosing a mutation resumes play")

	game.player.shield_charges = 0
	game.player.invulnerable_until = 0
	game.player.take_player_damage(9999.0)
	await process_frame
	check(game.game_state == "game_over", "lethal damage reaches game-over state")

	game.audio.stop_all()
	await create_timer(0.2).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("SMOKE PASS: gameplay loop, enemies, combat, pickups, and game over")
		quit(0)
	else:
		quit(1)
