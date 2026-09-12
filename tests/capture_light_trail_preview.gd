extends SceneTree

func _init() -> void:
	call_deferred("_run")

func capture(label: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/light-trail-%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	game.current_wave = 2
	game._open_upgrade_draft()
	await capture("upgrade")
	game._on_upgrade_selected("light_trail")
	paused = true
	var trail = get_nodes_in_group("light_trails").front()
	trail.last_position = Vector2(-480, 80)
	for i in range(1, 61):
		var t := float(i) / 60.0
		game.player.position = Vector2(-480 + t * 480, 80 + sin(t * PI * 1.6) * 90)
		trail._physics_process(0.04)
	game._spawn_enemy("cat")
	var enemy = get_nodes_in_group("enemies").back()
	enemy.position = Vector2(-168, 80 + sin(0.65 * PI * 1.6) * 90)
	enemy.spawn_scale = 1.0
	trail._physics_process(0.2)
	enemy.queue_redraw()
	game.hud.toast_label.hide()
	game.hud.update_stats(2500, 3, 30, 100, 100, 0.4, game.player.get_active_buffs(), 1.0)
	await capture("fresh")
	trail._physics_process(1.5)
	await capture("fading")
	trail._physics_process(3.0)
	await capture("expired")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit()
