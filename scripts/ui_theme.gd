extends RefCounted

const DISPLAY = preload("res://assets/fonts/Newsreader.ttf")
const BODY = preload("res://assets/fonts/DMSans.ttf")
const INK := Color("101013")
const PAPER := Color("ded8cc")
const SURFACE := Color("211e20")
const LINE := Color("443c3a")
const MUTED := Color("b0a59d")
const ACCENT := Color("963c3b")
const HUD_MUTED := Color("c3b9ab")
const HUD_LINE := Color("4a4240")
const DANGER := Color("c35c50")

static func panel(color: Color = Color.TRANSPARENT, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	style.set_corner_radius_all(4)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

static func flat_bar(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(2)
	return style

static func focus() -> StyleBoxFlat:
	var style := panel(Color.TRANSPARENT, ACCENT)
	style.draw_center = false
	style.set_border_width_all(2)
	style.set_expand_margin_all(3)
	return style

static func make() -> Theme:
	var theme := Theme.new()
	theme.default_font = BODY
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", PAPER)
	for type in ["Button", "CheckButton"]:
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(state, type, PAPER)
		theme.set_stylebox("normal", type, panel())
		theme.set_stylebox("hover", type, panel(SURFACE))
		theme.set_stylebox("pressed", type, panel(Color("322626")))
		theme.set_stylebox("focus", type, focus())
	theme.set_icon("checked", "CheckButton", preload("res://assets/ui/toggle-on.svg"))
	theme.set_icon("unchecked", "CheckButton", preload("res://assets/ui/toggle-off.svg"))
	for state in ["normal", "hover", "pressed"]:
		var row := panel(SURFACE if state == "hover" else Color.TRANSPARENT)
		row.content_margin_left = 0
		row.content_margin_right = 0
		row.border_color = LINE
		row.border_width_bottom = 1
		theme.set_stylebox(state, "CheckButton", row)
	theme.set_stylebox("background", "ProgressBar", flat_bar(HUD_LINE))
	theme.set_stylebox("fill", "ProgressBar", flat_bar(PAPER))
	var track := flat_bar(LINE)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", flat_bar(ACCENT))
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat_bar(INK))
	theme.set_icon("grabber", "HSlider", preload("res://assets/ui/slider-knob.svg"))
	theme.set_icon("grabber_highlight", "HSlider", preload("res://assets/ui/slider-knob.svg"))
	return theme
