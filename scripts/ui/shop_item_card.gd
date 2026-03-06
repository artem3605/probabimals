extends "res://scripts/ui/item_card.gd"
## Shop card with light-blue pixel frame, price panel, and buy button.
## Hover stays active across all child controls within the frame.

signal buy_pressed

const FRAME_BG := Color("c8e6f5")
const FRAME_BORDER := Color("7ab8e0")

var buy_button: Button


func setup_as_shop_item(item: Dictionary, pixel_font: Font) -> void:
	_font = pixel_font
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
	add_theme_stylebox_override("panel", _make_style(FRAME_BG, FRAME_BG, 0, 12))

	# main_button is display-only inside the shop frame: no clicks, no hover style
	main_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var normal_style := _make_style(card_color, BORDER_BLACK, 4, 4)
	main_button.add_theme_stylebox_override("hover", normal_style)

	# Disconnect base-class hover signals (they were connected on main_button)
	for conn in main_button.mouse_entered.get_connections():
		main_button.mouse_entered.disconnect(conn["callable"])
	for conn in main_button.mouse_exited.get_connections():
		main_button.mouse_exited.disconnect(conn["callable"])

	# Frame-level hover: stays active when mouse moves between children
	mouse_entered.connect(_on_hover_in)
	mouse_exited.connect(_on_hover_out)

	_build_price_panel(item, pixel_font)
	_build_buy_button(pixel_font)


func _build_price_panel(item: Dictionary, pixel_font: Font) -> void:
	var price_panel := PanelContainer.new()
	price_panel.custom_minimum_size = Vector2(56, 32)
	price_panel.add_theme_stylebox_override("panel", _make_style(GOLD, BORDER_BLACK, 3, 4))
	price_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var price_hbox := HBoxContainer.new()
	price_hbox.add_theme_constant_override("separation", 4)
	price_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	price_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_panel.add_child(price_hbox)

	price_hbox.add_child(_create_coin_icon())

	var price_label := Label.new()
	price_label.text = str(int(item.get("cost", 0)))
	price_label.add_theme_font_override("font", pixel_font)
	price_label.add_theme_font_size_override("font_size", 12)
	price_label.add_theme_color_override("font_color", DARK)
	price_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_hbox.add_child(price_label)

	bottom_control = price_panel
	_vbox.add_child(bottom_control)


func _build_buy_button(pixel_font: Font) -> void:
	buy_button = Button.new()
	buy_button.custom_minimum_size = Vector2(96, 28)
	buy_button.add_theme_font_override("font", pixel_font)
	buy_button.add_theme_font_size_override("font_size", 10)
	buy_button.pressed.connect(func(): buy_pressed.emit())
	buy_button.mouse_entered.connect(_on_hover_in)
	buy_button.mouse_exited.connect(_on_hover_out)
	_vbox.add_child(buy_button)
	set_buy_status("buy")


func set_buy_status(status: String) -> void:
	if buy_button == null:
		return
	_apply_buy_button_style(buy_button)
	match status:
		"buy":
			buy_button.text = "BUY"
			buy_button.disabled = false
			modulate = Color(1, 1, 1, 1)
		"no_money":
			buy_button.text = "NO COINS"
			buy_button.disabled = true
			modulate = Color(0.7, 0.7, 0.7, 1)
		"sold":
			buy_button.text = "SOLD"
			buy_button.disabled = true
			modulate = Color(0.7, 0.7, 0.7, 1)


func _apply_buy_button_style(btn: Button) -> void:
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


func _on_hover_in() -> void:
	card_hover_entered.emit()


func _on_hover_out() -> void:
	if not get_global_rect().has_point(get_global_mouse_position()):
		card_hover_exited.emit()


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
