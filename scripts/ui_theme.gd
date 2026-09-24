extends RefCounted

const DISPLAY = preload("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
const INK := Color("101211")
const SURFACE := Color("191c19")
const LINE := Color("3b4039")
const PAPER := Color("e5e1d5")
const MUTED := Color("9ba294")
const ACCENT := Color("bb5545")

static func panel(color: Color = SURFACE, border: Color = LINE) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func flat_bar(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	return style

static func focus() -> StyleBoxFlat:
	var style := panel(Color.TRANSPARENT, PAPER)
	style.draw_center = false
	style.set_border_width_all(2)
	style.set_expand_margin_all(4)
	return style

static func make() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", PAPER)
	for type in ["Button", "CheckButton"]:
		for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			theme.set_color(state, type, PAPER)
		theme.set_stylebox("normal", type, panel())
		theme.set_stylebox("hover", type, panel(Color("272c26"), MUTED))
		theme.set_stylebox("pressed", type, panel(Color("363c32"), PAPER))
		theme.set_stylebox("focus", type, focus())
	theme.set_icon("checked", "CheckButton", preload("res://assets/ui/toggle-on.svg"))
	theme.set_icon("unchecked", "CheckButton", preload("res://assets/ui/toggle-off.svg"))
	theme.set_stylebox("background", "ProgressBar", flat_bar(LINE))
	theme.set_stylebox("fill", "ProgressBar", flat_bar(MUTED))
	var track := flat_bar(LINE)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	theme.set_stylebox("slider", "HSlider", track)
	theme.set_stylebox("grabber_area", "HSlider", flat_bar(MUTED))
	theme.set_stylebox("grabber_area_highlight", "HSlider", flat_bar(PAPER))
	return theme
