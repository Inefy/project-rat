extends SceneTree
## Capture the production four-wing owl, including a live attack warning.

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	seed(3)
	root.size = Vector2i(1280,720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999.0
	game.current_wave = 3
	game.player.autofire = false
	game.player.set_physics_process(false)
	game.player.position = Vector2.ZERO
	game.player._update_aim(Vector2.RIGHT)
	game.hud.set_encounter("RANGED SIEGE")
	var offsets := [Vector2(-235,-125),Vector2(245,-115),Vector2(-210,145),Vector2(230,135)]
	var facings := [PI/4,PI*3/4,PI*7/4,PI*5/4]
	for i in range(offsets.size()):
		game._spawn_enemy("owl")
		var owl = get_nodes_in_group("enemies").back()
		owl.elite = false
		owl.scale = Vector2.ONE
		owl.global_position = game.player.global_position+offsets[i]
		owl.rotation = facings[i]
		owl.spawn_scale = 1.0
		if i == 1:
			owl.ranged_windup = true
			owl.ranged_clock = .30
			owl.ranged_direction = -offsets[i].normalized()
		if i == 2:
			owl.health = owl.max_health*.72
		owl.process_mode = Node.PROCESS_MODE_DISABLED
		owl.queue_redraw()
	game.player.get_node("ArenaCamera").reset_smoothing()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/owl/in-game.png")
	game.audio.stop_all()
	await create_timer(.25,true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	quit()
