extends Node2D

const PlayerScript = preload("res://scripts/first_person_player.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const EnemyProjectileScript = preload("res://scripts/enemy_projectile.gd")
const PowerUpScript = preload("res://scripts/power_up.gd")
const ImpactFXScript = preload("res://scripts/impact_fx.gd")
const HUDScript = preload("res://scripts/hud.gd")
const ReticleScript = preload("res://scripts/aim_reticle.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")
const CrumbBombScript = preload("res://scripts/crumb_bomb.gd")
const ThreatOverlayScript = preload("res://scripts/threat_overlay.gd")
const FizzyCanScript = preload("res://scripts/fizzy_can.gd")
const SettingsScript = preload("res://scripts/settings_panel.gd")
const NightmareMotifs = preload("res://scripts/nightmare_motifs.gd")
const KENNEY_TREE_TEXTURE = preload("res://assets/kenney/background/tree.png")
const KENNEY_SMALL_TREE_TEXTURE = preload("res://assets/kenney/background/treeSmall_green2.png")
const KENNEY_SMALL_TREE_ALT_TEXTURE = preload("res://assets/kenney/background/treeSmall_green3.png")
const KENNEY_BUSH_TEXTURE = preload("res://assets/kenney/background/bush1.png")
const KENNEY_BUSH_ALT_TEXTURE = preload("res://assets/kenney/background/bushAlt1.png")
const KENNEY_FENCE_TEXTURE = preload("res://assets/kenney/background/fence.png")

const ARENA := Rect2(-1200.0, -700.0, 2400.0, 1400.0)
const INK := Color("0b0d17")
const GRASS := Color("0d111a")
const GRASS_DARK := Color("070b12")
const DIRT := Color("1a1823")
const CREAM := Color("fff0bf")
const TOMATO := Color("df5144")
const CHEESE := Color("f6c53f")
const POWER_TYPES: Array[String] = ["cheese", "rapid", "triple", "power", "haste", "shield", "pierce"]
const COMBO_WINDOW_MS := 2400
const UPGRADES := {
	"light_trail": {"id": "light_trail", "title": "LIGHT TRAIL", "description": "Leave light for 3s.\nDeals 1.5x bullet damage/s.", "color": Color("ffe7a0")},
	"pinball": {"id": "pinball", "title": "BOUNCE", "description": "Bullets bounce off walls once.", "color": Color("55ad87")},
	"scurry_bomb": {"id": "scurry_bomb", "title": "DASH BOMB", "description": "Dash leaves a bomb.\nDamage: 2.5x bullet damage.", "color": Color("ef6f6c")},
	"snack_orbit": {"id": "snack_orbit", "title": "ORBIT", "description": "3 orbiting bullets for 6.5s.\nPickups recharge them.", "color": Color("8d79ad")},
	"split_acorns": {"id": "split_acorns", "title": "SPLIT SHOT", "description": "Bounces add 1 bullet\nat 60% damage.", "color": Color("55ad87")},
	"dash_refund": {"id": "dash_refund", "title": "DASH RECHARGE", "description": "Bomb hits reduce\ndash cooldown by 0.4s.", "color": Color("ef6f6c")},
	"orbit_feast": {"id": "orbit_feast", "title": "EXTRA ORBITS", "description": "Orbiting bullets: 3 → 5.", "color": Color("8d79ad")},
	"quick_whiskers": {"id": "quick_whiskers", "title": "FIRE RATE", "description": "10% shorter shot interval.", "color": Color("ef6f6c")},
	"heavy_seeds": {"id": "heavy_seeds", "title": "DAMAGE", "description": "+3.5 damage.", "color": Color("e89b4f")},
	"fleet_feet": {"id": "fleet_feet", "title": "SPEED", "description": "+20 speed.", "color": Color("79a85b")},
	"thick_fur": {"id": "thick_fur", "title": "HEALTH", "description": "+16 max HP. Heal 20 HP.", "color": Color("d95863")},
	"long_teeth": {"id": "long_teeth", "title": "PIERCING", "description": "Bullets pierce +1 target.", "color": Color("f4d7a1")},
	"big_paws": {"id": "big_paws", "title": "BULLET SIZE", "description": "Larger bullets.", "color": Color("8d79ad")},
	"lucky_tail": {"id": "lucky_tail", "title": "DROP CHANCE", "description": "+3% pickup drop chance.", "color": Color("f2c14e")},
	"extra_pocket": {"id": "extra_pocket", "title": "MULTISHOT", "description": "+1 bullet per shot.", "color": Color("4f9f8f")},
	"cheese_magnet": {"id": "cheese_magnet", "title": "PICKUP RANGE", "description": "+55 pickup range.", "color": Color("e7b84b")},
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
var settings: CanvasLayer
var pending_treats: Array[String] = []
var boss_reward_pending := false
var overtime := false
var best_combo := 1
var encounter := "BIRD SWARM"
var spawned_this_wave := 0
var run_clock := 0.0
var best_wave := 0
var previous_best_wave := 0
var kills_without_treat := 0
var streak_rewarded := false
var active_boss: CharacterBody2D
var first_person: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide() # CanvasLayer menus remain visible above the 3D world.
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
	hud.resume_requested.connect(_toggle_pause)
	hud.overtime_requested.connect(_continue_overtime)
	settings = SettingsScript.new()
	add_child(settings)
	settings.changed.connect(_apply_settings)
	hud.settings_requested.connect(func(): settings.show_settings())
	_apply_settings()
	var records := ConfigFile.new()
	if records.load("user://records.cfg") == OK:
		best_wave = int(records.get_value("records", "wave", 0))
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
	combo_expires = 0
	best_combo = 1
	run_clock = 0.0
	previous_best_wave = best_wave
	overtime = false
	boss_reward_pending = false
	pending_treats.clear()
	kills_without_treat = 0
	streak_rewarded = false
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
	player.aim_assist = settings.aim_assist
	add_child(ThreatOverlayScript.new())
	first_person = preload("res://scripts/first_person_view.gd").new()
	add_child(first_person)
	audio.start_ambience()
	for at in [Vector2(-650, 190), Vector2(650, -190)]:
		var can := FizzyCanScript.new()
		can.position = at
		add_child(can)
	_spawn_powerup("triple", Vector2(85, 0))

	reticle = ReticleScript.new()
	reticle.enabled = true
	reticle.z_index = 80
	reticle.add_to_group("run_entities")
	add_child(reticle)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hud.begin_game()
	hud.set_autofire(true)
	var empty_buffs: Array[String] = []
	hud.update_stats(0, 0, 0, player.health, player.max_health, 0.0, empty_buffs)
	hud.update_combo(1, 0.0)

func return_to_menu() -> void:
	get_tree().paused = false
	game_state = "menu"
	wave_active = false
	_clear_run_nodes()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	hud.show_menu()

func _toggle_pause() -> void:
	if game_state != "playing" or settings.is_open():
		return
	var paused := not get_tree().paused
	get_tree().paused = paused
	hud.set_paused(paused)
	if paused:
		hud.set_build_text(player.get_build_description())
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta: float) -> void:
	if game_state != "playing" or get_tree().paused or not is_instance_valid(player):
		return
	run_clock += delta
	_update_combo_decay(delta)

	if not wave_active:
		intermission -= delta
		if intermission <= 0.0:
			_begin_next_wave()
	else:
		spawn_cooldown -= delta
		if not wave_queue.is_empty() and spawn_cooldown <= 0.0 and _living_enemy_count() < get_enemy_cap(current_wave):
			var next_kind: String = wave_queue.pop_front()
			_spawn_enemy(next_kind)
			spawned_this_wave += 1
			# Breathers belong in a crowded fight; fast clears should keep the pressure on.
			spawn_cooldown = 1.0 if spawned_this_wave % 12 == 0 and _living_enemy_count() >= get_enemy_cap(current_wave) / 2 else get_spawn_interval(current_wave)
		if wave_queue.is_empty() and _living_enemy_count() <= 3:
			for enemy in get_tree().get_nodes_in_group("enemies"):
				enemy.cleanup = true
		if wave_queue.is_empty() and _living_enemy_count() == 0:
			_finish_wave()

	hud.update_stats(score, current_wave, kills, player.health, player.max_health, _wave_progress(), player.get_active_buffs(), player.get_dash_charge())
	if is_instance_valid(active_boss) and not active_boss.dying:
		hud.set_boss_status(active_boss.enemy_kind.replace("_", " ").to_upper(), active_boss.boss_phase, active_boss.health / active_boss.max_health)
	hud.update_combo(combo, clampf(float(combo_expires - int(run_clock * 1000.0)) / COMBO_WINDOW_MS, 0.0, 1.0))
	if wave_active and wave_queue.is_empty() and _living_enemy_count() <= 3:
		hud.set_encounter("LAST %d - FOLLOW THE GOLD ARROWS" % _living_enemy_count())
	hud.update_tip(player, current_wave, settings.tips)

func _process(delta: float) -> void:
	if not get_tree().paused:
		shake_strength = maxf(0.0, shake_strength - delta * 34.0)
	# Browsers release pointer lock themselves on Escape.
	if OS.has_feature("web") and game_state == "playing" and not get_tree().paused and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		_toggle_pause()

func _begin_next_wave() -> void:
	current_wave += 1
	spawned_this_wave = 0
	streak_rewarded = false
	for kind in pending_treats:
		player.apply_powerup(kind)
	pending_treats.clear()
	wave_active = true
	wave_queue.clear()
	encounter = ["BIRD SWARM", "CAT PINCER", "RANGED SIEGE", "ELITE HUNT"][(current_wave - 1) % 4]
	var regular_count := get_regular_enemy_count(current_wave)
	for i in range(regular_count):
		wave_queue.append(_encounter_enemy(i))
	var boss_wave := current_wave % 5 == 0
	var boss_kind := ""
	if boss_wave:
		boss_kind = get_boss_kind(current_wave)
		wave_queue.insert(mini(4, wave_queue.size()), boss_kind)
	wave_total = wave_queue.size()
	spawn_cooldown = 0.15
	hud.show_wave_banner(current_wave, boss_kind)
	hud.set_encounter("BOSS" if boss_wave else encounter)
	if boss_wave:
		audio.play("shield", 0.03, -1.0)
		_add_shake(8.0)

func get_regular_enemy_count(for_wave: int) -> int:
	var count := 8 + for_wave * 6 + int(for_wave / 5) * 4
	return roundi(count * 0.8) if settings.cozy else count

func get_enemy_cap(for_wave: int) -> int:
	var cap := mini(42, 10 + for_wave * 2)
	return roundi(cap * 0.7) if settings.cozy else cap

func get_spawn_limit() -> int:
	# Keep boss patterns readable while reinforcements keep arriving.
	var cap := get_enemy_cap(current_wave)
	if is_instance_valid(active_boss) and not active_boss.dying:
		cap = mini(cap, 18 + active_boss.boss_phase * 6)
	return cap

func get_spawn_interval(for_wave: int) -> float:
	return maxf(0.14, 0.48 - for_wave * 0.016 - floorf(float(for_wave) / 10.0) * 0.02) * (1.25 if settings.cozy else 1.0)

func _encounter_enemy(index: int) -> String:
	# Isolated introductions precede mixed encounters. Every recipe leaves room to move.
	var introductions := {3: "owl", 4: "snake", 6: "raccoon", 10: "fox"}
	if index == 0 and introductions.has(current_wave):
		return introductions[current_wave]
	if current_wave <= 2:
		return "cat" if current_wave == 2 and index % 4 == 0 else "bird"
	# Keep later unlocks present in every recipe, including bird and cat waves.
	if current_wave >= 6 and index % 5 == 4:
		return "fox" if current_wave >= 10 and index % 10 == 9 else "raccoon"
	match encounter:
		"BIRD SWARM":
			return "bird" if index % 4 != 0 else _choose_enemy_kind()
		"CAT PINCER":
			return "cat" if index % 3 == 0 else "bird"
		"RANGED SIEGE":
			return "owl" if index % 4 == 0 else ("snake" if current_wave >= 4 and index % 4 == 2 else "bird")
	return _choose_enemy_kind()

func get_boss_kind(for_wave: int) -> String:
	if for_wave % 15 == 0:
		return "barn_owl"
	if for_wave % 10 == 0:
		return "junkyard_dog"
	return "alpha_cat"

func _finish_wave() -> void:
	wave_active = false
	_clear_enemy_projectiles()
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.collected_already or pickup.is_queued_for_deletion():
			continue
		pickup.collected_already = true
		pending_treats.append(pickup.kind)
		score += 75
		pickup.queue_free()
	var clear_bonus := 400 * current_wave
	score += clear_bonus
	intermission = max(1.8, 3.0 - current_wave * 0.035)
	hud.show_toast("CRUMBS TEMPORARILY SECURED!  +%d" % clear_bonus, Color("4f9f8f"))
	audio.play("wave_clear", 0.02)
	player.heal(6.0 if settings.cozy else 3.0)
	# Emergency cheese prevents one bad wave from ending an otherwise healthy run.
	if current_wave % 3 == 0 and is_instance_valid(player) and player.health < player.max_health * 0.7:
		_spawn_powerup("cheese", player.global_position + Vector2(110, 0).rotated(rng.randf_range(0.0, TAU)))
	if current_wave == 15 and not overtime:
		_record_run()
		game_state = "victory"
		get_tree().paused = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		hud.show_victory(score, best_combo)
	else:
		_open_upgrade_draft()

func _choose_enemy_kind() -> String:
	var roll := rng.randf()
	if current_wave < 2:
		return "bird" if roll < 0.68 else "cat"
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
		return "snake" if current_wave >= 4 else "owl"
	if current_wave < 10:
		if roll < 0.26:
			return "bird"
		if roll < 0.52:
			return "cat"
		if roll < 0.69:
			return "owl"
		if roll < 0.84:
			return "snake"
		return "raccoon"
	if current_wave < 15:
		if roll < 0.20:
			return "bird"
		if roll < 0.40:
			return "cat"
		if roll < 0.56:
			return "owl"
		if roll < 0.70:
			return "snake"
		if roll < 0.86:
			return "raccoon"
		return "fox"
	if roll < 0.16:
		return "bird"
	if roll < 0.32:
		return "cat"
	if roll < 0.48:
		return "owl"
	if roll < 0.62:
		return "snake"
	if roll < 0.82:
		return "raccoon"
	return "fox"

func _spawn_enemy(kind: String) -> void:
	if not is_instance_valid(player):
		return
	var enemy := EnemyScript.new()
	var is_boss := kind in ["alpha_cat", "junkyard_dog", "barn_owl"]
	var is_elite := not is_boss and current_wave >= 3 and ((encounter == "ELITE HUNT" and spawned_this_wave == 3) or rng.randf() < minf(0.24, 0.03 + current_wave * 0.01))
	enemy.setup(kind, player, current_wave, is_elite)
	if settings.cozy:
		enemy.contact_damage *= 0.7
		enemy.move_speed *= 0.88
	enemy.global_position = _random_spawn_position()
	if encounter == "CAT PINCER":
		var side := -1.0 if spawned_this_wave % 2 == 0 else 1.0
		var candidate: Vector2 = player.global_position + Vector2(side * 610.0, rng.randf_range(-180, 180))
		candidate = candidate.clamp(ARENA.position + Vector2(45, 45), ARENA.end - Vector2(45, 45))
		if candidate.distance_to(player.global_position) > 440:
			enemy.global_position = candidate
	enemy.add_to_group("run_entities")
	add_child(enemy)
	enemy.died.connect(_on_enemy_died)
	enemy.hit.connect(_on_enemy_hit)
	enemy.phase_changed.connect(func(_boss_kind: String, phase: int): hud.show_toast("PHASE %d" % phase, TOMATO))
	enemy.projectile_requested.connect(_on_enemy_projectile_requested)
	if is_boss:
		active_boss = enemy

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
	var now := int(run_clock * 1000.0)
	if combo > 1 or (kills > 1 and now <= combo_expires):
		combo = min(8, combo + 1)
	else:
		combo = 1
	combo_expires = now + COMBO_WINDOW_MS
	best_combo = maxi(best_combo, combo)
	score += points * combo
	_spawn_impact(death_position, color, 42.0)
	audio.play("enemy_death", 0.09, -2.0 if enemy.get("elite") else -5.0)
	_add_shake(6.0 if enemy.get("elite") else 2.0)
	if combo == 8 and not streak_rewarded:
		streak_rewarded = true
		player.apply_powerup("rapid")
		hud.show_toast("MAX STREAK! RAPID CLAWS UNLEASHED", CHEESE)
		audio.play("pickup", 0.04)
	if enemy.get("enemy_kind") in ["alpha_cat", "junkyard_dog", "barn_owl"]:
		boss_reward_pending = true
		pending_treats.append("power")
		pending_treats.append("shield")
		_clear_enemy_projectiles()
		hud.show_toast("BOSS DOWN • BONUS UPGRADE", Color("f6c53f"))

	var drop_chance: float = minf(0.18, 0.055 + player.drop_luck)
	kills_without_treat += 1
	if enemy.get("elite") or kills_without_treat >= (8 if settings.cozy else 12) or rng.randf() < drop_chance:
		kills_without_treat = 0
		var kind := _choose_powerup()
		call_deferred("_spawn_powerup", kind, death_position)

func _update_combo_decay(delta: float = 0.0) -> void:
	if not wave_active:
		# Drafts and the breath between waves never cost a streak.
		combo_expires += int(round(delta * 1000.0))
		return
	var now := int(run_clock * 1000.0)
	while combo > 1 and now > combo_expires:
		combo -= 1
		combo_expires += 650

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
	# A last-kill drop may arrive after the wave-clear callback has banked loot.
	if game_state in ["upgrade", "victory"]:
		pending_treats.append(kind)
		score += 75
		return
	if game_state != "playing":
		return
	var pickup := PowerUpScript.new()
	pickup.setup(kind, at, player)
	pickup.add_to_group("run_entities")
	add_child(pickup)
	pickup.collected.connect(_on_powerup_collected)

func _on_powerup_collected(_kind: String, at: Vector2, color: Color) -> void:
	_spawn_feedback(at, color, "pickup")
	hud.feedback_overlay.pulse(color, false)
	audio.play("pickup", 0.04, 4.0)
	score += 75

func _on_shot_fired(at: Vector2, powered: bool) -> void:
	var fx := ImpactFXScript.new()
	fx.setup(at, Color("f2c14e") if powered else Color("fff4d6"), 11.0, 0.16)
	fx.spokes = 4
	fx.add_to_group("run_entities")
	add_child(fx)
	audio.play("power_shoot" if powered else "shoot", 0.055)

func _on_player_pickup_message(title: String, color: Color) -> void:
	hud.show_toast(title, color, 1.3)
	if title == "BLOCKED":
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
	if player.upgrade_levels.get("scurry_bomb", 0) > 0:
		var bomb := CrumbBombScript.new()
		bomb.position = at
		bomb.owner_player = player
		add_child(bomb)
	audio.play("dash", 0.035)
	_spawn_impact(at, Color("f4d7a1"), 34.0)
	_add_shake(3.0)

func _on_player_damage_feedback(at: Vector2, blocked: bool) -> void:
	if not blocked:
		audio.play("player_hit", 0.045, 3.0)
	_spawn_feedback(at, Color("9bdded") if blocked else Color("fa4f69"), "blocked" if blocked else "damage")
	hud.feedback_overlay.pulse(Color("9bdded") if blocked else Color("ed294f"), not blocked)
	_add_shake(8.0 if blocked else 20.0)

func _spawn_feedback(at: Vector2, color: Color, kind: String) -> void:
	var effect := preload("res://scripts/feedback_burst.gd").new()
	effect.position = at
	effect.tint = color
	effect.kind = kind
	add_child(effect)

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
	if current_wave == 1 and player.upgrade_levels.is_empty():
		candidates.assign(["pinball", "scurry_bomb", "snack_orbit"])
	elif current_wave == 2 and "light_trail" in candidates:
		current_upgrade_ids.append("light_trail")
		candidates.erase("light_trail")
	# Sometimes guarantee one eligible synergy, leaving two unrestricted choices.
	elif rng.randf() < 0.65:
		for id in ["split_acorns", "dash_refund", "orbit_feast"]:
			if id in candidates:
				current_upgrade_ids.append(id)
				candidates.erase(id)
				break
	while current_upgrade_ids.size() < 3 and not candidates.is_empty():
		var selected_index := rng.randi_range(0, candidates.size() - 1)
		current_upgrade_ids.append(candidates[selected_index])
		candidates.remove_at(selected_index)
	var cards: Array[Dictionary] = []
	for id in current_upgrade_ids:
		var card: Dictionary = UPGRADES[id].duplicate()
		card["description"] = _upgrade_description(id)
		cards.append(card)
	if cards.is_empty():
		player.heal(24.0)
		score += 1000
		boss_reward_pending = false
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		hud.show_toast("+24 HP • +1000 SCORE", Color("f6c53f"))
		return
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
	intermission = 0.65
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hud.show_toast(String(data["title"]), data["color"])
	audio.play("pickup", 0.025, 1.5)
	current_upgrade_ids.clear()
	if boss_reward_pending:
		boss_reward_pending = false
		_open_upgrade_draft()
		hud.show_toast("BONUS UPGRADE", Color("f6c53f"))

func _on_player_died() -> void:
	if game_state != "playing":
		return
	game_state = "game_over"
	get_tree().paused = true
	wave_active = false
	reticle.enabled = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_spawn_impact(player.global_position, Color("d95863"), 110.0)
	audio.play("player_hit", 0.02, 2.0)
	_add_shake(24.0)
	var old_best := high_score
	if score > high_score:
		high_score = score
		_save_high_score(high_score)
	hud.show_game_over(score, current_wave, kills, high_score, score > old_best)
	_record_run()
	hud.show_death_tip(player.last_damage_source, best_combo, current_wave > previous_best_wave)

func _clear_enemy_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):
		projectile.spent = true
		projectile.set_deferred("monitoring", false)
		projectile.queue_free()

func _continue_overtime() -> void:
	if game_state != "victory":
		return
	overtime = true
	hud.hide_victory()
	get_tree().paused = false
	game_state = "playing"
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_open_upgrade_draft()

func _record_run() -> void:
	if score > high_score:
		high_score = score
		_save_high_score(high_score)
	best_wave = maxi(best_wave, current_wave)
	var records := ConfigFile.new()
	records.set_value("records", "wave", best_wave)
	records.save("user://records.cfg")

func _apply_settings() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, settings.volume)))
	AudioServer.set_bus_mute(0, settings.volume <= 0.001)
	if is_instance_valid(player):
		player.aim_assist = settings.aim_assist
	hud.large_text = settings.large_text
	hud.set_control_labels(settings.keys)
	hud.set_autofire(player.autofire if is_instance_valid(player) else true)

func _upgrade_description(id: String) -> String:
	var values := {
		"quick_whiskers": "Shot interval %.2fs → %.2fs" % [player.fire_interval, maxf(0.09, player.fire_interval * 0.9)],
		"heavy_seeds": "Damage %.1f → %.1f" % [player.base_damage, player.base_damage + 3.5],
		"fleet_feet": "Speed %d → %d" % [player.move_speed, minf(470, player.move_speed + 20)],
		"thick_fur": "Max HP %d → %d\nHeal 20 HP" % [player.max_health, player.max_health + 16],
		"long_teeth": "Pierce %d → %d targets" % [player.base_pierce, player.base_pierce + 1],
		"big_paws": "Bullet size %.1f → %.1f" % [player.bullet_radius, minf(8.25, player.bullet_radius + 1)],
		"lucky_tail": "Bonus drops %d%% → %d%%" % [roundi(player.drop_luck * 100), roundi((player.drop_luck + 0.03) * 100)],
		"extra_pocket": "Bullets per shot %d → %d" % [player.permanent_projectiles, player.permanent_projectiles + 1],
		"cheese_magnet": "Pickup range %d → %d" % [player.magnet_radius, minf(330, player.magnet_radius + 55)],
	}
	return "Level %d\n%s" % [int(player.upgrade_levels.get(id, 0)) + 1, values.get(id, UPGRADES[id]["description"])]

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
	active_boss = null
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
	# A low-contrast nightmare garden sits beneath the bright combat sprites.
	draw_rect(ARENA, GRASS, true)
	for x in range(int(ARENA.position.x) - 100, int(ARENA.end.x), 185):
		var stripe := PackedVector2Array([
			Vector2(x, ARENA.position.y), Vector2(x + 130, ARENA.position.y),
			Vector2(x + 265, ARENA.end.y), Vector2(x + 85, ARENA.end.y),
		])
		draw_colored_polygon(stripe, Color(GRASS_DARK, 0.55 if posmod(int(x / 185), 2) == 0 else 0.25))
	# Broken contour lines bend the ground without looking like attack warnings.
	for row in range(13):
		var contour := PackedVector2Array()
		for column in range(49):
			var x := -1200.0 + column * 50.0
			var y := -645.0 + row * 104.0 + sin(x * 0.005 + row * 0.7) * 24.0
			contour.append(Vector2(x, y))
		draw_polyline(contour, Color("23202d"), 1.0, true)
	for index in range(160):
		var at := Vector2(-1160 + posmod(index * 317, 2320), -660 + posmod(index * 191, 1320))
		draw_line(at, at + Vector2(8, -4), Color("292332"), 1.0, true)
	for at in [Vector2(-370, -120), Vector2(390, 90), Vector2(-830, 320), Vector2(870, -220)]:
		NightmareMotifs.spiral(self, at, 90, Color("373247"))
	for at in [Vector2(-370, -120), Vector2(390, 90), Vector2(-890, -460), Vector2(820, 480)]:
		NightmareMotifs.eye(self, at, 46.0, Color("465265"), -0.16)
	# The old hose becomes an almost living, tangled root.
	var hose := PackedVector2Array([Vector2(-1120, -545), Vector2(-810, -610), Vector2(-520, -525), Vector2(-185, -585), Vector2(105, -520)])
	draw_polyline(hose, INK, 23.0, true)
	draw_polyline(hose, Color("354553"), 14.0, true)
	_draw_kenney_backyard_props()
	# A bruised, cracked path runs through the garden.
	var path := PackedVector2Array([Vector2(-1200, 420), Vector2(-820, 300), Vector2(-430, 350), Vector2(-40, 240), Vector2(390, 285), Vector2(780, 180), Vector2(1200, 240)])
	draw_polyline(path, INK, 148.0, true)
	draw_polyline(path, DIRT, 130.0, true)
	draw_polyline(path, Color("302638"), 2.0, true)
	for marker in [Vector2(-760, -360), Vector2(690, 330), Vector2(-410, 470), Vector2(540, -420)]:
		draw_circle(marker + Vector2(9, 12), 61.0, Color(0.18, 0.08, 0.09, 0.26))
		draw_circle(marker, 58.0, Color("282b36"))
		draw_arc(marker, 58.0, 0.0, TAU, 32, INK, 7.0, true)
		draw_arc(marker + Vector2(-10, -8), 33.0, 3.4, 5.5, 14, Color("576174"), 2.0, true)
		NightmareMotifs.eye(self, marker, 25.0, Color("75868e"))
	# The familiar picnic survives as a desaturated, crooked patchwork.
	var blanket := Rect2(-150, -105, 300, 210)
	draw_rect(Rect2(blanket.position + Vector2(12, 15), blanket.size).grow(9.0), Color(0.16, 0.07, 0.08, 0.28), true)
	draw_rect(blanket.grow(8.0), INK, true)
	for row in range(4):
		for column in range(6):
			var patch_color := Color("373744") if (row + column) % 2 == 0 else Color("281b2d")
			var top := blanket.position + Vector2(column * 50, row * 52.5)
			var skew := sin(row * 1.8) * 8.0
			var next_skew := sin((row + 1) * 1.8) * 8.0
			draw_colored_polygon(PackedVector2Array([top + Vector2(skew, 0), top + Vector2(50 + skew, 0), top + Vector2(50 + next_skew, 52.5), top + Vector2(next_skew, 52.5)]), patch_color)
	_draw_picnic_junk()
	# Wilted flowers and chalk flecks stay dimmer than real pickups.
	for flower in [Vector2(-1030, -520), Vector2(-920, 560), Vector2(-580, -570), Vector2(320, -560), Vector2(980, -470), Vector2(1020, 520), Vector2(360, 540)]:
		for petal in range(5):
			draw_circle(flower + Vector2.from_angle(TAU * petal / 5.0) * 8.0, 5.0, Color("62425c"))
		draw_circle(flower, 4.0, Color("859091"))
	for crumb in [Vector2(-250, -280), Vector2(240, 180), Vector2(850, -110), Vector2(-870, 80)]:
		draw_circle(crumb, 5.0, Color("54566b"))
	_draw_no_rats_sign(Vector2(880, -420))
	# A cold double border makes the arena limits visible in the dark.
	draw_rect(ARENA, INK, false, 28.0)
	draw_rect(ARENA.grow(-17.0), Color("526277"), false, 7.0)
	for nail in [Vector2(-1175, -675), Vector2(1175, -675), Vector2(-1175, 675), Vector2(1175, 675)]:
		draw_circle(nail, 11.0, INK)
		draw_circle(nail - Vector2(2, 2), 5.0, Color("8a8e9c"))

func _draw_picnic_junk() -> void:
	# A familiar cloth has become the frame of something looking back.
	for ring in range(4):
		draw_arc(Vector2.ZERO, 32 + ring * 18, ring * 0.8, ring * 0.8 + 4.8, 64, Color("514153"), 1.5, true)
	NightmareMotifs.eye(self, Vector2.ZERO, 72, Color("77717e"), -0.1)
	for i in range(8):
		var at := Vector2.from_angle(i * TAU / 8.0) * Vector2(120, 83)
		draw_line(at, at * 0.8 + Vector2(7, -5), Color("716675"), 2, true)

func _draw_no_rats_sign(at: Vector2) -> void:
	draw_set_transform(at, -0.09, Vector2.ONE)
	draw_line(Vector2(0, 42), Vector2(0, 126), INK, 18.0, true)
	draw_line(Vector2(0, 42), Vector2(0, 126), Color("9a6136"), 10.0, true)
	draw_rect(Rect2(-65, -36, 144, 94), Color(0.12, 0.05, 0.06, 0.3), true)
	draw_rect(Rect2(-72, -45, 144, 94), INK, true)
	draw_rect(Rect2(-64, -37, 128, 78), Color("5d6174"), true)
	NightmareMotifs.eye(self, Vector2(0, 2), 32.0, Color("c2b6ca"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_kenney_backyard_props() -> void:
	# Crooked bare trees frame the arena; familiar shrubs recede into blue shadow.
	var tall_trees := [
		Vector2(-570, -245), Vector2(570, -245),
		Vector2(-570, 260), Vector2(570, 260),
	]
	for at in tall_trees:
		NightmareMotifs.tree(self, at + Vector2(0, 100), 245.0, -32.0 if at.x < 0 else 32.0)

	var small_trees := [
		Vector2(-430, -315), Vector2(430, -315), Vector2(-430, 315), Vector2(430, 315),
	]
	for index in range(small_trees.size()):
		NightmareMotifs.tree(self, small_trees[index] + Vector2(0, 50), 120.0, 26.0 if index % 2 == 0 else -26.0)

	var bushes := [
		Vector2(-470, -280), Vector2(470, -280), Vector2(-470, 280), Vector2(470, 280),
	]
	for index in range(bushes.size()):
		var texture = KENNEY_BUSH_TEXTURE if index % 2 == 0 else KENNEY_BUSH_ALT_TEXTURE
		_draw_prop(texture, bushes[index], Vector2(150, 72))

	for at in [Vector2(-620, -325), Vector2(620, -325), Vector2(-620, 325), Vector2(620, 325)]:
		_draw_prop(KENNEY_FENCE_TEXTURE, at, Vector2(132, 98))

func _draw_prop(texture: Texture2D, center: Vector2, size: Vector2) -> void:
	draw_texture_rect(texture, Rect2(center - size * 0.5, size), false, Color("455063"))
