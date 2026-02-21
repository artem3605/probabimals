extends Node

const COLOR_GOLD := Color(0.95, 0.78, 0.2)
const COLOR_GOLD_DARK := Color(0.7, 0.55, 0.1)
const COLOR_BG_DARK := Color(0.08, 0.08, 0.1, 0.92)
const COLOR_BG_PANEL := Color(0.1, 0.1, 0.14, 0.88)
const COLOR_BORDER := Color(0.7, 0.55, 0.15, 0.7)
const COLOR_TEXT := Color(0.95, 0.93, 0.88)
const COLOR_TEXT_MUTED := Color(0.6, 0.58, 0.52)
const COLOR_RED := Color(0.9, 0.25, 0.2)
const COLOR_GREEN := Color(0.2, 0.85, 0.35)
const COLOR_CYAN := Color(0.3, 0.9, 0.95)
const COLOR_MAGENTA := Color(0.9, 0.3, 0.7)

var font_regular: Font
var font_bold: Font
var font_semibold: Font
var game_theme: Theme

func _ready() -> void:
	font_regular = load("res://assets/fonts/Fredoka-Regular.ttf")
	font_semibold = load("res://assets/fonts/Fredoka-SemiBold.ttf")
	font_bold = load("res://assets/fonts/Fredoka-Bold.ttf")
	game_theme = _build_theme()

func _build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = font_semibold
	theme.default_font_size = 20

	_setup_button_styles(theme)
	_setup_label_styles(theme)
	_setup_panel_styles(theme)

	return theme

func _setup_button_styles(theme: Theme) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = COLOR_BG_DARK
	normal.border_color = COLOR_GOLD_DARK
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	normal.set_content_margin_all(16)

	var hover := normal.duplicate()
	hover.bg_color = Color(0.12, 0.12, 0.16, 0.95)
	hover.border_color = COLOR_GOLD

	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.06, 0.06, 0.08, 0.95)
	pressed.border_color = COLOR_GOLD

	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.06, 0.06, 0.08, 0.5)
	disabled.border_color = Color(0.3, 0.3, 0.3, 0.3)

	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_color("font_color", "Button", COLOR_GOLD)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", COLOR_GOLD_DARK)
	theme.set_color("font_disabled_color", "Button", COLOR_TEXT_MUTED)
	theme.set_font("font", "Button", font_semibold)
	theme.set_font_size("font_size", "Button", 22)

func _setup_label_styles(theme: Theme) -> void:
	theme.set_color("font_color", "Label", COLOR_TEXT)
	theme.set_font("font", "Label", font_semibold)
	theme.set_font_size("font_size", "Label", 20)
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.4))

func _setup_panel_styles(theme: Theme) -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_PANEL
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(10)
	panel_style.set_content_margin_all(12)
	theme.set_stylebox("panel", "PanelContainer", panel_style)
	theme.set_stylebox("panel", "Panel", panel_style)

	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0.05, 0.05, 0.07, 0.5)
	scroll_bg.set_corner_radius_all(8)
	theme.set_stylebox("panel", "ScrollContainer", scroll_bg)

func make_panel_style(color: Color = COLOR_BG_PANEL, border: Color = COLOR_BORDER, radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(12)
	return style

func make_accent_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(18)
	return style
