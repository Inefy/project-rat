extends SceneTree
## Validate the four-wing owl asset and its actual ranged-enemy integration.

var failures: Array[String] = []
var volley: Array[Vector2] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("OWL MODEL FAIL: " + message)

func record_feather(_origin: Vector2, direction: Vector2, _speed: float, _damage: float, kind: String) -> void:
	check(kind == "feather", "regular owl retains its feather projectile")
	volley.append(direction)

func run() -> void:
	check(FileAccess.get_sha256("res://assets/models/owl.glb") == FileAccess.get_sha256("res://art/models/owl.glb"), "runtime model matches Blender export")
	check(FileAccess.get_file_as_bytes("res://assets/models/owl.glb").size() < 512 * 1024, "complete four-wing GLB fits below 512 KiB")
	var source: Node3D = load("res://assets/models/owl.glb").instantiate()
	var parts := source.find_children("*", "MeshInstance3D", true, false)
	check(parts.size() == 1, "all feather details export as a single mesh")
	if parts.size() != 1:
		source.free()
		quit(1)
		return
	var mesh: ArrayMesh = parts[0].mesh
	check(mesh.get_surface_count() == 2, "only paint and human skin materials are needed")
	var triangles := 0
	var unlit_paint := false
	var human_skin := false
	var white := false
	var blue := false
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		check(colors.size() == arrays[Mesh.ARRAY_VERTEX].size(), "feather ink and skin colors survive export")
		var material: BaseMaterial3D = mesh.surface_get_material(surface)
		check(material.vertex_color_use_as_albedo, "imported mesh displays its vertex colors")
		check(material.albedo_texture == null, "no texture images are required")
		if material.resource_name == "OWL_Paint":
			unlit_paint = material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and material.albedo_color == Color.WHITE
		if material.resource_name == "OWL_Skin":
			human_skin = material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
		for color in colors:
			white = white or (color.r > .9 and color.g > .9 and color.b > .9)
			blue = blue or (color.b > .2 and color.b > color.r * 1.8 and color.g > .12)
	check(unlit_paint and human_skin, "MS Paint silhouette and realistic navel keep separate shading")
	check(white and blue, "blank white eyes and slate-blue beak survive import")
	check(triangles > 1000 and triangles <= 18000, "full feather geometry fits its triangle budget")
	check(RenderingServer.mesh_get_surface(mesh.get_rid(), 0).get("lods", []).size() > 0, "Godot generates distance LODs for reuse")
	var bounds := mesh.get_aabb()
	check(bounds.size.x > 5.5 and bounds.size.y > 5.7, "complete wingspan and stick legs are exported")
	check(bounds.size.z > 2.5, "wings spread in depth so side views remain visible")
	var frames: Array = preload("res://scripts/model_sprites.gd").FRAMES["owl"]
	check(frames.size() == 8, "all eight owl directions are preloaded")
	var sprite_bytes := 0
	var hashes: Array[String] = []
	for i in range(8):
		check(frames[i].get_size() == Vector2(192,192), "each owl direction fits the 192px game budget")
		check(frames[i].get_image().get_used_rect().size.x > 60, "every facing has a readable wingspan, including side views")
		var path := "res://assets/sprites/owl_%d.png" % i
		sprite_bytes += FileAccess.get_file_as_bytes(path).size()
		var hash := FileAccess.get_sha256(path)
		check(not hashes.has(hash), "each direction is a distinct render")
		hashes.append(hash)
	check(sprite_bytes < 96 * 1024, "all eight game sprites total under 96 KiB")
	var front: Image = frames[2].get_image()
	var paint_pixels := 0
	for y in range(front.get_height()):
		for x in range(front.get_width()):
			if front.get_pixel(x,y).is_equal_approx(Color("b65a00")):
				paint_pixels += 1
	check(paint_pixels > 600, "body retains solid undithered MS Paint fill")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.audio.stop_all()
	game.audio.pool.clear()
	game.start_game()
	game.intermission = 999
	game.current_wave = 3
	game.player.autofire = false
	game.player.set_physics_process(false)
	check(game._encounter_enemy(0) == "owl", "wave three still introduces the regular owl")
	check(game.get_boss_kind(15) == "barn_owl", "Barn Owl remains the separate wave-fifteen boss")
	game._spawn_enemy("owl")
	var owl = get_nodes_in_group("enemies").back()
	owl.set_physics_process(false)
	check(owl.is_visible_in_tree(), "the replacement owl is visible in the arena")
	check(is_equal_approx(owl.radius,23.0), "art change preserves the owl collision radius")
	check(is_equal_approx(owl._sprite_size(),owl.radius*4.2), "wing framing is applied to the production enemy")
	owl.projectile_requested.connect(record_feather)
	owl.attack_cooldown = 0.0
	owl.ranged_windup = false
	owl._update_owl(.01,Vector2.RIGHT,300.0)
	check(owl.is_winding_up() and volley.is_empty(), "owl warns before firing")
	owl._update_owl(.66,Vector2.RIGHT,300.0)
	check(volley.size() == 3, "owl still fires its three-feather fan")
	if volley.size() == 3:
		check(volley[0].y < 0 and volley[1].is_equal_approx(Vector2.RIGHT) and volley[2].y > 0, "feathers retain their spread around the aimed direction")
	check(not owl.ranged_windup and owl.attack_cooldown > 1.0, "owl restores its attack cooldown")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.audio.stop_all()
	await create_timer(.25,true).timeout
	game.queue_free()
	source.free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("OWL MODEL PASS: MS Paint shading, human navel, mesh/sprite budgets and wave-three feather attack")
	quit(0 if failures.is_empty() else 1)
