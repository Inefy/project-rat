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
	await physics_frame
	check(game.current_wave == 1, "first wave begins")
	check(game._living_enemy_count() >= 4, "all core enemy types spawn")
	var found_snake := false
	for spawned_enemy in get_nodes_in_group("enemies"):
		if spawned_enemy.enemy_kind == "snake":
			found_snake = true
	check(found_snake, "snake archetype is active")

	game.player.apply_powerup("shield")
	var health_before: float = game.player.health
	game.player.take_player_damage(25.0)
	check(game.player.health == health_before, "shield absorbs one hit")
	game.player.apply_powerup("rapid")
	game.player.apply_powerup("triple")
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
