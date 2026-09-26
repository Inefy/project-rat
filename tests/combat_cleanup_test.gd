extends SceneTree

class CountingPlayer:
	extends "res://scripts/player.gd"
	var volleys := 0

	func fire() -> void:
		volleys += 1

var failures: Array[String] = []
var game: Node

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("COMBAT CLEANUP FAIL: " + message)

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	game.settings.cozy = false
	paused = true
	for pickup in get_nodes_in_group("pickups"):
		pickup.free()
	_check_fire_cadence()
	_check_defeated_targets()
	_check_healing_feedback()
	await _check_wave_rewards()
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("COMBAT CLEANUP PASS: steady firing, defeated targets, healing, and complete wave rewards")
	quit(0 if failures.is_empty() else 1)

func _check_fire_cadence() -> void:
	var rat := CountingPlayer.new()
	game.add_child(rat)
	rat.using_directional_aim = true
	# Measure actual physics-driven volleys over ten seconds at different tick rates.
	for rate in [30, 60, 120]:
		for interval in [0.15, 0.135, 0.09]:
			for rapid in [false, true]:
				rat.active_time = 0
				rat.fire_interval = interval
				rat.rapid_until = 20000 if rapid else 0
				rat.shot_cooldown = 0
				rat.volleys = 0
				rat.autofire = true
				for frame in range(rate * 10):
					rat._physics_process(1.0 / rate)
				var expected: float = 10.0 / (interval * (rat.RAPID_INTERVAL_MULTIPLIER if rapid else 1.0))
				check(absf(rat.volleys - expected) <= 1.0, "%.3fs interval, rapid=%s at %d Hz delivers intended rate (%d vs %.1f)" % [interval, rapid, rate, rat.volleys, expected])
	# Releasing fire must not bank volleys for the next press.
	rat.autofire = false
	for frame in range(600):
		rat._physics_process(1.0 / 60.0)
	rat.volleys = 0
	rat.autofire = true
	rat._physics_process(0)
	check(rat.volleys == 1, "manual fire resumes immediately without an idle burst")
	rat.volleys = 0
	rat._physics_process(2.0)
	check(rat.volleys <= 3, "a stall cannot create an unbounded catch-up burst")
	rat.volleys = 0
	rat._physics_process(1.0 / 60.0)
	check(rat.volleys <= 1, "stall debt does not spill into later frames")
	rat.free()

func _check_defeated_targets() -> void:
	var fallen = game.EnemyScript.new()
	fallen.setup("bird", game.player, 1)
	game.add_child(fallen)
	fallen.take_damage(999)
	check(game._living_enemy_count() == 0, "defeated enemies immediately release their crowd slot")
	var target = game.EnemyScript.new()
	target.setup("cat", game.player, 1)
	game.add_child(target)
	for pierce in [0, 1]:
		var bullet = load("res://scripts/bullet.gd").new()
		bullet.setup(Vector2.ZERO, Vector2.RIGHT, 920, 10, 4.5, pierce, Color.WHITE)
		game.add_child(bullet)
		bullet._on_body_entered(fallen)
		check(not bullet.spent and bullet.pierce == pierce and bullet.hit_ids.is_empty(), "a fallen enemy cannot consume a seed or a pierce charge")
		var hp: float = target.health
		bullet._on_body_entered(target)
		bullet._on_body_entered(target)
		check(target.health == hp - 10, "the next living target takes exactly one hit")
		bullet.queue_free()
	target.queue_free()

func _check_healing_feedback() -> void:
	game.player.health = game.player.max_health - 6.5
	game.player.apply_powerup("cheese")
	check(game.player.health == game.player.max_health, "cheese still heals up to maximum health")
	check(game.hud.toast_label.text == "+6.5 HP", "healing feedback reports health actually restored")
	game.player.apply_powerup("cheese")
	check(game.hud.toast_label.text == "POWER +2s", "full-health cheese retains its useful power conversion")

func _check_wave_rewards() -> void:
	var saved := {}
	for path in ["user://highscore.save", "user://records.cfg"]:
		saved[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	game.current_wave = 15
	game.wave_active = true
	game.wave_queue.clear()
	game.high_score = 0
	game.kills_without_treat = 11
	game._spawn_enemy("bird")
	get_nodes_in_group("enemies").back().take_damage(999)
	var expected_score: int = game.score + 400 * 15 + 75
	# Finish before the deferred drop is added to the scene. Victory must include it.
	game._finish_wave()
	check(game.score == expected_score and game.high_score == expected_score, "victory and saved record include the final enemy's drop")
	check(game.pending_treats.size() == 1, "the deferred drop is banked before showing victory")
	var detail: Label = game.hud.victory_overlay.find_child("VictoryDetail", true, false)
	check(game.hud._format_score(expected_score) in detail.text, "victory screen shows the complete score")
	await process_frame
	check(game.score == expected_score and game.pending_treats.size() == 1, "deferred callback cannot duplicate a banked drop")
	# A maxed build skips the draft but should bank loot just like every other clear.
	game.game_state = "playing"
	game.current_wave = 18
	game.wave_active = true
	game.player.health = 20
	for id in game.UPGRADES:
		while game.player.can_take_upgrade(id):
			game.player.apply_upgrade(id)
	game.player.health = 20
	game.pending_treats.clear()
	game._finish_wave()
	paused = true
	var banked: int = game.pending_treats.size()
	game._spawn_powerup("rapid", Vector2(600, 0))
	check(game.game_state == "playing" and banked == 1 and game.pending_treats.size() == banked + 1, "emergency healing and late drops bank even when the draft is exhausted")
	check(get_nodes_in_group("pickups").is_empty(), "intermission rewards never get stranded in the arena")
	game._begin_next_wave()
	check(game.pending_treats.is_empty() and game.player.rapid_until > game.player.game_time_ms(), "banked rewards activate at the next wave")
	# A deferred drop from an abandoned run must never enter the fresh run.
	game.kills_without_treat = 11
	game._spawn_enemy("bird")
	get_nodes_in_group("enemies").back().take_damage(999)
	game.start_game()
	game.intermission = 999
	game.player.autofire = false
	paused = true
	await process_frame
	check(get_nodes_in_group("pickups").size() == 1 and game.pending_treats.is_empty(), "restart keeps only the new run's opening treat")
	for path in saved:
		if saved[path] == null:
			DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(saved[path])
			file.close()
