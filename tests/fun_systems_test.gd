extends SceneTree

var failures: Array[String] = []
var game: Node

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("FUN FAIL: " + message)

func clean_enemies() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.queue_free()

func spawn(kind: String, at: Vector2) -> Node:
	game._spawn_enemy(kind)
	var enemy = get_nodes_in_group("enemies").back()
	enemy.global_position = at
	return enemy

func _run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.start_game()
	await process_frame
	game.intermission = 999
	game.player.autofire = false
	game.player.apply_powerup("rapid")
	game.player.dash_ready_at = game.player.game_time_ms() + 1000
	game.combo_expires = 1800
	game.combo = 4
	var enemy := spawn("owl", Vector2(400, 0))
	game._spawn_powerup("cheese", Vector2(-400, 0))
	game._on_enemy_projectile_requested(Vector2(500, 0), Vector2.LEFT, 100, 5, "feather")
	await physics_frame
	game._toggle_pause()
	var pickup = get_nodes_in_group("pickups").back()
	var projectile = get_nodes_in_group("enemy_projectiles").back()
	var age: float = game.player.anim_time
	var clock: int = game.player.game_time_ms()
	var cooldown: float = game.player.get_dash_charge()
	var life: float = pickup.life
	var enemy_position: Vector2 = enemy.position
	var projectile_position: Vector2 = projectile.position
	var run_clock: float = game.run_clock
	await create_timer(0.15, true).timeout
	check(not game.player.can_process(), "player is pausable")
	check(game.player.anim_time == age and game.player.game_time_ms() == clock, "player and buff clock freeze")
	check(game.player.get_dash_charge() == cooldown, "dash recharge freezes")
	check(game.run_clock == run_clock, "combo clock freezes")
	check(pickup.life == life and enemy.position == enemy_position and projectile.position == projectile_position, "world and pickups freeze")
	game._toggle_pause()
	await physics_frame
	await physics_frame
	check(game.player.game_time_ms() > clock, "clock resumes")
	game.current_wave = 1
	game._open_upgrade_draft()
	check(game.current_upgrade_ids.size() == 3 and "pinball" in game.current_upgrade_ids and "scurry_bomb" in game.current_upgrade_ids and "snack_orbit" in game.current_upgrade_ids, "first draft defines a build")
	check(game.hud.upgrade_cards.get_child(0).has_focus(), "first card gets keyboard and controller focus")
	check(game.hud.upgrade_cards.get_child(0).get_theme_color("font_focus_color") == game.hud.dark, "focused card remains readable")
	game._on_upgrade_selected("pinball")
	check(game.player.can_take_upgrade("split_acorns") and not game.player.can_take_upgrade("orbit_feast"), "synergy prerequisites")
	game.player.apply_upgrade("split_acorns")
	var bullet = load("res://scripts/bullet.gd").new()
	bullet.setup(Vector2(1168, 0), Vector2.RIGHT, 920, 18, 4.5, 0, Color.WHITE)
	bullet.bounces_left = 1
	bullet.split_on_bounce = true
	game.add_child(bullet)
	var before: int = get_nodes_in_group("player_bullets").size()
	bullet._physics_process(0.02)
	check(bullet.velocity.x < 0 and bullet.bounces_left == 0, "fence reflects the seed once")
	check(get_nodes_in_group("player_bullets").size() == before + 1, "rebound creates one split seed")
	check(not get_nodes_in_group("player_bullets").back().split_on_bounce, "split does not recurse")
	clean_enemies()
	await process_frame
	enemy = spawn("bird", Vector2(60, 0))
	game.player.apply_upgrade("scurry_bomb")
	game.player.apply_upgrade("dash_refund")
	game.player.dash_ready_at = game.player.game_time_ms() + 1000
	var bomb = load("res://scripts/crumb_bomb.gd").new()
	bomb.position = Vector2.ZERO
	bomb.owner_player = game.player
	game.add_child(bomb)
	bomb.detonate()
	check(enemy.dying, "crumb damages enemies in its radius")
	check(game.player.dash_ready_at == game.player.game_time_ms() + 600, "successful crumb refunds 400ms")
	await process_frame
	game.player.apply_upgrade("snack_orbit")
	game.player.apply_powerup("cheese")
	check(game.player.power_until > game.player.game_time_ms(), "full health cheese becomes power")
	check(game.player.orbit_until > game.player.game_time_ms(), "pickup charges orbit")
	game.player.shield_charges = 2
	var power_before: int = game.player.power_until
	game.player.apply_powerup("shield")
	check(game.player.power_until == mini(power_before + 2000, game.player.game_time_ms() + 9000), "full shield tops up capped power")
	var orbit_point: Vector2 = game.player.position + Vector2.from_angle(game.player.anim_time * 3.2) * 90
	enemy = spawn("cat", orbit_point)
	var hp: float = enemy.health
	game.player.orbit_hit_cooldown = 0
	game.player._update_orbit(0)
	check(enemy.health < hp, "orbit seeds deal contact damage")
	for i in range(3):
		game.player.apply_upgrade("extra_pocket")
	game.player.apply_powerup("triple")
	before = get_nodes_in_group("player_bullets").size()
	game.player.fire()
	check(get_nodes_in_group("player_bullets").size() == before + 6, "triple pickup adds seeds to max multishot")
	game.player.using_controller = true
	game.player.aim_direction = Vector2.UP
	game.player.aim_assist = false
	game.player._physics_process(0)
	check(game.player.aim_direction == Vector2.UP, "released aiming stick retains direction")
	# Settings must persist, retain controller bindings, and explain changed keys.
	var settings_path := "user://settings.cfg"
	var old_settings = FileAccess.get_file_as_bytes(settings_path) if FileAccess.file_exists(settings_path) else null
	var original_keys: Dictionary = game.settings.keys.duplicate()
	var original_assist: bool = game.settings.aim_assist
	var original_shake: float = game.settings.shake
	game.settings.keys["dash"] = KEY_Q
	game.settings.aim_assist = true
	game.settings.shake = 0.0
	game.settings._apply_keys()
	game.settings._save()
	var loaded = load("res://scripts/settings_panel.gd").new()
	loaded._load()
	check(loaded.keys["dash"] == KEY_Q and loaded.aim_assist and loaded.shake == 0, "comfort options and keys persist")
	check(game.hud.dash_key == "Q" and game.player.aim_assist, "settings update live gameplay and hints")
	var has_pad := false
	for event in InputMap.action_get_events("dash"):
		if event is InputEventJoypadButton:
			has_pad = true
	check(has_pad, "remapping preserves controller dash")
	loaded.free()
	game.settings.keys = original_keys
	game.settings.aim_assist = original_assist
	game.settings.shake = original_shake
	game.settings._apply_keys()
	game._apply_settings()
	if old_settings == null:
		DirAccess.remove_absolute(settings_path)
	else:
		var settings_file := FileAccess.open(settings_path, FileAccess.WRITE)
		settings_file.store_buffer(old_settings)
		settings_file.close()
	clean_enemies()
	await process_frame
	enemy = spawn("owl", Vector2(400, 0))
	enemy.attack_cooldown = 0
	before = get_nodes_in_group("enemy_projectiles").size()
	enemy._update_owl(0.01, Vector2.LEFT, 400)
	check(enemy.ranged_windup and get_nodes_in_group("enemy_projectiles").size() == before, "owl announces before firing")
	enemy._update_owl(0.5, Vector2.LEFT, 400)
	enemy._update_owl(0.2, Vector2.UP, 400)
	check(get_nodes_in_group("enemy_projectiles").size() == before + 3, "owl completes announced volley")
	check(enemy.ranged_direction == Vector2.LEFT, "last part of wind-up commits direction")
	clean_enemies()
	await process_frame
	enemy = spawn("alpha_cat", Vector2(400, 0))
	enemy.take_damage(999999)
	check(game.boss_reward_pending and "power" in game.pending_treats, "boss guarantees banked rewards")
	for shot in get_nodes_in_group("enemy_projectiles"):
		check(shot.spent, "boss death neutralizes projectiles immediately")
	await process_frame
	game.current_wave = 5
	game._open_upgrade_draft()
	game._on_upgrade_selected(game.current_upgrade_ids[0])
	check(game.game_state == "upgrade" and not game.boss_reward_pending, "boss offers a second mutation")
	game._on_upgrade_selected(game.current_upgrade_ids[0])
	check(game.game_state == "playing" and not paused, "bonus draft resumes")
	# Leave exactly two eligible options, then one, then none.
	for id in game.UPGRADES:
		if id not in ["heavy_seeds", "thick_fur"]:
			while game.player.can_take_upgrade(id):
				game.player.apply_upgrade(id)
	for id in ["heavy_seeds", "thick_fur"]:
		var max_level := 9 if id == "heavy_seeds" else 6
		while int(game.player.upgrade_levels.get(id, 0)) < max_level - 1:
			game.player.apply_upgrade(id)
	game._open_upgrade_draft()
	check(game.current_upgrade_ids.size() == 2, "two-option draft")
	game._on_upgrade_selected("heavy_seeds")
	game._open_upgrade_draft()
	check(game.current_upgrade_ids.size() == 1, "one-option draft")
	game._on_upgrade_selected("thick_fur")
	game._open_upgrade_draft()
	check(game.current_upgrade_ids.is_empty() and game.game_state == "playing" and not paused, "exhausted draft grants fallback without locking")
	game.current_wave = 14
	game._begin_next_wave()
	check("barn_owl" in game.wave_queue, "final boss is scheduled")
	# Isolate persistence for victory test, restoring the user's exact files afterward.
	var saved := {}
	for path in ["user://highscore.save", "user://records.cfg"]:
		saved[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	game.wave_queue.clear()
	clean_enemies()
	await process_frame
	game._finish_wave()
	check(game.game_state == "victory" and paused and game.hud.victory_overlay.visible, "wave 15 reaches victory")
	game._continue_overtime()
	check(game.overtime and game.game_state == "playing" and not paused, "maxed build can enter overtime")
	for path in saved:
		if saved[path] == null:
			DirAccess.remove_absolute(path)
		else:
			var file := FileAccess.open(path, FileAccess.WRITE)
			file.store_buffer(saved[path])
	game.audio.stop_all()
	game.player.autofire = false
	paused = true
	await create_timer(0.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("FUN PASS: pause, drafts, builds, rewards, warnings, controller aim, victory and overtime")
	quit(0 if failures.is_empty() else 1)
