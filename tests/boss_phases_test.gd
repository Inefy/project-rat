extends SceneTree

const EnemyScript = preload("res://scripts/enemy.gd")
var failures: Array[String] = []
var shots: Array[Dictionary] = []
var transitions: Array[int] = []
var game: Node

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("BOSS PHASES FAIL: " + message)

func spawn(kind: String, wave: int = 15, elite: bool = false) -> Node:
	var enemy := EnemyScript.new()
	enemy.setup(kind, game.player, wave, elite)
	enemy.position = Vector2(400, 0)
	game.add_child(enemy)
	enemy.projectile_requested.connect(func(_at: Vector2, direction: Vector2, _speed: float, _damage: float, shot_kind: String):
		shots.append({"direction": direction, "kind": shot_kind})
	)
	enemy.phase_changed.connect(func(_kind: String, phase: int): transitions.append(phase))
	return enemy

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	game.player.autofire = false
	game.intermission = 999
	paused = true
	# Every archetype, including elites and the former armoured dog, takes full hits.
	for kind in ["bird", "cat", "owl", "snake", "raccoon", "fox", "alpha_cat", "junkyard_dog", "barn_owl"]:
		var enemy := spawn(kind, 15, true)
		var hp: float = enemy.health
		enemy.take_damage(5.0)
		check(is_equal_approx(enemy.health, hp - 5.0), kind + " takes direct health damage")
		enemy.state = "recover"
		hp = enemy.health
		enemy.take_damage(4.0)
		check(is_equal_approx(enemy.health, hp - 5.0), kind + " rewards hits during recovery")
		enemy.free()

	for kind in ["alpha_cat", "junkyard_dog", "barn_owl"]:
		transitions.clear()
		var boss := spawn(kind)
		check(boss.boss_phase == 1, kind + " starts in phase one")
		boss.take_damage(boss.max_health * 0.34)
		check(boss.boss_phase == 2 and boss.state == "phase_shift", kind + " transitions at two-thirds health")
		var hp: float = boss.health
		boss.take_damage(1.0)
		check(boss.health == hp - 1.0 and transitions == [2], "transition remains vulnerable and does not restart")
		var clock: float = boss.state_clock
		await create_timer(0.06, true).timeout
		check(boss.state_clock == clock, "boss transition respects pause")
		boss.take_damage(boss.max_health * 0.34)
		check(boss.boss_phase == 3 and transitions == [2, 3], kind + " transitions at one-third health")
		check(boss.boss_patterns.volleys_left == 0, "phase change cancels unfinished bursts")
		var base_dps: float = game.player.base_damage / game.player.fire_interval
		check(boss.max_health / (base_dps * 0.5) < 110.0, kind + " takes under 110s with zero upgrades and half the shots landing")
		boss.free()

		for phase in [1, 2, 3]:
			boss = spawn(kind)
			if phase > 1:
				boss.take_damage(boss.max_health * (0.34 if phase == 2 else 0.68))
			shots.clear()
			var attacks := {}
			var max_chain := 0
			var chain := 0
			var recoveries := 0
			var previous_state: String = boss.state
			# Exercise complete timed cycles, without relying on wall-clock performance.
			for frame in range(1800):
				boss.boss_patterns.update(1.0 / 60.0, Vector2.LEFT, 400.0)
				if boss.state == "telegraph":
					attacks[boss.boss_patterns.attack] = true
				if boss.state in ["pounce", "charge"] and previous_state == "telegraph":
					chain += 1
					max_chain = maxi(max_chain, chain)
				if boss.state == "recover" and previous_state != "recover":
					check(boss.velocity == Vector2.ZERO, "rush stops at its recovery opening")
					recoveries += 1
					chain = 0
				previous_state = boss.state
			check(recoveries >= 2, "%s phase %d has repeated recovery openings" % [kind, phase])
			if kind == "alpha_cat":
				check(max_chain == phase, "cat adds one telegraphed pounce per phase")
				check(attacks.has("ring") == (phase >= 2), "cat adds a sonic ring in later phases")
			elif kind == "junkyard_dog":
				check(attacks.has("charge"), "dog always threatens a charge")
				check(attacks.has("ring") == (phase >= 2), "dog adds shockwave sequences")
				check((not shots.is_empty()) == (phase >= 2), "dog starts projectile pressure after phase one")
			else:
				check(attacks.has("sweep") == (phase >= 2), "owl unlocks sweeping volleys")
				check(attacks.has("dive") == (phase == 3) and attacks.has("ring") == (phase == 3), "owl final phase adds dives and rotating rings")
			print("PATTERNS %s phase %d: %s, %d projectiles" % [kind, phase, str(attacks.keys()), shots.size()])
			boss.free()

	var boss := spawn("alpha_cat", 5)
	boss.boss_patterns._windup("pounce", Vector2.LEFT, 0.6)
	boss.boss_patterns.update(0.39, Vector2.UP, 400)
	boss.boss_patterns.update(0.1, Vector2.DOWN, 400)
	check(boss.pounce_direction == Vector2.LEFT, "final warning commits to a dodgeable direction")
	boss.boss_patterns.update(0.12, Vector2.RIGHT, 400)
	check(boss.state == "pounce" and boss.velocity.x < 0, "pounce follows its warning")
	boss.free()

	boss = spawn("junkyard_dog", 10)
	boss.take_damage(boss.max_health * 0.68)
	shots.clear()
	boss.boss_patterns._begin_rings(Vector2.RIGHT, 3)
	boss.boss_patterns._release_attack()
	check(shots.size() >= 12, "late shockwave creates a substantial ring")
	for shot in shots:
		check(absf(shot.direction.angle()) >= 0.62, "ring leaves its advertised escape gap")
	check(boss.state == "telegraph", "next shockwave gets a fresh warning")
	boss.take_damage(999999)
	var count := shots.size()
	boss._physics_process(1.0)
	check(shots.size() == count, "dead bosses cannot finish pending attacks")
	await process_frame

	# Director and HUD integrate phase state, rather than just showing a toast.
	game.current_wave = 10
	game._spawn_enemy("junkyard_dog")
	boss = game.active_boss
	check(game.get_spawn_limit() < game.get_enemy_cap(10), "boss reinforcements leave room for its patterns")
	boss.take_damage(boss.max_health * 0.68)
	check(game.get_spawn_limit() == 36, "reinforcement pressure increases with phases")
	paused = false
	game._physics_process(0)
	paused = true
	check(game.hud.progress_label.text.contains("PHASE 3/3") and is_equal_approx(game.hud.wave_bar.value, boss.health / boss.max_health), "boss HUD shows current phase and actual health")
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("BOSS PHASES PASS: direct damage, transitions, movesets, warnings, recovery, pause and director integration")
	quit(0 if failures.is_empty() else 1)
