extends SceneTree
## Spawn every model through production gameplay paths. A graphical run also
## captures the real arena, with test-only labels and frozen actors for review.
const Sprites = preload("res://scripts/model_sprites.gd")
const ENEMIES := ["bird", "cat", "owl", "snake", "fox", "raccoon", "alpha_cat", "junkyard_dog", "barn_owl"]
var failures: Array[String] = []
var actors: Dictionary = {}

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("CAST FAIL: " + message)

func register(kind: String, actor: Node2D) -> void:
	check(actor.is_visible_in_tree(), kind + " is visible in the production scene")
	check(Sprites.FRAMES.has(kind), kind + " has production sprite resources")
	actors[kind] = actor
	actor.process_mode = Node.PROCESS_MODE_DISABLED
	actor.queue_redraw()

func prop_position(index: int) -> Vector2:
	return Vector2(-510 + (index % 7) * 170, 230 + (index / 7) * 75)

func run() -> void:
	seed(1)
	root.size = Vector2i(1440, 1000)
	root.content_scale_size = Vector2i(1440, 1000)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.audio.stop_all()
	game.audio.pool.clear()
	game.start_game()
	game.intermission = 999.0
	game.current_wave = 1
	game.player.autofire = false
	game.player.aim_assist = false
	# Let the audio backend finish starting before stopping the staged scene.
	await create_timer(.05, true).timeout
	game.audio.stop_all()
	game.player.position = Vector2(0, 155)
	game.player._update_aim(Vector2.RIGHT)
	register("rat", game.player)
	game.player.get_node("ArenaCamera").position = Vector2(0, -155)
	game.player.get_node("ArenaCamera").reset_smoothing()
	game.hud.set_encounter("FULL CAST PREVIEW")
	game.hud.set_autofire(false)
	var buffs: Array[String] = []
	game.hud.update_stats(0, 1, 0, game.player.health, game.player.max_health, 0.0, buffs)
	# Remove the starter gift; the pickup row below spawns each treat once.
	for pickup in get_nodes_in_group("pickups"):
		pickup.free()
	for i in range(ENEMIES.size()):
		var kind: String = ENEMIES[i]
		game._spawn_enemy(kind)
		var enemy = get_nodes_in_group("enemies").back()
		check(enemy.enemy_kind == kind and enemy.target == game.player, kind + " spawns with its actual behavior and target")
		check(enemy.died.is_connected(game._on_enemy_died), kind + " is connected to scoring and drops")
		check(enemy.projectile_requested.is_connected(game._on_enemy_projectile_requested), kind + " is connected to combat projectiles")
		enemy.position = Vector2(-480 + i * 240, -210) if i < 5 else Vector2(-480 + (i - 5) * 320, 10)
		enemy.rotation = 0.0 if kind == "bird" else PI / 4
		enemy.spawn_scale = 1.0
		register(kind, enemy)
	var introductions := {1: "bird", 2: "cat", 3: "owl", 4: "snake", 6: "raccoon", 10: "fox"}
	for wave in introductions:
		game.current_wave = wave
		check(game._encounter_enemy(0) == introductions[wave], "wave %d introduces %s" % [wave, introductions[wave]])
	for wave in [5, 10, 15]:
		check(actors.has(game.get_boss_kind(wave)), "wave %d boss has its own model" % wave)
	game.current_wave = 1
	var prop_index := 0
	for kind in game.PowerUpScript.DEFINITIONS:
		game._spawn_powerup(kind, prop_position(prop_index))
		var pickup = get_nodes_in_group("pickups").back()
		check(pickup.kind == kind and pickup.collected.is_connected(game._on_powerup_collected), kind + " spawns as a collectible treat")
		register(kind, pickup)
		prop_index += 1
	game.player.fire()
	check(not get_nodes_in_group("player_bullets").is_empty(), "the player fires the seed model")
	for bullet in get_nodes_in_group("player_bullets"):
		bullet.position = prop_position(prop_index)
		register("seed", bullet)
	prop_index += 1
	for kind in ["feather", "venom", "bone", "sonic"]:
		game._on_enemy_projectile_requested(prop_position(prop_index), Vector2.RIGHT, 0.0, 1.0, kind)
		var projectile = get_nodes_in_group("enemy_projectiles").back()
		check(projectile.projectile_kind == kind, kind + " uses the production enemy projectile")
		register(kind, projectile)
		prop_index += 1
	game.player.upgrade_levels["scurry_bomb"] = 1
	game._on_player_dash(prop_position(prop_index))
	for entity in get_nodes_in_group("run_entities"):
		if entity.get_script() == game.CrumbBombScript:
			register("crumb", entity)
		elif entity.get_script() == game.FizzyCanScript:
			entity.position = prop_position(13)
			register("fizzy", entity)
	check(actors.size() == 24, "all ten characters and fourteen props appear in the game")
	for kind in Sprites.FRAMES:
		check(actors.has(kind), kind + " has a production actor, not just an unused asset")
		var frames: Array = Sprites.FRAMES[kind]
		check(frames.size() == (8 if kind == "rat" or kind in ENEMIES else 1), kind + " has the complete directional set")
		for i in range(frames.size()):
			check(frames[i].resource_path == "res://assets/sprites/%s_%d.png" % [kind, i], kind + " points at the shipped render")
	# Freeze only this verification scene. Production movement and wave timing
	# remain covered by the gameplay and individual creature regression suites.
	game.process_mode = Node.PROCESS_MODE_DISABLED
	if DisplayServer.get_name() != "headless" and failures.is_empty():
		for kind in actors:
			var caption := Label.new()
			caption.text = kind.replace("_", " ").to_upper()
			caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var caption_y := 34 if kind == "rat" else (53 if kind in ENEMIES else 26)
			caption.position = actors[kind].position + Vector2(-85, caption_y)
			caption.size.x = 170
			caption.add_theme_color_override("font_color", Color("fff0c5"))
			caption.add_theme_font_size_override("font_size", 17)
			caption.z_index = 30
			game.add_child(caption)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/all-models-in-game.png")
	game.audio.stop_all()
	await create_timer(.25, true).timeout
	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("CAST PASS: 10 characters and 14 props spawned through production paths; 94 sprite references and wave introductions verified")
	quit(0 if failures.is_empty() else 1)
