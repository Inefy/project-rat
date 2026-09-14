extends SceneTree
## Inspect the actual production textures, including tiny silhouettes.
const Sprites = preload("res://scripts/model_sprites.gd")
const CAST := ["rat", "bird", "cat", "owl", "snake", "raccoon", "fox", "alpha_cat", "junkyard_dog", "barn_owl"]
const NOTES := ["EARS / SCARF / BLASTER", "WINGS / QUIFF / BEAK", "GREEN EYES / HANDS / BLADE", "ROUND / DISKS / TUFTS", "COIL / S-NECK / HOOD", "MASK / STRIPES / LID", "LONG LEGS / HUGE TAIL", "CROWN / CAPE / MAGENTA", "SQUARE / JOWLS / SPIKES", "HEART / WINGS / GOWN"]

class Lineup extends Control:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1440, 900), Color("241e2c"))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(28, 43), "PROJECT R.A.T.  /  THE USUAL PICNIC SUSPECTS", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("fff0c5"))
		draw_string(font, Vector2(29, 73), "Original Blender models  /  Front + three-quarter  /  Small-size silhouette check", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("c7b9cd"))
		for i in range(CAST.size()):
			var at := Vector2(22 + (i % 5) * 283, 95 + (i / 5) * 395)
			var tile := StyleBoxFlat.new()
			tile.bg_color = Color("423949")
			tile.set_corner_radius_all(12)
			draw_style_box(tile, Rect2(at, Vector2(267, 378)))
			var frames: Array = Sprites.FRAMES[CAST[i]]
			draw_string(font, at + Vector2(14, 29), CAST[i].replace("_", " ").to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 245, 21, Color("fff0c5"))
			draw_texture_rect(frames[2], Rect2(at + Vector2(3, 53), Vector2(160, 160)), false)
			draw_texture_rect(frames[1], Rect2(at + Vector2(137, 78), Vector2(127, 127)), false)
			draw_string(font, at + Vector2(12, 245), NOTES[i], HORIZONTAL_ALIGNMENT_LEFT, 245, 13, Color("efc977"))
			draw_string(font, at + Vector2(12, 271), "READS SMALL", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("c7b9cd"))
			draw_texture_rect(frames[1], Rect2(at + Vector2(13, 283), Vector2(64, 64)), false)
			draw_texture_rect(frames[2], Rect2(at + Vector2(89, 283), Vector2(64, 64)), false, Color("17121c"))
			draw_texture_rect(frames[5], Rect2(at + Vector2(177, 283), Vector2(64, 64)), false)

func _init() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1440, 900)
	root.content_scale_size = Vector2i(1440, 900)
	root.add_child(Lineup.new())
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://art/cast-lineup.png")
	quit()
