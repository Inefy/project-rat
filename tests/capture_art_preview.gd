extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	_save_frame("res://build/silly-menu-preview.png")

	game.start_game()
	await process_frame
	game.current_wave = 10
	for setup in [
		["bird", Vector2(-280, -170)],
		["cat", Vector2(280, -170)],
		["owl", Vector2(390, 110)],
		["snake", Vector2(-390, 130)],
		["raccoon", Vector2(-300, 250)],
		["junkyard_dog", Vector2(330, 270)],
	]:
		game._spawn_enemy(setup[0])
		var spawned := game.get_tree().get_nodes_in_group("enemies").back() as Node2D
		spawned.global_position = setup[1]
		spawned.spawn_scale = 1.0
		spawned.process_mode = Node.PROCESS_MODE_DISABLED
	await process_frame
	RenderingServer.force_draw()
	await process_frame
	_save_frame("res://build/silly-gameplay-preview.png")
	game.audio.stop_all()
	game.queue_free()
	await process_frame
	await process_frame
	quit()

func _save_frame(path: String) -> void:
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	if error != OK:
		printerr("Could not save preview: %s" % error)
