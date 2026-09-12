extends Node3D
## Render the existing arena simulation in meters; its XY plane becomes XZ.
const SCALE := 0.01
const MODEL_KINDS := ["bird", "cat", "owl", "snake", "raccoon", "fox", "alpha_cat", "junkyard_dog", "barn_owl", "cheese", "rapid", "triple", "power", "haste", "shield", "pierce", "seed", "feather", "venom", "bone", "sonic", "crumb", "fizzy"]
var models: Dictionary = {}
var actors: Dictionary = {}
var camera := Camera3D.new()
var weapon := Node3D.new()
var muzzle: MeshInstance3D
var recoil := 0.0
var hit_marker := 0.0
var lines := ImmediateMesh.new()
var overlay: Control
var game: Node2D

func world(at: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(at.x * SCALE, height, at.y * SCALE)

func _ready() -> void:
	name = "FirstPersonView"
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("run_entities")
	game = get_parent()
	_load_models()
	_build_garden()
	camera.name = "FirstPersonCamera"
	camera.fov = 82.0
	camera.near = 0.035
	camera.far = 100.0
	add_child(camera)
	camera.make_current()
	_build_weapon()
	var geometry := MeshInstance3D.new()
	geometry.mesh = lines
	geometry.material_override = _material(Color.WHITE, true)
	geometry.material_override.vertex_color_use_as_albedo = true
	add_child(geometry)
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	overlay = preload("res://scripts/first_person_overlay.gd").new()
	overlay.view = self
	layer.add_child(overlay)
	game.player.shot_fired.connect(func(_at, _powered): recoil = 1.0)
	_sync_world()
	_update_camera(0.0)

func _load_models() -> void:
	# Merge named model parts by material once, keeping horde draw calls bounded.
	for kind in MODEL_KINDS:
		var source: Node3D = load("res://assets/models/%s.glb" % kind).instantiate()
		var surfaces := {}
		for part in source.find_children("*", "MeshInstance3D", true, false):
			var transform: Transform3D = part.transform
			var ancestor: Node = part.get_parent()
			while ancestor != source:
				transform = ancestor.transform * transform
				ancestor = ancestor.get_parent()
			for index in range(part.mesh.get_surface_count()):
				var material: Material = part.get_active_material(index)
				if not surfaces.has(material):
					var surface := SurfaceTool.new()
					surface.begin(Mesh.PRIMITIVE_TRIANGLES)
					surface.set_material(material)
					surfaces[material] = surface
				surfaces[material].append_from(part.mesh, index, transform)
		var mesh := ArrayMesh.new()
		for surface in surfaces.values():
			surface.commit(mesh)
		models[kind] = mesh
		source.free()

func _material(color: Color, unshaded: bool = false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.88
	if unshaded:
		result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return result

func _mesh(parent: Node3D, shape: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.position = at
	instance.material_override = material
	parent.add_child(instance)
	return instance

func _box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return _mesh(parent, shape, at, material)

func _sphere(parent: Node3D, at: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 12
	shape.rings = 6
	return _mesh(parent, shape, at, material)

func _build_garden() -> void:
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("080b1a")
	sky_material.sky_horizon_color = Color("55455b")
	sky_material.ground_horizon_color = Color("55455b")
	sky_material.ground_bottom_color = Color("131b22")
	var sky := Sky.new()
	sky.sky_material = sky_material
	environment.environment.background_mode = Environment.BG_SKY
	environment.environment.sky = sky
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a9bbd4")
	environment.environment.ambient_light_energy = 0.65
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	var moonlight := DirectionalLight3D.new()
	moonlight.rotation_degrees = Vector3(-38, -30, 0)
	moonlight.light_color = Color("acbee2")
	moonlight.light_energy = 1.25
	moonlight.shadow_enabled = true
	add_child(moonlight)
	var floor_material := ShaderMaterial.new()
	floor_material.shader = Shader.new()
	floor_material.shader.code = "shader_type spatial;\nvoid fragment(){vec2 p=UV*vec2(24.,14.); float tile=mod(floor(p.x)+floor(p.y),2.); vec2 edge=min(fract(p),1.-fract(p)); float seam=1.-smoothstep(0.,0.018,min(edge.x,edge.y)); ALBEDO=mix(mix(vec3(.095,.125,.13),vec3(.12,.15,.15),tile),vec3(.055,.075,.075),seam); ROUGHNESS=1.;}"
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(24, 14)
	_mesh(self, floor_mesh, Vector3.ZERO, floor_material)
	var stone := _material(Color("41454e"))
	var wood := _material(Color("292632"))
	var glow := _material(Color("f7a68c"), true)
	for side in [-1.0, 1.0]:
		_box(self, Vector3(0, 0.36, side * 7.0), Vector3(24.2, 0.72, 0.18), stone)
		_box(self, Vector3(side * 12.0, 0.36, 0), Vector3(0.18, 0.72, 14.2), stone)
		for x in range(-12, 13):
			_box(self, Vector3(x, 1.2, side * 7.0), Vector3(0.065, 1.5, 0.065), wood)
		for z in range(-7, 8):
			_box(self, Vector3(side * 12.0, 1.2, z), Vector3(0.065, 1.5, 0.065), wood)
		_box(self, Vector3(0, 1.65, side * 7.0), Vector3(24, 0.06, 0.06), wood)
		_box(self, Vector3(side * 12.0, 1.65, 0), Vector3(0.06, 0.06, 14), wood)
		for index in range(10):
			var tree := Node3D.new()
			tree.position = Vector3(-14.0 + index * 3.1, 0, side * (8.3 + sin(index * 4.0)))
			add_child(tree)
			var trunk := _box(tree, Vector3(0, 2.4, 0), Vector3(0.32, 4.8, 0.35), wood)
			trunk.rotation.z = sin(index * 3.0) * 0.12
			for branch in [-1.0, 1.0]:
				var limb := _box(tree, Vector3(branch * 0.6, 3.0, 0), Vector3(0.17, 2.0, 0.17), wood)
				limb.rotation.z = branch * -0.65
				_sphere(tree, Vector3(branch * 0.09, 1.6, -side * 0.2), 0.043, glow)
	# Landmarks sit outside the playable fence, so they never imply missing collisions.
	_box(self, Vector3(14, 0.6, 0), Vector3(1.4, 1.2, 2.8), stone)
	_box(self, Vector3(14, 1.24, 0), Vector3(1.8, 0.16, 3.1), stone)
	for z in [-1.0, 0.0, 1.0]:
		_box(self, Vector3(14, 1.55, z), Vector3(0.12, 0.5, 0.12), _material(Color("c8bca8")))
		_sphere(self, Vector3(14, 1.85, z), 0.075, glow)
	_sphere(self, Vector3(35, 16, -14), 4.2, _material(Color("c27380"), true))
	_sphere(self, Vector3(33.7, 16.3, -14.5), 3.95, _material(Color("0b0e1b"), true))

func _build_weapon() -> void:
	camera.add_child(weapon)
	var wood := _material(Color("745341"))
	var metal := _material(Color("649887"))
	_box(weapon, Vector3(0.2, -0.20, -0.47), Vector3(0.12, 0.13, 0.22), wood)
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.068
	barrel.bottom_radius = 0.075
	barrel.height = 0.34
	barrel.radial_segments = 12
	_mesh(weapon, barrel, Vector3(0.2, -0.16, -0.6), metal).rotation.x = PI * 0.5
	_box(weapon, Vector3(0.2, -0.075, -0.63), Vector3(0.025, 0.045, 0.035), wood)
	var paw := _material(Color("b28a99"))
	_sphere(weapon, Vector3(0.25, -0.29, -0.4), 0.095, paw).scale = Vector3(0.8, 0.75, 1.2)
	_sphere(weapon, Vector3(0.095, -0.25, -0.52), 0.083, paw).scale = Vector3(0.8, 0.7, 1.0)
	muzzle = _sphere(weapon, Vector3(0.2, -0.16, -0.8), 0.07, _material(Color("ffe5a5"), true))
	for part in weapon.get_children():
		part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
	if not is_instance_valid(game.player) or is_queued_for_deletion():
		return
	if not get_tree().paused:
		recoil = maxf(0.0, recoil - delta * 14.0)
		hit_marker = maxf(0.0, hit_marker - delta)
		_sync_world()
		_update_camera(delta)
	overlay.visible = game.game_state == "playing" and not get_tree().paused
	overlay.queue_redraw()

func _update_camera(delta: float) -> void:
	var rat = game.player
	camera.position = world(rat.global_position, rat.EYE_HEIGHT * SCALE)
	camera.rotation = Vector3(rat.pitch, -rat.yaw, 0)
	var shake: float = game.shake_strength * game.settings.shake * 0.0007
	camera.h_offset = sin(rat.anim_time * 95) * shake
	camera.v_offset = cos(rat.anim_time * 81) * shake
	var moving: bool = rat.velocity.length() > 30.0
	weapon.position = Vector3(sin(rat.distance_walked * 0.035) * 0.009 if moving else 0.0, 0.0, recoil * 0.06)
	muzzle.visible = recoil > 0.35
	camera.fov = lerpf(camera.fov, 88.0 if rat.game_time_ms() < rat.dash_until else 82.0, minf(1.0, delta * 12.0))

func _model(kind: String, height: float) -> Node3D:
	var pivot := Node3D.new()
	var mesh: ArrayMesh = models[kind]
	var bounds := mesh.get_aabb()
	var factor := height / maxf(bounds.size.y, 0.01)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.scale = Vector3.ONE * factor
	instance.position = Vector3(-bounds.get_center().x, -bounds.position.y, -bounds.get_center().z) * factor
	pivot.add_child(instance)
	return pivot

func _sync_world() -> void:
	lines.clear_surfaces()
	lines.surface_begin(Mesh.PRIMITIVE_LINES)
	# ImmediateMesh needs at least one primitive even when the arena is empty.
	_line(Vector3(0, -1, 0), Vector3(0.001, -1, 0), Color.BLACK)
	var current := {}
	for entity in game.get_children():
		if not entity is Node2D or entity.is_queued_for_deletion():
			continue
		var kind := ""
		var height := 0.3
		var lift := 0.0
		if entity.is_in_group("enemies"):
			if entity.dying:
				continue
			kind = entity.enemy_kind
			height = maxf(80.0, entity.radius * 3.0 * entity.scale.y) * SCALE
			_enemy_warnings(entity)
		elif entity.is_in_group("pickups"):
			kind = entity.kind
			lift = 0.12 + sin(entity.age * 4.0) * 0.04
			_ring(world(entity.global_position, 0.025), 0.23, entity.tint)
		elif entity.is_in_group("player_bullets"):
			kind = "seed"
			height = entity.radius * 2.0 * SCALE
			lift = entity.height * SCALE - height * 0.5
		elif entity.is_in_group("enemy_projectiles"):
			kind = entity.projectile_kind
			height = 0.20
			lift = 0.48
			_ring(world(entity.global_position, 0.58), 0.12, entity.tint)
		elif entity.get_script() == game.FizzyCanScript:
			kind = "fizzy"
			height = 0.8
		elif entity.get_script() == game.CrumbBombScript:
			kind = "crumb"
			_ring(world(entity.global_position, 0.03), entity.blast_radius * SCALE, Color("f6c53f"))
		elif entity.is_in_group("light_trails"):
			for segment in entity.segments:
				var tint := Color("ffe7a0").darkened(clampf((entity.clock - segment.born) / entity.DURATION, 0, 0.9))
				for offset in [-0.08, 0.0, 0.08]:
					_line(world(segment.from, 0.025) + Vector3(offset, 0, 0), world(segment.to, 0.025) + Vector3(offset, 0, 0), tint)
		elif entity.get_script() == game.ImpactFXScript and entity.size > 15:
			_ring(world(entity.global_position, 0.18), maxf(0.01, entity.size * SCALE * entity.elapsed / entity.duration), entity.tint.darkened(entity.elapsed / entity.duration))
		if kind.is_empty():
			continue
		var id: int = entity.get_instance_id()
		current[id] = true
		if not actors.has(id):
			var model := _model(kind, height)
			actors[id] = model
			add_child(model)
			if entity.is_in_group("enemies"):
				entity.hit.connect(func(_at): hit_marker = 0.12)
		var actor: Node3D = actors[id]
		actor.position = world(entity.global_position, lift)
		actor.rotation.y = -entity.rotation + PI * 0.5
		if entity.is_in_group("enemies"):
			actor.position.y += absf(sin(entity.age * 9.0)) * 0.025
			actor.scale = Vector3.ONE * maxf(0.08, entity.spawn_scale)
			if entity.hit_flash > 0:
				_ring(actor.position + Vector3(0, 0.03, 0), entity.radius * SCALE, Color("fff3d5"))
			if entity.elite:
				_ring(actor.position + Vector3(0, height + 0.08, 0), 0.18, Color("ffc75f"))
	for id in actors.keys():
		if not current.has(id):
			actors[id].queue_free()
			actors.erase(id)
	var rat = game.player
	if rat.game_time_ms() < rat.orbit_until:
		var count := 5 if rat.upgrade_levels.get("orbit_feast", 0) > 0 else 3
		for index in range(count):
			var point: Vector2 = rat.global_position + Vector2.from_angle(rat.anim_time * 3.2 + TAU * index / count) * 90.0
			_ring(world(point, 0.36), 0.1, Color("ffdf82"))
	lines.surface_end()

func _line(from: Vector3, to: Vector3, color: Color) -> void:
	lines.surface_set_color(color)
	lines.surface_add_vertex(from)
	lines.surface_add_vertex(to)

func _ring(at: Vector3, radius: float, color: Color, start: float = 0.0, span: float = TAU) -> void:
	for index in range(48):
		var a := start + span * index / 48.0
		var b := start + span * (index + 1) / 48.0
		_line(at + Vector3(cos(a), 0, sin(a)) * radius, at + Vector3(cos(b), 0, sin(b)) * radius, color)

func _enemy_warnings(enemy: Node2D) -> void:
	var at := world(enemy.global_position, 0.035)
	if enemy.state == "phase_shift":
		_ring(at, (enemy.radius + 25) * SCALE, Color("df5144"))
	if not enemy.is_winding_up():
		return
	var locked: bool = enemy.ranged_clock <= 0.22 if enemy.ranged_windup else enemy.state_clock <= 0.22
	var tint := Color("ff5a5d") if locked else Color("ffd16a")
	_ring(at, (enemy.radius + 14) * enemy.scale.x * SCALE, tint)
	var direction: Vector2 = enemy.ranged_direction if enemy.ranged_windup else enemy.pounce_direction
	var reach := 180.0
	if enemy.boss_patterns:
		var pattern = enemy.boss_patterns
		direction = pattern.locked_direction
		if pattern.attack == "ring":
			for radius in [0.9, 1.2]:
				_ring(at, radius * enemy.scale.x, tint, pattern.ring_angle + 0.62, TAU - 1.24)
			return
		if pattern.attack in ["pounce", "charge", "dive"]:
			reach = pattern._rush_speed() * pattern._rush_duration()
			var side := world(direction.orthogonal() * enemy.radius * enemy.scale.x)
			_line(at + side, at + world(direction * reach) + side, tint)
			_line(at - side, at + world(direction * reach) - side, tint)
		else:
			reach = 310.0 * enemy.scale.x
			var spread := 0.78 if pattern.attack == "sweep" else (0.3 if enemy.boss_phase == 1 else 0.45)
			for offset in [-spread, spread]:
				_line(at, at + world(direction.rotated(offset) * reach), tint)
	_line(at, at + world(direction * reach), tint)
