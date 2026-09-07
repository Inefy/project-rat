extends Node2D

var owner_player: Node2D
var fuse := 0.48
var blast_radius := 115.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("run_entities")
	z_index = 16

func _physics_process(delta: float) -> void:
	fuse -= delta
	queue_redraw()
	if fuse <= 0.0:
		detonate()

func detonate() -> void:
	if is_queued_for_deletion():
		return
	var hit_any := false
	if is_instance_valid(owner_player) and owner_player.alive:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not enemy.dying and global_position.distance_to(enemy.global_position) < blast_radius + enemy.radius:
				hit_any = true
				enemy.take_damage(owner_player.base_damage * 2.5, global_position.direction_to(enemy.global_position) * 280.0)
		if hit_any and owner_player.upgrade_levels.get("dash_refund", 0) > 0:
			owner_player.dash_ready_at = maxi(owner_player.game_time_ms(), owner_player.dash_ready_at - 400)
	get_parent()._spawn_impact(global_position, Color("f6c53f"), blast_radius)
	get_parent().audio.play("enemy_death", 0.08)
	queue_free()

func _draw() -> void:
	draw_arc(Vector2.ZERO, blast_radius, 0, TAU, 48, Color(1.0, 0.8, 0.2, 0.3), 2.0, true)
	preload("res://scripts/model_sprites.gd").paint(self, "crumb", rotation, 38.0, fuse, 1.5)
