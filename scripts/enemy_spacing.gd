extends Node
## Resolve crowded bodies after every enemy has finished moving.

const PADDING := 8.0
const BODY_SCALE := 1.35

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	process_physics_priority = 10

static func body_radius(enemy: Node2D) -> float:
	return enemy.radius * maxf(enemy.scale.x, enemy.scale.y) * BODY_SCALE

func _physics_process(delta: float) -> void:
	var game = get_parent()
	if game.game_state != "playing" or not is_instance_valid(game.player) or not game.player.alive:
		return
	var enemies: Array[Node2D] = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy.dying and not enemy.is_queued_for_deletion():
			enemies.append(enemy)
	# Two short passes settle dense groups without a hard collision pile-up.
	for pass_index in range(2):
		for i in range(enemies.size()):
			var a := enemies[i]
			for j in range(i + 1, enemies.size()):
				var b := enemies[j]
				var gap := body_radius(a) + body_radius(b) + PADDING
				var offset := a.global_position - b.global_position
				if offset.length_squared() >= gap * gap:
					continue
				var a_weight := _mobility(a)
				var b_weight := _mobility(b)
				var total := a_weight + b_weight
				if total <= 0.0:
					continue
				var distance := offset.length()
				var direction := offset / distance if distance > 0.01 else Vector2.from_angle(float((i * 37 + j * 17) % 360) * PI / 180.0)
				var correction := direction * minf(12.0, (gap - distance) * clampf(delta * 30.0, 0.0, 1.0))
				_shift(a, correction * a_weight / total)
				_shift(b, -correction * b_weight / total)

func _mobility(enemy: Node2D) -> float:
	if enemy.enemy_kind == "owl" or enemy.spawn_grace > 0.0:
		return 0.0
	return 0.25 if enemy.is_boss() else 1.0

func _shift(enemy: Node2D, correction: Vector2) -> void:
	if correction.is_zero_approx():
		return
	var margin: Vector2 = Vector2.ONE * enemy.radius
	enemy.global_position = (enemy.global_position + correction).clamp(enemy.ARENA.position + margin, enemy.ARENA.end - margin)
