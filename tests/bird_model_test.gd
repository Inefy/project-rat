extends SceneTree
## Verify the many-eyed bird and its actual opening-wave combat integration.

var failures: Array[String] = []
var bird_kills := 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("BIRD MODEL FAIL: " + message)

func record_death(enemy: Node, _position: Vector2, _points: int, _color: Color) -> void:
	check(enemy.enemy_kind == "bird", "the production bird receives the projectile hit")
	bird_kills += 1

func run() -> void:
	check(FileAccess.get_sha256("res://assets/models/bird.glb") == FileAccess.get_sha256("res://art/models/bird.glb"), "runtime model matches Blender export")
	check(FileAccess.get_file_as_bytes("res://assets/models/bird.glb").size() < 1024 * 1024, "texture-free reusable GLB fits below 1 MiB")
	var source: Node3D = load("res://assets/models/bird.glb").instantiate()
	var parts := source.find_children("*", "MeshInstance3D", true, false)
	check(parts.size() == 1, "all feathers, eyes and feet export as one mesh")
	if parts.size() != 1:
		source.free()
		quit(1)
		return
	var mesh: ArrayMesh = parts[0].mesh
	check(mesh.get_surface_count() == 4, "paint, feathers, skin and eyes share four materials")
	var triangles := 0
	var unlit_paint := false
	var lit_features := 0
	var gold := false
	var ivory := false
	for surface in range(mesh.get_surface_count()):
		var arrays := mesh.surface_get_arrays(surface)
		triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
		var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
		check(colors.size() == arrays[Mesh.ARRAY_VERTEX].size(), "paint and anatomical colors survive export")
		var material: BaseMaterial3D = mesh.surface_get_material(surface)
		check(material.vertex_color_use_as_albedo, "imported mesh displays its vertex colors")
		check(material.albedo_texture == null, "no texture images are required")
		if material.resource_name == "BIRD_Paint":
			unlit_paint = material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED and material.albedo_color == Color.WHITE
		elif material.resource_name in ["BIRD_Feather", "BIRD_Skin", "BIRD_Eye"]:
			if material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL:
				lit_features += 1
		for color in colors:
			gold = gold or (color.r > .4 and color.g > .15 and color.r > color.b * 3.0)
			ivory = ivory or (color.r > .75 and color.g > .7 and color.b > .6)
	check(unlit_paint and lit_features == 3, "MS Paint body and realistic features keep separate shading")
	check(gold and ivory, "golden eyes and ivory feather colors survive import")
	check(triangles > 1000 and triangles <= 32000, "many-eyed wings and feet fit the geometry budget")
	check(RenderingServer.mesh_get_surface(mesh.get_rid(), 0).get("lods", []).size() > 0, "Godot generates distance LODs for reuse")
	var bounds := mesh.get_aabb()
	check(bounds.size.y > 5.5 and bounds.size.z > 6.0, "complete upright wing, sweeping wing, tail and feet are exported")
	check(bounds.size.x > 3.5, "opposing wing sweeps support turning views")
	var frames: Array = preload("res://scripts/model_sprites.gd").FRAMES["bird"]
	check(frames.size() == 8, "all eight bird directions are preloaded")
	var sprite_bytes := 0
	var hashes: Array[String] = []
	for i in range(8):
		check(frames[i].get_size() == Vector2(192,192), "each direction fits the 192px game budget")
		check(frames[i].get_image().get_used_rect().size.x > 65, "all facings keep a readable silhouette")
		var path := "res://assets/sprites/bird_%d.png" % i
		sprite_bytes += FileAccess.get_file_as_bytes(path).size()
		var hash := FileAccess.get_sha256(path)
		check(not hashes.has(hash), "each direction is a distinct render")
		hashes.append(hash)
	check(sprite_bytes < 128 * 1024, "all eight browser sprites fit below 128 KiB")
	var profile: Image = frames[0].get_image()
	# Flood-fill the outside so the intentional spaces between legs and tail
	# are not mistaken for a transparent hole inside the body or head.
	var outside := PackedByteArray()
	outside.resize(profile.get_width() * profile.get_height())
	var frontier: Array[Vector2i] = [Vector2i.ZERO]
	outside[0] = 1
	while not frontier.is_empty():
		var point: Vector2i = frontier.pop_back()
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = point + offset
			if next.x < 0 or next.y < 0 or next.x >= profile.get_width() or next.y >= profile.get_height():
				continue
			var pixel := next.y * profile.get_width() + next.x
			if outside[pixel] == 0 and profile.get_pixelv(next).a < .01:
				outside[pixel] = 1
				frontier.append(next)
	var paint_pixels := 0
	var hollow_pixels := 0
	for y in range(profile.get_height()):
		var first := -1
		var last := -1
		for x in range(profile.get_width()):
			if profile.get_pixel(x,y).is_equal_approx(Color("a94a00")):
				paint_pixels += 1
				if first < 0: first = x
				last = x
		if last - first > 20:
			for x in range(first + 3,last - 3):
				if profile.get_pixel(x,y).a < .01 and outside[y * profile.get_width() + x] == 0:
					hollow_pixels += 1
	check(paint_pixels > 1400, "body and head retain solid undithered orange fill")
	check(hollow_pixels < 30, "the orange body and head are filled without transparent gaps")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.audio.stop_all()
	game.audio.pool.clear()
	game.start_game()
	game.intermission = 999
	game.current_wave = 1
	var rat = game.player
	rat.autofire = false
	rat.aim_assist = false
	rat.set_physics_process(false)
	rat.position = Vector2.ZERO
	check(game._encounter_enemy(0) == "bird", "the bird remains the opening-wave enemy")
	game._spawn_enemy("bird")
	var bird = get_nodes_in_group("enemies").back()
	bird.set_physics_process(false)
	bird.position = Vector2(200,0)
	check(bird.is_visible_in_tree(), "replacement bird is visible in the arena")
	check(is_equal_approx(bird.radius,16.0), "art change preserves the bird collision radius")
	check(is_equal_approx(bird._sprite_size(),bird.radius*4.6), "production sprite gives wings and feet room")
	check(bird.max_health <= rat.base_damage, "opening bird remains a one-seed target")
	var smallest := INF
	var largest := -INF
	for i in range(12):
		bird.age = i * .15
		bird._update_bird(1.0,Vector2.RIGHT)
		check(bird.velocity.x > 0.0, "weaving still advances toward the player")
		smallest = minf(smallest,bird.velocity.angle())
		largest = maxf(largest,bird.velocity.angle())
	check(largest-smallest > .5, "bird retains its characteristic weaving movement")
	bird.died.connect(record_death)
	rat._update_aim(Vector2.RIGHT)
	rat.fire()
	for i in range(24):
		await physics_frame
	check(bird_kills == 1, "actual seed projectile physics defeats the replacement bird")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	game.audio.stop_all()
	await create_timer(.25,true).timeout
	game.queue_free()
	source.free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("BIRD MODEL PASS: solid MS Paint fill, shaded eye wings/feet, asset budgets, opening-wave weaving and seed collision")
	quit(0 if failures.is_empty() else 1)
