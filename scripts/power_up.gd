extends Area2D

signal collected(kind: String, position: Vector2, color: Color)

const DEFINITIONS := {
	"cheese": {"color": Color("ffe66d"), "letter": "+", "name": "Cheese"},
	"rapid": {"color": Color("ff75bd"), "letter": "R", "name": "Rapid Claws"},
	"triple": {"color": Color("a58bff"), "letter": "3", "name": "Triple Seed"},
	"power": {"color": Color("ff9f43"), "letter": "P", "name": "Power Nibble"},
	"haste": {"color": Color("6dff95"), "letter": ">", "name": "Sugar Rush"},
	"shield": {"color": Color("6ef7ff"), "letter": "S", "name": "Tin-can Shield"},
	"pierce": {"color": Color("f1f6ff"), "letter": "!", "name": "Needle Teeth"},
}

var kind := "cheese"
var tint := Color("ffe66d")
var age := 0.0
var life := 16.0
var collected_already := false
var magnet_target: Node2D

func setup(power_kind: String, at: Vector2, player: Node2D) -> void:
	kind = power_kind
	global_position = at
	magnet_target = player
	var data: Dictionary = DEFINITIONS.get(kind, DEFINITIONS["cheese"])
	tint = data["color"]

func _ready() -> void:
	collision_layer = 16
	collision_mask = 1
	monitoring = true
	monitorable = false
	add_to_group("pickups")
	z_index = 15
	var collision := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 19.0
	collision.shape = circle
	add_child(collision)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	life -= delta
	rotation += delta * 0.7
	if is_instance_valid(magnet_target):
		var delta_to_player := magnet_target.global_position - global_position
		var magnet_radius: float = float(magnet_target.get("magnet_radius"))
		if delta_to_player.length() < magnet_radius:
			global_position += delta_to_player.normalized() * (235.0 + (magnet_radius - delta_to_player.length()) * 1.6) * delta
	if life <= 0.0:
		queue_free()
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if collected_already or not body.has_method("apply_powerup"):
		return
	collected_already = true
	body.apply_powerup(kind)
	collected.emit(kind, global_position, tint)
	set_deferred("monitoring", false)
	call_deferred("queue_free")

func _draw() -> void:
	var pulse := 1.0 + sin(age * 5.0) * 0.08
	var warning_alpha: float = 0.12 if life > 4.0 else 0.06 + absf(sin(age * 10.0)) * 0.13
	draw_circle(Vector2.ZERO, 30.0 * pulse, Color(tint, warning_alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * pulse)
	var diamond := PackedVector2Array([Vector2(0, -19), Vector2(19, 0), Vector2(0, 19), Vector2(-19, 0)])
	draw_colored_polygon(diamond, Color("12183b"))
	draw_polyline(PackedVector2Array([Vector2(0, -19), Vector2(19, 0), Vector2(0, 19), Vector2(-19, 0), Vector2(0, -19)]), tint, 3.0, true)
	var data: Dictionary = DEFINITIONS.get(kind, DEFINITIONS["cheese"])
	var font := ThemeDB.fallback_font
	var letter: String = data["letter"]
	var text_size := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(font, -text_size * 0.5 + Vector2(0, 6), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, tint)
