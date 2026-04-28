extends PanelContainer
## Base card component for dice display. Subclass ShopItemCard adds the shop frame.

signal card_pressed
signal card_hover_entered
signal card_hover_exited

const DARK := Color("1a1a1a")
const GOLD := Color("ffd700")
const BORDER_BLACK := Color("000000")
const RARITY_COMMON := "common"
const RARITY_UNCOMMON := "uncommon"
const RARITY_RARE := "rare"
const RARITY_COMMON_COLOR := Color("000000")
const RARITY_UNCOMMON_COLOR := Color("8ec3ff")
const RARITY_RARE_COLOR := Color("ffd700")
const RARITY_RARE_ALT_COLOR := Color("ff69b4")

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

const ITEM_CARD_DEFAULT_SIZE := Vector2(96, 96)
const ITEM_CARD_CONTENT_SEPARATION := 8
const ITEM_CARD_NAME_FONT_SIZE := 12
const ITEM_CARD_NAME_MIN_SIZE := Vector2(96, 18)
const ITEM_CARD_MAIN_BORDER_WIDTH := 4
const ITEM_CARD_MAIN_MARGIN := 4
const ITEM_CARD_MAIN_FONT_SIZE := 24
const FRAME_BG := Color("c8e6f5")
const ITEM_CARD_FRAME_MARGIN := 12
const ACTION_BUTTON_SIZE := Vector2(96, 28)
const ACTION_BUTTON_FONT_SIZE := 10
const ACTION_BUTTON_BORDER_WIDTH := 3
const ACTION_BUTTON_MARGIN := 4
const COUNTER_ROW_SEPARATION := 0
const COUNTER_BUTTON_SIZE := Vector2(28, 28)
const COUNTER_BUTTON_FONT_SIZE := 12
const COUNTER_LABEL_SIZE := Vector2(40, 28)
const COUNTER_LABEL_FONT_SIZE := 10
const COIN_ICON_SIZE := 18

var main_button: Button
var bottom_control: Control
var hover_name: String = ""
var hover_description: String = ""
var hover_cost: int = -1
var _card_color: Color = Color.WHITE
var _font: Font
var _vbox: VBoxContainer
var _accent_active: bool = false
var _accent_color: Color = GOLD
var _is_selected: bool = false
var _is_framed: bool = false
var _rarity: String = RARITY_COMMON
var _rarity_animation_active: bool = false
var _rarity_phase: float = 0.0


func setup_as_dice_item(die: Die, pixel_font: Font) -> void:
	const DiceFacePanel = preload("res://scripts/ui/dice_face_panel.gd")

	var vals := die.get_face_values()
	var faces_str := ",".join(vals.map(func(f: int) -> String: return str(f)))
	hover_name = die.die_name
	hover_description = _with_rarity_line("%s\nFaces: (%s)" % [die.description, faces_str], die.rarity)
	_set_rarity(die.rarity)
	var card_color: Color = DIE_COLORS.get(die.color, Color.WHITE)
	_setup_card(card_color, "", pixel_font)

	var face_panel := DiceFacePanel.new()
	face_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	face_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_button.add_child(face_panel)
	face_panel.set_face_color(card_color)
	face_panel.set_value(5)

	var name_label := Label.new()
	name_label.text = DIE_NAMES.get(die.color, "BASIC")
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", ITEM_CARD_NAME_FONT_SIZE)
	name_label.add_theme_color_override("font_color", DARK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = ITEM_CARD_NAME_MIN_SIZE
	bottom_control = name_label
	_vbox.add_child(bottom_control)


func _process(delta: float) -> void:
	if not _rarity_animation_active:
		return
	_rarity_phase = fmod(_rarity_phase + delta, TAU)
	_refresh_button_frame()


func _setup_card(card_color: Color, label_text: String, pixel_font: Font,
		card_size: Vector2 = ITEM_CARD_DEFAULT_SIZE) -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", ITEM_CARD_CONTENT_SEPARATION)
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vbox)

	_card_color = card_color
	var text_color := _get_text_color(card_color)

	main_button = Button.new()
	main_button.custom_minimum_size = card_size
	main_button.pivot_offset = card_size / 2.0
	main_button.add_theme_stylebox_override("normal", _make_style(card_color, BORDER_BLACK, ITEM_CARD_MAIN_BORDER_WIDTH, ITEM_CARD_MAIN_MARGIN))
	main_button.add_theme_stylebox_override("hover", _make_style(card_color, GOLD, ITEM_CARD_MAIN_BORDER_WIDTH, ITEM_CARD_MAIN_MARGIN))
	main_button.add_theme_font_override("font", pixel_font)
	main_button.add_theme_font_size_override("font_size", ITEM_CARD_MAIN_FONT_SIZE)
	main_button.add_theme_color_override("font_color", text_color)
	main_button.add_theme_color_override("font_hover_color", text_color)
	main_button.text = label_text
	main_button.pressed.connect(func(): card_pressed.emit())
	main_button.mouse_entered.connect(func(): card_hover_entered.emit())
	main_button.mouse_exited.connect(func(): card_hover_exited.emit())
	_vbox.add_child(main_button)


func set_bottom_text(text: String, color: Color = DARK) -> void:
	if bottom_control is Label:
		(bottom_control as Label).text = text
		(bottom_control as Label).add_theme_color_override("font_color", color)


func set_selected(selected: bool) -> void:
	_is_selected = selected
	_refresh_button_frame()


func set_accent(accented: bool, accent_color: Color = GOLD) -> void:
	_accent_active = accented
	_accent_color = accent_color
	_refresh_button_frame()


func is_accented() -> bool:
	return _accent_active


func is_rarity_animation_active() -> bool:
	return _rarity_animation_active

func setup_frame() -> void:
	_is_framed = true
	add_theme_stylebox_override("panel", _make_style(FRAME_BG, FRAME_BG, 0, ITEM_CARD_FRAME_MARGIN))
	main_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_button.add_theme_stylebox_override("hover", _make_style(_card_color, BORDER_BLACK, ITEM_CARD_MAIN_BORDER_WIDTH, ITEM_CARD_MAIN_MARGIN))
	for conn in main_button.mouse_entered.get_connections():
		main_button.mouse_entered.disconnect(conn["callable"])
	for conn in main_button.mouse_exited.get_connections():
		main_button.mouse_exited.disconnect(conn["callable"])
	mouse_entered.connect(_on_frame_hover_in)
	mouse_exited.connect(_on_frame_hover_out)
	gui_input.connect(_on_frame_click)
	_refresh_button_frame()


func create_action_button(text: String, pixel_font: Font) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = ACTION_BUTTON_SIZE
	btn.add_theme_font_override("font", pixel_font)
	btn.add_theme_font_size_override("font_size", ACTION_BUTTON_FONT_SIZE)
	btn.text = text
	btn.mouse_entered.connect(_on_frame_hover_in)
	btn.mouse_exited.connect(_on_frame_hover_out)
	_apply_action_button_style(btn)
	_vbox.add_child(btn)
	return btn


func create_counter_row(pixel_font: Font) -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", COUNTER_ROW_SEPARATION)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.mouse_entered.connect(_on_frame_hover_in)
	hbox.mouse_exited.connect(_on_frame_hover_out)

	var minus_btn := Button.new()
	minus_btn.custom_minimum_size = COUNTER_BUTTON_SIZE
	minus_btn.add_theme_font_override("font", pixel_font)
	minus_btn.add_theme_font_size_override("font_size", COUNTER_BUTTON_FONT_SIZE)
	minus_btn.text = "-"
	_apply_action_button_style(minus_btn)
	hbox.add_child(minus_btn)

	var count_label := Label.new()
	count_label.custom_minimum_size = COUNTER_LABEL_SIZE
	count_label.add_theme_font_override("font", pixel_font)
	count_label.add_theme_font_size_override("font_size", COUNTER_LABEL_FONT_SIZE)
	count_label.add_theme_color_override("font_color", DARK)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.text = "0"
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(count_label)

	var plus_btn := Button.new()
	plus_btn.custom_minimum_size = COUNTER_BUTTON_SIZE
	plus_btn.add_theme_font_override("font", pixel_font)
	plus_btn.add_theme_font_size_override("font_size", COUNTER_BUTTON_FONT_SIZE)
	plus_btn.text = "+"
	_apply_action_button_style(plus_btn)
	hbox.add_child(plus_btn)

	_vbox.add_child(hbox)
	return {"minus_btn": minus_btn, "label": count_label, "plus_btn": plus_btn}


func _apply_action_button_style(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", _make_style(DARK, BORDER_BLACK, ACTION_BUTTON_BORDER_WIDTH, ACTION_BUTTON_MARGIN))
	btn.add_theme_stylebox_override("hover", _make_style(Color(0.25, 0.25, 0.25), Color(0.4, 0.4, 0.4), ACTION_BUTTON_BORDER_WIDTH, ACTION_BUTTON_MARGIN))
	btn.add_theme_stylebox_override("pressed", _make_style(Color(0.04, 0.04, 0.04), BORDER_BLACK, ACTION_BUTTON_BORDER_WIDTH, ACTION_BUTTON_MARGIN))
	btn.add_theme_stylebox_override("disabled", _make_style(Color(0.07, 0.07, 0.07), Color(0.15, 0.15, 0.15), ACTION_BUTTON_BORDER_WIDTH, ACTION_BUTTON_MARGIN))
	btn.add_theme_color_override("font_color", GOLD)
	btn.add_theme_color_override("font_hover_color", GOLD)
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.667, 0))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.1))


func _on_frame_hover_in() -> void:
	card_hover_entered.emit()


func _on_frame_hover_out() -> void:
	if not get_global_rect().has_point(get_global_mouse_position()):
		card_hover_exited.emit()


func _on_frame_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		card_pressed.emit()


static func _create_coin_icon(display_size: int = COIN_ICON_SIZE) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = preload("res://assets/art/ui/coin.png")
	rect.custom_minimum_size = Vector2(display_size, display_size)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _make_style(bg_color: Color, border_color: Color = BORDER_BLACK,
		border_width: int = 4, margin_size: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(margin_size)
	return sb


func _get_text_color(bg: Color) -> Color:
	if bg.get_luminance() > 0.5:
		return Color("0a0a0a")
	return Color.WHITE


func _set_rarity(rarity: String) -> void:
	_rarity = _normalize_rarity(rarity)
	_rarity_animation_active = true
	set_process(true)
	_refresh_button_frame()


func _with_rarity_line(description: String, rarity: String) -> String:
	var rarity_line := "RARITY: %s" % _normalize_rarity(rarity).to_upper()
	var trimmed := description.strip_edges()
	if trimmed.is_empty():
		return rarity_line
	return "%s\n%s" % [trimmed, rarity_line]


func _normalize_rarity(rarity: String) -> String:
	var normalized := rarity.to_lower().strip_edges()
	match normalized:
		RARITY_UNCOMMON, RARITY_RARE:
			return normalized
	return RARITY_COMMON


func _rarity_pulse() -> float:
	return (sin(_rarity_phase * 3.0) + 1.0) * 0.5


func _rarity_border_width() -> int:
	match _rarity:
		RARITY_UNCOMMON:
			return 3
		RARITY_RARE:
			return 4
	return 1


func _rarity_border_color() -> Color:
	var pulse := _rarity_pulse()
	match _rarity:
		RARITY_COMMON:
			return RARITY_COMMON_COLOR
		RARITY_UNCOMMON:
			return RARITY_UNCOMMON_COLOR.lerp(Color.WHITE, pulse * 0.25)
		RARITY_RARE:
			return RARITY_RARE_COLOR.lerp(RARITY_RARE_ALT_COLOR, pulse)
	return RARITY_COMMON_COLOR


func _refresh_button_frame() -> void:
	if main_button == null:
		return
	if _is_framed:
		var frame_border_width := 0
		var frame_border := FRAME_BG
		if _accent_active:
			frame_border_width = 4
			frame_border = _accent_color
		elif _rarity_animation_active:
			frame_border_width = _rarity_border_width()
			frame_border = _rarity_border_color()
		add_theme_stylebox_override("panel", _make_style(FRAME_BG, frame_border, frame_border_width, ITEM_CARD_FRAME_MARGIN))

	var rarity_border := _rarity_border_color() if _rarity_animation_active else BORDER_BLACK
	var border := GOLD if _is_selected else (_accent_color if _accent_active else rarity_border)
	main_button.add_theme_stylebox_override("normal", _make_style(_card_color, border, ITEM_CARD_MAIN_BORDER_WIDTH, ITEM_CARD_MAIN_MARGIN))
	if _is_framed:
		main_button.add_theme_stylebox_override("hover", _make_style(_card_color, border, ITEM_CARD_MAIN_BORDER_WIDTH, ITEM_CARD_MAIN_MARGIN))
	else:
		var hover_border := _accent_color if _accent_active else GOLD
		main_button.add_theme_stylebox_override("hover", _make_style(_card_color, hover_border, ITEM_CARD_MAIN_BORDER_WIDTH, ITEM_CARD_MAIN_MARGIN))
