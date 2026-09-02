extends Node2D

const PlayerScript = preload("res://scripts/player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const EnemyProjectileScript = preload("res://scripts/enemy_projectile.gd")
const PowerUpScript = preload("res://scripts/power_up.gd")
const ImpactFXScript = preload("res://scripts/impact_fx.gd")
const HUDScript = preload("res://scripts/hud.gd")
const ReticleScript = preload("res://scripts/aim_reticle.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")

const ARENA := Rect2(-1200.0, -700.0, 2400.0, 1400.0)
const POWER_TYPES: Array[String] = ["cheese", "rapid", "triple", "power", "haste", "shield", "pierce"]
const UPGRADES := {
	"quick_whiskers": {"id": "quick_whiskers", "title": "QUICK WHISKERS", "description": "Fire 12% faster", "color": Color("ff75bd")},
	"heavy_seeds": {"id": "heavy_seeds", "title": "HEAVY SEEDS", "description": "+4.5 projectile damage", "color": Color("ff9f43")},
	"fleet_feet": {"id": "fleet_feet", "title": "FLEET FEET", "description": "+24 movement speed", "color": Color("6dff95")},
	"thick_fur": {"id": "thick_fur", "title": "THICK FUR", "description": "+20 maximum health and heal 32", "color": Color("ff6f91")},
	"long_teeth": {"id": "long_teeth", "title": "LONG TEETH", "description": "Projectiles pierce +1 target", "color": Color("f1f6ff")},
	"big_paws": {"id": "big_paws", "title": "BIG PAWS", "description": "Larger projectiles and hit area", "color": Color("a58bff")},
	"lucky_tail": {"id": "lucky_tail", "title": "LUCKY TAIL", "description": "+3.5% enemy drop chance", "color": Color("ffe66d")},
	"extra_pocket": {"id": "extra_pocket", "title": "EXTRA POCKET", "description": "+1 permanent projectile", "color": Color("62fff1")},
	"cheese_magnet": {"id": "cheese_magnet", "title": "CHEESE MAGNET", "description": "+65 pickup attraction range", "color": Color("f5d76e")},
}

var rng := RandomNumberGenerator.new()
var hud: CanvasLayer
var audio: Node
var player: CharacterBody2D
var reticle: Node2D
var game_state := "menu"
var current_wave := 0
var score := 0
var kills := 0
var high_score := 0
var wave_queue: Array[String] = []
var wave_total := 0
var spawn_cooldown := 0.0
var intermission := 0.0
var wave_active := false
var combo := 1
var combo_expires := 0
var run_started_at := 0
var current_upgrade_ids: Array[String] = []
var shake_strength := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	high_score = _load_high_score()
	audio = AudioManagerScript.new()
	add_child(audio)
	hud = HUDScript.new()
	add_child(hud)
	hud.start_requested.connect(start_game)
	hud.restart_requested.connect(start_game)
	hud.quit_to_menu_requested.connect(return_to_menu)
	hud.upgrade_selected.connect(_on_upgrade_selected)
	hud.ui_sound_requested.connect(_on_ui_sound_requested)
	hud.show_menu()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if game_state == "upgrade" and event is InputEventKey and event.pressed and not event.echo:
		var choice_index := -1
		match event.keycode:
			KEY_1:
				choice_index = 0
			KEY_2:
				choice_index = 1
			KEY_3:
				choice_index = 2
		if choice_index >= 0 and choice_index < current_upgrade_ids.size():
			_on_upgrade_selected(current_upgrade_ids[choice_index])
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and game_state == "playing":
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_accept"):
		if game_state in ["menu", "game_over"]:
			start_game()
			get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and game_state == "playing" and not get_tree().paused:
		_toggle_pause()

func start_game() -> void:
	get_tree().paused = false
	_clear_run_nodes()
	current_wave = 0
	score = 0
	kills = 0
	combo = 1
	shake_strength = 0.0
	current_upgrade_ids.clear()
	wave_queue.clear()
	wave_total = 0
	wave_active = false
	intermission = 0.75
	spawn_cooldown = 0.0
	run_started_at = Time.get_ticks_msec()
	game_state = "playing"

	player = PlayerScript.new()
	player.global_position = Vector2.ZERO
	player.add_to_group("run_entities")
	add_child(player)
	player.died.connect(_on_player_died)
	player.shot_fired.connect(_on_shot_fired)
	player.pickup_collected.connect(_on_player_pickup_message)
	player.autofire_changed.connect(_on_autofire_changed)
	player.dash_started.connect(_on_player_dash)
	player.damage_feedback.connect(_on_player_damage_feedback)

	reticle = ReticleScript.new()
	reticle.enabled = true
	reticle.z_index = 80
	reticle.add_to_group("run_entities")
	add_child(reticle)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	hud.begin_game()
	hud.set_autofire(true)
	var empty_buffs: Array[String] = []
	hud.update_stats(0, 0, 0, player.health, player.max_health, 0.0, empty_buffs)

func return_to_menu() -> void:
	get_tree().paused = false
	game_state = "menu"
	wave_active = false
	_clear_run_nodes()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hud.show_menu()

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	hud.set_paused(paused)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_HIDDEN)

func _physics_process(delta: float) -> void:
	if game_state != "playing" or get_tree().paused or not is_instance_valid(player):
		return
	if combo > 1 and Time.get_ticks_msec() > combo_expires:
		combo = 1

	if not wave_active:
		intermission -= delta
		if intermission <= 0.0:
			_begin_next_wave()
	else:
		spawn_cooldown -= delta
		if not wave_queue.is_empty() and spawn_cooldown <= 0.0:
			var next_kind: String = wave_queue.pop_front()
			_spawn_enemy(next_kind)
			spawn_cooldown = max(0.16, 0.68 - current_wave * 0.016)
		if wave_queue.is_empty() and _living_enemy_count() == 0:
			_finish_wave()

	hud.update_stats(score, current_wave, kills, player.health, player.max_health, _wave_progress(), player.get_active_buffs(), player.get_dash_charge())

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not player.has_node("ArenaCamera"):
		return
	var camera: Camera2D = player.get_node("ArenaCamera")
	if shake_strength > 0.05 and not get_tree().paused:
		camera.offset = Vector2(rng.randf_range(-shake_strength, shake_strength), rng.randf_range(-shake_strength, shake_strength))
		shake_strength = maxf(0.0, shake_strength - delta * 34.0)
	else:
		camera.offset = camera.offset.lerp(Vector2.ZERO, minf(1.0, delta * 14.0))

func _begin_next_wave() -> void:
	current_wave += 1
	wave_active = true
	wave_queue.clear()
	var regular_count := 7 + int(round(pow(float(current_wave), 0.92) * 3.4))
	for i in range(regular_count):
		wave_queue.append(_choose_enemy_kind())
	var boss_wave := current_wave % 5 == 0
	if boss_wave:
		wave_queue.insert(min(3, wave_queue.size()), "alpha_cat")
	wave_total = wave_queue.size()
	spawn_cooldown = 0.15
	hud.show_wave_banner(current_wave, boss_wave)
	if boss_wave:
		audio.play("shield", 0.03, -1.0)
		_add_shake(8.0)

func _finish_wave() -> void:
	wave_active = false
	var clear_bonus := 400 * current_wave
	score += clear_bonus
	intermission = max(1.8, 3.0 - current_wave * 0.035)
	hud.show_toast("WAVE CLEARED  +%d" % clear_bonus, Color("62fff1"))
	audio.play("wave_clear", 0.02)
	player.heal(10.0 + minf(10.0, current_wave))
	# A little guaranteed recovery every third wave keeps long runs viable.
	if current_wave % 3 == 0 and is_instance_valid(player) and player.health < player.max_health * 0.7:
		_spawn_powerup("cheese", player.global_position + Vector2(110, 0).rotated(rng.randf_range(0.0, TAU)))
	_open_upgrade_draft()

func _choose_enemy_kind() -> String:
	var roll := rng.randf()
	if current_wave < 2:
		return "bird" if roll < 0.72 else "cat"
	if current_wave < 3:
		if roll < 0.48:
			return "bird"
		if roll < 0.82:
			return "cat"
		return "owl"
	if current_wave < 6:
		if roll < 0.36:
			return "bird"
		if roll < 0.66:
			return "cat"
		if roll < 0.84:
			return "owl"
		return "snake"
	if roll < 0.32:
		return "bird"
	if roll < 0.62:
		return "cat"
	if roll < 0.81:
		return "owl"
	return "snake"

func _spawn_enemy(kind: String) -> void:
	if not is_instance_valid(player):
		return
	var enemy := EnemyScript.new()
	var is_elite := kind != "alpha_cat" and current_wave >= 2 and rng.randf() < minf(0.17, 0.025 + current_wave * 0.008)
	enemy.setup(kind, player, current_wave, is_elite)
	enemy.global_position = _random_spawn_position()
	enemy.add_to_group("run_entities")
	add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.hit.connect(_on_enemy_hit)
	enemy.projectile_requested.connect(_on_enemy_projectile_requested)

func _random_spawn_position() -> Vector2:
	var candidate := Vector2.ZERO
	for attempt in range(12):
		var angle := rng.randf_range(0.0, TAU)
		candidate = player.global_position + Vector2.from_angle(angle) * rng.randf_range(570.0, 760.0)
		candidate.x = clamp(candidate.x, ARENA.position.x + 45.0, ARENA.end.x - 45.0)
		candidate.y = clamp(candidate.y, ARENA.position.y + 45.0, ARENA.end.y - 45.0)
		if candidate.distance_to(player.global_position) > 440.0:
			break
	return candidate

func _on_enemy_projectile_requested(origin: Vector2, direction: Vector2, speed: float, damage: float, kind: String) -> void:
	if game_state != "playing":
		return
	var projectile := EnemyProjectileScript.new()
	projectile.setup(origin, direction, speed, damage, kind)
	projectile.add_to_group("run_entities")
	add_child(projectile)
	if kind == "venom":
		audio.play("venom", 0.08, -2.0)

func _on_enemy_died(enemy: Node, death_position: Vector2, points: int, color: Color) -> void:
	kills += 1
	var now := Time.get_ticks_msec()
	if now <= combo_expires:
		combo = min(8, combo + 1)
	else:
		combo = 1
	combo_expires = now + 1150
	score += points * combo
	_spawn_impact(death_position, color, 42.0)
	audio.play("enemy_death", 0.09, -2.0 if enemy.get("elite") else -5.0)
	_add_shake(6.0 if enemy.get("elite") else 2.0)
	if combo >= 4:
		hud.show_toast("CHAIN x%d" % combo, Color("ffe66d"))

	var drop_chance: float = minf(0.42, 0.115 + current_wave * 0.003 + player.drop_luck)
	if enemy.get("elite") or rng.randf() < drop_chance:
		var kind := _choose_powerup()
		call_deferred("_spawn_powerup", kind, death_position)

func _choose_powerup() -> String:
	# Weighted toward sustain, with the flashier weapon mutations still common.
	var roll := rng.randf()
	if is_instance_valid(player) and player.health < player.max_health * 0.4 and roll < 0.34:
		return "cheese"
	if roll < 0.18:
		return "cheese"
	if roll < 0.37:
		return "rapid"
	if roll < 0.53:
		return "triple"
	if roll < 0.67:
		return "power"
	if roll < 0.79:
		return "haste"
	if roll < 0.90:
		return "shield"
	return "pierce"

func _spawn_powerup(kind: String, at: Vector2) -> void:
	if not is_instance_valid(player):
		return
	var pickup := PowerUpScript.new()
	pickup.setup(kind, at, player)
	pickup.add_to_group("run_entities")
	add_child(pickup)
	pickup.collected.connect(_on_powerup_collected)

func _on_powerup_collected(_kind: String, at: Vector2, color: Color) -> void:
	_spawn_impact(at, color, 58.0)
	audio.play("pickup", 0.04)
	score += 75

func _on_shot_fired(at: Vector2, powered: bool) -> void:
	var fx := ImpactFXScript.new()
	fx.setup(at, Color("62fff1"), 11.0, 0.16)
	fx.spokes = 4
	fx.add_to_group("run_entities")
	add_child(fx)
	audio.play("power_shoot" if powered else "shoot", 0.055)

func _on_player_pickup_message(title: String, color: Color) -> void:
	hud.show_toast(title, color)
	if title == "SHIELD BLOCK":
		audio.play("shield", 0.04)

func _on_autofire_changed(enabled: bool) -> void:
	hud.set_autofire(enabled)

func _spawn_impact(at: Vector2, color: Color, size: float) -> void:
	var fx := ImpactFXScript.new()
	fx.setup(at, color, size)
	fx.add_to_group("run_entities")
	add_child(fx)

func _on_enemy_hit(_at: Vector2) -> void:
	audio.play("enemy_hit", 0.1, -2.0)

func _on_player_dash(at: Vector2) -> void:
	audio.play("dash", 0.035)
	_spawn_impact(at, Color("62fff1"), 34.0)
	_add_shake(3.0)

func _on_player_damage_feedback(at: Vector2, blocked: bool) -> void:
	if not blocked:
		audio.play("player_hit", 0.045)
	_spawn_impact(at, Color("6ef7ff") if blocked else Color("ff5b9e"), 65.0)
	_add_shake(5.0 if blocked else 14.0)

func _on_ui_sound_requested(event_name: String) -> void:
	audio.play(event_name, 0.025)

func _add_shake(amount: float) -> void:
	shake_strength = minf(24.0, shake_strength + amount)

func _open_upgrade_draft() -> void:
	if game_state != "playing" or not is_instance_valid(player):
		return
	var candidates: Array[String] = []
	for id in UPGRADES.keys():
		if player.can_take_upgrade(String(id)):
			candidates.append(String(id))
	current_upgrade_ids.clear()
	while current_upgrade_ids.size() < 3 and not candidates.is_empty():
		var selected_index := rng.randi_range(0, candidates.size() - 1)
		current_upgrade_ids.append(candidates[selected_index])
		candidates.remove_at(selected_index)
	var cards: Array[Dictionary] = []
	for id in current_upgrade_ids:
		cards.append(UPGRADES[id])
	game_state = "upgrade"
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hud.show_upgrade_draft(cards)

func _on_upgrade_selected(id: String) -> void:
	if game_state != "upgrade" or id not in current_upgrade_ids or not is_instance_valid(player):
		return
	player.apply_upgrade(id)
	var data: Dictionary = UPGRADES[id]
	hud.hide_upgrade_draft()
	get_tree().paused = false
	game_state = "playing"
	intermission = maxf(1.4, 2.35 - current_wave * 0.025)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	hud.show_toast(String(data["title"]), data["color"])
	audio.play("pickup", 0.025, 1.5)
	current_upgrade_ids.clear()

func _on_player_died() -> void:
	if game_state != "playing":
		return
	game_state = "game_over"
	wave_active = false
	reticle.enabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_spawn_impact(player.global_position, Color("ff5b9e"), 110.0)
	audio.play("player_hit", 0.02, 2.0)
	_add_shake(24.0)
	var old_best := high_score
	if score > high_score:
		high_score = score
		_save_high_score(high_score)
	hud.show_game_over(score, current_wave, kills, high_score, score > old_best)

func _living_enemy_count() -> int:
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
			count += 1
	return count

func _wave_progress() -> float:
	if wave_total <= 0:
		return 0.0
	var remaining := wave_queue.size() + _living_enemy_count()
	return 1.0 - float(remaining) / float(wave_total)

func _clear_run_nodes() -> void:
	for node in get_tree().get_nodes_in_group("run_entities"):
		if is_instance_valid(node):
			node.queue_free()
	player = null
	reticle = null

func _load_high_score() -> int:
	if not FileAccess.file_exists("user://highscore.save"):
		return 0
	var file := FileAccess.open("user://highscore.save", FileAccess.READ)
	return int(file.get_as_text()) if file else 0

func _save_high_score(value: int) -> void:
	var file := FileAccess.open("user://highscore.save", FileAccess.WRITE)
	if file:
		file.store_string(str(value))

func _draw() -> void:
	# Large neon arena; all art is procedural so the project has no asset dependencies.
	draw_rect(ARENA, Color("080c26"), true)
	for x in range(int(ARENA.position.x), int(ARENA.end.x) + 1, 100):
		var major := posmod(x, 500) == 0
		draw_line(Vector2(x, ARENA.position.y), Vector2(x, ARENA.end.y), Color(0.15, 0.38, 0.53, 0.15 if major else 0.065), 2.0 if major else 1.0)
	for y in range(int(ARENA.position.y), int(ARENA.end.y) + 1, 100):
		var major := posmod(y, 500) == 0
		draw_line(Vector2(ARENA.position.x, y), Vector2(ARENA.end.x, y), Color(0.15, 0.38, 0.53, 0.15 if major else 0.065), 2.0 if major else 1.0)
	# Sewer covers and scattered crumb markers give the open arena landmarks.
	for marker in [Vector2(-760, -360), Vector2(670, 310), Vector2(-420, 440), Vector2(520, -430), Vector2.ZERO]:
		draw_circle(marker, 58.0, Color(0.02, 0.05, 0.13, 0.75))
		draw_arc(marker, 58.0, 0.0, TAU, 36, Color(0.18, 0.72, 0.76, 0.20), 3.0)
		for i in range(8):
			draw_line(marker + Vector2.from_angle(TAU * i / 8.0) * 21.0, marker + Vector2.from_angle(TAU * i / 8.0) * 49.0, Color(0.2, 0.55, 0.65, 0.14), 3.0)
	draw_rect(ARENA, Color("35e6dc"), false, 6.0)
	draw_rect(ARENA.grow(-14.0), Color(0.3, 0.4, 0.9, 0.25), false, 2.0)
