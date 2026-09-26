extends SceneTree
## Check shipped mutation artwork and the five newly integrated creature models.
const Sprites = preload("res://scripts/model_sprites.gd")
const Icon = preload("res://scripts/upgrade_icon.gd")
const Game = preload("res://scripts/main.gd")
const CAST := ["rat", "raccoon", "alpha_cat", "junkyard_dog", "barn_owl"]
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		printerr("NIGHTMARE ART FAIL: " + message)

func inspect_texture(texture: Texture2D, label: String) -> void:
	check(texture.get_size() == Vector2(192, 192), label + " has production resolution")
	var pixels := texture.get_image()
	check(pixels != null and not pixels.is_empty(), label + " loads image data")
	var bounds := pixels.get_used_rect()
	check(bounds.size.x > 15 and bounds.size.y > 15, label + " has visible artwork")
	check(bounds.position.x >= 2 and bounds.position.y >= 2 and bounds.end.x <= 190 and bounds.end.y <= 190, label + " keeps transparent margins")

class Catalog extends Control:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1440, 1080), Color("15191f"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(28, 44), "PROJECT R.A.T. / REMAINING NIGHTMARE CAST", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color("eee6cf"))
		draw_string(font, Vector2(28, 74), "Production Blender renders / front + three-quarter / 16 distinct mutation textures", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("a5afa8"))
		for i in range(CAST.size()):
			var at := Vector2(22 + i * 283, 99)
			draw_rect(Rect2(at, Vector2(268, 310)), Color("30353d"))
			draw_texture_rect(Sprites.FRAMES[CAST[i]][2], Rect2(at + Vector2(0, 27), Vector2(213, 213)), false)
			draw_texture_rect(Sprites.FRAMES[CAST[i]][1], Rect2(at + Vector2(148, 126), Vector2(116, 116)), false)
			draw_string(font, at + Vector2(12, 281), CAST[i].replace("_", " ").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 247, 20, Color("eee6cf"))
		draw_string(font, Vector2(28, 452), "PICKUPS", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("e3bb6a"))
		for i in range(Game.POWER_TYPES.size()):
			var key: String = Game.POWER_TYPES[i]
			var at := Vector2(33 + i * 200, 470)
			draw_texture_rect(Sprites.FRAMES[key][0], Rect2(at + Vector2(30, 0), Vector2(96, 96)), false)
			draw_string(font, at + Vector2(0, 123), key.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 165, 16, Color("eee6cf"))
		draw_string(font, Vector2(28, 637), "MUTATIONS", HORIZONTAL_ALIGNMENT_LEFT, -1, 21, Color("e3bb6a"))
		var index := 0
		for key in Game.UPGRADES:
			var at := Vector2(24 + (index % 8) * 177, 659 + (index / 8) * 192)
			draw_rect(Rect2(at, Vector2(164, 177)), Color("232830"))
			draw_texture_rect(Icon.TEXTURES[key], Rect2(at + Vector2(27, 10), Vector2(110, 110)), false)
			draw_string(font, at + Vector2(3, 153), Game.UPGRADES[key]["title"], HORIZONTAL_ALIGNMENT_CENTER, 158, 14, Color("eee6cf"))
			index += 1

func run() -> void:
	check(Icon.TEXTURES.size() == Game.UPGRADES.size(), "Every mutation has dedicated artwork")
	var hashes: Array[int] = []
	for key in Game.UPGRADES:
		check(Icon.TEXTURES.has(key), key + " has a texture")
		if not Icon.TEXTURES.has(key):
			continue
		var texture: Texture2D = Icon.TEXTURES[key]
		inspect_texture(texture, key)
		var fingerprint := hash(texture.get_image().get_data())
		check(not hashes.has(fingerprint), key + " does not reuse another mutation's pixels")
		hashes.append(fingerprint)
	for kind in CAST:
		for texture: Texture2D in Sprites.FRAMES[kind]:
			inspect_texture(texture, kind)
	for kind in CAST + Game.POWER_TYPES:
		var packed: PackedScene = load("res://assets/models/%s.glb" % kind)
		check(packed != null, kind + " GLB imports")
		if packed != null:
			var model := packed.instantiate()
			var meshes := model.find_children("*", "MeshInstance3D", true, false)
			check(meshes.size() == 1, kind + " exports one reusable mesh")
			var paint := false
			var skin := false
			for part: MeshInstance3D in meshes:
				for surface in range(part.mesh.get_surface_count()):
					var material: BaseMaterial3D = part.mesh.surface_get_material(surface)
					check(material.vertex_color_use_as_albedo and material.albedo_texture == null, kind + " preserves its authored colors without external textures")
					if material.resource_name == "NIGHTMARE_Paint":
						paint = material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
					if material.resource_name == "NIGHTMARE_Skin":
						skin = material.shading_mode == BaseMaterial3D.SHADING_MODE_PER_PIXEL
			check(paint and (skin or kind not in CAST), kind + " keeps flat paint and shaded anatomy")
			check(FileAccess.get_sha256("res://assets/models/%s.glb" % kind) == FileAccess.get_sha256("res://art/models/%s.glb" % kind), kind + " runtime model matches Blender export")
			model.free()
	for kind in Game.POWER_TYPES:
		inspect_texture(Sprites.FRAMES[kind][0], kind)
	if DisplayServer.get_name() != "headless" and failures.is_empty():
		root.size = Vector2i(1440, 1080)
		root.content_scale_size = Vector2i(1440, 1080)
		root.add_child(Catalog.new())
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://art/nightmare-cast/production-sheet.png")
	if failures.is_empty():
		print("NIGHTMARE ART PASS: 12 colored GLBs, 40 creature facings, 7 pickups, 16 unique mutation textures; margins verified")
	quit(0 if failures.is_empty() else 1)
