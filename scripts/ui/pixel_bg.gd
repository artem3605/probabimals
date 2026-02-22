extends Control
## Base class for screens that share the pixel-art background style:
## sky-blue fill, faint grid overlay, dark square strips at top & bottom.

const BG_COLOR := Color("87ceeb")
const DARK := Color("1a1a1a")
const GOLD := Color("ffd700")
const BORDER_BLACK := Color("000000")
const SHADOW_COLOR := Color(0, 0, 0, 0.5)

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

	var normal := StyleBoxFlat.new()
	normal.bg_color = DARK
	normal.border_color = BORDER_BLACK
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(0)
	normal.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate()
	hover.bg_color = Color("2a2a2a")
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate()
	pressed.bg_color = Color("0a0a0a")
	btn.add_theme_stylebox_override("pressed", pressed)

	var focus := normal.duplicate()
	focus.border_color = GOLD
	btn.add_theme_stylebox_override("focus", focus)

	btn.add_theme_color_override("font_color", GOLD)
	btn.add_theme_color_override("font_hover_color", GOLD)
	btn.add_theme_color_override("font_pressed_color", Color("ccaa00"))
	btn.add_theme_color_override("font_focus_color", GOLD)

	return btn


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
