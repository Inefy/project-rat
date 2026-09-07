extends Node2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("run_entities")
	z_index = 90

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var game := get_parent()
	if game.game_state != "playing" or not is_instance_valid(game.player):
		return
	var canvas := get_canvas_transform()
	var visible_rect := Rect2(Vector2(44, 115), get_viewport_rect().size - Vector2(88, 275))
	var center := visible_rect.get_center()
	var cleanup: bool = game.wave_queue.is_empty() and game._living_enemy_count() <= 3
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dying:
			continue
		var screen: Vector2 = canvas * enemy.global_position
		if visible_rect.has_point(screen):
			continue
		if not cleanup and not enemy.is_winding_up():
			continue
		var direction := (screen - center).normalized()
		var half := visible_rect.size * 0.5
		var factor := minf(half.x / maxf(absf(direction.x), 0.001), half.y / maxf(absf(direction.y), 0.001))
		var tip := canvas.affine_inverse() * (center + direction * factor)
		var side := direction.orthogonal()
		var points := PackedVector2Array([tip + direction * 12, tip - direction * 9 + side * 9, tip - direction * 9 - side * 9])
		draw_colored_polygon(points, Color("f6c53f") if cleanup else Color("df5144"))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), Color("321f2b"), 3, true)
		count += 1
		if count >= 12:
			break
