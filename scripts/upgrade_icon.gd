extends Control
## Dedicated Blender renders for every mutation, independent of UI scale.

const TEXTURES := {
	"light_trail": preload("res://assets/upgrades/light_trail.png"),
	"pinball": preload("res://assets/upgrades/pinball.png"),
	"scurry_bomb": preload("res://assets/upgrades/scurry_bomb.png"),
	"snack_orbit": preload("res://assets/upgrades/snack_orbit.png"),
	"split_acorns": preload("res://assets/upgrades/split_acorns.png"),
	"dash_refund": preload("res://assets/upgrades/dash_refund.png"),
	"orbit_feast": preload("res://assets/upgrades/orbit_feast.png"),
	"quick_whiskers": preload("res://assets/upgrades/quick_whiskers.png"),
	"heavy_seeds": preload("res://assets/upgrades/heavy_seeds.png"),
	"fleet_feet": preload("res://assets/upgrades/fleet_feet.png"),
	"thick_fur": preload("res://assets/upgrades/thick_fur.png"),
	"long_teeth": preload("res://assets/upgrades/long_teeth.png"),
	"big_paws": preload("res://assets/upgrades/big_paws.png"),
	"lucky_tail": preload("res://assets/upgrades/lucky_tail.png"),
	"extra_pocket": preload("res://assets/upgrades/extra_pocket.png"),
	"cheese_magnet": preload("res://assets/upgrades/cheese_magnet.png"),
}

var kind := "":
	set(value):
		kind = value
		queue_redraw()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)

func _draw() -> void:
	var texture: Texture2D = TEXTURES.get(kind)
	if texture == null:
		return
	var side := minf(size.x, size.y)
	draw_texture_rect(texture, Rect2((size - Vector2.ONE * side) * 0.5, Vector2.ONE * side), false)
