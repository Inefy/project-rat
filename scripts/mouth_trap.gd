extends Node2D

const ATLAS = preload("res://assets/sprites/hazards/mouth_trap.png")
const CELL := 320.0
const DRAW_SIZE := 220.0
const FOOTPRINT := Vector2(79.0, 33.0)
const DAMAGE := 22.0
const LIFETIME := 18.0
const SPAWN_WARNING := 0.9
const BITE_WARNING := 0.34
const SNAP_TIME := 0.16
const CLOSED_TIME := 0.55
const OPEN_TIME := 0.38
const RECOVERY_TIME := 0.8
const FADE_TIME := 0.65

enum Phase { APPEARING, ARMED, WINDUP, SNAPPING, CLOSED, OPENING, RECOVERY, EXPIRING }
var phase := Phase.APPEARING
var age := 0.0
var phase_clock := 0.0
var bite_landed := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	z_index = 5
	add_to_group("run_entities")
	add_to_group("mouth_traps")

func _change_phase(next_phase: Phase) -> void:
	phase = next_phase
	phase_clock = 0.0
	z_index = 25 if phase in [Phase.SNAPPING, Phase.CLOSED] else 5
	queue_redraw()

func contains_rat() -> bool:
	var rat = get_parent().player
	if not is_instance_valid(rat) or not rat.alive:
		return false
	var relative := to_local(rat.global_position) / FOOTPRINT
	return relative.length_squared() <= 1.0

func _physics_process(delta: float) -> void:
	var game = get_parent()
	if game.game_state != "playing" or not is_instance_valid(game.player) or not game.player.alive:
		return
	age += delta
	phase_clock += delta
	if age >= LIFETIME and phase != Phase.EXPIRING:
		_change_phase(Phase.EXPIRING)
	match phase:
		Phase.APPEARING:
			if phase_clock >= SPAWN_WARNING:
				_change_phase(Phase.ARMED)
		Phase.ARMED:
			if contains_rat():
				bite_landed = false
				_change_phase(Phase.WINDUP)
		Phase.WINDUP:
			if phase_clock >= BITE_WARNING:
				_change_phase(Phase.SNAPPING)
		Phase.SNAPPING:
			# The impact belongs to the jaws meeting, not to entering a trigger area.
			if not bite_landed and phase_clock >= SNAP_TIME * 0.65:
				bite_landed = true
				game.audio.play("enemy_hit", 0.04, 5.0)
				if contains_rat():
					var away: Vector2 = global_position.direction_to(game.player.global_position)
					if away.is_zero_approx():
						away = Vector2.DOWN.rotated(rotation)
					game.player.take_player_damage(14.0 if game.settings.cozy else DAMAGE, away * 170.0, "mouth trap")
			if phase_clock >= SNAP_TIME:
				_change_phase(Phase.CLOSED)
		Phase.CLOSED:
			if phase_clock >= CLOSED_TIME:
				_change_phase(Phase.OPENING)
		Phase.OPENING:
			if phase_clock >= OPEN_TIME:
				_change_phase(Phase.RECOVERY)
		Phase.RECOVERY:
			if phase_clock >= RECOVERY_TIME:
				_change_phase(Phase.ARMED)
		Phase.EXPIRING:
			if phase_clock >= FADE_TIME:
				queue_free()
	queue_redraw()

func _draw() -> void:
	var frame := 0
	var alpha := 1.0
	var growth := 1.0
	match phase:
		Phase.APPEARING:
			alpha = clampf(phase_clock / SPAWN_WARNING, 0.0, 1.0)
			growth = lerpf(0.65, 1.0, alpha)
		Phase.WINDUP:
			frame = 1
		Phase.SNAPPING:
			frame = clampi(1 + floori(phase_clock / SNAP_TIME * 5.0), 1, 5)
		Phase.CLOSED:
			frame = 5
		Phase.OPENING:
			frame = clampi(5 - floori(phase_clock / OPEN_TIME * 6.0), 0, 5)
		Phase.EXPIRING:
			alpha = 1.0 - clampf(phase_clock / FADE_TIME, 0.0, 1.0)
			growth = lerpf(0.8, 1.0, alpha)
	var dimensions := Vector2.ONE * DRAW_SIZE * growth
	draw_texture_rect_region(ATLAS, Rect2(-dimensions * 0.5, dimensions), Rect2(frame * CELL, 0, CELL, CELL), Color(1, 1, 1, alpha))
	if phase in [Phase.APPEARING, Phase.WINDUP]:
		var warning := Color("edc374") if phase == Phase.APPEARING else Color("ff6e58")
		warning.a = 0.9
		draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, FOOTPRINT.y / FOOTPRINT.x))
		draw_arc(Vector2.ZERO, FOOTPRINT.x + 8, 0, TAU, 48, warning, 2.5, true)
		draw_set_transform(Vector2.ZERO)
