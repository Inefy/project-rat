extends CanvasLayer

const UI = preload("res://scripts/ui_theme.gd")
const UpgradeIcon = preload("res://scripts/upgrade_icon.gd")
const DemoRules = preload("res://scripts/demo_rules.gd")

signal resume_requested
signal settings_requested
signal overtime_requested
signal start_requested
signal demo_setup_requested
signal demo_start_requested(wave: int)
signal restart_requested
signal quit_to_menu_requested
signal upgrade_selected(id: String)
signal upgrade_reroll_requested
signal ui_sound_requested(event_name: String)

var root: Control
var menu_overlay: ColorRect
var demo_overlay: ColorRect
var demo_wave: SpinBox
var demo_summary: Label
var demo_play: Button
var demo_run := false
var demo_start_wave := 1
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
var health_panel: PanelContainer
var menu_records: Label
var draft_context: Label
var draft_build: Label
var reroll_button: Button


var pale := UI.PAPER

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
	feedback_overlay.health_target = health_panel
	_build_menu()
	_build_demo_setup()
	_build_game_over()
	_build_pause()
	_build_upgrade_draft()
	_build_victory()

func _label(text: String, font_size: int, color: Color = UI.PAPER) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _heading(text: String, font_size: int = 48) -> Label:
	var label := _label(text, font_size, UI.PAPER)
	label.add_theme_font_override("font", UI.DISPLAY)
	return label

func _place(node: Control, parent: Node, at: Vector2, dimensions: Vector2 = Vector2.ZERO) -> void:
	parent.add_child(node)
	node.position = at
	if dimensions != Vector2.ZERO:
		node.size = dimensions

func _overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.color = UI.INK
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(overlay)
	return overlay

func _meter(parent: Node, color: Color, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = 1.0
	bar.add_theme_stylebox_override("background", UI.flat_bar(UI.HUD_LINE))
	bar.add_theme_stylebox_override("fill", UI.flat_bar(color))
	bar.custom_minimum_size = Vector2(width, 4)
	parent.add_child(bar)
	bar.set_deferred("size", Vector2(width, 4))
	return bar

func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(252, 52)
	button.add_theme_font_size_override("font_size", 19)
	if primary:
		for state in ["normal", "hover", "pressed"]:
			button.add_theme_stylebox_override(state, UI.panel(UI.ACCENT if state == "normal" else Color("ac504a")))
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(state, UI.PAPER)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(func(): ui_sound_requested.emit("ui_hover"))
	button.pressed.connect(func(): ui_sound_requested.emit("ui_click"))
	return button

func _rule(parent: Node) -> void:
	var line := ColorRect.new()
	line.color = UI.LINE
	line.custom_minimum_size.y = 1
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _build_game_hud() -> void:
	# A compact wave group at left and score group at right keep the arena clear.
	var wave_group := Control.new()
	_place(wave_group, root, Vector2(32, 24), Vector2(350, 110))
	wave_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wave_label = _label("Wave 01", 26, UI.PAPER)
	_place(wave_label, wave_group, Vector2.ZERO)
	encounter_label = _label("", 15, UI.HUD_MUTED)
	_place(encounter_label, wave_group, Vector2(0, 37))
	wave_bar = _meter(wave_group, UI.HUD_MUTED, 260)
	wave_bar.position = Vector2(0, 68)
	progress_label = _label("Wave progress", 12, UI.HUD_MUTED)
	_place(progress_label, wave_group, Vector2(0, 78))
	for fraction in [1.0 / 3.0, 2.0 / 3.0]:
		var marker := ColorRect.new()
		marker.color = UI.INK
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wave_bar.add_child(marker)
		marker.anchor_left = fraction
		marker.anchor_right = fraction
		marker.anchor_bottom = 1.0
		marker.offset_left = -1
		marker.offset_right = 1
		marker.hide()
		phase_markers.append(marker)
	var score_group := VBoxContainer.new()
	root.add_child(score_group)
	score_group.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	score_group.offset_left = -260
	score_group.offset_top = 22
	score_group.offset_right = -32
	score_group.custom_minimum_size.x = 228
	score_group.add_theme_constant_override("separation", 2)
	score_label = _label("0", 30, UI.PAPER)
	score_group.add_child(score_label)
	var caption := _label("Score", 13, UI.HUD_MUTED)
	score_group.add_child(caption)
	kills_label = _label("0 kills", 15, UI.HUD_MUTED)
	score_group.add_child(kills_label)
	combo_label = _label("", 15, UI.HUD_MUTED)
	score_group.add_child(combo_label)
	for child in score_group.get_children():
		child.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_bar = _meter(score_group, UI.HUD_MUTED, 100)
	combo_bar.size_flags_horizontal = Control.SIZE_SHRINK_END
	buffs_label = _label("", 14, UI.PAPER)
	buffs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(buffs_label)
	buffs_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	buffs_label.offset_left = -320
	buffs_label.offset_top = 163
	buffs_label.offset_right = -32
	buffs_label.offset_bottom = 333
	health_panel = PanelContainer.new()
	root.add_child(health_panel)
	health_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	health_panel.offset_left = 28
	health_panel.offset_top = -134
	health_panel.offset_right = 358
	health_panel.offset_bottom = -28
	health_panel.custom_minimum_size = Vector2(330, 106)
	health_panel.add_theme_stylebox_override("panel", UI.panel(Color(0.06, 0.055, 0.065, 0.90)))
	var vitals := VBoxContainer.new()
	vitals.add_theme_constant_override("separation", 7)
	health_panel.add_child(vitals)
	health_label = _label("Health   100 / 100", 15, UI.PAPER)
	vitals.add_child(health_label)
	health_bar = _meter(vitals, UI.PAPER, 294)
	health_bar.max_value = 100
	health_bar.value = 100
	dash_label = _label("Dash ready   [Shift]", 14, UI.HUD_MUTED)
	vitals.add_child(dash_label)
	dash_bar = _meter(vitals, UI.ACCENT, 294)
	dash_bar.value = 1
	autofire_label = _label("", 14, UI.HUD_MUTED)
	root.add_child(autofire_label)
	autofire_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	autofire_label.offset_left = -330
	autofire_label.offset_top = -64
	autofire_label.offset_right = -32
	autofire_label.offset_bottom = -42
	autofire_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	control_hint = _label("Esc  Pause", 14, UI.HUD_MUTED)
	root.add_child(control_hint)
	control_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	control_hint.offset_left = -330
	control_hint.offset_top = -40
	control_hint.offset_right = -32
	control_hint.offset_bottom = -18
	control_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	banner_label = _label("", 38, UI.PAPER)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(banner_label)
	banner_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_label.offset_left = -350
	banner_label.offset_top = 140
	banner_label.offset_right = 350
	banner_label.offset_bottom = 194
	banner_label.modulate.a = 0
	toast_label = _label("", 22, UI.PAPER)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(toast_label)
	toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_label.offset_left = -290
	toast_label.offset_top = -172
	toast_label.offset_right = 290
	toast_label.offset_bottom = -138
	toast_label.modulate.a = 0
	tip_label = _label("", 16, UI.HUD_MUTED)
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(tip_label)
	tip_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	tip_label.offset_left = -230
	tip_label.offset_top = -78
	tip_label.offset_right = 230
	tip_label.offset_bottom = -30
	gameplay_hud = [wave_group, score_group, health_panel, buffs_label, autofire_label, control_hint, banner_label, toast_label, tip_label]

func _build_menu() -> void:
	menu_overlay = _overlay()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_bottom = -60
	menu_overlay.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 620
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	var kicker := _label("THE NIGHTMARE GARDEN", 14, UI.MUTED)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(kicker)
	var title := _heading("Project R.A.T.", 86)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var goal := _label("Survive 15 waves. Defeat 3 bosses.", 23, UI.PAPER)
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(goal)
	var detail := _label("Choose upgrades. Find your build. Keep moving.", 17, UI.MUTED)
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(detail)
	var space := Control.new()
	space.custom_minimum_size.y = 12
	column.add_child(space)
	menu_start = _button("Start run", true)
	menu_start.pressed.connect(func(): start_requested.emit())
	menu_start.custom_minimum_size = Vector2(320, 54)
	menu_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(menu_start)
	var secondary := HBoxContainer.new()
	secondary.add_theme_constant_override("separation", 12)
	secondary.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(secondary)
	var demo := _button("Demo mode")
	demo.custom_minimum_size = Vector2(154, 46)
	demo.pressed.connect(func(): demo_setup_requested.emit())
	secondary.add_child(demo)
	var options := _button("Settings")
	options.pressed.connect(func(): settings_requested.emit())
	options.custom_minimum_size = Vector2(154, 46)
	secondary.add_child(options)
	menu_records = _label("", 16, UI.MUTED)
	menu_records.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(menu_records)
	var footer := VBoxContainer.new()
	menu_overlay.add_child(footer)
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 80
	footer.offset_right = -80
	footer.offset_top = -84
	footer.add_theme_constant_override("separation", 20)
	_rule(footer)
	menu_help = _label("", 14, UI.MUTED)
	menu_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	footer.add_child(menu_help)

func _build_demo_setup() -> void:
	demo_overlay = _overlay()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	demo_overlay.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 620
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	var title := _heading("Demo mode", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var intro := _label("Jump straight into a wave with a random build.", 20, UI.MUTED)
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(intro)
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	row.add_theme_constant_override("separation", 20)
	column.add_child(row)
	var wave_caption := _label("Starting wave", 22)
	wave_caption.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(wave_caption)
	demo_wave = SpinBox.new()
	demo_wave.min_value = DemoRules.MIN_WAVE
	demo_wave.max_value = DemoRules.MAX_WAVE
	demo_wave.step = 1
	demo_wave.rounded = true
	demo_wave.update_on_text_changed = true
	demo_wave.select_all_on_focus = true
	demo_wave.value = DemoRules.DEFAULT_WAVE
	demo_wave.custom_minimum_size = Vector2(150, 52)
	demo_wave.add_theme_font_size_override("font_size", 24)
	row.add_child(demo_wave)
	var edit := demo_wave.get_line_edit()
	edit.add_theme_font_size_override("font_size", 24)
	edit.add_theme_color_override("font_color", UI.PAPER)
	edit.add_theme_stylebox_override("normal", UI.panel(UI.SURFACE, UI.LINE))
	edit.add_theme_stylebox_override("focus", UI.focus())
	edit.text_submitted.connect(func(_text: String): _request_demo_start())
	var presets := HBoxContainer.new()
	presets.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	presets.add_theme_constant_override("separation", 12)
	column.add_child(presets)
	for wave in [5, 10, 20, 30]:
		var preset := _button(str(wave))
		preset.custom_minimum_size = Vector2(68, 42)
		preset.pressed.connect(func(): demo_wave.value = wave)
		presets.add_child(preset)
	demo_summary = _label("", 18, UI.MUTED)
	demo_summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	demo_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	demo_summary.custom_minimum_size = Vector2(620, 78)
	column.add_child(demo_summary)
	demo_play = _button("", true)
	demo_play.custom_minimum_size = Vector2(320, 54)
	demo_play.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	demo_play.pressed.connect(_request_demo_start)
	column.add_child(demo_play)
	var back := _button("Back to title")
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func(): quit_to_menu_requested.emit())
	column.add_child(back)
	demo_wave.value_changed.connect(func(_value: float): _update_demo_summary())
	_update_demo_summary()
	demo_overlay.hide()

func _update_demo_summary() -> void:
	var wave := int(demo_wave.value)
	var treats := DemoRules.starting_treats(wave)
	demo_summary.text = "Up to %d upgrade picks from earlier waves and bosses.\nFull health%s. Practice scores are not saved." % [DemoRules.upgrade_budget(wave), " + %d random treats" % treats if treats > 0 else ""]
	demo_play.text = "Play wave %d" % wave

func _request_demo_start() -> void:
	if not demo_overlay.visible:
		return
	# Commit a typed number even when the start button takes focus immediately.
	var text := demo_wave.get_line_edit().text.strip_edges()
	if text.is_valid_int():
		demo_wave.value = DemoRules.starting_wave(int(text))
	demo_start_requested.emit(int(demo_wave.value))

func show_demo_setup() -> void:
	menu_overlay.hide()
	demo_overlay.show()
	demo_wave.get_line_edit().grab_focus()
	demo_wave.get_line_edit().select_all()

func set_demo_run(enabled: bool, starting_wave: int = 1) -> void:
	demo_run = enabled
	demo_start_wave = starting_wave
	retry_button.text = "Retry wave %d" % starting_wave if enabled else "Try again"

func _build_game_over() -> void:
	game_over_overlay = _overlay()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_over_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(580, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	var title := _heading("Run complete", 58)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	final_score_label = _label("0", 64, UI.PAPER)
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(final_score_label)
	final_detail_label = _label("", 20, UI.MUTED)
	final_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(final_detail_label)
	best_label = _label("", 17, UI.MUTED)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(best_label)
	death_tip = _label("", 18, UI.MUTED)
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
	pause_overlay = _overlay()
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 100)
	center.add_child(layout)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 310
	column.add_theme_constant_override("separation", 14)
	layout.add_child(column)
	column.add_child(_heading("Paused", 60))
	var space := Control.new()
	space.custom_minimum_size.y = 24
	column.add_child(space)
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
	build.custom_minimum_size.x = 450
	build.add_theme_constant_override("separation", 20)
	layout.add_child(build)
	build.add_child(_label("Your upgrades", 23, UI.PAPER))
	_rule(build)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(450, 280)
	build.add_child(scroll)
	build_label = _label("", 20, UI.MUTED)
	build_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(build_label)
	pause_overlay.hide()

func _build_upgrade_draft() -> void:
	upgrade_overlay = _overlay()
	upgrade_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	upgrade_overlay.add_child(center)
	var stack := VBoxContainer.new()
	stack.custom_minimum_size.x = 1072
	stack.add_theme_constant_override("separation", 12)
	center.add_child(stack)
	stack.add_child(_label("Wave clear", 16, UI.MUTED))
	stack.add_child(_heading("Choose an upgrade", 50))
	stack.add_child(_label("Your choice lasts for the rest of this run.", 18, UI.MUTED))
	var space := Control.new()
	space.custom_minimum_size.y = 12
	stack.add_child(space)
	upgrade_cards = HBoxContainer.new()
	upgrade_cards.add_theme_constant_override("separation", 20)
	stack.add_child(upgrade_cards)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 24)
	stack.add_child(footer)
	draft_context = _label("", 17, UI.PAPER)
	draft_context.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draft_context.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(draft_context)
	reroll_button = _button("Reroll  [R]", false)
	reroll_button.custom_minimum_size = Vector2(240, 44)
	reroll_button.pressed.connect(func(): upgrade_reroll_requested.emit())
	footer.add_child(reroll_button)
	draft_build = _label("", 15, UI.MUTED)
	draft_build.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(draft_build)
	upgrade_overlay.hide()

func show_upgrade_draft(options: Array[Dictionary]) -> void:
	for child in upgrade_cards.get_children():
		upgrade_cards.remove_child(child)
		child.queue_free()
	for index in range(options.size()):
		var data := options[index]
		var card := Button.new()
		card.custom_minimum_size = Vector2(344, 386 if large_text else 350)
		card.add_theme_color_override("font_color", UI.PAPER)
		card.add_theme_color_override("font_focus_color", UI.PAPER)
		card.add_theme_stylebox_override("normal", UI.panel(Color(0.06, 0.055, 0.065, 0.80), UI.LINE))
		card.add_theme_stylebox_override("hover", UI.panel(UI.SURFACE))
		card.add_theme_stylebox_override("pressed", UI.panel(Color("322626")))
		var focused := UI.panel(Color(0.59, 0.23, 0.23, 0.12), UI.ACCENT)
		card.add_theme_stylebox_override("focus", focused)
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var content := VBoxContainer.new()
		card.add_child(content)
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 24
		content.offset_right = -24
		content.offset_top = 24
		content.offset_bottom = -24
		content.add_theme_constant_override("separation", 12)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := UpgradeIcon.new()
		icon.kind = data["id"]
		icon.custom_minimum_size = Vector2(64, 64)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		content.add_child(icon)
		var tag := _label(String(data.get("tag", "Permanent upgrade")), 14, Color("c9bc91"))
		tag.name = "MutationTag"
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(tag)
		var title := _label(String(data["title"]).capitalize(), 25, UI.PAPER)
		title.name = "MutationTitle"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(title)
		var description := _label(String(data["description"]).replace(" → ", " to "), 21 if large_text else 18, UI.MUTED)
		description.name = "MutationDescription"
		description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(description)
		var choose := _label("Choose  [%d]" % (index + 1), 17, UI.PAPER)
		choose.name = "MutationChoice"
		choose.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(choose)
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

func set_draft_context(next_wave: String, build: String, remaining: int, can_reroll: bool) -> void:
	draft_context.text = next_wave
	draft_build.text = build
	reroll_button.text = "Reroll  [R]   %d left" % remaining
	reroll_button.disabled = not can_reroll
	reroll_button.tooltip_text = "Replace the offered upgrades. Two rerolls per run." if can_reroll else ("No rerolls left this run." if remaining == 0 else "All eligible choices are already shown.")

func set_menu_records(score: int, wave: int) -> void:
	menu_records.text = "Best score  %s     /     Best wave  %d" % [_format_score(score), wave] if wave > 0 else "Your first run starts here."

func show_menu() -> void:
	demo_overlay.hide()
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
	demo_overlay.hide()
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
	health_label.add_theme_font_size_override("font_size", 18 if large_text else 15)
	dash_label.add_theme_font_size_override("font_size", 18 if large_text else 14)
	score_label.text = _format_score(score)
	wave_label.text = ("Demo / Wave %02d" if demo_run else "Wave %02d") % wave
	kills_label.text = "%d kills" % kills
	health_label.text = "Health   %d / %d" % [ceil(health), ceil(max_health)]
	health_bar.max_value = max_health
	health_bar.value = health
	wave_bar.value = clamp(progress, 0.0, 1.0)
	progress_label.text = "Wave progress"
	for marker in phase_markers:
		marker.hide()
	buffs_label.text = "\n".join(buffs)
	dash_bar.value = dash_charge
	dash_label.text = "Dash ready   [%s / RB]" % dash_key if dash_charge >= 0.999 else "Dash   %.1fs" % ((1.0 - dash_charge) * 1.35)
	dash_label.add_theme_color_override("font_color", UI.HUD_MUTED if dash_charge >= 0.999 else pale)

func set_boss_status(title: String, phase: int, health_ratio: float) -> void:
	progress_label.text = "%s • PHASE %d/3" % [title, phase]
	wave_bar.value = clampf(health_ratio, 0.0, 1.0)
	for marker in phase_markers:
		marker.show()

func set_autofire(enabled: bool) -> void:
	autofire_label.text = "Auto-fire %s   [%s]" % ["on" if enabled else "off", fire_key]
	autofire_label.add_theme_color_override("font_color", UI.HUD_MUTED if enabled else pale)

func show_wave_banner(wave: int, boss_kind: String = "") -> void:
	var boss_names := {
		"alpha_cat": "ALPHA CAT",
		"junkyard_dog": "JUNKYARD DOG",
		"barn_owl": "BARN OWL",
	}
	banner_label.text = String(boss_names.get(boss_kind, "Wave %02d" % wave))
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
	final_score_label.text = _format_score(score)
	final_detail_label.text = "Wave %d   /   %d kills" % [wave, kills]
	best_label.text = "New best  " + _format_score(best) if is_new_best else "Best  " + _format_score(best)
	if demo_run:
		best_label.text = "Demo from wave %d / Practice score" % demo_start_wave

func set_paused(paused: bool) -> void:
	pause_overlay.visible = paused
	if paused:
		resume_button.grab_focus()

func update_combo(multiplier: int, remaining: float) -> void:
	combo_label.text = "x%d streak" % multiplier if multiplier > 1 else ""
	combo_label.add_theme_color_override("font_color", UI.PAPER if multiplier >= 4 else UI.HUD_MUTED)
	combo_bar.value = remaining
	combo_bar.visible = multiplier > 1

func set_encounter(title: String) -> void:
	encounter_label.text = title.capitalize()

func set_build_text(text: String) -> void:
	build_label.text = text.replace(" • ", "\n\n")

func set_control_labels(keys: Dictionary) -> void:
	dash_key = OS.get_keycode_string(keys["dash"])
	fire_key = OS.get_keycode_string(keys["toggle_autofire"])
	var movement := "%s/%s/%s/%s" % [OS.get_keycode_string(keys["move_up"]), OS.get_keycode_string(keys["move_left"]), OS.get_keycode_string(keys["move_down"]), OS.get_keycode_string(keys["move_right"])]
	aim_keys = "Arrows" if keys["aim_up"] == KEY_UP and keys["aim_left"] == KEY_LEFT and keys["aim_down"] == KEY_DOWN and keys["aim_right"] == KEY_RIGHT else "%s/%s/%s/%s" % [OS.get_keycode_string(keys["aim_up"]), OS.get_keycode_string(keys["aim_left"]), OS.get_keycode_string(keys["aim_down"]), OS.get_keycode_string(keys["aim_right"])]
	control_hint.text = "%s / Esc   Pause" % OS.get_keycode_string(keys["pause"])
	menu_help.text = "%s   Move       Mouse / %s   Aim       %s   Dash" % [movement, aim_keys, dash_key]

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

func show_death_tip(source: String, streak: int, new_wave: bool) -> void:
	var hints := {
		"bird": "Keep moving across the flock; dash through a gap when surrounded.",
		"cat": "Wait for the pounce line to lock, then dodge sideways.",
		"fox": "Dodge across the red ambush line, then attack during recovery.",
		"raccoon": "Step sideways during the wind-up; punish the end of the charge.",
		"owl": "Move between feather volleys; close in while the owl recovers.",
		"feather": "Cross the gaps between feathers instead of retreating with the volley.",
		"snake": "Keep circling when the snake winds up its venom shot.",
		"venom": "Change direction after the venom shot is aimed.",
		"alpha_cat": "Dodge across pounces and attack during the recovery window.",
		"junkyard_dog": "Watch the charge line; move through the gap in each shockwave.",
		"barn_owl": "Keep space for the feather fans and save your dash for the dive.",
		"bone": "Keep moving across bone trails and avoid getting pinned at the fence.",
		"sonic": "Look for the gap in the ring, or dash through it.",
		"fizzy can": "Shoot the can from outside its blast radius, or dash clear before it bursts.",
	}
	death_tip.text = "Caught by %s. %s\nBest streak x%d%s" % [source.replace("_", " "), hints.get(source, "Dash through attacks when your escape route closes."), streak, " • New wave record" if new_wave else ""]

func _build_victory() -> void:
	victory_overlay = _overlay()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_overlay.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	var title := _heading("You survived.", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var detail := _label("", 22, UI.MUTED)
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
	detail.text = "Score %s • Best streak x%d" % [_format_score(score), streak]
	overtime_button.grab_focus()

func hide_victory() -> void:
	victory_overlay.hide()
	set_game_hud_visible(true)

func _format_score(value: int) -> String:
	var digits := str(value)
	var result := ""
	for index in range(digits.length()):
		if index > 0 and (digits.length() - index) % 3 == 0:
			result += ","
		result += digits[index]
	return result
