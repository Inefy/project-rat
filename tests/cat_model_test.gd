extends SceneTree
## Validate the Blender export and its lightweight top-down sprite integration.

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("CAT MODEL FAIL: " + message)

func run() -> void:
	check(FileAccess.get_sha256("res://assets/models/cat.glb") == FileAccess.get_sha256("res://art/models/cat.glb"), "runtime export matches the Blender export")
	var source: Node3D = load("res://assets/models/cat.glb").instantiate()
	var parts := source.find_children("*", "MeshInstance3D", true, false)
	check(parts.size() == 1, "one runtime mesh, not hundreds of separate hand details")
	if parts.size() != 1:
		source.free()
		quit(1)
		return
	var mesh: ArrayMesh = parts[0].mesh
	check(mesh.get_surface_count() == 3, "three shared material surfaces")
	var triangles := 0
	var green_eyes := false
	for i in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(i)
		triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
		check(arrays[Mesh.ARRAY_COLOR].size() == arrays[Mesh.ARRAY_VERTEX].size(), "vertex colors survive import")
		var mat: BaseMaterial3D = mesh.surface_get_material(i)
		check(mat.vertex_color_use_as_albedo, "materials display the authored colors")
		if mat.resource_name == "CAT_Eyes":
			green_eyes = mat.emission_enabled and mat.emission.g > mat.emission.r * 5.0 and mat.emission.g > mat.emission.b * 5.0
	check(green_eyes, "eyes emit green instead of white in the dark garden")
	check(triangles > 1000 and triangles <= 18000, "detailed model stays within the browser triangle budget")
	check(RenderingServer.mesh_get_surface(mesh.get_rid(), 0).get("lods", []).size() > 0, "body has generated distance-based LODs")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	# Rendering assertions do not need Ogg playback in the headless audio driver.
	game.audio.stop_all()
	game.audio.pool.clear()
	game.start_game()
	game.intermission = 999
	game.current_wave = 2
	game.player.autofire = false
	game.player.set_physics_process(false)
	var frames: Array = preload("res://scripts/model_sprites.gd").FRAMES["cat"]
	check(frames.size() == 8, "all eight cat directions are loaded by the top-down renderer")
	var sprite_bytes := 0
	for i in range(8):
		check(frames[i].get_size() == Vector2(192, 192), "cat sprites stay within the 192px browser budget")
		sprite_bytes += FileAccess.get_file_as_bytes("res://assets/sprites/cat_%d.png" % i).size()
	check(sprite_bytes < 256 * 1024, "all cat directions total less than 256 KiB")
	game._spawn_enemy("cat")
	var cat = get_nodes_in_group("enemies").back()
	check(cat.is_visible_in_tree(), "cat is visible in the top-down world")
	check(is_equal_approx(cat._sprite_size(), cat.radius * 3.65), "tall ears and blade tail use the fitted sprite framing")
	check(cat.tint == Color("18bc35"), "cat indicators match the green eyes")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.audio.stop_all()
	await create_timer(0.25, true).timeout
	game.queue_free()
	source.free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("CAT MODEL PASS: Blender asset, green eyes, LODs, triangle budget and eight lightweight top-down sprites")
	quit(0 if failures.is_empty() else 1)
