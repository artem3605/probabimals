extends Control
## Base class for screens that share the pixel-art background style:
## sky-blue fill with faint grid overlay.

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

const DIE_NAMES := {
	"colorless": "BASIC",
	"red": "LOADED",
	"green": "BALANCED",
	"blue": "BLUE",
	"gold": "GOLD",
	"purple": "PURPLE",
}

const DICE_SHEET_COLS := 3
const DICE_SHEET_ROWS := 2

var _pixel_font: Font


func _ready() -> void:
	_pixel_font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	queue_redraw()


func _draw_all_bg() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG_COLOR)
	var col := Color(0, 0, 0, 0.10)
	var cell := 32.0
	for i in range(1, int(size.x / cell)):
		var x := float(i) * cell
		draw_line(Vector2(x, 0), Vector2(x, size.y), col, 1.0)
	for j in range(1, int(size.y / cell)):
		var y := float(j) * cell
		draw_line(Vector2(0, y), Vector2(size.x, y), col, 1.0)


## Create a pixel-style button (dark bg, gold text, black border, drop shadow).
func _make_pixel_button(text: String, min_size: Vector2, font_size: int = 16) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_override("font", _pixel_font)
	btn.add_theme_font_size_override("font_size", font_size)
	_apply_dark_button_style(btn)
	return btn


func _apply_dark_button_style(btn: Button, border_width: int = 4, margin: int = 8) -> void:
	btn.add_theme_stylebox_override("normal", _make_style(DARK, BORDER_BLACK, border_width, margin))
	btn.add_theme_stylebox_override("hover", _make_style(Color(0.25, 0.25, 0.25), Color(0.4, 0.4, 0.4), border_width, margin))
	btn.add_theme_stylebox_override("pressed", _make_style(Color(0.04, 0.04, 0.04), BORDER_BLACK, border_width, margin))
	btn.add_theme_stylebox_override("disabled", _make_style(Color(0.07, 0.07, 0.07), Color(0.15, 0.15, 0.15), border_width, margin))

	var focus := _make_style(Color(0, 0, 0, 0), GOLD, border_width, margin)
	focus.draw_center = false
	btn.add_theme_stylebox_override("focus", focus)

	btn.add_theme_color_override("font_color", GOLD)
	btn.add_theme_color_override("font_hover_color", GOLD)
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.667, 0))
	btn.add_theme_color_override("font_focus_color", GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.1))


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


## Create the standard screen layout: margin > outer VBox > content VBox (expands) + bottom action bar (fixed).
## Returns { "content": VBoxContainer, "action_bar": HBoxContainer }.
func _make_screen_layout(content_separation: int = 32, clip_content: bool = false) -> Dictionary:
	var margin := _make_screen_margin()
	add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 32)
	margin.add_child(outer)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", content_separation)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.clip_contents = clip_content
	outer.add_child(content)

	var center := CenterContainer.new()
	outer.add_child(center)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 24)
	center.add_child(bar)

	return { "content": content, "action_bar": bar }


## Create the standard full-screen margin container used by all screens.
func _make_screen_margin() -> MarginContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 64)
	margin.add_theme_constant_override("margin_bottom", 24)
	return margin


## Create a centered title label with a dark underline bar and round/target subtitle.
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

	var sub := _make_pixel_label(
		"Round %d. Target %d." % [GameManager.current_round, GameManager.target_score], 12, DARK)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(sub)

	return vbox


## Create the standard "MENU" button that returns to the main menu.
## Override _go_to_main_menu() in subclasses to customize transition behavior.
func _make_menu_button() -> Button:
	var btn := _make_pixel_button("MENU", Vector2(96, 56), 14)
	btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	btn.pressed.connect(_go_to_main_menu)
	return btn


## Navigate back to the main menu. Override in subclasses for custom transitions.
func _go_to_main_menu() -> void:
	GameManager.go_to_main_menu()


## Load the 3x2 dice sprite sheet and return an array of AtlasTextures (faces 1-6).
func _load_dice_sheet() -> Array[AtlasTexture]:
	var textures: Array[AtlasTexture] = []
	var sheet: Texture2D = load("res://assets/art/dice/dice_sheet.png")
	var cell_w := sheet.get_width() / float(DICE_SHEET_COLS)
	var cell_h := sheet.get_height() / float(DICE_SHEET_ROWS)
	for row in DICE_SHEET_ROWS:
		for col in DICE_SHEET_COLS:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)
			textures.append(atlas)
	return textures


## Create a transparent-background button for displaying dice/card sprites.
func _make_icon_button(min_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.custom_minimum_size = min_size
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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
