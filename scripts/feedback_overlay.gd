extends Control

var tint := Color.WHITE
var remaining := 0.0
var duration := 0.55
var hurt := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_PAUSABLE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func pulse(color: Color, is_damage: bool) -> void:
	# A pickup cannot overwrite an active damage warning.
	if remaining > 0 and hurt and not is_damage:
		return
	tint = color
	hurt = is_damage
	duration = 0.55 if hurt else 0.7
	remaining = duration
	queue_redraw()

func _process(delta: float) -> void:
	if remaining > 0:
		remaining = maxf(0, remaining - delta)
		queue_redraw()

func _draw() -> void:
	if remaining <= 0:
		return
	var alpha := pow(remaining / duration, 1.5)
	for i in range(14):
		var inset := float(i * 5)
		var color := Color(tint, alpha * (0.20 if hurt else 0.075) * (1.0 - float(i) / 14.0))
		draw_rect(Rect2(inset, inset, size.x - inset * 2, size.y - inset * 2), color, false, 10)
	if hurt:
		draw_rect(Rect2(24, 621, 338, 74), Color(tint, alpha * 0.8), false, 4)
