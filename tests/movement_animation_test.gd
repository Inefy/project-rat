extends SceneTree
## Check movement poses on production actors, including pause behavior.
const CAST := ["rat", "bird", "cat", "owl", "snake", "raccoon", "fox", "alpha_cat", "junkyard_dog", "barn_owl"]
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("MOVEMENT FAIL: " + message)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.audio.stop_all()
	game.intermission = 999.0
	game.player.autofire = false
	var actors: Array = [game.player]
	for i in range(1, CAST.size()):
		game._spawn_enemy(CAST[i])
		var actor = get_nodes_in_group("enemies").back()
		actor.global_position = Vector2.from_angle(i * TAU / 9.0) * 600.0
		actor.spawn_grace = 0.0
		actors.append(actor)
	var phases: Array[float] = []
	for actor in actors:
		phases.append(actor.movement_animation.phase)
	Input.action_press("move_right")
	await create_timer(0.2, true).timeout
	Input.action_release("move_right")
	check(game.player.position.x > 20.0, "the rat moves while animating")
	for i in range(actors.size()):
		if CAST[i] == "owl":
			check(actors[i].velocity.is_zero_approx() and not actors[i].movement_animation.airborne, "perched owl rests while aiming")
		else:
			check(not is_equal_approx(phases[i], actors[i].movement_animation.phase), CAST[i] + " advances movement poses")
		var atlas: Texture2D = actors[i].movement_animation.SHEETS[CAST[i]]
		check(atlas.get_size() == Vector2(1280, 1440), CAST[i] + " has all directions, movement poses and rest pose")
		var pixels := atlas.get_image()
		for direction in range(8):
			check(pixels.get_region(Rect2i(direction * 160, 0, 160, 160)).get_data() != pixels.get_region(Rect2i(direction * 160, 320, 160, 160)).get_data(), CAST[i] + " has distinct poses in direction " + str(direction))
		phases[i] = actors[i].movement_animation.phase
	paused = true
	await create_timer(0.1, true).timeout
	for i in range(actors.size()):
		check(is_equal_approx(phases[i], actors[i].movement_animation.phase), CAST[i] + " freezes while paused")
	game.queue_free()
	paused = false
	await process_frame
	await process_frame
	if failures.is_empty():
		print("MOVEMENT PASS: all ten actors animate, have distinct poses in every direction, and freeze on pause")
	quit(0 if failures.is_empty() else 1)
