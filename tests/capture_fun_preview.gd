extends SceneTree

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/fun-%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await capture("menu")
	game.settings.show_settings()
	await capture("settings")
	game.settings.hide_settings()
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	game.current_wave = 1
	game._open_upgrade_draft()
	await capture("draft")
	game._on_upgrade_selected("snack_orbit")
	game.player.apply_powerup("cheese")
	game.current_wave = 7
	game.hud.set_encounter("RANGED SIEGE")
	for entry in [["owl", Vector2(380, -120)], ["cat", Vector2(-310, -150)], ["raccoon", Vector2(320, 250)], ["snake", Vector2(-380, 220)]]:
		game._spawn_enemy(entry[0])
		var enemy = get_nodes_in_group("enemies").back()
		enemy.position = entry[1]
		enemy.spawn_scale = 1
		enemy.state = "telegraph"
		enemy.state_clock = 0.15
		enemy.pounce_direction = enemy.position.direction_to(game.player.position)
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
	await capture("gameplay")
	game._toggle_pause()
	await capture("pause")
	game.hud.set_paused(false)
	game.hud.show_victory(123456, 8)
	await capture("victory")
	game.hud.hide_victory()
	game.hud.show_game_over(5000, 7, 100, 5000, true)
	game.hud.show_death_tip("fox", 8, true)
	await capture("death")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	quit()
