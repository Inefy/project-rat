extends SceneTree
## Reproducible capture of the production fox in the real top-down arena.

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	seed(10)
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999.0
	game.current_wave = 10
	game.player.autofire = false
	game.player.set_physics_process(false)
	game.player.position = Vector2.ZERO
	game.player._update_aim(Vector2.RIGHT)
	game.hud.set_encounter("FOX AMBUSH")
	var offsets := [Vector2(-220, -105), Vector2(210, -95), Vector2(170, 145), Vector2(-170, 155)]
	for i in range(offsets.size()):
		game._spawn_enemy("fox")
		var fox = get_nodes_in_group("enemies").back()
		fox.elite = false
		fox.scale = Vector2.ONE
		fox.global_position = game.player.global_position + offsets[i]
		fox.rotation = offsets[i].angle() + PI
		fox.spawn_scale = 1.0
		if i == 1:
			fox.state = "telegraph"
			fox.state_clock = 0.25
			fox.pounce_direction = Vector2.from_angle(fox.rotation)
		if i == 3:
			fox.state = "dart"
			fox.pounce_direction = Vector2.from_angle(fox.rotation)
			fox.health = fox.max_health * 0.72
		fox.process_mode = Node.PROCESS_MODE_DISABLED
		fox.queue_redraw()
	game.player.get_node("ArenaCamera").reset_smoothing()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/fox/in-game.png")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit()
