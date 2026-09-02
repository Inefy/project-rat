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
	game.start_game()
	await process_frame
	check(game.game_state == "playing", "game enters playing state")
	check(is_instance_valid(game.player), "player spawns")
	check(game.player.health == game.player.max_health, "player starts at full health")

	game._begin_next_wave()
	game._spawn_enemy("bird")
	game._spawn_enemy("cat")
	game._spawn_enemy("owl")
	await physics_frame
	check(game.current_wave == 1, "first wave begins")
	check(game._living_enemy_count() >= 3, "all core enemy types spawn")

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

	var enemies := get_nodes_in_group("enemies")
	if not enemies.is_empty():
		enemies[0].take_damage(999999.0)
	await process_frame
	check(game.kills >= 1, "enemy death advances kill counter")
	check(game.score > 0, "enemy death awards score")

	for kind in game.POWER_TYPES:
		game._spawn_powerup(kind, game.player.global_position + Vector2(60, 0))
	await physics_frame
	check(get_nodes_in_group("pickups").size() == game.POWER_TYPES.size(), "all power-up types instantiate")

	game.player.shield_charges = 0
	game.player.invulnerable_until = 0
	game.player.take_player_damage(9999.0)
	await process_frame
	check(game.game_state == "game_over", "lethal damage reaches game-over state")

	if failures.is_empty():
		print("SMOKE PASS: gameplay loop, enemies, combat, pickups, and game over")
		quit(0)
	else:
		quit(1)
