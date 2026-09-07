extends StaticBody2D

var spent := false
var health := 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("run_entities")
	collision_layer = 2
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 22.0
	shape.shape = circle
	add_child(shape)
	z_index = 6

func take_damage(_amount: float, _knockback: Vector2 = Vector2.ZERO) -> void:
	if spent:
		return
	spent = true
	set_deferred("collision_layer", 0)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.dying and global_position.distance_to(enemy.global_position) < 210.0:
			enemy.take_damage(65.0, global_position.direction_to(enemy.global_position) * 650.0)
	get_parent()._spawn_impact(global_position, Color("55ad87"), 210.0)
	get_parent().audio.play("shield", 0.1)
	queue_free()

func _draw() -> void:
	draw_arc(Vector2.ZERO, 30, 0, TAU, 32, Color("fff0bf"), 2.0, true)
	preload("res://scripts/model_sprites.gd").paint(self, "fizzy", rotation, 62.0)

func _can_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("3c7767")
	style.border_color = Color("321f2b")
	style.set_border_width_all(4)
	style.set_corner_radius_all(7)
	return style
