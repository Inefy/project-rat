extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("RUN IMPROVEMENTS FAIL: " + message)

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	game.rng.seed = 3271
	check(game.rerolls_remaining == 2, "new runs have two rerolls")
	game.current_wave = 1
	game._open_upgrade_draft()
	var first: Array = game.current_upgrade_ids.duplicate()
	game._reroll_upgrades()
	check(game.current_upgrade_ids == first and game.rerolls_remaining == 2, "opening choices cannot waste a reroll")
	check(game.hud.reroll_button.disabled, "unavailable reroll is disabled")
	game._on_upgrade_selected("pinball")
	game.current_wave = 4
	game._open_upgrade_draft()
	var previous: Array = game.current_upgrade_ids.duplicate()
	var levels: Dictionary = game.player.upgrade_levels.duplicate()
	game.hud.reroll_button.pressed.emit()
	check(paused and game.game_state == "upgrade", "reroll keeps the world paused")
	check(game.rerolls_remaining == 1 and game.player.upgrade_levels == levels, "button spends one reroll without awarding an upgrade")
	check(game.current_upgrade_ids.size() == 3, "reroll fills three cards")
	for id in game.current_upgrade_ids:
		check(id not in previous and game.player.can_take_upgrade(id), "reroll offers fresh eligible choices")
	check(game.hud.upgrade_cards.get_child(0).has_focus(), "rerolled cards retain keyboard/controller focus")
	check("Alpha Cat" in game.hud.draft_context.text and "Bounce" in game.hud.draft_build.text, "draft shows boss preview and owned build")
	game._on_upgrade_selected(game.current_upgrade_ids[0])
	game.current_wave = 2
	game._open_upgrade_draft()
	check("light_trail" in game.current_upgrade_ids, "wave two guarantees Light Trail")
	var key := InputEventKey.new()
	key.keycode = KEY_R
	key.pressed = true
	key.echo = true
	game._unhandled_input(key)
	check(game.rerolls_remaining == 1, "key repeat cannot consume a reroll")
	key.echo = false
	game._unhandled_input(key)
	check(game.rerolls_remaining == 0 and "light_trail" in game.current_upgrade_ids, "keyboard reroll preserves guaranteed Light Trail")
	var unique := {}
	for id in game.current_upgrade_ids:
		unique[id] = true
	check(unique.size() == game.current_upgrade_ids.size(), "guaranteed card never duplicates")
	previous = game.current_upgrade_ids.duplicate()
	game._reroll_upgrades()
	check(game.current_upgrade_ids == previous and game.hud.reroll_button.disabled, "empty reroll budget leaves choices intact")
	game.boss_reward_pending = true
	game._on_upgrade_selected("light_trail")
	check(game.game_state == "upgrade" and game.rerolls_remaining == 0, "bonus draft does not reset rerolls")
	game._on_upgrade_selected(game.current_upgrade_ids[0])
	game.rerolls_remaining = 2
	game.current_wave = 4
	for id in game.UPGRADES:
		if id != "heavy_seeds":
			while game.player.can_take_upgrade(id):
				game.player.apply_upgrade(id)
	game._open_upgrade_draft()
	game._reroll_upgrades()
	check(game.current_upgrade_ids == ["heavy_seeds"] and game.rerolls_remaining == 2, "one remaining option cannot waste a reroll")
	game._on_upgrade_selected("heavy_seeds")
	game._reroll_upgrades()
	check(game.rerolls_remaining == 2, "reroll outside a draft is ignored")
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	await process_frame
	check(game.rerolls_remaining == 2, "restart replenishes rerolls")
	# Test the corner-clamping failure case across many deterministic arrivals.
	for position in [Vector2.ZERO, Vector2(-1170, -670), Vector2(1170, -670), Vector2(-1170, 670), Vector2(1170, 670), Vector2(0, 670)]:
		game.player.position = position
		for attempt in range(500):
			var at: Vector2 = game._random_spawn_position()
			check(at.distance_to(position) > 440, "arrival stays outside the player's safety radius")
			check(game.ARENA.grow(-44).has_point(at), "arrival stays inside the arena")
	game.player.position = Vector2.ZERO
	game.player.invulnerable_until = 0
	# Every enemy, including bosses, is shootable but cannot hurt the player
	# or start an attack while its arrival indicator is on screen.
	for kind in ["bird", "cat", "owl", "snake", "raccoon", "fox", "alpha_cat", "junkyard_dog", "barn_owl"]:
		game._spawn_enemy(kind)
		var enemy = get_nodes_in_group("enemies").back()
		enemy.position = Vector2(5, 0)
		enemy.attack_cooldown = 0
		var health: float = game.player.health
		var shots := get_nodes_in_group("enemy_projectiles").size()
		enemy._physics_process(0.2)
		enemy._physics_process(0.2)
		check(enemy.position == Vector2(5, 0) and enemy.velocity == Vector2.ZERO, kind + " stays still during arrival")
		check(game.player.health == health and get_nodes_in_group("enemy_projectiles").size() == shots, kind + " cannot deal damage or fire during arrival")
		var enemy_health: float = enemy.health
		enemy.take_damage(1)
		check(enemy.health < enemy_health, kind + " can still be shot during arrival")
		if kind == "bird":
			game._toggle_pause()
			var grace: float = enemy.spawn_grace
			await create_timer(0.08, true).timeout
			check(enemy.spawn_grace == grace, "pause freezes the arrival countdown")
			game._toggle_pause()
			enemy._physics_process(0.3)
			check(game.player.health == health, "last arrival frame is still harmless")
			enemy._physics_process(0.01)
			check(game.player.health < health, "contact damage resumes after arrival")
		enemy.free()
	# Verify the real damage-to-death path and restore the user's records.
	var saved := {}
	for path in ["user://highscore.save", "user://records.cfg"]:
		saved[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	game.player.invulnerable_until = 0
	game.player.take_player_damage(99999, Vector2.ZERO, "venom")
	check(game.game_state == "game_over" and "venom" in game.hud.death_tip.text and "Change direction" in game.hud.death_tip.text, "death names the hit and its counter")
	for path in saved:
		if saved[path] == null:
			DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(saved[path])
			file.close()
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("RUN IMPROVEMENTS PASS: rerolls, build context, 3000 safe arrivals, spawn protection, and death feedback")
	quit(0 if failures.is_empty() else 1)
