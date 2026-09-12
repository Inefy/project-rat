extends Control

var view: Node3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var game = view.game
	if not is_instance_valid(game.player):
		return
	var center := size * 0.5
	var tint := Color("ffe4ac") if view.hit_marker > 0 else Color("f7f0df")
	var gap: float = 7.0 + view.recoil * 3.0
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		draw_line(center + direction * gap, center + direction * (gap + 7), Color("171922"), 4.0, true)
		draw_line(center + direction * gap, center + direction * (gap + 7), tint, 2.0, true)
	draw_circle(center, 1.5, tint)
	if view.hit_marker > 0:
		for direction in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			draw_line(center + direction * 12, center + direction * 17, tint, 2, true)
	# A player-relative radar makes rear attacks and final stragglers readable.
	var radar := Vector2(95, 245)
	draw_circle(radar, 65, Color(0.035, 0.045, 0.065, 0.88))
	draw_arc(radar, 65, 0, TAU, 64, Color("839493"), 1.0, true)
	draw_line(radar, radar + Vector2(-42, -50), Color("444f55"), 1, true)
	draw_line(radar, radar + Vector2(42, -50), Color("444f55"), 1, true)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dying:
			continue
		var relative: Vector2 = (enemy.global_position - game.player.global_position).rotated(-game.player.yaw) * 0.06
		var dot := radar + relative.limit_length(61)
		draw_circle(dot, 3.7 if enemy.is_boss() else 2.5, Color("ffd16a") if enemy.is_winding_up() else Color("f07186"))
	for pickup in get_tree().get_nodes_in_group("pickups"):
		var relative: Vector2 = (pickup.global_position - game.player.global_position).rotated(-game.player.yaw) * 0.06
		draw_circle(radar + relative.limit_length(61), 2, Color("a9e5bb"))
	draw_colored_polygon(PackedVector2Array([radar + Vector2(0, -5), radar + Vector2(-4, 4), radar + Vector2(4, 4)]), Color("faf0d9"))
	draw_string(ThemeDB.fallback_font, radar + Vector2(-38, 83), "THREAT RADAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("b4c4c3"))
