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

	rat.yaw = 0
	rat.pitch = 0
	rat._update_aim(Vector2.ZERO)
	key(KEY_W, true)
	rat._physics_process(0)
	check(rat.velocity.is_equal_approx(Vector2.UP * rat.move_speed), "W moves forward at the initial heading")
	key(KEY_RIGHT, true)
	rat._physics_process(0.25)
	check(rat.yaw > 0 and rat.aim_direction.x > 0, "right arrow turns the view right")
	check(rat.velocity.normalized().is_equal_approx(rat.aim_direction), "forward movement follows the current turn")
	check(not get_nodes_in_group("player_bullets").is_empty(), "holding an aim key fires with auto-fire disabled")
	key(KEY_UP, true)
	rat._physics_process(0.1)
	check(rat.pitch > 0, "up arrow looks up")
	key(KEY_W, false)
	key(KEY_UP, false)
	key(KEY_RIGHT, false)
	var heading: Vector2 = rat.aim_direction
	rat.shot_cooldown = 0
	var bullets: int = get_nodes_in_group("player_bullets").size()
	rat._physics_process(0)
	check(rat.velocity == Vector2.ZERO, "looking does not move the rat")
	check(rat.aim_direction.is_equal_approx(heading), "releasing arrows retains the heading")
	check(get_nodes_in_group("player_bullets").size() == bullets, "releasing arrows stops manual firing")

	var yaw: float = rat.yaw
	if DisplayServer.get_name() != "headless":
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(40, 20)
		var pitch: float = rat.pitch
		rat._unhandled_input(motion)
		check(rat.yaw > yaw and rat.pitch < pitch, "captured mouse turns right and looks down")
		motion.relative = Vector2(0, -100000)
		rat._unhandled_input(motion)
		check(is_equal_approx(rat.pitch, 1.1), "vertical look is clamped")
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_RIGHT_X
	stick.axis_value = -1
	Input.parse_input_event(stick)
	Input.flush_buffered_events()
	yaw = rat.yaw
	rat._physics_process(0.1)
	check(rat.yaw < yaw, "right stick turns left")
	stick = stick.duplicate()
	stick.axis_value = 0
	Input.parse_input_event(stick)
	Input.flush_buffered_events()
	yaw = rat.yaw
	rat._physics_process(0.1)
	check(rat.yaw == yaw, "released stick retains heading")

	settings._set_key("aim_up", KEY_I)
	settings._apply_keys()
	game._apply_settings()
	rat.pitch = 0
	key(KEY_I, true)
	rat._physics_process(0.1)
	check(rat.pitch > 0 and rat.velocity == Vector2.ZERO, "remapped look key works independently")
	check(game.hud.menu_help.text.contains("I/"), "hints reflect remapped look keys")
	key(KEY_I, false)
	key(KEY_UP, true)
	check(not Input.is_action_pressed("aim_up") and Input.is_action_pressed("ui_up"), "old look key still navigates menus")
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
		print("KEYBOARD AIM PASS: relative movement, mouse look, pitch clamp, gamepad and saved remapping")
	quit(0 if failures.is_empty() else 1)
