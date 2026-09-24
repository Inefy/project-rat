extends CanvasLayer

const UI = preload("res://scripts/ui_theme.gd")
const SillyMenuBackdropScript = preload("res://scripts/silly_menu_backdrop.gd")

signal resume_requested
signal settings_requested
signal overtime_requested
signal start_requested
signal restart_requested
signal quit_to_menu_requested
signal upgrade_selected(id: String)
signal ui_sound_requested(event_name: String)

var root: Control
var menu_overlay: ColorRect
var game_over_overlay: ColorRect
var pause_overlay: ColorRect
var score_label: Label
var wave_label: Label
var kills_label: Label
var health_label: Label
var health_bar: ProgressBar
var wave_bar: ProgressBar
var progress_label: Label
var phase_markers: Array[ColorRect] = []
var buffs_label: Label
var autofire_label: Label
var banner_label: Label
var toast_label: Label
var final_score_label: Label
var final_detail_label: Label
var best_label: Label
var dash_label: Label
var dash_bar: ProgressBar
var upgrade_overlay: ColorRect
var upgrade_cards: HBoxContainer
var gameplay_hud: Array[CanvasItem] = []
var combo_label: Label
var combo_bar: ProgressBar
var encounter_label: Label
var tip_label: Label
var build_label: Label
var death_tip: Label
var victory_overlay: ColorRect
var menu_start: Button
var retry_button: Button
var resume_button: Button
var overtime_button: Button
var toast_tween: Tween
var large_text := false
var control_hint: Label
var menu_help: Label
var fire_key := "F"
var dash_key := "Shift"
var aim_keys := "Arrows"
var feedback_overlay: Control


var cyan := UI.MUTED
var pink := UI.ACCENT
var pale := UI.PAPER
var dark := UI.INK

func _ready() -> void:
	layer = 100
	root = Control.new()
	root.theme = UI.make()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_game_hud()
	feedback_overlay = preload("res://scripts/feedback_overlay.gd").new()
	root.add_child(feedback_overlay)
	_build_menu()
	_build_game_over()
	_build_pause()
	_build_upgrade_draft()
	_build_victory()

func _label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if font_size >= 30:
		label.add_theme_font_override("font", UI.DISPLAY)
	return label

func _panel_style(color: Color, border: Color, _radius: int = 0) -> StyleBoxFlat:
	return UI.panel(color, border)

func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(310, 56)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 20)
	if primary:
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, UI.panel(UI.PAPER if state == "normal" else Color("f6f1e4"), UI.PAPER))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, UI.INK)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(func(): ui_sound_requested.emit("ui_hover"))
	button.pressed.connect(func(): ui_sound_requested.emit("ui_click"))
	return button

func _focus_style() -> StyleBoxFlat:
	return UI.focus()

func _rule(parent: Node) -> void:
	var line := ColorRect.new()
	line.color = UI.LINE
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _build_game_hud() -> void:
	score_label = _label("SCORE 000000", 25, pale)
	score_label.position = Vector2(28, 20)
	root.add_child(score_label)
	wave_label = _label("WAVE 0", 20, cyan)
	wave_label.position = Vector2(30, 57)
	root.add_child(wave_label)
	kills_label = _label("KILLS 0", 15, pale)
	kills_label.position = Vector2(30, 87)
	root.add_child(kills_label)

	var health_panel := PanelContainer.new()
	health_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	health_panel.position = Vector2(32, -108)
	health_panel.size = Vector2(290, 70)
	health_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.063, 0.071, 0.067, 0.85), dark, 14))
	root.add_child(health_panel)
	var health_box := VBoxContainer.new()
	health_panel.add_child(health_box)
	health_label = _label("HP 100 / 100", 14, pale)
	health_box.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(250, 6)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", UI.flat_bar(UI.LINE))
	health_bar.add_theme_stylebox_override("fill", UI.flat_bar(UI.ACCENT))
	health_box.add_child(health_bar)

	var wave_panel := PanelContainer.new()
	wave_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	wave_panel.position = Vector2(-205, 20)
	wave_panel.size = Vector2(410, 62)
	wave_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.063, 0.071, 0.067, 0.85), dark, 14))
	root.add_child(wave_panel)
	var wave_box := VBoxContainer.new()
	wave_panel.add_child(wave_box)
	var incoming := _label("WAVE PROGRESS", 13, UI.MUTED)
	progress_label = incoming
	incoming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_box.add_child(incoming)
	wave_bar = ProgressBar.new()
	wave_bar.custom_minimum_size = Vector2(370, 4)
	wave_bar.max_value = 1.0
	wave_bar.value = 0.0
	wave_bar.show_percentage = false
	wave_bar.add_theme_stylebox_override("background", UI.flat_bar(UI.LINE))
	var wave_fill := StyleBoxFlat.new()
	wave_fill.bg_color = cyan
	wave_fill.set_corner_radius_all(3)
	wave_bar.add_theme_stylebox_override("fill", wave_fill)
	wave_box.add_child(wave_bar)
	for fraction in [1.0 / 3.0, 2.0 / 3.0]:
		var marker := ColorRect.new()
		marker.color = dark
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wave_bar.add_child(marker)
		marker.anchor_left = fraction
		marker.anchor_right = fraction
		marker.anchor_bottom = 1.0
		marker.offset_left = -1.5
		marker.offset_right = 1.5
		marker.hide()
		phase_markers.append(marker)

	buffs_label = _label("", 15, pale)
	buffs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	buffs_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	buffs_label.position = Vector2(-370, 22)
	buffs_label.size = Vector2(340, 120)
	root.add_child(buffs_label)
	autofire_label = _label("AUTO-FIRE: ON  [F]", 14, cyan)
	autofire_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	autofire_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	autofire_label.position = Vector2(-322, -30)
	autofire_label.size = Vector2(290, 24)
	root.add_child(autofire_label)
	var dash_panel := PanelContainer.new()
	dash_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	dash_panel.position = Vector2(-322, -108)
	dash_panel.size = Vector2(290, 70)
	dash_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.063, 0.071, 0.067, 0.85), dark, 12))
	root.add_child(dash_panel)
	var dash_box := VBoxContainer.new()
	dash_panel.add_child(dash_box)
	dash_label = _label("DASH READY  [SHIFT / RB]", 12, cyan)
	dash_box.add_child(dash_label)
	dash_bar = ProgressBar.new()
	dash_bar.custom_minimum_size = Vector2(250, 6)
	dash_bar.max_value = 1.0
	dash_bar.value = 1.0
	dash_bar.show_percentage = false
	dash_bar.add_theme_stylebox_override("background", UI.flat_bar(UI.LINE))
	dash_bar.add_theme_stylebox_override("fill", UI.flat_bar(UI.MUTED))
	dash_box.add_child(dash_bar)

	var controls := _label("ESC: PAUSE", 13, pale)
	control_hint = controls
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls.position = Vector2(-490, -28)
	controls.size = Vector2(980, 20)
	root.add_child(controls)

	banner_label = _label("WAVE 1", 48, Color.WHITE)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_label.position = Vector2(-400, 145)
	banner_label.size = Vector2(800, 70)
	banner_label.modulate.a = 0.0
	root.add_child(banner_label)
	toast_label = _label("", 24, cyan)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_label.position = Vector2(-350, -145)
	toast_label.size = Vector2(700, 42)
	toast_label.modulate.a = 0.0
	root.add_child(toast_label)
	combo_label = _label("STREAK x1", 18, UI.MUTED)
	combo_label.position = Vector2(30, 117)
	root.add_child(combo_label)
	combo_bar = ProgressBar.new()
	combo_bar.position = Vector2(30, 149)
	combo_bar.max_value = 1.0
	combo_bar.show_percentage = false
	combo_bar.size = Vector2(150, 3)
	root.add_child(combo_bar)
	combo_bar.set_deferred("size", Vector2(150, 3))
	encounter_label = _label("", 17, pale)
	encounter_label.position = Vector2(420, 96)
	encounter_label.size.x = 440
	encounter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(encounter_label)
	tip_label = _label("", 18, pale)
	tip_label.position = Vector2(335, 598)
	tip_label.size = Vector2(560, 54)
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(tip_label)
	gameplay_hud = [combo_label, combo_bar, encounter_label, tip_label, score_label, wave_label, kills_label, health_panel, wave_panel, buffs_label, autofire_label, dash_panel, controls, banner_label, toast_label]

func _build_menu() -> void:
	menu_overlay = ColorRect.new()
	menu_overlay.color = Color.TRANSPARENT
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(menu_overlay)
	menu_overlay.add_child(SillyMenuBackdropScript.new())
	var edition := _label("A NIGHTMARE SURVIVAL GAME", 14, cyan)
	edition.position = Vector2(88, 54)
	menu_overlay.add_child(edition)
	var box := VBoxContainer.new()
	box.position = Vector2(88, 148)
	box.custom_minimum_size.x = 380
	box.add_theme_constant_override("separation", 6)
	menu_overlay.add_child(box)
	box.add_child(_label("PROJECT", 25, pale))
	var title := _label("R.A.T.", 154, pale)
	title.add_theme_constant_override("line_spacing", 0)
	box.add_child(title)
	var subtitle := _label("Small rat. Long night.", 22, cyan)
	box.add_child(subtitle)
	var space := Control.new()
	space.custom_minimum_size.y = 30
	box.add_child(space)
	menu_start = _button("Start run", true)
	menu_start.pressed.connect(func(): start_requested.emit())
	box.add_child(menu_start)
	var options := _button("Settings")
	options.pressed.connect(func(): settings_requested.emit())
	box.add_child(options)
	var footer := VBoxContainer.new()
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 88
	footer.offset_right = -88
	footer.offset_top = -88
	footer.add_theme_constant_override("separation", 18)
	menu_overlay.add_child(footer)
	_rule(footer)
	menu_help = _label("", 14, cyan)
	menu_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(menu_help)

func _build_game_over() -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.color = Color(0.063, 0.071, 0.067, 0.98)
	game_over_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(game_over_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(580, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	var title := _label("THE NIGHT WINS", 64, pale)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	final_score_label = _label("000000", 88, pale)
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(final_score_label)
	final_detail_label = _label("WAVE 0  •  KILLS 0", 20, cyan)
	final_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(final_detail_label)
	best_label = _label("BEST 000000", 17, UI.MUTED)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(best_label)
	death_tip = _label("", 18, pale)
	death_tip.custom_minimum_size.x = 800
	death_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	death_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(death_tip)
	var restart := _button("Try again", true)
	retry_button = restart
	restart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart.pressed.connect(func(): restart_requested.emit())
	box.add_child(restart)
	var menu := _button("Return to title")
	menu.custom_minimum_size = Vector2(240, 42)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.add_theme_font_size_override("font_size", 16)
	menu.pressed.connect(func(): quit_to_menu_requested.emit())
	box.add_child(menu)
	game_over_overlay.hide()

func _build_pause() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.063, 0.071, 0.067, 0.94)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root.add_child(pause_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 90)
	center.add_child(layout)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 360
	column.add_theme_constant_override("separation", 12)
	layout.add_child(column)
	column.add_child(_label("TAKE A BREATHER", 14, cyan))
	column.add_child(_label("PAUSED", 80, pale))
	resume_button = _button("Resume", true)
	resume_button.pressed.connect(func(): resume_requested.emit())
	column.add_child(resume_button)
	var options := _button("Settings")
	options.pressed.connect(func(): settings_requested.emit())
	column.add_child(options)
	var menu := _button("Return to title")
	menu.pressed.connect(func(): quit_to_menu_requested.emit())
	column.add_child(menu)
	var build := VBoxContainer.new()
	build.custom_minimum_size.x = 440
	build.add_theme_constant_override("separation", 22)
	layout.add_child(build)
	build.add_child(_label("YOUR MUTATIONS", 16, cyan))
	_rule(build)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 260)
	build.add_child(scroll)
	build_label = _label("", 20, pale)
	build_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(build_label)
	pause_overlay.hide()

func _build_upgrade_draft() -> void:
	upgrade_overlay = ColorRect.new()
	upgrade_overlay.color = Color(0.063, 0.071, 0.067, 0.97)
	upgrade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	upgrade_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root.add_child(upgrade_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.add_child(center)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 18)
	center.add_child(stack)
	var title := _label("ADAPT. SURVIVE.", 64, pale)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	var detail := _label("Choose a mutation for the next wave.", 18, cyan)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(detail)
	upgrade_cards = HBoxContainer.new()
	upgrade_cards.add_theme_constant_override("separation", 18)
	stack.add_child(upgrade_cards)
	upgrade_overlay.hide()

func show_upgrade_draft(options: Array[Dictionary]) -> void:
	for child in upgrade_cards.get_children():
		upgrade_cards.remove_child(child)
		child.queue_free()
	for index in range(options.size()):
		var data := options[index]
		var card := Button.new()
		card.custom_minimum_size = Vector2(340, 380 if large_text else 320)
		card.add_theme_color_override("font_focus_color", pale)
		card.add_theme_stylebox_override("normal", UI.panel())
		card.add_theme_stylebox_override("hover", UI.panel(Color("272c26"), UI.MUTED))
		card.add_theme_stylebox_override("pressed", UI.panel(Color("363c32"), UI.PAPER))
		card.add_theme_stylebox_override("focus", _focus_style())
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 26
		content.offset_right = -26
		content.offset_top = 24
		content.offset_bottom = -24
		content.add_theme_constant_override("separation", 16)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		var number := _label("0%d  /  MUTATION" % (index + 1), 14, cyan)
		content.add_child(number)
		_rule(content)
		var title := _label(data["title"], 34 if large_text else 30, pale)
		title.name = "MutationTitle"
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(title)
		var description := _label(data["description"], 21 if large_text else 18, pale)
		description.name = "MutationDescription"
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(description)
		content.add_child(_label("Select   [%d]" % (index + 1), 14, cyan))
		for child in content.get_children():
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.mouse_entered.connect(func(): ui_sound_requested.emit("ui_hover"))
		card.pressed.connect(_on_upgrade_card_pressed.bind(String(data["id"])))
		upgrade_cards.add_child(card)
	upgrade_overlay.show()
	if upgrade_cards.get_child_count() > 0:
		upgrade_cards.get_child(0).grab_focus()

func _on_upgrade_card_pressed(id: String) -> void:
	ui_sound_requested.emit("ui_click")
	upgrade_selected.emit(id)

func hide_upgrade_draft() -> void:
	upgrade_overlay.hide()

func show_menu() -> void:
	feedback_overlay.remaining = 0.0
	feedback_overlay.queue_redraw()
	victory_overlay.hide()
	menu_overlay.show()
	game_over_overlay.hide()
	pause_overlay.hide()
	upgrade_overlay.hide()
	set_game_hud_visible(false)
	menu_start.grab_focus()

func begin_game() -> void:
	feedback_overlay.remaining = 0.0
	feedback_overlay.queue_redraw()
	victory_overlay.hide()
	menu_overlay.hide()
	game_over_overlay.hide()
	pause_overlay.hide()
	upgrade_overlay.hide()
	set_game_hud_visible(true)

func set_game_hud_visible(enabled: bool) -> void:
	for node in gameplay_hud:
		node.visible = enabled

func update_stats(score: int, wave: int, kills: int, health: float, max_health: float, progress: float, buffs: Array[String], dash_charge: float = 1.0) -> void:
	buffs_label.add_theme_font_size_override("font_size", 18 if large_text else 15)
	kills_label.add_theme_font_size_override("font_size", 18 if large_text else 15)
	health_label.add_theme_font_size_override("font_size", 18 if large_text else 14)
	dash_label.add_theme_font_size_override("font_size", 16 if large_text else 12)
	score_label.text = "SCORE %06d" % score
	wave_label.text = "WAVE %d" % wave
	kills_label.text = "KILLS %d" % kills
	health_label.text = "HP %d / %d" % [ceil(health), ceil(max_health)]
	health_bar.max_value = max_health
	health_bar.value = health
	wave_bar.value = clamp(progress, 0.0, 1.0)
	progress_label.text = "WAVE PROGRESS"
	for marker in phase_markers:
		marker.hide()
	buffs_label.text = "\n".join(buffs)
	dash_bar.value = dash_charge
	dash_label.text = "DASH READY [%s / RB]" % dash_key if dash_charge >= 0.999 else "DASH %.1fs" % ((1.0 - dash_charge) * 1.35)
	dash_label.add_theme_color_override("font_color", UI.MUTED if dash_charge >= 0.999 else pale)

func set_boss_status(title: String, phase: int, health_ratio: float) -> void:
	progress_label.text = "%s • PHASE %d/3" % [title, phase]
	wave_bar.value = clampf(health_ratio, 0.0, 1.0)
	for marker in phase_markers:
		marker.show()

func set_autofire(enabled: bool) -> void:
	autofire_label.text = "AUTO-FIRE: %s  [%s]" % ["ON" if enabled else "OFF", fire_key]
	autofire_label.add_theme_color_override("font_color", UI.MUTED if enabled else pale)

func show_wave_banner(wave: int, boss_kind: String = "") -> void:
	var boss_names := {
		"alpha_cat": "ALPHA CAT",
		"junkyard_dog": "JUNKYARD DOG",
		"barn_owl": "BARN OWL",
	}
	banner_label.text = String(boss_names.get(boss_kind, "WAVE %d" % wave))
	banner_label.add_theme_color_override("font_color", Color("ef6f6c") if not boss_kind.is_empty() else pale)
	banner_label.modulate.a = 0.0
	banner_label.position.y = 165
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(banner_label, "modulate:a", 1.0, 0.18)
	tween.tween_property(banner_label, "position:y", 135.0, 0.28).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_interval(1.15)
	tween.tween_property(banner_label, "modulate:a", 0.0, 0.42)

func show_toast(text: String, color: Color, hold: float = 0.75) -> void:
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	toast_label.modulate.a = 0.0
	toast_label.scale = Vector2(0.82, 0.82)
	toast_label.pivot_offset = toast_label.size * 0.5
	var tween := create_tween()
	toast_tween = tween
	tween.set_parallel(true)
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.12)
	tween.tween_property(toast_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_interval(hold)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)

func show_game_over(score: int, wave: int, kills: int, best: int, is_new_best: bool) -> void:
	set_game_hud_visible(false)
	game_over_overlay.show()
	retry_button.grab_focus()
	final_score_label.text = "%06d" % score
	final_detail_label.text = "WAVE %d  •  KILLS %d" % [wave, kills]
	best_label.text = "NEW BEST %06d" % best if is_new_best else "BEST %06d" % best

func set_paused(paused: bool) -> void:
	pause_overlay.visible = paused
	if paused:
		resume_button.grab_focus()

func update_combo(multiplier: int, remaining: float) -> void:
	combo_label.text = "STREAK x%d" % multiplier
	combo_label.add_theme_color_override("font_color", UI.MUTED if multiplier >= 4 else pale)
	combo_bar.value = remaining

func set_encounter(title: String) -> void:
	encounter_label.text = title

func set_build_text(text: String) -> void:
	build_label.text = text.replace(" • ", "\n\n")

func set_control_labels(keys: Dictionary) -> void:
	dash_key = OS.get_keycode_string(keys["dash"])
	fire_key = OS.get_keycode_string(keys["toggle_autofire"])
	var movement := "%s/%s/%s/%s" % [OS.get_keycode_string(keys["move_up"]), OS.get_keycode_string(keys["move_left"]), OS.get_keycode_string(keys["move_down"]), OS.get_keycode_string(keys["move_right"])]
	aim_keys = "Arrows" if keys["aim_up"] == KEY_UP and keys["aim_left"] == KEY_LEFT and keys["aim_down"] == KEY_DOWN and keys["aim_right"] == KEY_RIGHT else "%s/%s/%s/%s" % [OS.get_keycode_string(keys["aim_up"]), OS.get_keycode_string(keys["aim_left"]), OS.get_keycode_string(keys["aim_down"]), OS.get_keycode_string(keys["aim_right"])]
	control_hint.text = "%s / ESC: PAUSE" % OS.get_keycode_string(keys["pause"])
	menu_help.text = "Move: %s  •  Aim: mouse / %s  •  Dash: %s" % [movement, aim_keys, dash_key]

func update_tip(player: Node, wave: int, enabled: bool) -> void:
	if not enabled or wave > 3:
		tip_label.text = ""
	elif player.distance_walked < 150:
		tip_label.text = "Move to dodge."
	elif player.dash_count == 0:
		tip_label.text = "%s / RB: dash through attacks." % dash_key
	elif wave <= 1:
		tip_label.text = "Mouse / %s: aim. Space / click: fire." % aim_keys
	else:
		tip_label.text = "Red attack line: dodge."

func show_death_tip(_source: String, streak: int, new_wave: bool) -> void:
	death_tip.text = "Best streak x%d%s" % [streak, " • New wave record" if new_wave else ""]

func _build_victory() -> void:
	victory_overlay = ColorRect.new()
	victory_overlay.color = UI.INK
	victory_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(victory_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_overlay.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	var title := _label("DAYBREAK", 80, pale)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var detail := _label("", 22, pale)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.name = "VictoryDetail"
	column.add_child(detail)
	overtime_button = _button("Endless mode", true)
	overtime_button.pressed.connect(func(): overtime_requested.emit())
	column.add_child(overtime_button)
	var done := _button("Return to title")
	done.pressed.connect(func(): quit_to_menu_requested.emit())
	column.add_child(done)
	victory_overlay.hide()

func show_victory(score: int, streak: int) -> void:
	set_game_hud_visible(false)
	victory_overlay.show()
	var detail := victory_overlay.find_child("VictoryDetail", true, false) as Label
	detail.text = "Score %d • Best streak x%d" % [score, streak]
	overtime_button.grab_focus()

func hide_victory() -> void:
	victory_overlay.hide()
	set_game_hud_visible(true)
