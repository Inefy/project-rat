extends CanvasLayer

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


var cyan := Color("55ad87")
var pink := Color("e44f45")
var pale := Color("fff0bf")
var dark := Color("321f2b")

const KENNEY_PARROT_TEXTURE = preload("res://assets/sprites/bird_2.png")
const KENNEY_OWL_TEXTURE = preload("res://assets/sprites/owl_2.png")
const KENNEY_SNAKE_TEXTURE = preload("res://assets/sprites/snake_2.png")
const KENNEY_DOG_TEXTURE = preload("res://assets/sprites/junkyard_dog_2.png")
const KENNEY_BUTTON_TEXTURE = preload("res://assets/kenney/ui/button_brown.png")
const KENNEY_BUTTON_PRESSED_TEXTURE = preload("res://assets/kenney/ui/button_red.png")

func _ready() -> void:
	layer = 100
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_game_hud()
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
	label.add_theme_color_override("font_outline_color", dark)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 4)
	label.add_theme_color_override("font_shadow_color", Color(0.07, 0.03, 0.05, 0.55))
	return label

func _panel_style(color: Color, border: Color, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(4)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	style.shadow_color = Color(0.12, 0.05, 0.07, 0.45)
	style.shadow_size = 7
	style.shadow_offset = Vector2(5, 7)
	return style

func _textured_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 12.0
	style.texture_margin_top = 8.0
	style.texture_margin_right = 12.0
	style.texture_margin_bottom = 8.0
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(310, 58)
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", dark)
	button.add_theme_color_override("font_focus_color", dark)
	button.add_theme_color_override("font_hover_color", dark)
	button.add_theme_color_override("font_pressed_color", pale)
	button.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.28))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _panel_style(Color("f6c53f"), dark, 9))
	button.add_theme_stylebox_override("hover", _panel_style(Color("ffe581"), dark, 9))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("df5144"), dark, 9))
	button.add_theme_stylebox_override("focus", _focus_style())
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(func():
		ui_sound_requested.emit("ui_hover")
		_wiggle_control(button, true)
	)
	button.mouse_exited.connect(func(): _wiggle_control(button, false))
	button.pressed.connect(func(): ui_sound_requested.emit("ui_click"))
	return button

func _focus_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = Color("f6c53f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_expand_margin_all(5)
	return style

func _wiggle_control(control: Control, hovered: bool) -> void:
	control.pivot_offset = control.size * 0.5
	var tween := control.create_tween().set_parallel(true)
	tween.tween_property(control, "scale", Vector2(1.055, 1.055) if hovered else Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK)
	tween.tween_property(control, "rotation", deg_to_rad(-1.5) if hovered else 0.0, 0.12)

func _build_game_hud() -> void:
	score_label = _label("SNACK-FUND 000000", 25, pale)
	score_label.position = Vector2(28, 20)
	root.add_child(score_label)
	wave_label = _label("TROUBLE 0", 20, cyan)
	wave_label.position = Vector2(30, 57)
	root.add_child(wave_label)
	kills_label = _label("0 GOONS BONKED", 15, pale)
	kills_label.position = Vector2(30, 87)
	root.add_child(kills_label)

	var health_panel := PanelContainer.new()
	health_panel.position = Vector2(28, 625)
	health_panel.size = Vector2(330, 66)
	health_panel.add_theme_stylebox_override("panel", _panel_style(Color(1.0, 0.96, 0.83, 0.94), dark, 14))
	root.add_child(health_panel)
	var health_box := VBoxContainer.new()
	health_panel.add_child(health_box)
	health_label = _label("TAIL STATUS 100 / 100", 14, pale)
	health_box.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(290, 16)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	health_bar.add_theme_stylebox_override("background", _panel_style(Color("d8caa8"), dark, 6))
	health_bar.add_theme_stylebox_override("fill", _panel_style(Color("d95863"), Color("8f3e4e"), 6))
	health_box.add_child(health_bar)

	var wave_panel := PanelContainer.new()
	wave_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	wave_panel.position = Vector2(-205, 20)
	wave_panel.size = Vector2(410, 62)
	wave_panel.add_theme_stylebox_override("panel", _panel_style(Color(1.0, 0.96, 0.83, 0.94), dark, 14))
	root.add_child(wave_panel)
	var wave_box := VBoxContainer.new()
	wave_panel.add_child(wave_box)
	var incoming := _label("GARDEN PANIC-O-METER", 13, Color("f6c53f"))
	incoming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_box.add_child(incoming)
	wave_bar = ProgressBar.new()
	wave_bar.custom_minimum_size = Vector2(370, 13)
	wave_bar.max_value = 1.0
	wave_bar.value = 0.0
	wave_bar.show_percentage = false
	wave_bar.add_theme_stylebox_override("background", _panel_style(Color("d8caa8"), dark, 5))
	wave_bar.add_theme_stylebox_override("fill", _panel_style(cyan, Color("356b60"), 5))
	wave_box.add_child(wave_bar)

	buffs_label = _label("NO SHOW-OFFS YET", 15, pale)
	buffs_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	buffs_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	buffs_label.position = Vector2(-370, 22)
	buffs_label.size = Vector2(340, 120)
	root.add_child(buffs_label)
	autofire_label = _label("AUTO-FIRE: ON  [F]", 14, cyan)
	autofire_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	autofire_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	autofire_label.position = Vector2(-295, -54)
	autofire_label.size = Vector2(265, 26)
	root.add_child(autofire_label)
	var dash_panel := PanelContainer.new()
	dash_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	dash_panel.position = Vector2(-350, -140)
	dash_panel.size = Vector2(320, 48)
	dash_panel.add_theme_stylebox_override("panel", _panel_style(Color(1.0, 0.96, 0.83, 0.94), dark, 12))
	root.add_child(dash_panel)
	var dash_box := VBoxContainer.new()
	dash_panel.add_child(dash_box)
	dash_label = _label("SCURRY READY  [SHIFT / RB]", 12, cyan)
	dash_box.add_child(dash_label)
	dash_bar = ProgressBar.new()
	dash_bar.custom_minimum_size = Vector2(280, 8)
	dash_bar.max_value = 1.0
	dash_bar.value = 1.0
	dash_bar.show_percentage = false
	dash_bar.add_theme_stylebox_override("background", _panel_style(Color("d8caa8"), dark, 4))
	dash_bar.add_theme_stylebox_override("fill", _panel_style(Color("f2c14e"), Color("a97925"), 4))
	dash_box.add_child(dash_bar)

	var controls := _label("WASD MOVE   •   MOUSE AIM   •   SHIFT DASH   •   F AUTO-FIRE   •   P / ESC PAUSE", 13, pale)
	control_hint = controls
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	controls.position = Vector2(-350, -28)
	controls.size = Vector2(700, 20)
	root.add_child(controls)

	banner_label = _label("WAVE 1", 48, Color.WHITE)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner_label.position = Vector2(-400, 145)
	banner_label.size = Vector2(800, 70)
	banner_label.modulate.a = 0.0
	root.add_child(banner_label)
	toast_label = _label("RAPID CLAWS", 24, cyan)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast_label.position = Vector2(-350, -145)
	toast_label.size = Vector2(700, 42)
	toast_label.modulate.a = 0.0
	root.add_child(toast_label)
	combo_label = _label("BONK STREAK x1", 18, Color("f6c53f"))
	combo_label.position = Vector2(30, 117)
	root.add_child(combo_label)
	combo_bar = ProgressBar.new()
	combo_bar.position = Vector2(30, 145)
	combo_bar.size = Vector2(170, 9)
	combo_bar.max_value = 1.0
	combo_bar.show_percentage = false
	root.add_child(combo_bar)
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
	var backdrop := SillyMenuBackdropScript.new()
	menu_overlay.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(760, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	var eyebrow := _label("A NEEDLESSLY DRAMATIC TALE OF CHEESE", 17, Color("f6c53f"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var title := _label("PROJECT R.A.T.", 72, pale)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.rotation = deg_to_rad(-1.2)
	box.add_child(title)
	var subtitle := _label("RUN  •  BITE  •  CAUSE A SCENE", 24, pink)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	var critter_row := HBoxContainer.new()
	critter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	critter_row.add_theme_constant_override("separation", -2)
	for texture in [KENNEY_PARROT_TEXTURE, KENNEY_OWL_TEXTURE, KENNEY_SNAKE_TEXTURE, KENNEY_DOG_TEXTURE]:
		var critter := TextureRect.new()
		critter.texture = texture
		critter.custom_minimum_size = Vector2(64, 64)
		critter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		critter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		critter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		critter_row.add_child(critter)
	box.add_child(critter_row)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 7
	box.add_child(spacer)
	var description := _label("A peaceful picnic. A suspicious cheese. Absolutely no adult supervision.\nBonk the garden goons and hoard upgrades of questionable safety.", 18, pale)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)
	var start_button := _button("START THE BAD IDEA")
	menu_start = start_button
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(func(): start_requested.emit())
	box.add_child(start_button)
	var options := _button("COMFORT & CONTROLS")
	options.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	options.pressed.connect(func(): settings_requested.emit())
	box.add_child(options)
	var help := _label("WASD move  •  Mouse aim  •  Shift scurry  •  F auto-fire  •  Common sense optional", 13, pale)
	menu_help = help
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help)

func _build_game_over() -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.color = Color(0.20, 0.07, 0.09, 0.94)
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
	var title := _label("THE GARDEN WON. RUDE.", 45, pink)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	final_score_label = _label("000000", 66, pale)
	final_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(final_score_label)
	final_detail_label = _label("WAVE 0  •  0 RASCALS SHOOED", 20, cyan)
	final_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(final_detail_label)
	best_label = _label("BEST 000000", 17, Color("ffe66d"))
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(best_label)
	death_tip = _label("", 18, pale)
	death_tip.custom_minimum_size.x = 800
	death_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	death_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(death_tip)
	var restart := _button("BLAME LAG & RETRY")
	retry_button = restart
	restart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart.pressed.connect(func(): restart_requested.emit())
	box.add_child(restart)
	var menu := Button.new()
	menu.text = "SULK AT TITLE"
	menu.custom_minimum_size = Vector2(240, 42)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.add_theme_font_size_override("font_size", 16)
	menu.pressed.connect(func(): quit_to_menu_requested.emit())
	box.add_child(menu)
	game_over_overlay.hide()

func _build_pause() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.12, 0.08, 0.07, 0.88)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root.add_child(pause_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 850
	column.add_theme_constant_override("separation", 18)
	center.add_child(column)
	var title := _label("TACTICAL SNACK BREAK", 36, pale)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(850, 160)
	column.add_child(scroll)
	build_label = _label("", 20, pale)
	build_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	build_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	scroll.add_child(build_label)
	resume_button = _button("RESUME THE CHAOS")
	resume_button.pressed.connect(func(): resume_requested.emit())
	column.add_child(resume_button)
	var options := _button("COMFORT & CONTROLS")
	options.pressed.connect(func(): settings_requested.emit())
	column.add_child(options)
	var menu := _button("RETURN TO TITLE")
	menu.pressed.connect(func(): quit_to_menu_requested.emit())
	column.add_child(menu)
	pause_overlay.hide()

func _build_upgrade_draft() -> void:
	upgrade_overlay = ColorRect.new()
	upgrade_overlay.color = Color(0.11, 0.19, 0.11, 0.95)
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
	var eyebrow := _label("SOMEHOW, YOU SURVIVED", 17, Color("f6c53f"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(eyebrow)
	var title := _label("CHOOSE A TERRIBLE IDEA", 45, pale)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	var subtitle := _label("Permanent for this run • Side effects probably hilarious", 16, pale)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(subtitle)
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
		card.text = "[%d]  %s\n\n%s" % [index + 1, data["title"], data["description"]]
		card.custom_minimum_size = Vector2(350, 245)
		card.add_theme_font_size_override("font_size", 21 if large_text else 18)
		# The normal card is pale, so pale text disappears into its background.
		# Keep the default and hover states dark, then switch to the light palette
		# only while the pressed card uses its saturated upgrade color.
		card.add_theme_color_override("font_color", dark)
		card.add_theme_color_override("font_focus_color", dark)
		card.add_theme_color_override("font_hover_color", dark)
		card.add_theme_color_override("font_pressed_color", pale)
		card.add_theme_color_override("font_outline_color", Color(1.0, 1.0, 1.0, 0.35))
		card.add_theme_constant_override("outline_size", 2)
		var card_color: Color = data["color"]
		card.add_theme_stylebox_override("normal", _panel_style(Color("fff4d6"), dark, 18))
		card.add_theme_stylebox_override("hover", _panel_style(card_color.lightened(0.30), dark, 18))
		card.add_theme_stylebox_override("pressed", _panel_style(card_color, dark, 18))
		card.add_theme_stylebox_override("focus", _focus_style())
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.mouse_entered.connect(func():
			ui_sound_requested.emit("ui_hover")
			_wiggle_control(card, true)
		)
		card.mouse_exited.connect(func(): _wiggle_control(card, false))
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
	victory_overlay.hide()
	menu_overlay.show()
	game_over_overlay.hide()
	pause_overlay.hide()
	upgrade_overlay.hide()
	set_game_hud_visible(false)
	menu_start.grab_focus()

func begin_game() -> void:
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
	score_label.text = "SNACK-FUND %06d" % score
	wave_label.text = "TROUBLE %d" % wave
	kills_label.text = "%d GOONS BONKED" % kills
	health_label.text = "TAIL STATUS %d / %d" % [ceil(health), ceil(max_health)]
	health_bar.max_value = max_health
	health_bar.value = health
	wave_bar.value = clamp(progress, 0.0, 1.0)
	buffs_label.text = "\n".join(buffs) if not buffs.is_empty() else "NO SHOW-OFFS YET"
	dash_bar.value = dash_charge
	dash_label.text = "DASH READY [%s / RB]" % dash_key if dash_charge >= 0.999 else "DASH %.1fs" % ((1.0 - dash_charge) * 1.35)
	dash_label.add_theme_color_override("font_color", Color("f2c14e") if dash_charge >= 0.999 else pale)

func set_autofire(enabled: bool) -> void:
	autofire_label.text = "AUTO-FIRE: %s  [%s]" % ["ON" if enabled else "OFF", fire_key]
	autofire_label.add_theme_color_override("font_color", Color("f2c14e") if enabled else pale)

func show_wave_banner(wave: int, boss_kind: String = "") -> void:
	var boss_names := {
		"alpha_cat": "THE CAT HAS MANAGEMENT EXPERIENCE!",
		"junkyard_dog": "BIG DOG. ZERO LEASH. GREAT.",
		"barn_owl": "THE OWL KNOWS WHAT YOU DID!",
	}
	banner_label.text = String(boss_names.get(boss_kind, "TROUBLE, ROUND %d!" % wave))
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

func show_toast(text: String, color: Color) -> void:
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
	tween.tween_interval(0.75)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)

func show_game_over(score: int, wave: int, kills: int, best: int, is_new_best: bool) -> void:
	set_game_hud_visible(false)
	game_over_overlay.show()
	retry_button.grab_focus()
	final_score_label.text = "%06d" % score
	final_detail_label.text = "TROUBLE %d  •  %d GOONS BONKED" % [wave, kills]
	best_label.text = "NEW BEST! %06d" % best if is_new_best else "BEST %06d" % best

func set_paused(paused: bool) -> void:
	pause_overlay.visible = paused
	if paused:
		resume_button.grab_focus()

func update_combo(multiplier: int, remaining: float) -> void:
	combo_label.text = "BONK STREAK x%d" % multiplier
	combo_label.add_theme_color_override("font_color", Color("f6c53f") if multiplier >= 4 else pale)
	combo_bar.value = remaining

func set_encounter(title: String) -> void:
	encounter_label.text = title

func set_build_text(text: String) -> void:
	build_label.text = text

func set_control_labels(keys: Dictionary) -> void:
	dash_key = OS.get_keycode_string(keys["dash"])
	fire_key = OS.get_keycode_string(keys["toggle_autofire"])
	var movement := "%s/%s/%s/%s" % [OS.get_keycode_string(keys["move_up"]), OS.get_keycode_string(keys["move_left"]), OS.get_keycode_string(keys["move_down"]), OS.get_keycode_string(keys["move_right"])]
	control_hint.text = "%s MOVE / MOUSE AIM / %s DASH / ESC PAUSE" % [movement, dash_key]
	menu_help.text = "%s move / Mouse aim / %s dash / Controller supported" % [movement, dash_key]

func update_tip(player: Node, wave: int, enabled: bool) -> void:
	if not enabled or wave > 3:
		tip_label.text = ""
	elif player.distance_walked < 150:
		tip_label.text = "Move with your movement keys or left stick."
	elif player.dash_count == 0:
		tip_label.text = "Dash through danger! %s or RB. Briefly invulnerable." % dash_key
	elif wave <= 1:
		tip_label.text = "Aim with mouse or right stick. Firing is automatic. Clear the wave to choose a build."
	else:
		tip_label.text = "Reach streak x8 for Rapid Claws! Yellow attack line: wind-up. Red: step aside!"

func show_death_tip(source: String, streak: int, new_wave: bool) -> void:
	var advice := {
		"fox": "Fox dash: step sideways when its charge line turns red.",
		"cat": "Cat pounce: dash across its path after the red line locks.",
		"alpha_cat": "Alpha Cat: dodge the pounce, then watch for the ring of shots.",
		"feather": "Feather volley: watch the wind-up and move across the firing line.",
		"venom": "Snake venom: keep moving sideways as the snake winds up.",
		"sonic": "Sonic ring: dash through a gap in the expanding shots.",
		"bone": "Bone burst: leave space around the dog after its charge.",
		"raccoon": "Raccoon: bait the charge, then hit it during recovery.",
		"junkyard_dog": "Dog charge: step off the red line and punish its recovery.",
		"bird": "Bird swarm: keep a route open and dash before you are surrounded.",
	}
	death_tip.text = "%s\nBest streak x%d%s" % [advice.get(source, "Keep an escape route open and use your invulnerable dash."), streak, " / NEW WAVE RECORD!" if new_wave else ""]

func _build_victory() -> void:
	victory_overlay = ColorRect.new()
	victory_overlay.color = Color("213a31")
	victory_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(victory_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	victory_overlay.add_child(center)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	center.add_child(column)
	var title := _label("THE PICNIC IS SAVED!", 52, Color("f6c53f"))
	column.add_child(title)
	var detail := _label("", 22, pale)
	detail.name = "VictoryDetail"
	column.add_child(detail)
	overtime_button = _button("KEEP GOING: ENDLESS OVERTIME")
	overtime_button.pressed.connect(func(): overtime_requested.emit())
	column.add_child(overtime_button)
	var done := _button("CELEBRATE AT THE TITLE")
	done.pressed.connect(func(): quit_to_menu_requested.emit())
	column.add_child(done)
	victory_overlay.hide()

func show_victory(score: int, streak: int) -> void:
	set_game_hud_visible(false)
	victory_overlay.show()
	var detail := victory_overlay.find_child("VictoryDetail", true, false) as Label
	detail.text = "15 waves / 3 bosses / %d points / Best streak x%d" % [score, streak]
	overtime_button.grab_focus()

func hide_victory() -> void:
	victory_overlay.hide()
	set_game_hud_visible(true)
