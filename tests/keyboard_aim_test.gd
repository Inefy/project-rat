extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("KEYBOARD AIM FAIL: " + message)

func key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var settings = game.settings
	var original_keys: Dictionary = settings.keys.duplicate()
	settings.keys = settings.DEFAULT_KEYS.duplicate()
	settings._apply_keys()
	game.start_game()
	game.intermission = 999
	var rat = game.player
	rat.set_physics_process(false)
	rat.aim_assist = false
	rat.autofire = false

	key(KEY_W, true)
	key(KEY_RIGHT, true)
	rat._physics_process(0)
	check(rat.velocity == Vector2.UP * rat.move_speed, "W moves independently while right arrow aims")
	check(rat.aim_direction == Vector2.RIGHT, "right arrow aims right")
	check(get_nodes_in_group("player_bullets").size() == 1, "holding an aim key fires with auto-fire disabled")
	key(KEY_UP, true)
	rat._physics_process(0)
	var diagonal := Vector2(1, -1).normalized()
	check(rat.aim_direction.is_equal_approx(diagonal), "two arrows produce normalized diagonal aim")
	game.reticle._process(0)
	check(game.reticle.global_position.is_equal_approx(rat.global_position + diagonal * 150), "reticle follows keyboard aim")
	key(KEY_W, false)
	key(KEY_UP, false)
	key(KEY_RIGHT, false)
	rat.shot_cooldown = 0
	var bullets: int = get_nodes_in_group("player_bullets").size()
	rat._physics_process(0)
	check(rat.velocity == Vector2.ZERO, "arrow aiming does not move the rat")
	check(rat.aim_direction.is_equal_approx(diagonal), "releasing arrows retains last aim")
	check(get_nodes_in_group("player_bullets").size() == bullets, "releasing arrows stops manual firing")

	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(12, 0)
	rat._unhandled_input(motion)
	rat._physics_process(0)
	check(not rat.using_directional_aim, "mouse movement resumes mouse aiming")
	var mouse_delta: Vector2 = rat.get_global_mouse_position() - rat.global_position
	if mouse_delta.length() > 4:
		check(rat.aim_direction.is_equal_approx(mouse_delta.normalized()), "mouse aim follows cursor again")
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_RIGHT_X
	stick.axis_value = -1
	Input.parse_input_event(stick)
	Input.flush_buffered_events()
	rat._physics_process(0)
	check(rat.aim_direction == Vector2.LEFT, "right stick still aims")
	stick = stick.duplicate()
	stick.axis_value = 0
	Input.parse_input_event(stick)
	Input.flush_buffered_events()
	rat._physics_process(0)
	check(rat.aim_direction == Vector2.LEFT, "released stick retains direction")

	settings._set_key("aim_up", KEY_I)
	settings._apply_keys()
	game._apply_settings()
	key(KEY_I, true)
	rat._physics_process(0)
	check(rat.aim_direction == Vector2.UP and rat.velocity == Vector2.ZERO, "remapped aim key works independently")
	check(game.hud.menu_help.text.contains("I/"), "hints reflect remapped aim keys")
	key(KEY_I, false)
	key(KEY_DOWN, true)
	key(KEY_DOWN, false)
	check(rat.aim_direction == Vector2.DOWN, "a short aim tap is retained between physics ticks")
	key(KEY_UP, true)
	check(not Input.is_action_pressed("aim_up") and Input.is_action_pressed("ui_up"), "old aim key still navigates menus without aiming")
	key(KEY_UP, false)

	var settings_path: String = settings.PATH
	var saved = FileAccess.get_file_as_bytes(settings_path) if FileAccess.file_exists(settings_path) else null
	settings._save()
	var loaded = load("res://scripts/settings_panel.gd").new()
	loaded._load()
	check(loaded.keys["aim_up"] == KEY_I, "aim binding persists")
	loaded.free()
	var legacy := ConfigFile.new()
	legacy.set_value("keys", "move_up", KEY_UP)
	legacy.save(settings_path)
	loaded = load("res://scripts/settings_panel.gd").new()
	loaded._load()
	check(loaded.keys["move_up"] == KEY_UP and loaded.keys["aim_up"] == KEY_W, "legacy arrow movement migrates without duplicate aim bindings")
	loaded.free()
	if saved == null:
		DirAccess.remove_absolute(settings_path)
	else:
		var file := FileAccess.open(settings_path, FileAccess.WRITE)
		file.store_buffer(saved)
		file.close()
	settings.keys = original_keys
	settings._apply_keys()
	paused = true
	game.audio.stop_all()
	await create_timer(0.3).timeout
	game.queue_free()
	await process_frame
	paused = false
	if failures.is_empty():
		print("KEYBOARD AIM PASS: movement, diagonals, firing, reticle, mouse/stick switching and saved remapping")
	quit(0 if failures.is_empty() else 1)
