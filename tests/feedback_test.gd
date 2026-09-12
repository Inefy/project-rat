extends SceneTree

var failures: Array[String] = []
const Burst = preload("res://scripts/feedback_burst.gd")

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("FEEDBACK FAIL: " + message)

func bursts(game: Node) -> Array:
	return game.get_children().filter(func(node): return node.get_script() == Burst)

func capture(label: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/feedback-%s.png" % label)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	paused = true
	var rat = game.player
	var overlay = game.hud.feedback_overlay
	game._spawn_powerup("rapid", rat.position)
	get_nodes_in_group("pickups").back()._on_body_entered(rat)
	check(bursts(game).size() == 1 and bursts(game)[0].kind == "pickup", "collecting an actual pickup creates a light burst")
	check(overlay.remaining > 0 and not overlay.hurt, "pickup starts a colored screen pulse")
	bursts(game)[0].elapsed = 0.14
	bursts(game)[0].queue_redraw()
	await capture("pickup")
	var remaining: float = overlay.remaining
	await create_timer(0.06, true).timeout
	check(overlay.remaining == remaining and bursts(game)[0].elapsed == 0.14, "pause freezes screen and world feedback")
	for effect in bursts(game):
		effect.queue_free()
	await process_frame
	rat.invulnerable_until = 0
	var health: float = rat.health
	rat.take_player_damage(17)
	check(rat.health == health - 17 and overlay.hurt, "damage starts a red warning and removes health")
	check(bursts(game).size() == 1 and bursts(game)[0].kind == "damage", "damage creates its own impact burst")
	bursts(game)[0].elapsed = 0.14
	bursts(game)[0].queue_redraw()
	rat.queue_redraw()
	await capture("damage")
	overlay.pulse(Color.GREEN, false)
	check(overlay.hurt and overlay.tint == Color("ed294f"), "pickup cannot hide an active damage warning")
	rat.take_player_damage(17)
	check(rat.health == health - 17 and bursts(game).size() == 1, "invulnerability prevents duplicate damage feedback")
	for effect in bursts(game):
		effect.queue_free()
	await process_frame
	overlay.remaining = 0
	rat.invulnerable_until = 0
	rat.shield_charges = 1
	rat.take_player_damage(17)
	check(rat.health == health - 17 and rat.shield_charges == 0, "shield blocks health damage")
	check(not overlay.hurt and overlay.tint == Color("9bdded") and bursts(game)[0].kind == "blocked", "shield feedback stays distinct from a damaging hit")
	bursts(game)[0].elapsed = 0.14
	bursts(game)[0].queue_redraw()
	await capture("shield")
	overlay._process(1)
	bursts(game)[0]._process(1)
	check(overlay.remaining == 0 and bursts(game)[0].is_queued_for_deletion(), "effects expire cleanly")
	game.return_to_menu()
	await process_frame
	check(overlay.remaining == 0 and bursts(game).is_empty(), "menu clears active effects")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("FEEDBACK PASS: pickup, damage, priority, shield, invulnerability, pause and cleanup")
	quit(0 if failures.is_empty() else 1)
