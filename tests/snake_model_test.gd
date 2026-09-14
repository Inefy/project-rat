extends SceneTree
## Validate the reference snake's art budgets and production venom behavior.

var failures: Array[String] = []
var shots: Array[Vector2] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("SNAKE MODEL FAIL: " + message)

func record_venom(_origin: Vector2, direction: Vector2, speed: float, damage: float, kind: String) -> void:
	check(kind == "venom" and speed > 270.0 and damage > 0.0, "snake fires its damaging venom projectile")
	shots.append(direction)

func run() -> void:
	check(FileAccess.get_sha256("res://assets/models/snake.glb") == FileAccess.get_sha256("res://art/models/snake.glb"), "runtime model matches Blender export")
	check(FileAccess.get_file_as_bytes("res://assets/models/snake.glb").size() < 512 * 1024, "reusable GLB fits below 512 KiB")
	var source: Node3D = load("res://assets/models/snake.glb").instantiate()
	var parts := source.find_children("*", "MeshInstance3D", true, false)
	check(parts.size() == 1, "body, patches, eyes and tongue export as a single mesh")
	if parts.size() != 1:
		source.free()
		quit(1)
		return
	var mesh: ArrayMesh = parts[0].mesh
	check(mesh.get_surface_count() == 3, "only paint, flesh and eye materials are needed")
	var triangles := 0
	var unlit_paint := false
	var shaded_flesh := false
	var shaded_eye := false
	var green := false
	var red := false
	var cream := false
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		check(colors.size() == arrays[Mesh.ARRAY_VERTEX].size(), "paint and human feature colors survive export")
		var material: BaseMaterial3D = mesh.surface_get_material(surface)
		check(material.vertex_color_use_as_albedo, "imported mesh displays its vertex colors")
		check(material.albedo_texture == null, "no texture images are required")
		if material.resource_name == "SNAKE_Paint":
			unlit_paint = material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and material.albedo_color == Color.WHITE
		if material.resource_name == "SNAKE_Flesh":
			shaded_flesh = material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
		if material.resource_name == "SNAKE_Eye":
			shaded_eye = material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
		for color in colors:
			green = green or (color.g > .15 and color.g > color.r * 3.0 and color.g > color.b * 2.0)
			red = red or (color.r > .25 and color.r > color.g * 3.0 and color.r > color.b * 3.0)
			cream = cream or (color.r > .7 and color.g > .65 and color.b > .5)
	check(unlit_paint and shaded_flesh and shaded_eye, "flat MS Paint body and realistic eye/tongue retain separate shading")
	check(green and red and cream, "green body and cream/red patches survive import")
	check(triangles > 1000 and triangles <= 18000, "complete model fits its triangle budget")
	check(RenderingServer.mesh_get_surface(mesh.get_rid(), 0).get("lods", []).size() > 0, "Godot generates distance LODs for reuse")
	var bounds := mesh.get_aabb()
	check(bounds.size.y > 5.0 and bounds.size.z > 4.0, "raised neck, full coil and long tongue are exported")
	check(bounds.size.x > 1.3, "coil has depth to stay readable in other facings")
	var frames: Array = preload("res://scripts/model_sprites.gd").FRAMES["snake"]
	check(frames.size() == 8, "all eight snake directions are preloaded")
	var sprite_bytes := 0
	var hashes: Array[String] = []
	for i in range(8):
		check(frames[i].get_size() == Vector2(192,192), "each direction fits the 192px game budget")
		check(frames[i].get_image().get_used_rect().size.x > 24, "each facing has a visible body, including head-on views")
		var path := "res://assets/sprites/snake_%d.png" % i
		sprite_bytes += FileAccess.get_file_as_bytes(path).size()
		var hash := FileAccess.get_sha256(path)
		check(not hashes.has(hash), "each direction is a distinct render")
		hashes.append(hash)
	check(sprite_bytes < 96 * 1024, "all eight game sprites total under 96 KiB")
	var profile: Image = frames[0].get_image()
	var paint_pixels := 0
	for y in range(profile.get_height()):
		for x in range(profile.get_width()):
			if profile.get_pixel(x,y).is_equal_approx(Color("197c36")):
				paint_pixels += 1
	check(paint_pixels > 600, "body retains solid undithered MS Paint green")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.audio.stop_all()
	game.audio.pool.clear()
	game.start_game()
	game.intermission = 999
	game.current_wave = 4
	game.player.autofire = false
	game.player.set_physics_process(false)
	check(game._encounter_enemy(0) == "snake", "wave four introduces the snake")
	game._spawn_enemy("snake")
	var snake = get_nodes_in_group("enemies").back()
	snake.set_physics_process(false)
	check(snake.is_visible_in_tree(), "replacement snake is visible in the arena")
	check(is_equal_approx(snake.radius,20.0), "art change preserves the snake collision radius")
	check(is_equal_approx(snake._sprite_size(),snake.radius*4.2), "production enemy gives the tall neck and coil room")
	snake.projectile_requested.connect(record_venom)
	snake.attack_cooldown = 0.0
	snake.ranged_windup = false
	snake._update_snake(.01,Vector2.RIGHT,300.0)
	check(snake.is_winding_up() and shots.is_empty(), "snake warns before spitting venom")
	snake._update_snake(.66,Vector2.RIGHT,300.0)
	check(shots.size() == 1, "snake fires one venom shot after the warning")
	if shots.size() == 1:
		check(shots[0].is_equal_approx(Vector2.RIGHT), "venom preserves its aimed direction")
	check(not snake.ranged_windup and snake.attack_cooldown > 1.0, "snake restores its attack cooldown")
	snake.velocity = Vector2.ZERO
	snake._update_snake(.10,Vector2.RIGHT,100.0)
	check(snake.velocity.dot(Vector2.RIGHT) < 0.0, "snake retreats when the player gets too close")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.audio.stop_all()
	await create_timer(.25,true).timeout
	game.queue_free()
	source.free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("SNAKE MODEL PASS: MS Paint shading, human eyes/tongue, mesh/sprite budgets, wave-four venom attack and retreat")
	quit(0 if failures.is_empty() else 1)
