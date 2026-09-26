extends CanvasLayer

const UI = preload("res://scripts/ui_theme.gd")

signal changed

const PATH := "user://settings.cfg"
const DEFAULT_KEYS := {"move_up": KEY_W, "move_left": KEY_A, "move_down": KEY_S, "move_right": KEY_D, "aim_up": KEY_UP, "aim_left": KEY_LEFT, "aim_down": KEY_DOWN, "aim_right": KEY_RIGHT, "dash": KEY_SHIFT, "toggle_autofire": KEY_F, "pause": KEY_P}
var volume := 0.8
var shake := 0.5
var mouse_sensitivity := 1.0
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
	overlay.color = UI.INK
	overlay.theme = UI.make()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 1096
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_font_override("font", UI.DISPLAY)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	close_button = Button.new()
	close_button.text = "Done"
	close_button.custom_minimum_size = Vector2(112, 44)
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_stylebox_override("normal", UI.panel(UI.ACCENT))
	for state in ["normal", "hover", "pressed"]:
		close_button.add_theme_stylebox_override(state, UI.panel(UI.ACCENT if state == "normal" else UI.ACCENT.lightened(0.12)))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		close_button.add_theme_color_override(state, UI.INK)
	close_button.pressed.connect(hide_settings)
	header.add_child(close_button)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	column.add_child(columns)
	var comfort := VBoxContainer.new()
	comfort.custom_minimum_size.x = 460
	comfort.add_theme_constant_override("separation", 8)
	var comfort_panel := PanelContainer.new()
	comfort_panel.add_theme_stylebox_override("panel", UI.panel(UI.SURFACE, UI.LINE))
	columns.add_child(comfort_panel)
	comfort_panel.add_child(comfort)
	_section(comfort, "Sound & comfort")
	_slider(comfort, "Volume", volume, func(value): volume = value; _save())
	_slider(comfort, "Camera shake", shake, func(value): shake = value; _save())
	var space := Control.new()
	space.custom_minimum_size.y = 16
	comfort.add_child(space)
	_toggle(comfort, "Aim assist", aim_assist, func(value): aim_assist = value; _save())
	_toggle(comfort, "Cozy difficulty", cozy, func(value): cozy = value; _save())
	_toggle(comfort, "Large text", large_text, func(value): large_text = value; _save())
	_toggle(comfort, "Hints", tips, func(value): tips = value; _save())
	var controls := VBoxContainer.new()
	controls.custom_minimum_size.x = 500
	controls.add_theme_constant_override("separation", 8)
	var controls_panel := PanelContainer.new()
	controls_panel.add_theme_stylebox_override("panel", UI.panel(UI.SURFACE, UI.LINE))
	columns.add_child(controls_panel)
	controls_panel.add_child(controls)
	_section(controls, "Keyboard")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(500, 350)
	scroll.follow_focus = true
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	controls.add_child(scroll)
	var options := VBoxContainer.new()
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("separation", 2)
	scroll.add_child(options)
	for action in DEFAULT_KEYS:
		var row := HBoxContainer.new()
		options.add_child(row)
		var label := Label.new()
		label.text = "Auto-fire" if action == "toggle_autofire" else action.replace("_", " ").capitalize()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(126, 44)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_stylebox_override("normal", UI.panel(Color.TRANSPARENT, UI.LINE))
		button.tooltip_text = "Change " + label.text.to_lower()
		key_buttons[action] = button
		button.pressed.connect(func():
			waiting_action = action
			button.text = "Press a key"
		)
		row.add_child(button)
	_refresh_keys()
	var reset := Button.new()
	reset.text = "Reset key bindings"
	reset.size_flags_horizontal = Control.SIZE_SHRINK_END
	reset.pressed.connect(func():
		keys = DEFAULT_KEYS.duplicate()
		waiting_action = ""
		_apply_keys()
		_refresh_keys()
		_save()
	)
	controls.add_child(reset)
	var help := Label.new()
	help.text = "Select a key to rebind it. Scroll for more controls. Esc cancels."
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", UI.MUTED)
	column.add_child(help)
	overlay.hide()

func _section(parent: Node, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", UI.DISPLAY)
	label.add_theme_font_size_override("font_size", 26)
	label.add_theme_color_override("font_color", UI.ACCENT)
	parent.add_child(label)
	var rule := ColorRect.new()
	rule.color = UI.LINE
	rule.custom_minimum_size.y = 1
	parent.add_child(rule)

func _slider(parent: Node, title: String, value: float, callback: Callable) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = 48
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 170
	row.add_child(label)
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(205, 24)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.tooltip_text = title
	row.add_child(slider)
	var amount := Label.new()
	amount.custom_minimum_size.x = 54
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.text = "%d%%" % roundi(value * 100)
	row.add_child(amount)
	slider.value_changed.connect(func(new_value):
		amount.text = "%d%%" % roundi(new_value * 100)
		callback.call(new_value)
	)

func _toggle(parent: Node, title: String, value: bool, callback: Callable) -> void:
	var button := CheckButton.new()
	button.text = title
	button.button_pressed = value
	button.custom_minimum_size.y = 48
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
			_set_key(waiting_action, event.physical_keycode)
			_apply_keys()
			_save()
		waiting_action = ""
		_refresh_keys()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		hide_settings()
		get_viewport().set_input_as_handled()

func _set_key(action: String, key: int) -> void:
	var old_key: int = keys[action]
	for other_action in keys:
		if other_action != action and keys[other_action] == key:
			keys[other_action] = old_key
	keys[action] = key

func _apply_keys() -> void:
	for action in keys:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				InputMap.action_erase_event(action, event)
		var event := InputEventKey.new()
		event.physical_keycode = int(keys[action])
		InputMap.action_add_event(action, event)
	# Arrow keys now aim independently of movement. Escape still pauses.
	var fallbacks := {"pause": KEY_ESCAPE}
	for action in fallbacks:
		if fallbacks[action] not in keys.values():
			var event := InputEventKey.new()
			event.physical_keycode = fallbacks[action]
			InputMap.action_add_event(action, event)

func _refresh_keys() -> void:
	for action in key_buttons:
		key_buttons[action].text = OS.get_keycode_string(keys[action])

func _load() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) != OK:
		return
	volume = clampf(float(config.get_value("comfort", "volume", volume)), 0, 1)
	shake = clampf(float(config.get_value("comfort", "shake", shake)), 0, 1)
	mouse_sensitivity = clampf(float(config.get_value("comfort", "mouse_sensitivity", 1.0)), 0.1, 2.0)
	aim_assist = bool(config.get_value("comfort", "aim_assist", false))
	cozy = bool(config.get_value("comfort", "cozy", false))
	tips = bool(config.get_value("comfort", "tips", true))
	large_text = bool(config.get_value("comfort", "large_text", false))
	for action in keys:
		# Swap conflicts when migrating older movement bindings onto the new aim keys.
		if config.has_section_key("keys", action):
			_set_key(action, int(config.get_value("keys", action)))

func _save() -> void:
	var config := ConfigFile.new()
	for property in ["volume", "shake", "mouse_sensitivity", "aim_assist", "cozy", "tips", "large_text"]:
		config.set_value("comfort", property, get(property))
	for action in keys:
		config.set_value("keys", action, keys[action])
	config.save(PATH)
	changed.emit()
