extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("LIGHT TRAIL FAIL: " + message)

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	paused = true
	check(get_nodes_in_group("light_trails").is_empty(), "trail requires its upgrade")
	game.current_wave = 2
	game._open_upgrade_draft()
	check("light_trail" in game.current_upgrade_ids, "wave two guarantees the new upgrade")
	game._on_upgrade_selected("light_trail")
	paused = true
	var rat = game.player
	var trail = get_nodes_in_group("light_trails").front()
	check(not rat.can_take_upgrade("light_trail") and rat.get_build_description().contains("LIGHT TRAIL"), "upgrade is permanent for the run and cannot duplicate")
	rat.apply_upgrade("light_trail")
	check(get_nodes_in_group("light_trails").size() == 1, "only one trail controller exists")
	rat.position = Vector2(60, 0)
	trail._physics_process(0.2)
	check(trail.segments.size() == 1 and trail.segments[0].from == Vector2.ZERO and trail.segments[0].to == rat.position, "movement leaves a world-space path")
	var enemy = load("res://scripts/enemy.gd").new()
	enemy.setup("raccoon", rat, 1)
	enemy.position = Vector2(30, 0)
	enemy.add_to_group("run_entities")
	game.add_child(enemy)
	var outside = load("res://scripts/enemy.gd").new()
	outside.setup("raccoon", rat, 1)
	outside.position = Vector2(30, 120)
	outside.add_to_group("run_entities")
	game.add_child(outside)
	var hp: float = enemy.health
	var outside_hp: float = outside.health
	var tick_damage: float = rat.base_damage * 1.5 * 0.2
	trail._physics_process(0.2)
	check(is_equal_approx(enemy.health, hp - tick_damage), "standing on light takes damage over time")
	check(outside.health == outside_hp, "nearby enemies outside the trail are safe")
	rat.position = Vector2.ZERO
	hp = enemy.health
	trail._physics_process(0.2)
	check(trail.segments.size() == 2 and is_equal_approx(enemy.health, hp - tick_damage), "overlapping paths do not multiply damage")
	outside.position = Vector2(30, -120)
	trail._physics_process(0.2)
	check(is_equal_approx(outside.health, outside_hp - tick_damage), "fast crossings between damage ticks still hurt")
	rat.apply_upgrade("heavy_seeds")
	hp = enemy.health
	trail._physics_process(0.2)
	check(is_equal_approx(enemy.health, hp - rat.base_damage * 1.5 * 0.2), "trail damage follows base damage upgrades")
	hp = enemy.health
	trail._physics_process(3.01)
	check(trail.segments.is_empty() and enemy.health == hp, "expired light disappears and cannot damage")
	trail._physics_process(1.0)
	check(trail.segments.is_empty(), "standing still cannot build a permanent damage pool")
	# Exercise real dash movement rather than only moving the test fixture.
	rat._update_dash(Vector2.RIGHT, true)
	rat._physics_process(0.05)
	trail._physics_process(0.05)
	check(rat.position.x > 30 and trail.segments.size() == 1 and trail.segments[0].to == rat.position, "dashes leave an unbroken trail")
	var clock: float = trail.clock
	var segment_count: int = trail.segments.size()
	await create_timer(0.06, true).timeout
	check(trail.clock == clock and trail.segments.size() == segment_count, "pause freezes damage and fading")
	game.return_to_menu()
	await process_frame
	check(get_nodes_in_group("light_trails").is_empty(), "returning to menu clears the trail")
	game.start_game()
	game.player.autofire = false
	paused = true
	check(game.player.can_take_upgrade("light_trail") and get_nodes_in_group("light_trails").is_empty(), "new runs start without the upgrade")
	game.player.apply_upgrade("light_trail")
	trail = get_nodes_in_group("light_trails").front()
	game.player.alive = false
	trail._physics_process(0.2)
	check(trail.is_queued_for_deletion(), "player death stops trail damage")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("LIGHT TRAIL PASS: draft, movement, damage, crossings, expiry, dash, pause and cleanup")
	quit(0 if failures.is_empty() else 1)
