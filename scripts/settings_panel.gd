extends CanvasLayer

signal changed

const PATH := "user://settings.cfg"
const DEFAULT_KEYS := {"move_up": KEY_W, "move_left": KEY_A, "move_down": KEY_S, "move_right": KEY_D, "dash": KEY_SHIFT, "toggle_autofire": KEY_F, "pause": KEY_P}
var volume := 0.8
var shake := 0.5
var aim_assist := false
var cozy := false
var tips := true
var large_text := false
var keys: Dictionary = DEFAULT_KEYS.duplicate()
var overlay: ColorRect
var close_button: Button
var key_buttons: Dictionary = {}
var waiting_action := ""
var previous_focus: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_load()
	_apply_keys()
	overlay = ColorRect.new()
	overlay.color = Color("211c29")
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(760, 0)
	column.add_theme_constant_override("separation", 12)
	center.add_child(column)
	var title := Label.new()
	title.text = "MAKE YOURSELF COMFORTABLE"
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(760, 470)
	column.add_child(scroll)
	var options := VBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 10)
	scroll.add_child(options)
	_slider(options, "Sound volume", volume, func(value): volume = value; _save())
	_slider(options, "Camera shake", shake, func(value): shake = value; _save())
	_toggle(options, "Gentle aim assist", aim_assist, func(value): aim_assist = value; _save())
	_toggle(options, "Cozy difficulty (gentler new enemies)", cozy, func(value): cozy = value; _save())
	_toggle(options, "Larger gameplay and upgrade text", large_text, func(value): large_text = value; _save())
	_toggle(options, "Show learn-as-you-play hints", tips, func(value): tips = value; _save())
	for action in DEFAULT_KEYS:
		var button := Button.new()
		button.custom_minimum_size.y = 38
		button.add_theme_font_size_override("font_size", 18)
		key_buttons[action] = button
		button.pressed.connect(func():
			waiting_action = action
			button.text = "Press a keyboard key (Esc cancels)"
		)
		options.add_child(button)
	_refresh_keys()
	var reset := Button.new()
	reset.text = "Restore keyboard controls"
	reset.pressed.connect(func():
		keys = DEFAULT_KEYS.duplicate()
		waiting_action = ""
		_apply_keys()
		_refresh_keys()
		_save()
	)
	options.add_child(reset)
	close_button = Button.new()
	close_button.text = "DONE"
	close_button.custom_minimum_size.y = 48
	close_button.pressed.connect(hide_settings)
	column.add_child(close_button)
	overlay.hide()

func _slider(parent: Node, title: String, value: float, callback: Callable) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 310
	label.add_theme_font_size_override("font_size", 20)
	row.add_child(label)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(300, 32)
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.value_changed.connect(callback)
	row.add_child(slider)

func _toggle(parent: Node, title: String, value: bool, callback: Callable) -> void:
	var button := CheckButton.new()
	button.text = title
	button.button_pressed = value
	button.add_theme_font_size_override("font_size", 20)
	button.toggled.connect(callback)
	parent.add_child(button)

func is_open() -> bool:
	return is_instance_valid(overlay) and overlay.visible

func show_settings() -> void:
	previous_focus = get_viewport().gui_get_focus_owner()
	overlay.show()
	close_button.grab_focus()

func hide_settings() -> void:
	waiting_action = ""
	_refresh_keys()
	overlay.hide()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()

func _input(event: InputEvent) -> void:
	if not is_open():
		return
	if event is InputEventKey and event.pressed and not event.echo and not waiting_action.is_empty():
		if event.keycode != KEY_ESCAPE and event.physical_keycode not in [KEY_1, KEY_2, KEY_3, KEY_ENTER, KEY_SPACE]:
			var old_key: int = keys[waiting_action]
			for action in keys:
				if keys[action] == event.physical_keycode:
					keys[action] = old_key
			keys[waiting_action] = event.physical_keycode
			_apply_keys()
			_save()
		waiting_action = ""
		_refresh_keys()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		hide_settings()
		get_viewport().set_input_as_handled()

func _apply_keys() -> void:
	for action in keys:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		var event := InputEventKey.new()
		event.physical_keycode = int(keys[action])
		InputMap.action_add_event(action, event)
	# Escape remains a dependable pause shortcut. Arrow movement remains available
	# unless an arrow is explicitly assigned to another action.
	var fallbacks := {"move_up": KEY_UP, "move_down": KEY_DOWN, "move_left": KEY_LEFT, "move_right": KEY_RIGHT, "pause": KEY_ESCAPE}
	for action in fallbacks:
		if fallbacks[action] not in keys.values():
			var event := InputEventKey.new()
			event.physical_keycode = fallbacks[action]
			InputMap.action_add_event(action, event)

func _refresh_keys() -> void:
	for action in key_buttons:
		key_buttons[action].text = "%s: %s" % [action.replace("_", " ").capitalize(), OS.get_keycode_string(keys[action])]

func _load() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	volume = clampf(float(config.get_value("comfort", "volume", volume)), 0, 1)
	shake = clampf(float(config.get_value("comfort", "shake", shake)), 0, 1)
	aim_assist = bool(config.get_value("comfort", "aim_assist", false))
	cozy = bool(config.get_value("comfort", "cozy", false))
	tips = bool(config.get_value("comfort", "tips", true))
	large_text = bool(config.get_value("comfort", "large_text", false))
	for action in keys:
		keys[action] = int(config.get_value("keys", action, keys[action]))

func _save() -> void:
	var config := ConfigFile.new()
	for property in ["volume", "shake", "aim_assist", "cozy", "tips", "large_text"]:
		config.set_value("comfort", property, get(property))
	for action in keys:
		config.set_value("keys", action, keys[action])
	config.save(PATH)
	changed.emit()
