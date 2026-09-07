extends RefCounted
## Blender renders; explicit preloads keep every facing in web exports.
const FRAMES := {
	"rat": [preload("res://assets/sprites/rat_0.png"), preload("res://assets/sprites/rat_1.png"), preload("res://assets/sprites/rat_2.png"), preload("res://assets/sprites/rat_3.png"), preload("res://assets/sprites/rat_4.png"), preload("res://assets/sprites/rat_5.png"), preload("res://assets/sprites/rat_6.png"), preload("res://assets/sprites/rat_7.png")],
	"bird": [preload("res://assets/sprites/bird_0.png"), preload("res://assets/sprites/bird_1.png"), preload("res://assets/sprites/bird_2.png"), preload("res://assets/sprites/bird_3.png"), preload("res://assets/sprites/bird_4.png"), preload("res://assets/sprites/bird_5.png"), preload("res://assets/sprites/bird_6.png"), preload("res://assets/sprites/bird_7.png")],
	"cat": [preload("res://assets/sprites/cat_0.png"), preload("res://assets/sprites/cat_1.png"), preload("res://assets/sprites/cat_2.png"), preload("res://assets/sprites/cat_3.png"), preload("res://assets/sprites/cat_4.png"), preload("res://assets/sprites/cat_5.png"), preload("res://assets/sprites/cat_6.png"), preload("res://assets/sprites/cat_7.png")],
	"owl": [preload("res://assets/sprites/owl_0.png"), preload("res://assets/sprites/owl_1.png"), preload("res://assets/sprites/owl_2.png"), preload("res://assets/sprites/owl_3.png"), preload("res://assets/sprites/owl_4.png"), preload("res://assets/sprites/owl_5.png"), preload("res://assets/sprites/owl_6.png"), preload("res://assets/sprites/owl_7.png")],
	"snake": [preload("res://assets/sprites/snake_0.png"), preload("res://assets/sprites/snake_1.png"), preload("res://assets/sprites/snake_2.png"), preload("res://assets/sprites/snake_3.png"), preload("res://assets/sprites/snake_4.png"), preload("res://assets/sprites/snake_5.png"), preload("res://assets/sprites/snake_6.png"), preload("res://assets/sprites/snake_7.png")],
	"raccoon": [preload("res://assets/sprites/raccoon_0.png"), preload("res://assets/sprites/raccoon_1.png"), preload("res://assets/sprites/raccoon_2.png"), preload("res://assets/sprites/raccoon_3.png"), preload("res://assets/sprites/raccoon_4.png"), preload("res://assets/sprites/raccoon_5.png"), preload("res://assets/sprites/raccoon_6.png"), preload("res://assets/sprites/raccoon_7.png")],
	"fox": [preload("res://assets/sprites/fox_0.png"), preload("res://assets/sprites/fox_1.png"), preload("res://assets/sprites/fox_2.png"), preload("res://assets/sprites/fox_3.png"), preload("res://assets/sprites/fox_4.png"), preload("res://assets/sprites/fox_5.png"), preload("res://assets/sprites/fox_6.png"), preload("res://assets/sprites/fox_7.png")],
	"alpha_cat": [preload("res://assets/sprites/alpha_cat_0.png"), preload("res://assets/sprites/alpha_cat_1.png"), preload("res://assets/sprites/alpha_cat_2.png"), preload("res://assets/sprites/alpha_cat_3.png"), preload("res://assets/sprites/alpha_cat_4.png"), preload("res://assets/sprites/alpha_cat_5.png"), preload("res://assets/sprites/alpha_cat_6.png"), preload("res://assets/sprites/alpha_cat_7.png")],
	"junkyard_dog": [preload("res://assets/sprites/junkyard_dog_0.png"), preload("res://assets/sprites/junkyard_dog_1.png"), preload("res://assets/sprites/junkyard_dog_2.png"), preload("res://assets/sprites/junkyard_dog_3.png"), preload("res://assets/sprites/junkyard_dog_4.png"), preload("res://assets/sprites/junkyard_dog_5.png"), preload("res://assets/sprites/junkyard_dog_6.png"), preload("res://assets/sprites/junkyard_dog_7.png")],
	"barn_owl": [preload("res://assets/sprites/barn_owl_0.png"), preload("res://assets/sprites/barn_owl_1.png"), preload("res://assets/sprites/barn_owl_2.png"), preload("res://assets/sprites/barn_owl_3.png"), preload("res://assets/sprites/barn_owl_4.png"), preload("res://assets/sprites/barn_owl_5.png"), preload("res://assets/sprites/barn_owl_6.png"), preload("res://assets/sprites/barn_owl_7.png")],
	"cheese": [preload("res://assets/sprites/cheese_0.png")],
	"rapid": [preload("res://assets/sprites/rapid_0.png")],
	"triple": [preload("res://assets/sprites/triple_0.png")],
	"power": [preload("res://assets/sprites/power_0.png")],
	"haste": [preload("res://assets/sprites/haste_0.png")],
	"shield": [preload("res://assets/sprites/shield_0.png")],
	"pierce": [preload("res://assets/sprites/pierce_0.png")],
	"seed": [preload("res://assets/sprites/seed_0.png")],
	"feather": [preload("res://assets/sprites/feather_0.png")],
	"venom": [preload("res://assets/sprites/venom_0.png")],
	"bone": [preload("res://assets/sprites/bone_0.png")],
	"sonic": [preload("res://assets/sprites/sonic_0.png")],
	"crumb": [preload("res://assets/sprites/crumb_0.png")],
	"fizzy": [preload("res://assets/sprites/fizzy_0.png")],
}

static func paint(canvas: CanvasItem, kind: String, facing: float, size: float, age: float = 0.0, bounce: float = 0.0, scale_factor: float = 1.0, flash: bool = false) -> void:
	var frames: Array = FRAMES[kind]
	var index := posmod(int(round(facing / (TAU / 8.0))), 8) if frames.size() == 8 else 0
	var texture: Texture2D = frames[index]
	# Counter parent rotation; choose a genuine camera-facing render instead.
	canvas.draw_set_transform(Vector2.ZERO, -facing, Vector2.ONE * scale_factor)
	var bob := sin(age * 10.0) * bounce
	var squash := 1.0 + sin(age * 10.0) * bounce * 0.008
	var rect := Rect2(Vector2(-size * squash * 0.5, -size * 0.56 + bob), Vector2(size * squash, size / squash))
	canvas.draw_texture_rect(texture, rect, false, Color(1.7, 1.7, 1.7) if flash else Color.WHITE)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
