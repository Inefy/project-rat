extends SceneTree
## Validate the reference fox export and its production ambusher integration.

var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("FOX MODEL FAIL: " + message)

func run() -> void:
	check(FileAccess.get_sha256("res://assets/models/fox.glb") == FileAccess.get_sha256("res://art/models/fox.glb"), "runtime GLB matches the Blender export")
	check(FileAccess.get_file_as_bytes("res://assets/models/fox.glb").size() < 320 * 1024, "GLB stays below 320 KiB")
	var source: Node3D = load("res://assets/models/fox.glb").instantiate()
	var parts := source.find_children("*", "MeshInstance3D", true, false)
	check(parts.size() == 1, "the exported fox uses one mesh")
	if parts.size() != 1:
		source.free()
		quit(1)
		return
	var mesh: ArrayMesh = parts[0].mesh
	check(mesh.get_surface_count() == 3, "paint, skin and eyes share three materials")
	var triangles := 0
	var orange := false
	var white := false
	var pink := false
	var unlit_paint := false
	var lit_skin := false
	var lit_eyes := false
	for i in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(i)
		triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		check(colors.size() == arrays[Mesh.ARRAY_VERTEX].size(), "authored colors survive GLB import")
		var material: BaseMaterial3D = mesh.surface_get_material(i)
		check(material.vertex_color_use_as_albedo, "imported materials display vertex colors")
		check(material.albedo_texture == null, "model needs no texture download")
		if material.resource_name == "FOX_Paint":
			unlit_paint = material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and material.albedo_color == Color.WHITE
		elif material.resource_name == "FOX_Skin":
			lit_skin = material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
		elif material.resource_name == "FOX_Eyes":
			lit_eyes = material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
		for color in colors:
			orange = orange or (color.r > 0.8 and color.g > 0.1 and color.g < 0.6 and color.b < 0.05)
			white = white or (color.r > 0.8 and color.g > 0.8 and color.b > 0.8)
			pink = pink or (color.r > 0.6 and color.g < 0.06 and color.b > 0.15)
	check(orange and white and pink, "orange body, white markings and magenta tongue survive import")
	check(unlit_paint and lit_skin and lit_eyes, "flat MS Paint fill and realistic human shading survive GLB export")
	check(triangles > 1000 and triangles <= 13000, "simplified sculpt stays inside its triangle budget")
	check(RenderingServer.mesh_get_surface(mesh.get_rid(), 0).get("lods", []).size() > 0, "Godot generates distance LODs")
	var bounds := mesh.get_aabb()
	check(bounds.size.y > 4.5 and bounds.size.y < 5.1, "human ears retain the authored upright model height")
	check(bounds.size.z > 3.0, "full curled tail and muzzle are exported")
	var frames: Array = preload("res://scripts/model_sprites.gd").FRAMES["fox"]
	check(frames.size() == 8, "renderer loads all eight fox directions")
	var sprite_bytes := 0
	var hashes: Array[String] = []
	for i in range(8):
		check(frames[i].get_size() == Vector2(192, 192), "fox sprite fits the 192px browser budget")
		var path := "res://assets/sprites/fox_%d.png" % i
		sprite_bytes += FileAccess.get_file_as_bytes(path).size()
		var hash := FileAccess.get_sha256(path)
		check(not hashes.has(hash), "each facing has a distinct render")
		hashes.append(hash)
	check(sprite_bytes < 64 * 1024, "eight directions total under 64 KiB")
	var front: Image = frames[2].get_image()
	var flat_pixels := 0
	for y in range(front.get_height()):
		for x in range(front.get_width()):
			if front.get_pixel(x, y).is_equal_approx(Color("ff7700")):
				flat_pixels += 1
	check(flat_pixels > 1000, "body retains solid MS Paint orange without lighting gradients or dither noise")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.audio.stop_all()
	game.audio.pool.clear()
	game.start_game()
	game.intermission = 999
	game.current_wave = 10
	game.player.autofire = false
	game.player.set_physics_process(false)
	check(game._encounter_enemy(9) == "fox", "wave-ten encounters spawn fox ambushers")
	game._spawn_enemy("fox")
	var fox = get_nodes_in_group("enemies").back()
	fox.set_physics_process(false)
	check(fox.is_visible_in_tree(), "replacement fox is visible in the actual arena")
	check(is_equal_approx(fox._sprite_size(), fox.radius * 3.65), "sprite framing accommodates ears and tail")
	check(is_equal_approx(fox.radius, 24.0), "art change preserves the fox collision radius")
	fox.state = "stalk"
	fox.state_clock = 0.0
	fox._update_fox(0.01, Vector2.RIGHT, 300.0)
	check(fox.state == "telegraph", "fox still warns before ambushing")
	fox._update_fox(0.40, Vector2.RIGHT, 300.0)
	check(fox.state == "dart" and fox.velocity.x > 600.0, "fox still performs its committed dash")
	fox._update_fox(0.50, Vector2.RIGHT, 300.0)
	check(fox.state == "recover", "dash retains its recovery window")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.audio.stop_all()
	game.queue_free()
	source.free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("FOX MODEL PASS: reference colors, LODs, mesh budget, eight sprites and wave-ten ambusher")
	quit(0 if failures.is_empty() else 1)
