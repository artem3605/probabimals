extends PanelContainer
## Base card component for dice display. Subclass ShopItemCard adds the shop frame.

signal card_pressed
signal card_hover_entered
signal card_hover_exited

const DARK := Color("1a1a1a")
const GOLD := Color("ffd700")
const BORDER_BLACK := Color("000000")

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

var main_button: Button
var bottom_control: Control
var hover_name: String = ""
var hover_description: String = ""
var hover_cost: int = -1
var _card_color: Color = Color.WHITE
var _font: Font
var _vbox: VBoxContainer


func setup_as_dice_item(die: Die, pixel_font: Font) -> void:
	const DiceFacePanel = preload("res://scripts/ui/dice_face_panel.gd")

	var vals := die.get_face_values()
	var faces_str := ",".join(vals.map(func(f: int) -> String: return str(f)))
	hover_name = die.die_name
	hover_description = "%s\nFaces: (%s)" % [die.description, faces_str]
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
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", DARK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(96, 18)
	bottom_control = name_label
	_vbox.add_child(bottom_control)


func _setup_card(card_color: Color, label_text: String, pixel_font: Font,
		card_size: Vector2 = Vector2(96, 96)) -> void:
	add_theme_stylebox_override("panel", StyleBoxEmpty.new())

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 8)
	_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_vbox)

	_card_color = card_color
	var text_color := _get_text_color(card_color)

	main_button = Button.new()
	main_button.custom_minimum_size = card_size
	main_button.pivot_offset = card_size / 2.0
	main_button.add_theme_stylebox_override("normal", _make_style(card_color, BORDER_BLACK, 4, 4))
	main_button.add_theme_stylebox_override("hover", _make_style(card_color, GOLD, 4, 4))
	main_button.add_theme_font_override("font", pixel_font)
	main_button.add_theme_font_size_override("font_size", 24)
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
	if selected:
		main_button.add_theme_stylebox_override("normal", _make_style(_card_color, GOLD, 4, 4))
	else:
		main_button.add_theme_stylebox_override("normal", _make_style(_card_color, BORDER_BLACK, 4, 4))


const FRAME_BG := Color("c8e6f5")

func setup_frame() -> void:
	add_theme_stylebox_override("panel", _make_style(FRAME_BG, FRAME_BG, 0, 12))
	main_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_button.add_theme_stylebox_override("hover", _make_style(_card_color, BORDER_BLACK, 4, 4))
	for conn in main_button.mouse_entered.get_connections():
		main_button.mouse_entered.disconnect(conn["callable"])
	for conn in main_button.mouse_exited.get_connections():
		main_button.mouse_exited.disconnect(conn["callable"])
	mouse_entered.connect(_on_frame_hover_in)
	mouse_exited.connect(_on_frame_hover_out)
	gui_input.connect(_on_frame_click)


func create_action_button(text: String, pixel_font: Font) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(96, 28)
	btn.add_theme_font_override("font", pixel_font)
	btn.add_theme_font_size_override("font_size", 10)
	btn.text = text
	btn.mouse_entered.connect(_on_frame_hover_in)
	btn.mouse_exited.connect(_on_frame_hover_out)
	_apply_action_button_style(btn)
	_vbox.add_child(btn)
	return btn


func create_counter_row(pixel_font: Font) -> Dictionary:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	hbox.mouse_entered.connect(_on_frame_hover_in)
	hbox.mouse_exited.connect(_on_frame_hover_out)

	var minus_btn := Button.new()
	minus_btn.custom_minimum_size = Vector2(28, 28)
	minus_btn.add_theme_font_override("font", pixel_font)
	minus_btn.add_theme_font_size_override("font_size", 12)
	minus_btn.text = "-"
	_apply_action_button_style(minus_btn)
	hbox.add_child(minus_btn)

	var count_label := Label.new()
	count_label.custom_minimum_size = Vector2(40, 28)
	count_label.add_theme_font_override("font", pixel_font)
	count_label.add_theme_font_size_override("font_size", 10)
	count_label.add_theme_color_override("font_color", DARK)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count_label.text = "0"
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(count_label)

	var plus_btn := Button.new()
	plus_btn.custom_minimum_size = Vector2(28, 28)
	plus_btn.add_theme_font_override("font", pixel_font)
	plus_btn.add_theme_font_size_override("font_size", 12)
	plus_btn.text = "+"
	_apply_action_button_style(plus_btn)
	hbox.add_child(plus_btn)

	_vbox.add_child(hbox)
	return {"minus_btn": minus_btn, "label": count_label, "plus_btn": plus_btn}


func _apply_action_button_style(btn: Button) -> void:
	const BW := 3
	const MG := 4
	btn.add_theme_stylebox_override("normal", _make_style(DARK, BORDER_BLACK, BW, MG))
	btn.add_theme_stylebox_override("hover", _make_style(Color(0.25, 0.25, 0.25), Color(0.4, 0.4, 0.4), BW, MG))
	btn.add_theme_stylebox_override("pressed", _make_style(Color(0.04, 0.04, 0.04), BORDER_BLACK, BW, MG))
	btn.add_theme_stylebox_override("disabled", _make_style(Color(0.07, 0.07, 0.07), Color(0.15, 0.15, 0.15), BW, MG))
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


static func _create_coin_icon(display_size: int = 18) -> TextureRect:
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
