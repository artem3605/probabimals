extends VBoxContainer
## Unified card component used for shop items and dice display.

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


func setup_as_shop_item(item: Dictionary, pixel_font: Font) -> void:
	hover_name = item.get("name", "")
	hover_description = item.get("description", "")
	hover_cost = item.get("cost", 0)
	if item.get("category", "") == "die":
		var params: Dictionary = item.get("params", {})
		var face_vals: Array = params.get("faces", [1, 2, 3, 4, 5, 6])
		var faces_str := ",".join(face_vals.map(func(f: Variant) -> String: return str(int(f))))
		hover_description += "\nFaces: (%s)" % faces_str
	var card_color := _get_item_color(item)
	var label_text := _get_card_label(item)
	_setup_card(card_color, label_text, pixel_font)

	var price_style := _make_style(GOLD, BORDER_BLACK, 4, 4)
	var price_btn := Button.new()
	price_btn.custom_minimum_size = Vector2(56, 32)
	price_btn.add_theme_stylebox_override("normal", price_style)
	price_btn.add_theme_stylebox_override("hover", price_style)
	price_btn.add_theme_font_override("font", pixel_font)
	price_btn.add_theme_font_size_override("font_size", 12)
	price_btn.add_theme_color_override("font_color", DARK)
	price_btn.text = str(item.get("cost", 0))
	price_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_control = price_btn
	add_child(bottom_control)


func setup_as_dice_item(die: Die, pixel_font: Font) -> void:
	var vals := die.get_face_values()
	var faces_str := ",".join(vals.map(func(f: int) -> String: return str(f)))
	hover_name = die.die_name
	hover_description = "%s\nFaces: (%s)" % [die.description, faces_str]
	var card_color: Color = DIE_COLORS.get(die.color, Color.WHITE)
	_setup_card(card_color, "D", pixel_font)

	var name_label := Label.new()
	name_label.text = DIE_NAMES.get(die.color, "BASIC")
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", DARK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(96, 18)
	bottom_control = name_label
	add_child(bottom_control)


func _setup_card(card_color: Color, label_text: String, pixel_font: Font,
		card_size: Vector2 = Vector2(96, 96)) -> void:
	add_theme_constant_override("separation", 8)
	alignment = BoxContainer.ALIGNMENT_CENTER
	_card_color = card_color
	var text_color := _get_text_color(card_color)

	main_button = Button.new()
	main_button.custom_minimum_size = card_size
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
	add_child(main_button)


func set_bottom_text(text: String, color: Color = DARK) -> void:
	if bottom_control is Label:
		(bottom_control as Label).text = text
		(bottom_control as Label).add_theme_color_override("font_color", color)


func set_selected(selected: bool) -> void:
	if selected:
		main_button.add_theme_stylebox_override("normal", _make_style(_card_color, GOLD, 4, 4))
	else:
		main_button.add_theme_stylebox_override("normal", _make_style(_card_color, BORDER_BLACK, 4, 4))


func _make_style(bg_color: Color, border_color: Color = BORDER_BLACK,
		border_width: int = 4, margin_size: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(margin_size)
	return sb


func _get_item_color(item: Dictionary) -> Color:
	var category: String = item.get("category", "")
	match category:
		"die":
			var die_id: String = item.get("id", "")
			if "loaded" in die_id:
				return DIE_COLORS["red"]
			elif "balanced" in die_id:
				return DIE_COLORS["green"]
			return Color.WHITE
	return Color.WHITE


func _get_text_color(bg: Color) -> Color:
	if bg.get_luminance() > 0.5:
		return Color("0a0a0a")
	return Color.WHITE


func _get_card_label(item: Dictionary) -> String:
	var category: String = item.get("category", "")
	match category:
		"die":
			return "D"
		"face":
			var val: int = item.get("params", {}).get("value", 0)
			return str(val)
		"modifier":
			var val = item.get("params", {}).get("value", 2.0)
			return "x%s" % str(int(val))
	return "?"
