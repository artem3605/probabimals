extends "res://scripts/ui/item_card.gd"
## Shop card with light-blue pixel frame, price panel, and buy button.
## Hover stays active across all child controls within the frame.

signal buy_pressed

var buy_button: Button


func setup_as_shop_item(item: Dictionary, pixel_font: Font) -> void:
	const DiceFacePanel = preload("res://scripts/ui/dice_face_panel.gd")

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

	if item.get("category", "") == "die":
		var face_panel := DiceFacePanel.new()
		face_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		face_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		main_button.add_child(face_panel)
		face_panel.set_face_color(card_color)
		face_panel.set_value(5)

	setup_frame()

	_build_price_panel(item, pixel_font)
	buy_button = create_action_button("BUY", pixel_font)
	buy_button.pressed.connect(func(): buy_pressed.emit())
	set_buy_status("buy")


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


func set_buy_status(status: String) -> void:
	if buy_button == null:
		return
	_apply_action_button_style(buy_button)
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
		"locked":
			buy_button.text = "FOLLOW TIP"
			buy_button.disabled = true
			modulate = Color(0.85, 0.85, 0.85, 1)
		"guide":
			buy_button.text = "BUY THIS"
			buy_button.disabled = false
			modulate = Color(1, 1, 1, 1)


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
			return ""
		"face":
			var val: int = item.get("params", {}).get("value", 0)
			return str(val)
		"modifier":
			var val = item.get("params", {}).get("value", 2.0)
			return "x%s" % str(int(val))
	return "?"
