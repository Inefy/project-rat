extends Node2D

const DURATION := 3.0
const RADIUS := 20.0
const DAMAGE_MULTIPLIER := 1.5
const TICK_INTERVAL := 0.2
const SAMPLE_DISTANCE := 12.0
const MAX_SEGMENTS := 256

var owner_player: Node2D
var segments: Array[Dictionary] = []
var clock := 0.0
var tick_clock := 0.0
var last_position := Vector2.ZERO
var enemy_positions: Dictionary = {}
var glow_lines: Array[Line2D] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	add_to_group("run_entities")
	add_to_group("light_trails")
	z_index = 8
	last_position = owner_player.global_position
	for layer in [[RADIUS * 3.2, Color(1.0, 0.73, 0.25, 0.10)], [RADIUS * 2.0, Color(1.0, 0.87, 0.42, 0.24)], [7.0, Color(1.0, 0.98, 0.77, 0.78)]]:
		var line := Line2D.new()
		line.width = layer[0]
		line.modulate = layer[1]
		line.antialiased = true
		line.joint_mode = Line2D.LINE_JOINT_ROUND
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(line)
		glow_lines.append(line)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(owner_player) or not owner_player.alive:
		queue_free()
		return
	clock += delta
	while not segments.is_empty() and clock - float(segments[0].born) >= DURATION:
		segments.pop_front()
	var at: Vector2 = owner_player.global_position
	if last_position.distance_squared_to(at) >= SAMPLE_DISTANCE * SAMPLE_DISTANCE:
		segments.append({"from": last_position, "to": at, "born": clock})
		last_position = at
		if segments.size() > MAX_SEGMENTS:
			segments.pop_front()
	tick_clock += delta
	if tick_clock >= TICK_INTERVAL:
		# One hit per enemy per tick, even where the rat loops over its own trail.
		_damage_enemies()
		tick_clock = fmod(tick_clock, TICK_INTERVAL)
	_update_visuals()

func _damage_enemies() -> void:
	var current_positions := {}
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.dying:
			continue
		var id: int = enemy.get_instance_id()
		var at: Vector2 = enemy.global_position
		var previous: Vector2 = enemy_positions.get(id, at)
		current_positions[id] = at
		var reach: float = RADIUS + enemy.radius * absf(enemy.scale.x)
		if crosses_trail(previous, at, reach):
			enemy.take_damage(owner_player.base_damage * DAMAGE_MULTIPLIER * TICK_INTERVAL)
	enemy_positions = current_positions

func crosses_trail(from: Vector2, to: Vector2, reach: float) -> bool:
	# Sweep between damage ticks so a fast enemy cannot jump across a thin trail.
	var path_bounds := Rect2(from, Vector2.ZERO).expand(to).grow(reach)
	for segment in segments:
		var start: Vector2 = segment.from
		var end: Vector2 = segment.to
		var segment_bounds := Rect2(start, Vector2.ZERO).expand(end).grow(0.01)
		if not path_bounds.intersects(segment_bounds, true):
			continue
		var nearest := Geometry2D.get_closest_points_between_segments(from, to, start, end)
		if nearest[0].distance_squared_to(nearest[1]) <= reach * reach:
			return true
	return false

func _update_visuals() -> void:
	var points := PackedVector2Array()
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	var length := 0.0
	if not segments.is_empty():
		points.append(to_local(segments[0].from))
		offsets.append(0.0)
		colors.append(Color(1, 1, 1, clampf(1.0 - (clock - float(segments[0].born)) / DURATION, 0, 1)))
		for segment in segments:
			var at := to_local(segment.to)
			length += points[-1].distance_to(at)
			points.append(at)
			offsets.append(length)
			colors.append(Color(1, 1, 1, clampf(1.0 - (clock - float(segment.born)) / DURATION, 0, 1)))
		for i in range(offsets.size()):
			offsets[i] /= maxf(length, 0.001)
	var gradient := Gradient.new()
	if not offsets.is_empty():
		gradient.offsets = offsets
		gradient.colors = colors
	for line in glow_lines:
		line.points = points
		line.gradient = gradient
