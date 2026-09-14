extends SceneTree
## Stage real production birds at several facings, with a live health bar.

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	seed(1)
	root.size = Vector2i(1280,720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999.0
	game.current_wave = 1
	game.player.autofire = false
	game.player.set_physics_process(false)
	game.player.position = Vector2.ZERO
	game.player._update_aim(Vector2.RIGHT)
	game.hud.set_encounter("BIRD SWARM")
	var offsets := [Vector2(-235,-125),Vector2(245,-115),Vector2(-210,145),Vector2(230,135)]
	var facings := [PI/4,PI*3/4,PI*7/4,PI*5/4]
	for i in range(offsets.size()):
		game._spawn_enemy("bird")
		var bird = get_nodes_in_group("enemies").back()
		bird.elite = false
		bird.scale = Vector2.ONE
		bird.global_position = game.player.global_position+offsets[i]
		bird.rotation = facings[i]
		bird.spawn_scale = 1.0
		if i == 2:
			bird.health = bird.max_health*.72
		bird.process_mode = Node.PROCESS_MODE_DISABLED
		bird.queue_redraw()
	game.player.get_node("ArenaCamera").reset_smoothing()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/bird/in-game.png")
	game.audio.stop_all()
	await create_timer(.25,true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit()
