extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("FIRST PERSON FAIL: " + message)

func run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999
	game.settings.aim_assist = false
	game.player.aim_assist = false
	game.player.autofire = false
	game.player.set_physics_process(false)
	var view = game.first_person
	var rat = game.player
	check(root.get_camera_3d() == view.camera, "first-person camera is current")
	check(DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "starting captures the mouse")
	check(view.models.size() == 23, "all enemy, pickup and projectile models load")
	for mesh in view.models.values():
		check(mesh.get_surface_count() > 0 and mesh.get_aabb().size.y > 0, "model contains merged geometry")
	rat.position = Vector2(-150, 30)
	rat.yaw = PI * 0.5
	rat.pitch = 0.12
	rat._update_aim(Vector2.ZERO)
	view._update_camera(0)
	check(view.camera.position.is_equal_approx(Vector3(-1.5, 0.58, 0.3)), "camera follows the rat at eye height")
	var ray: Vector3 = -view.camera.global_basis.z
	check(Vector2(ray.x, ray.z).normalized().is_equal_approx(rat.aim_direction), "camera and weapon share horizontal aim")
	check(is_equal_approx(ray.y, sin(rat.pitch)), "camera follows pitch")
	Input.action_press("move_right")
	rat._physics_process(0)
	Input.action_release("move_right")
	check(rat.velocity.distance_to(Vector2.DOWN * rat.move_speed) < 0.001, "strafe is relative to facing (%s)" % rat.velocity)
	rat._update_dash(rat._get_move_input(), true)
	check(rat.dash_direction.is_equal_approx(rat.aim_direction), "stationary dash follows view")

	# The direct strafe probe above intentionally advances CharacterBody2D; restore
	# the known test position before checking projectile alignment.
	rat.position = Vector2(-150, 30)
	game._spawn_enemy("cat")
	var enemy = get_nodes_in_group("enemies").back()
	enemy.position = Vector2(250, 30)
	enemy.spawn_scale = 1.0
	enemy.rotation = PI
	enemy.set_physics_process(false)
	rat.pitch = 0
	rat.fire()
	var bullet = get_nodes_in_group("player_bullets").back()
	check(bullet.uses_height and is_equal_approx(bullet.height, rat.EYE_HEIGHT), "level shots start at eye height")
	var health: float = enemy.health
	# Exercise actual physics overlap, not only the damage callback.
	for i in range(40):
		await physics_frame
	check(enemy.health < health, "a forward shot hits the enemy through physics (paused=%s, rat=%s, bullet=%s, enemy=%s, hp=%s/%s)" % [paused,rat.position,bullet.position if is_instance_valid(bullet) else "freed",enemy.position,enemy.health,health])
	rat.pitch = 1.0
	rat.fire()
	bullet = get_nodes_in_group("player_bullets").back()
	check(bullet.vertical_speed > 0 and bullet.velocity.length() < rat.bullet_speed, "pitch changes projectile trajectory")
	health = enemy.health
	for i in range(40):
		await physics_frame
	check(enemy.health == health, "shots above the enemy miss")
	view._sync_world()
	check(view.actors.has(enemy.get_instance_id()), "spawned enemies appear in 3D")
	var enemy_id: int = enemy.get_instance_id()
	enemy.queue_free()
	await process_frame
	view._sync_world()
	check(not view.actors.has(enemy_id), "deleted actors are removed")

	game._toggle_pause()
	check(paused and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "pause releases mouse")
	var old_yaw: float = rat.yaw
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 100)
	rat._unhandled_input(motion)
	check(rat.yaw == old_yaw, "pause blocks camera input")
	game._toggle_pause()
	check(not paused and (DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED), "resume captures mouse")
	game.current_wave = 1
	game._open_upgrade_draft()
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "draft releases mouse")
	game._on_upgrade_selected(game.current_upgrade_ids[0])
	check(DisplayServer.get_name() == "headless" or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "choosing an upgrade captures mouse")
	game.return_to_menu()
	await process_frame
	check(not is_instance_valid(view) and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "menu clears the 3D run and releases mouse")
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	game.player.set_physics_process(false)
	game.player.pitch = -0.03
	for entry in [["bird", Vector2(250, -60)], ["cat", Vector2(280, 85)], ["owl", Vector2(510, -175)], ["raccoon", Vector2(620, 150)]]:
		game._spawn_enemy(entry[0])
		var raider = get_nodes_in_group("enemies").back()
		raider.position = entry[1]
		raider.rotation = entry[1].direction_to(Vector2.ZERO).angle()
		raider.spawn_scale = 1
		raider.set_physics_process(false)
	game.first_person._process(0)
	check(get_nodes_in_group("run_entities").filter(func(node): return node is Node3D).size() == 1, "restart creates one 3D world")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/first-person.png")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("FIRST PERSON PASS: models, camera, movement, projectiles, pause, drafts and restart")
	quit(0 if failures.is_empty() else 1)
