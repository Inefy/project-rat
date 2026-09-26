extends SceneTree
## Check the complete player-seed-to-blast path for the arena's explosive props.

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("FIZZY CAN FAIL: " + message)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.audio.stop_all()
	game.start_game()
	game.intermission = 999.0
	game.player.autofire = false

	var can: StaticBody2D
	for entity in get_nodes_in_group("run_entities"):
		if entity.get_script() == game.FizzyCanScript:
			can = entity
			break
	check(is_instance_valid(can), "a live explosive can is placed in the run")
	if not is_instance_valid(can):
		quit(1)
		return

	var enemy = game.EnemyScript.new()
	enemy.setup("cat", game.player, 1)
	enemy.global_position = can.global_position + Vector2(120.0, 0.0)
	enemy.spawn_grace = 0.0
	game.add_child(enemy)
	enemy.health = enemy.max_health

	game.player.global_position = can.global_position + Vector2(-120.0, 0.0)
	game.player.aim_direction = Vector2.RIGHT
	var rat_health_before: float = game.player.health
	game.player.fire()
	await create_timer(0.2, true).timeout

	check(not is_instance_valid(can), "a player seed detonates the can")
	check(enemy.health < enemy.max_health, "the blast damages a nearby enemy")
	check(enemy.knockback_velocity.length() > 0.0, "the blast knocks the enemy away")
	check(game.player.health < rat_health_before and game.player.last_damage_source == "fizzy can", "the blast also damages the rat")

	var count_after_blast := get_nodes_in_group("explosive_cans").size()
	game.can_spawn_timer = 0.0
	await physics_frame
	await process_frame
	check(get_nodes_in_group("explosive_cans").size() > count_after_blast, "a new can appears when the random spawn timer expires")
	for i in range(8):
		game._try_spawn_fizzy_can()
	check(get_nodes_in_group("explosive_cans").size() == game.MAX_ACTIVE_CANS, "the arena never exceeds its can cap")

	game.audio.stop_all()
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("FIZZY CAN PASS: player shot, enemy and rat blast damage, timed spawn, arena cap")
	quit(0 if failures.is_empty() else 1)
