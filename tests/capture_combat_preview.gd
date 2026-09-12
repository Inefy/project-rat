extends SceneTree

var game: Node

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/combat-%s.png" % label)

func clear_enemies() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()
	game._clear_enemy_projectiles()
	await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	var no_buffs: Array[String] = []
	paused = true
	for entry in [["alpha_cat", 5, "pounce"], ["junkyard_dog", 10, "ring"], ["barn_owl", 15, "sweep"], ["barn_owl", 15, "dive"]]:
		await clear_enemies()
		game.current_wave = entry[1]
		game._spawn_enemy(entry[0])
		var boss = game.active_boss
		boss.position = Vector2(280, -60)
		boss.spawn_scale = 1.0
		boss.take_damage(boss.max_health * 0.68)
		var direction: Vector2 = boss.position.direction_to(game.player.position)
		if entry[2] == "ring":
			boss.boss_patterns._begin_rings(direction, 3)
			boss.boss_patterns._release_attack()
			for shot in get_nodes_in_group("enemy_projectiles"):
				shot._physics_process(0.45)
		else:
			boss.boss_patterns._windup(entry[2], direction, 0.2)
		boss.queue_redraw()
		game.hud.update_stats(25000, entry[1], 200, 100, 100, 0, no_buffs, 1.0)
		game.hud.set_boss_status(entry[0].replace("_", " ").to_upper(), 3, boss.health / boss.max_health)
		game.hud.toast_label.modulate.a = 0
		await capture(entry[0] + "-" + entry[2])
	await clear_enemies()
	game.current_wave = 18
	game.run_clock = 900
	game.encounter = "BIRD SWARM"
	game.rng.seed = 413
	for i in range(180):
		game._spawn_enemy(game._encounter_enemy(i))
		var enemy = get_nodes_in_group("enemies").back()
		var angle := i * 2.399963
		enemy.position = Vector2.from_angle(angle) * (150.0 + sqrt(float(i) / 180.0) * 560.0)
		enemy.spawn_scale = 1.0
	game.hud.update_stats(25000, 18, 200, 100, 100, 0.3, no_buffs, 1.0)
	await capture("horde")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit()
