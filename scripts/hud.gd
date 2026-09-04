extends CanvasLayer

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

var cyan := Color("4f9f8f")
var pink := Color("d95863")
var pale := Color("fff4d6")
var dark := Color("40354f")

const KENNEY_PARROT_TEXTURE = preload("res://assets/kenney/animals/parrot.png")
const KENNEY_OWL_TEXTURE = preload("res://assets/kenney/animals/owl.png")
const KENNEY_SNAKE_TEXTURE = preload("res://assets/kenney/animals/snake.png")
const KENNEY_DOG_TEXTURE = preload("res://assets/kenney/animals/dog.png")
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

func _label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("40354f"))
	label.add_theme_constant_override("outline_size", 5)
	return label

func _panel_style(color: Color, border: Color, radius: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 18.0
	style.content_margin_right = 18.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	style.shadow_color = Color(0.25, 0.18, 0.20, 0.22)
	style.shadow_size = 5
	style.shadow_offset = Vector2(3, 4)
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
	button.add_theme_color_override("font_hover_color", dark)
	button.add_theme_stylebox_override("normal", _textured_style(KENNEY_BUTTON_TEXTURE))
	button.add_theme_stylebox_override("hover", _textured_style(KENNEY_BUTTON_TEXTURE))
	button.add_theme_stylebox_override("pressed", _textured_style(KENNEY_BUTTON_PRESSED_TEXTURE))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_entered.connect(func(): ui_sound_requested.emit("ui_hover"))
	button.pressed.connect(func(): ui_sound_requested.emit("ui_click"))
	return button

func _build_game_hud() -> void:
	score_label = _label("SCORE 000000", 28, pale)
	score_label.position = Vector2(28, 20)
	root.add_child(score_label)
	wave_label = _label("WAVE 0", 20, cyan)
	wave_label.position = Vector2(30, 57)
	root.add_child(wave_label)
	kills_label = _label("0 RASCALS SHOOED", 15, pale)
	kills_label.position = Vector2(30, 87)
	root.add_child(kills_label)

	var health_panel := PanelContainer.new()
	health_panel.position = Vector2(28, 625)
	health_panel.size = Vector2(330, 66)
	health_panel.add_theme_stylebox_override("panel", _panel_style(Color(1.0, 0.96, 0.83, 0.94), dark, 14))
	root.add_child(health_panel)
	var health_box := VBoxContainer.new()
	health_panel.add_child(health_box)
	health_label = _label("RAT VITALITY 100 / 100", 14, pale)
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
	var incoming := _label("PICNIC PERIMETER", 13, Color("f2c14e"))
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

	buffs_label = _label("NO ACTIVE PERKS", 15, pale)
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
	dash_label = _label("DASH READY  [SHIFT / RB]", 12, cyan)
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
	gameplay_hud = [score_label, wave_label, kills_label, health_panel, wave_panel, buffs_label, autofire_label, dash_panel, controls, banner_label, toast_label]

func _build_menu() -> void:
	menu_overlay = ColorRect.new()
	menu_overlay.color = Color(0.18, 0.28, 0.18, 0.89)
	menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(menu_overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_overlay.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(680, 0)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 13)
	center.add_child(box)
	var eyebrow := _label("A VERY SERIOUS BACKYARD ADVENTURE", 17, Color("f2c14e"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(eyebrow)
	var title := _label("PROJECT R.A.T.", 68, pale)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var subtitle := _label("RUN  •  AIM  •  SNACK", 25, Color("ef6f6c"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(subtitle)
	var critter_row := HBoxContainer.new()
	critter_row.alignment = BoxContainer.ALIGNMENT_CENTER
	critter_row.add_theme_constant_override("separation", 14)
	for texture in [KENNEY_PARROT_TEXTURE, KENNEY_OWL_TEXTURE, KENNEY_SNAKE_TEXTURE, KENNEY_DOG_TEXTURE]:
		var critter := TextureRect.new()
		critter.texture = texture
		critter.custom_minimum_size = Vector2(72, 72)
		critter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		critter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		critter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		critter_row.add_child(critter)
	box.add_child(critter_row)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 16
	box.add_child(spacer)
	var description := _label("The picnic is under attack! Dodge the flock, crack enemy armour,\nand stack silly perks before the backyard gets truly wild.", 19, pale)
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(description)
	var start_button := _button("DEFEND THE PICNIC")
	start_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_button.pressed.connect(func(): start_requested.emit())
	box.add_child(start_button)
	var help := _label("WASD to move  •  Mouse to aim  •  Shift to dash  •  F toggles auto-fire  •  Gamepad supported", 14, pale)
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(help)

func _build_game_over() -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.color = Color(0.29, 0.16, 0.18, 0.93)
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
	var title := _label("THE PICNIC WAS OVERRUN!", 45, Color("ef6f6c"))
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
	var restart := _button("TRY ANOTHER ROUND")
	restart.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart.pressed.connect(func(): restart_requested.emit())
	box.add_child(restart)
	var menu := Button.new()
	menu.text = "RETURN TO TITLE"
	menu.custom_minimum_size = Vector2(240, 42)
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.add_theme_font_size_override("font_size", 16)
	menu.pressed.connect(func(): quit_to_menu_requested.emit())
	box.add_child(menu)
	game_over_overlay.hide()

func _build_pause() -> void:
	pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.20, 0.25, 0.15, 0.84)
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	root.add_child(pause_overlay)
	var text := _label("PICNIC BREAK\n\nP / ESC TO RETURN", 36, pale)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.add_child(text)
	pause_overlay.hide()

func _build_upgrade_draft() -> void:
	upgrade_overlay = ColorRect.new()
	upgrade_overlay.color = Color(0.22, 0.28, 0.17, 0.93)
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
	var eyebrow := _label("ROUND SURVIVED", 17, Color("f2c14e"))
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(eyebrow)
	var title := _label("PICK A PERK", 45, pale)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(title)
	var subtitle := _label("Permanent for this run • Pick one", 16, pale)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(subtitle)
	upgrade_cards = HBoxContainer.new()
	upgrade_cards.add_theme_constant_override("separation", 18)
	stack.add_child(upgrade_cards)
	upgrade_overlay.hide()

func show_upgrade_draft(options: Array[Dictionary]) -> void:
	for child in upgrade_cards.get_children():
		child.queue_free()
	for index in range(options.size()):
		var data := options[index]
		var card := Button.new()
		card.text = "[%d]  %s\n\n%s" % [index + 1, data["title"], data["description"]]
		card.custom_minimum_size = Vector2(330, 175)
		card.add_theme_font_size_override("font_size", 18)
		card.add_theme_color_override("font_color", pale)
		card.add_theme_color_override("font_hover_color", Color.WHITE)
		var card_color: Color = data["color"]
		card.add_theme_stylebox_override("normal", _panel_style(Color("fff4d6"), dark, 18))
		card.add_theme_stylebox_override("hover", _panel_style(card_color.lightened(0.30), dark, 18))
		card.add_theme_stylebox_override("pressed", _panel_style(card_color, dark, 18))
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.mouse_entered.connect(func(): ui_sound_requested.emit("ui_hover"))
		card.pressed.connect(_on_upgrade_card_pressed.bind(String(data["id"])))
		upgrade_cards.add_child(card)
	upgrade_overlay.show()

func _on_upgrade_card_pressed(id: String) -> void:
	ui_sound_requested.emit("ui_click")
	upgrade_selected.emit(id)

func hide_upgrade_draft() -> void:
	upgrade_overlay.hide()

func show_menu() -> void:
	menu_overlay.show()
	game_over_overlay.hide()
	pause_overlay.hide()
	upgrade_overlay.hide()
	set_game_hud_visible(false)

func begin_game() -> void:
	menu_overlay.hide()
	game_over_overlay.hide()
	pause_overlay.hide()
	upgrade_overlay.hide()
	set_game_hud_visible(true)

func set_game_hud_visible(enabled: bool) -> void:
	for node in gameplay_hud:
		node.visible = enabled

func update_stats(score: int, wave: int, kills: int, health: float, max_health: float, progress: float, buffs: Array[String], dash_charge: float = 1.0) -> void:
	score_label.text = "SCORE %06d" % score
	wave_label.text = "WAVE %d" % wave
	kills_label.text = "%d RASCALS SHOOED" % kills
	health_label.text = "RAT VITALITY %d / %d" % [ceil(health), ceil(max_health)]
	health_bar.max_value = max_health
	health_bar.value = health
	wave_bar.value = clamp(progress, 0.0, 1.0)
	buffs_label.text = "\n".join(buffs) if not buffs.is_empty() else "NO ACTIVE PERKS"
	dash_bar.value = dash_charge
	dash_label.text = "DASH READY  [SHIFT / RB]" if dash_charge >= 0.999 else "DASH RECHARGING"
	dash_label.add_theme_color_override("font_color", Color("f2c14e") if dash_charge >= 0.999 else pale)

func set_autofire(enabled: bool) -> void:
	autofire_label.text = "AUTO-FIRE: %s  [F]" % ("ON" if enabled else "OFF")
	autofire_label.add_theme_color_override("font_color", Color("f2c14e") if enabled else pale)

func show_wave_banner(wave: int, boss_kind: String = "") -> void:
	var boss_names := {
		"alpha_cat": "ALPHA CAT POUNCES IN!",
		"junkyard_dog": "JUNKYARD DOG BREAKS LOOSE!",
		"barn_owl": "BARN OWL SWOOPS IN!",
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

func show_toast(text: String, color: Color) -> void:
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	toast_label.modulate.a = 0.0
	toast_label.scale = Vector2(0.82, 0.82)
	toast_label.pivot_offset = toast_label.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.12)
	tween.tween_property(toast_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK)
	tween.set_parallel(false)
	tween.tween_interval(0.75)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)

func show_game_over(score: int, wave: int, kills: int, best: int, is_new_best: bool) -> void:
	set_game_hud_visible(false)
	game_over_overlay.show()
	final_score_label.text = "%06d" % score
	final_detail_label.text = "WAVE %d  •  %d RASCALS SHOOED" % [wave, kills]
	best_label.text = "NEW BEST! %06d" % best if is_new_best else "BEST %06d" % best

func set_paused(paused: bool) -> void:
	pause_overlay.visible = paused
