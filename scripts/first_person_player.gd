extends "res://scripts/player.gd"

const EYE_HEIGHT := 58.0
var yaw := PI * 0.5
var pitch := 0.0

func _ready() -> void:
	super._ready()
	get_node("ArenaCamera").enabled = false
	using_directional_aim = true

func _unhandled_input(event: InputEvent) -> void:
	if not alive or get_tree().paused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sensitivity: float = get_parent().settings.mouse_sensitivity * 0.0025
		yaw = wrapf(yaw + event.relative.x * sensitivity, -PI, PI)
		pitch = clampf(pitch - event.relative.y * sensitivity, -1.1, 1.1)
		_update_aim(Vector2.ZERO)
	if event.is_action_pressed("toggle_autofire"):
		autofire = not autofire
		autofire_changed.emit(autofire)

func _get_move_input() -> Vector2:
	return super._get_move_input().rotated(yaw)

func _update_aim(directional_aim: Vector2, delta: float = 0.0) -> void:
	yaw = wrapf(yaw + directional_aim.x * delta * 2.3, -PI, PI)
	pitch = clampf(pitch - directional_aim.y * delta * 1.6, -1.1, 1.1)
	super._update_aim(Vector2(sin(yaw), -cos(yaw)))

func _configure_bullet(bullet: Area2D) -> void:
	bullet.uses_height = true
	bullet.height = EYE_HEIGHT + tan(pitch) * 30.0
	bullet.vertical_speed = sin(pitch) * bullet_speed
	bullet.velocity *= cos(pitch)
