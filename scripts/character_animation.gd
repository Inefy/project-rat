extends RefCounted
## Movement poses rendered from the original Blender meshes, in every facing.

const CELL := 160.0
const POSE_COUNT := 8
const SHEETS := {
	"rat": preload("res://assets/sprites/movement/rat.png"),
	"bird": preload("res://assets/sprites/movement/bird.png"),
	"cat": preload("res://assets/sprites/movement/cat.png"),
	"owl": preload("res://assets/sprites/movement/owl.png"),
	"snake": preload("res://assets/sprites/movement/snake.png"),
	"raccoon": preload("res://assets/sprites/movement/raccoon.png"),
	"fox": preload("res://assets/sprites/movement/fox.png"),
	"alpha_cat": preload("res://assets/sprites/movement/alpha_cat.png"),
	"junkyard_dog": preload("res://assets/sprites/movement/junkyard_dog.png"),
	"barn_owl": preload("res://assets/sprites/movement/barn_owl.png"),
}
const STRIDE := {"rat": 140.0, "cat": 160.0, "snake": 170.0, "raccoon": 130.0, "fox": 125.0, "alpha_cat": 200.0, "junkyard_dog": 185.0}
const WINGBEATS := {"bird": 3.5, "owl": 1.65, "barn_owl": 1.3}

var phase := 0.0
var movement := 0.0
var lean := Vector2.ZERO
var stretch := Vector2.ONE
var airborne := false
var bracing := 0.0

func update(kind: String, delta: float, motion: Vector2, reference_speed: float, facing: float, state: String) -> void:
	var speed := motion.length()
	var speed_ratio := clampf(speed / maxf(reference_speed, 1.0), 0.0, 2.5)
	var smoothing := 1.0 - exp(-12.0 * delta)
	movement = lerpf(movement, minf(speed_ratio, 1.0), smoothing)
	lean = lean.lerp(motion.normalized() * minf(speed_ratio, 1.0), smoothing)
	airborne = WINGBEATS.has(kind)
	if airborne:
		phase += delta * float(WINGBEATS[kind]) * (0.85 + speed_ratio * 0.2) * TAU
	elif speed > 5.0:
		# Reverse the rat's steps while backing away, keeping aim independent.
		var reverse := -1.0 if kind == "rat" and motion.dot(Vector2.from_angle(facing)) < -speed * 0.4 else 1.0
		phase += speed * delta / float(STRIDE.get(kind, 150.0)) * TAU * reverse
	else:
		phase = lerp_angle(phase, 0.0, smoothing)
	phase = fposmod(phase, TAU)
	var rushing := state in ["dash", "pounce", "charge", "dart"]
	stretch = stretch.lerp(Vector2(1.16, 0.87) if rushing else Vector2.ONE, smoothing)
	bracing = lerpf(bracing, 1.0 if state in ["telegraph", "brace", "windup", "phase_shift"] else 0.0, smoothing)

func pose_index() -> int:
	return posmod(int(floor(phase / TAU * POSE_COUNT)), POSE_COUNT)

func shadow_scale() -> float:
	return 0.9 + sin(phase - 0.6) * 0.055 if airborne else 1.0 - sin(phase * 2.0) * movement * 0.025

func paint(canvas: CanvasItem, kind: String, facing: float, size: float, age: float, scale_factor: float = 1.0, flash: bool = false) -> void:
	var direction := posmod(int(round(facing / (TAU / 8.0))), 8)
	var weight := 1.0 if airborne else smoothstep(0.05, 0.7, movement)
	var roll := -lean.x * (0.045 if airborne else 0.025)
	var breathing := sin(age * 2.6) * (1.0 - movement) * 0.006
	var offset := lean * 1.5 + Vector2(0.0, size * bracing * 0.018 - breathing * size)
	var axis := lean.angle() if lean.length_squared() > 0.01 else facing
	var oriented_stretch := Transform2D(axis, Vector2.ZERO) * Transform2D(Vector2(stretch.x, 0), Vector2(0, stretch.y), Vector2.ZERO) * Transform2D(-axis, Vector2.ZERO)
	var body_scale := Vector2(1.0 + bracing * 0.06, 1.0 - bracing * 0.10 + breathing) * scale_factor
	var transform := Transform2D(-facing, Vector2.ZERO) * Transform2D(roll, offset) * oriented_stretch * Transform2D(Vector2(body_scale.x, 0), Vector2(0, body_scale.y), Vector2.ZERO)
	canvas.draw_set_transform_matrix(transform)
	var rect := Rect2(Vector2(-size * 0.5, -size * 0.56), Vector2.ONE * size)
	var tint := Color(1.7, 1.7, 1.7) if flash else Color.WHITE
	if weight < 1.0:
		canvas.draw_texture_rect_region(SHEETS[kind], rect, Rect2(direction * CELL, POSE_COUNT * CELL, CELL, CELL), Color(tint, 1.0 - weight))
	if weight > 0.0:
		canvas.draw_texture_rect_region(SHEETS[kind], rect, Rect2(direction * CELL, pose_index() * CELL, CELL, CELL), Color(tint, weight))
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
