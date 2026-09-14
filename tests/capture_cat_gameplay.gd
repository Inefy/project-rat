extends SceneTree
## Capture the production cat sprites in the top-down arena.

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999.0
	game.current_wave = 2
	game.player.autofire = false
	game.player.set_physics_process(false)
	game.player.position = Vector2.ZERO
	game.player._update_aim(Vector2.RIGHT)
	game.hud.set_encounter("CAT PINCER")
	var offsets := [Vector2(-200, -110), Vector2(220, -90), Vector2(180, 150)]
	for offset in offsets:
		game._spawn_enemy("cat")
		var cat = get_nodes_in_group("enemies").back()
		cat.global_position = game.player.global_position + offset
		cat.rotation = offset.angle() + PI
		if offset.y > 100:
			cat.state = "pounce"
			cat.rotation = -PI * 0.60
			cat.pounce_direction = Vector2.from_angle(cat.rotation)
		cat.spawn_scale = 1.0
		cat.health = cat.max_health * 0.72
		cat.process_mode = Node.PROCESS_MODE_DISABLED
		cat.queue_redraw()
	game.player.get_node("ArenaCamera").reset_smoothing()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/cat/in-game.png")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit()
