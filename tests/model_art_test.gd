extends SceneTree

const Sprites = preload("res://scripts/model_sprites.gd")

class Catalog extends Control:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1280, 720), Color("292133"))
		draw_string(ThemeDB.fallback_font, Vector2(28, 38), "PICNIC PUBLIC ENEMIES  /  BLENDER SPRITE CATALOG", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("fff0c5"))
		var index := 0
		for kind in Sprites.FRAMES:
			var at := Vector2(22 + (index % 8) * 157, 66 + (index / 8) * 211)
			draw_style_box(_tile(), Rect2(at, Vector2(148, 197)))
			var frames: Array = Sprites.FRAMES[kind]
			var texture: Texture2D = frames[1] if frames.size() == 8 else frames[0]
			draw_texture_rect(texture, Rect2(at + Vector2(2, 4), Vector2(144, 157)), false)
			draw_string(ThemeDB.fallback_font, at + Vector2(8, 180), str(kind).replace("_", " ").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 135, 14, Color("fff0c5"))
			index += 1
	func _tile() -> StyleBoxFlat:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("4a4252")
		style.set_corner_radius_all(8)
		return style

func _init() -> void:
	call_deferred("run")

func run() -> void:
	var total := 0
	for kind in Sprites.FRAMES:
		for texture: Texture2D in Sprites.FRAMES[kind]:
			assert(texture.get_size() == Vector2(192, 192), "Wrong sprite dimensions: " + kind)
			var image := texture.get_image()
			assert(not image.get_used_rect().size == Vector2i.ZERO, "Empty render: " + kind)
			total += 1
	assert(total == 94, "Incomplete asset set")
	print("ART PASS: 24 assets, 94 nonempty sprite renders")
	if DisplayServer.get_name() != "headless":
		root.add_child(Catalog.new())
		await process_frame
		await process_frame
		RenderingServer.force_draw()
		await process_frame
		root.get_texture().get_image().save_png("res://art/sprite-catalog.png")
	quit()
