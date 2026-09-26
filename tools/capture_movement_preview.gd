extends SceneTree
## Capture the actual player/enemy draw paths, using their production animator.
const CAST := ["rat", "bird", "cat", "owl", "snake", "raccoon", "fox", "alpha_cat", "junkyard_dog", "barn_owl"]

class Board extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("181e27"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(35, 42), "PROJECT R.A.T. / CHARACTER MOVEMENT", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("eee2c7"))
		for i in range(CAST.size()):
			var at := Vector2(128 + (i % 5) * 256, 300 + (i / 5) * 320)
			draw_string(font, at - Vector2(112, 0), CAST[i].replace("_", " ").to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 224, 17, Color("eee2c7"))

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var board := Board.new()
	root.add_child(board)
	var actors: Array[Node2D] = []
	var rat = load("res://scripts/player.gd").new()
	for i in range(CAST.size()):
		var actor = rat if i == 0 else load("res://scripts/enemy.gd").new()
		if i > 0:
			actor.setup(CAST[i], rat, 1)
			actor.spawn_scale = 1.0
		board.add_child(actor)
		actor.process_mode = Node.PROCESS_MODE_DISABLED
		if i == 0:
			actor.get_node("ArenaCamera").enabled = false
		actor.position = Vector2(128 + (i % 5) * 256, 204 + (i / 5) * 320)
		actor.scale = Vector2.ONE * 1.35
		actor.rotation = PI / 4
		actor.movement_animation.phase = float(i) * 0.4
		actors.append(actor)
	DirAccess.make_dir_recursive_absolute("res://build/movement-runtime")
	for frame in range(32):
		for i in range(actors.size()):
			actors[i].movement_animation.update(CAST[i], 1.0 / 16.0, Vector2.from_angle(PI / 4) * 180.0, 180.0, PI / 4, "move")
			actors[i].queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://build/movement-runtime/frame_%02d.png" % frame)
	board.queue_free()
	await process_frame
	print("MOVEMENT_PREVIEW_COMPLETE")
	quit()
