extends Control
## Base class for screens that share the pixel-art background style:
## sky-blue fill, faint grid overlay, dark square strips at top & bottom.

const BG_COLOR := Color("87ceeb")
const DARK := Color("1a1a1a")
const GOLD := Color("ffd700")
const BORDER_BLACK := Color("000000")
const SHADOW_COLOR := Color(0, 0, 0, 0.5)

const PINK := Color("ff69b4")
const GREEN := Color("9acd32")
const BLUE := Color("4a9eff")
const DISABLED_BG := Color("99a1af")
const DISABLED_TEXT := Color("4a5565")

const DIE_COLORS := {
	"colorless": Color.WHITE,
	"red": Color("ff4444"),
	"green": Color("9acd32"),
	"blue": Color("4a9eff"),
	"gold": Color("ffd700"),
	"purple": Color("9b59b6"),
}

const STRIP_H := 32.0
const BOTTOM_SQUARE_SIZE := 32.0
const BOTTOM_SQUARE_COUNT := 12

var _pixel_font: Font


func _ready() -> void:
	_pixel_font = load("res://assets/fonts/PressStart2P-Regular.ttf")


func _draw_pixel_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)


func _draw_grid_overlay() -> void:
	var col := Color(0, 0, 0, 0.10)
	var cell := 32.0
	var cols := int(size.x / cell)
	var rows := int(size.y / cell)
	for i in range(1, cols):
		var x := float(i) * cell
		draw_line(Vector2(x, 0), Vector2(x, size.y), col, 1.0)
	for j in range(1, rows):
		var y := float(j) * cell
		draw_line(Vector2(0, y), Vector2(size.x, y), col, 1.0)


func _draw_top_strip() -> void:
	var count := ceili(size.x / STRIP_H)
	var w := size.x / float(count)
	for i in count:
		draw_rect(Rect2(float(i) * w, 0, w - 1.0, STRIP_H), DARK)


func _draw_bottom_strip() -> void:
	var y := size.y - BOTTOM_SQUARE_SIZE - 16.0
	var total_w := float(BOTTOM_SQUARE_COUNT) * BOTTOM_SQUARE_SIZE
	var spacing := (size.x - total_w) / float(BOTTOM_SQUARE_COUNT + 1)
	for i in BOTTOM_SQUARE_COUNT:
		var x := spacing + float(i) * (BOTTOM_SQUARE_SIZE + spacing)
		draw_rect(Rect2(x, y, BOTTOM_SQUARE_SIZE, BOTTOM_SQUARE_SIZE), DARK)


func _draw_all_bg() -> void:
	_draw_pixel_background()
	_draw_grid_overlay()


## Create a pixel-style button (dark bg, gold text, black border, drop shadow).
func _make_pixel_button(text: String, min_size: Vector2, font_size: int = 16) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_override("font", _pixel_font)
	btn.add_theme_font_size_override("font_size", font_size)

	btn.add_theme_stylebox_override("normal", _make_style(DARK))
	btn.add_theme_stylebox_override("hover", _make_style(Color("2a2a2a")))
	btn.add_theme_stylebox_override("pressed", _make_style(Color("0a0a0a")))

	var focus := _make_style(DARK, GOLD)
	focus.bg_color = Color(0, 0, 0, 0)
	btn.add_theme_stylebox_override("focus", focus)

	btn.add_theme_color_override("font_color", GOLD)
	btn.add_theme_color_override("font_hover_color", GOLD)
	btn.add_theme_color_override("font_pressed_color", Color("ccaa00"))
	btn.add_theme_color_override("font_focus_color", GOLD)

	return btn


## Create a StyleBoxFlat with pixel-art defaults (0 corner radius).
func _make_style(bg_color: Color, border_color: Color = BORDER_BLACK,
		border_width: int = 4, margin: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(margin)
	return sb


## Create a colored button with dark text (for pink/green/blue action buttons).
func _make_colored_button(text: String, min_size: Vector2, bg_color: Color,
		hover_color: Color, font_size: int = 16) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_override("font", _pixel_font)
	btn.add_theme_font_size_override("font_size", font_size)

	btn.add_theme_stylebox_override("normal", _make_style(bg_color))
	btn.add_theme_stylebox_override("hover", _make_style(hover_color))
	btn.add_theme_stylebox_override("disabled", _make_style(DISABLED_BG))

	btn.add_theme_color_override("font_color", DARK)
	btn.add_theme_color_override("font_hover_color", DARK)
	btn.add_theme_color_override("font_disabled_color", DISABLED_TEXT)

	return btn


## Create a styled PanelContainer.
func _make_panel(bg_color: Color, border_color: Color, min_size: Vector2,
		margin: int = 8) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", _make_style(bg_color, border_color, 4, margin))
	return panel


## Create a Label pre-configured with the pixel font.
func _make_pixel_label(text: String, font_size: int, color: Color = DARK) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", _pixel_font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


## Create the standard full-screen margin container used by all screens.
func _make_screen_margin() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 64)
	margin.add_theme_constant_override("margin_bottom", 24)
	return margin


## Create a centered title label with a dark underline bar beneath it.
func _make_title_bar(title_text: String, font_size: int = 24) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var title := _make_pixel_label(title_text, font_size, DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var underline := ColorRect.new()
	underline.custom_minimum_size = Vector2(296, 4)
	underline.color = DARK
	vbox.add_child(underline)

	return vbox


## Draw drop-shadow rectangles behind a list of buttons.
func _draw_button_shadows(buttons: Array, shadow_offset := Vector2(8, 8)) -> void:
	for btn in buttons:
		if not is_instance_valid(btn) or not btn.visible:
			continue
		var b := btn as BaseButton
		var off := shadow_offset
		var mode: int = b.get_draw_mode()
		if mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED:
			off = Vector2(3, 3)
		draw_rect(
			Rect2(btn.global_position - global_position + off, btn.size),
			SHADOW_COLOR
		)
