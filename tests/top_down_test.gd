extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("TOP DOWN FAIL: " + message)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.audio.stop_all()
	game.audio.pool.clear()
	game.start_game()
	game.intermission = 999
	var rat = game.player
	rat.autofire = false
	rat.aim_assist = false
	rat.set_physics_process(false)
	var camera: Camera2D = rat.get_node("ArenaCamera")
	check(game.is_visible_in_tree() and rat.is_visible_in_tree(), "arena and rat render in 2D")
	check(root.get_camera_2d() == camera and root.get_camera_3d() == null, "top-down camera is the only active camera")
	check(camera.ignore_rotation, "aiming does not rotate the arena")
	check(DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_HIDDEN, "custom cursor works without pointer lock")
	rat._update_aim(Vector2.UP)
	Input.action_press("move_right")
	rat._physics_process(0)
	Input.action_release("move_right")
	check(rat.velocity.is_equal_approx(Vector2.RIGHT * rat.move_speed), "movement remains in screen directions while aiming up")
	rat.position = Vector2.ZERO
	rat._update_aim(Vector2.RIGHT)
	game._spawn_enemy("cat")
	var cat = get_nodes_in_group("enemies").back()
	cat.position = Vector2(200, 0)
	cat.spawn_scale = 1.0
	cat.set_physics_process(false)
	var health: float = cat.health
	rat.fire()
	var bullet = get_nodes_in_group("player_bullets").back()
	check(not bullet.uses_height, "top-down seeds use planar collision")
	for i in range(24):
		await physics_frame
	check(cat.health < health, "the reference cat takes damage through actual projectile physics")
	game._toggle_pause()
	check(paused, "pause stops the game")
	check(DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "pause exposes the menu cursor")
	game._toggle_pause()
	check(not paused and game.reticle.enabled, "resume restores top-down play and aiming")
	game.return_to_menu()
	await process_frame
	game.start_game()
	check(root.get_camera_2d() == game.player.get_node("ArenaCamera"), "restarting selects the new rat camera")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.audio.stop_all()
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("TOP DOWN PASS: camera, cursor, independent movement, cat projectile collision, pause and restart")
	quit(0 if failures.is_empty() else 1)
