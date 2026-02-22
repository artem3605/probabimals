extends "res://scripts/ui/pixel_bg.gd"

const REROLL_COST := 10
const SHOP_SLOTS := 7

const DIE_COLORS := {
	"colorless": Color.WHITE,
	"red": Color("ff4444"),
	"green": Color("9acd32"),
	"blue": Color("4a9eff"),
	"gold": Color("ffd700"),
	"purple": Color("9b59b6"),
}

var _shop_offerings: Array[Dictionary] = []
var _coin_label: Label
var _shop_container: HBoxContainer
var _reroll_btn: Button
var _ready_btn: Button
var _back_btn: Button
var _my_dice_btn: Button
var _info_popup: PanelContainer
var _info_label: RichTextLabel
var _buy_button: Button
var _selected_item: Dictionary = {}
var _all_buttons: Array = []


func _ready() -> void:
	super._ready()
	_build_ui()
	_generate_offerings()
	_update_coins()
	GameManager.coins_changed.connect(func(_a: int): _update_coins())


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_button_shadows(_all_buttons, Vector2(4, 4))
	_draw_shop_card_shadows()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 64)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 48)
	margin.add_child(vbox)

	_build_top_bar(vbox)
	_build_shop_row(vbox)
	_build_action_bar(vbox)
	_build_info_popup()


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(bar)

	# BACK button
	_back_btn = _make_pixel_button("BACK", Vector2(96, 52), 14)
	_back_btn.pressed.connect(_on_back_pressed)
	bar.add_child(_back_btn)
	_all_buttons.append(_back_btn)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	# Title
	var title_vbox := VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 8)
	bar.add_child(title_vbox)

	var title := Label.new()
	title.text = "FLEA MARKET"
	title.add_theme_font_override("font", _pixel_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_vbox.add_child(title)

	var underline := ColorRect.new()
	underline.custom_minimum_size = Vector2(296, 4)
	underline.color = DARK
	title_vbox.add_child(underline)

	# Spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer2)

	# Right side: coins + MY DICE
	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 12)
	bar.add_child(right_vbox)

	# Coin display
	var coin_panel := PanelContainer.new()
	var coin_style := StyleBoxFlat.new()
	coin_style.bg_color = GOLD
	coin_style.border_color = BORDER_BLACK
	coin_style.set_border_width_all(4)
	coin_style.set_corner_radius_all(0)
	coin_style.set_content_margin_all(8)
	coin_panel.add_theme_stylebox_override("panel", coin_style)
	coin_panel.custom_minimum_size = Vector2(124, 48)
	right_vbox.add_child(coin_panel)

	var coin_hbox := HBoxContainer.new()
	coin_hbox.add_theme_constant_override("separation", 8)
	coin_panel.add_child(coin_hbox)

	# Small coin icon (drawn as a colored square)
	var coin_icon := ColorRect.new()
	coin_icon.custom_minimum_size = Vector2(20, 20)
	coin_icon.color = Color("b8960a")
	coin_hbox.add_child(coin_icon)

	_coin_label = Label.new()
	_coin_label.add_theme_font_override("font", _pixel_font)
	_coin_label.add_theme_font_size_override("font_size", 16)
	_coin_label.add_theme_color_override("font_color", DARK)
	coin_hbox.add_child(_coin_label)

	# MY DICE button
	_my_dice_btn = Button.new()
	_my_dice_btn.text = "MY DICE"
	_my_dice_btn.custom_minimum_size = Vector2(124, 44)
	_my_dice_btn.add_theme_font_override("font", _pixel_font)
	_my_dice_btn.add_theme_font_size_override("font_size", 12)
	var dice_style := StyleBoxFlat.new()
	dice_style.bg_color = Color("4a9eff")
	dice_style.border_color = BORDER_BLACK
	dice_style.set_border_width_all(4)
	dice_style.set_corner_radius_all(0)
	dice_style.set_content_margin_all(8)
	_my_dice_btn.add_theme_stylebox_override("normal", dice_style)
	var dice_hover := dice_style.duplicate()
	dice_hover.bg_color = Color("5ab0ff")
	_my_dice_btn.add_theme_stylebox_override("hover", dice_hover)
	_my_dice_btn.add_theme_color_override("font_color", DARK)
	_my_dice_btn.add_theme_color_override("font_hover_color", DARK)
	_my_dice_btn.pressed.connect(_on_my_dice_pressed)
	right_vbox.add_child(_my_dice_btn)
	_all_buttons.append(_my_dice_btn)


func _build_shop_row(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_shop_container = HBoxContainer.new()
	_shop_container.add_theme_constant_override("separation", 32)
	center.add_child(_shop_container)


func _build_action_bar(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	center.add_child(hbox)

	# REROLL button (pink)
	_reroll_btn = Button.new()
	_reroll_btn.custom_minimum_size = Vector2(152, 68)
	_reroll_btn.add_theme_font_override("font", _pixel_font)
	_reroll_btn.add_theme_font_size_override("font_size", 14)
	var reroll_style := StyleBoxFlat.new()
	reroll_style.bg_color = Color("ff69b4")
	reroll_style.border_color = BORDER_BLACK
	reroll_style.set_border_width_all(4)
	reroll_style.set_corner_radius_all(0)
	reroll_style.set_content_margin_all(8)
	_reroll_btn.add_theme_stylebox_override("normal", reroll_style)
	var reroll_hover := reroll_style.duplicate()
	reroll_hover.bg_color = Color("ff80c0")
	_reroll_btn.add_theme_stylebox_override("hover", reroll_hover)
	_reroll_btn.add_theme_color_override("font_color", DARK)
	_reroll_btn.add_theme_color_override("font_hover_color", DARK)
	_reroll_btn.text = "REROLL\n%d coins" % REROLL_COST
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	hbox.add_child(_reroll_btn)
	_all_buttons.append(_reroll_btn)

	# READY! button (green)
	_ready_btn = Button.new()
	_ready_btn.text = "READY!"
	_ready_btn.custom_minimum_size = Vector2(168, 68)
	_ready_btn.add_theme_font_override("font", _pixel_font)
	_ready_btn.add_theme_font_size_override("font_size", 16)
	var ready_style := StyleBoxFlat.new()
	ready_style.bg_color = Color("9acd32")
	ready_style.border_color = BORDER_BLACK
	ready_style.set_border_width_all(4)
	ready_style.set_corner_radius_all(0)
	ready_style.set_content_margin_all(8)
	_ready_btn.add_theme_stylebox_override("normal", ready_style)
	var ready_hover := ready_style.duplicate()
	ready_hover.bg_color = Color("b0dd48")
	_ready_btn.add_theme_stylebox_override("hover", ready_hover)
	_ready_btn.add_theme_color_override("font_color", DARK)
	_ready_btn.add_theme_color_override("font_hover_color", DARK)
	_ready_btn.pressed.connect(_on_ready_pressed)
	hbox.add_child(_ready_btn)
	_all_buttons.append(_ready_btn)


func _build_info_popup() -> void:
	_info_popup = PanelContainer.new()
	_info_popup.visible = false
	_info_popup.set_anchors_preset(Control.PRESET_CENTER)
	_info_popup.custom_minimum_size = Vector2(400, 180)
	_info_popup.offset_left = -200
	_info_popup.offset_right = 200
	_info_popup.offset_top = -90
	_info_popup.offset_bottom = 90
	var popup_style := StyleBoxFlat.new()
	popup_style.bg_color = Color("1a1a1a")
	popup_style.border_color = GOLD
	popup_style.set_border_width_all(4)
	popup_style.set_corner_radius_all(0)
	popup_style.set_content_margin_all(16)
	_info_popup.add_theme_stylebox_override("panel", popup_style)
	add_child(_info_popup)

	var popup_vbox := VBoxContainer.new()
	popup_vbox.add_theme_constant_override("separation", 12)
	_info_popup.add_child(popup_vbox)

	_info_label = RichTextLabel.new()
	_info_label.bbcode_enabled = true
	_info_label.fit_content = true
	_info_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_info_label.add_theme_font_override("normal_font", _pixel_font)
	_info_label.add_theme_font_override("bold_font", _pixel_font)
	_info_label.add_theme_font_size_override("normal_font_size", 12)
	_info_label.add_theme_font_size_override("bold_font_size", 14)
	popup_vbox.add_child(_info_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	popup_vbox.add_child(btn_row)

	_buy_button = _make_pixel_button("BUY", Vector2(100, 40), 12)
	_buy_button.pressed.connect(_on_buy_pressed)
	btn_row.add_child(_buy_button)

	var close_btn := _make_pixel_button("CLOSE", Vector2(100, 40), 12)
	close_btn.pressed.connect(func(): _info_popup.visible = false)
	btn_row.add_child(close_btn)


# -- Shop generation -----------------------------------------------------------

func _generate_offerings() -> void:
	_shop_offerings.clear()
	var catalogue := DataManager.get_shop_catalogue()
	if catalogue.is_empty():
		return

	var shuffled := catalogue.duplicate()
	shuffled.shuffle()
	var count := mini(SHOP_SLOTS, shuffled.size())
	for i in count:
		_shop_offerings.append(shuffled[i])

	_refresh_shop_display()


func _refresh_shop_display() -> void:
	for child in _shop_container.get_children():
		child.queue_free()

	for i in _shop_offerings.size():
		var item := _shop_offerings[i]
		var card := _create_shop_card(item, i)
		_shop_container.add_child(card)


func _create_shop_card(item: Dictionary, _index: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.alignment = BoxContainer.ALIGNMENT_CENTER

	# Die visual card (96x96)
	var card_btn := Button.new()
	card_btn.custom_minimum_size = Vector2(96, 96)

	var card_color := _get_item_color(item)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = card_color
	card_style.border_color = BORDER_BLACK
	card_style.set_border_width_all(4)
	card_style.set_corner_radius_all(0)
	card_style.set_content_margin_all(4)
	card_btn.add_theme_stylebox_override("normal", card_style)

	var hover_style := card_style.duplicate()
	hover_style.border_color = GOLD
	card_btn.add_theme_stylebox_override("hover", hover_style)

	card_btn.add_theme_font_override("font", _pixel_font)
	card_btn.add_theme_font_size_override("font_size", 24)
	card_btn.add_theme_color_override("font_color", _get_text_color(card_color))
	card_btn.add_theme_color_override("font_hover_color", _get_text_color(card_color))
	card_btn.text = _get_card_label(item)
	card_btn.pressed.connect(_on_shop_item_clicked.bind(item))
	col.add_child(card_btn)

	# Price tag (gold, small)
	var price_btn := Button.new()
	price_btn.custom_minimum_size = Vector2(56, 32)
	var price_style := StyleBoxFlat.new()
	price_style.bg_color = GOLD
	price_style.border_color = BORDER_BLACK
	price_style.set_border_width_all(4)
	price_style.set_corner_radius_all(0)
	price_style.set_content_margin_all(4)
	price_btn.add_theme_stylebox_override("normal", price_style)
	price_btn.add_theme_stylebox_override("hover", price_style)
	price_btn.add_theme_font_override("font", _pixel_font)
	price_btn.add_theme_font_size_override("font_size", 12)
	price_btn.add_theme_color_override("font_color", DARK)
	price_btn.text = str(item.get("cost", 0))
	price_btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(price_btn)

	return col


func _get_item_color(item: Dictionary) -> Color:
	var category: String = item.get("category", "")
	match category:
		"die":
			var die_id: String = item.get("id", "")
			if "loaded" in die_id:
				return Color("ff4444")
			elif "balanced" in die_id:
				return Color("9acd32")
			return Color.WHITE
		"face":
			return Color.WHITE
		"modifier":
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


func _draw_shop_card_shadows() -> void:
	for card_col in _shop_container.get_children():
		if card_col is VBoxContainer and card_col.get_child_count() > 0:
			var card_btn: Control = card_col.get_child(0)
			if is_instance_valid(card_btn) and card_btn.visible:
				var gp := card_btn.global_position - global_position
				draw_rect(
					Rect2(gp + Vector2(4, 4), card_btn.size),
					SHADOW_COLOR
				)


# -- Coin display --------------------------------------------------------------

func _update_coins() -> void:
	if _coin_label:
		_coin_label.text = str(GameManager.coins)
	if _reroll_btn:
		_reroll_btn.disabled = GameManager.coins < REROLL_COST


# -- Callbacks -----------------------------------------------------------------

func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()


func _on_reroll_pressed() -> void:
	if GameManager.coins < REROLL_COST:
		return
	GameManager.coins -= REROLL_COST
	GameManager.coins_changed.emit(GameManager.coins)
	_generate_offerings()
	_update_coins()


func _on_ready_pressed() -> void:
	GameManager.go_to_dice_select()


func _on_my_dice_pressed() -> void:
	_info_popup.visible = true
	_buy_button.visible = false
	var dice := GameManager.dice_bag.get_all()
	var text := "[b]MY DICE[/b]\n"
	for i in dice.size():
		var d: Die = dice[i]
		text += "Die %d: %s (%s)\n" % [i + 1, str(d.faces), d.color]
	_info_label.text = text


func _on_shop_item_clicked(item: Dictionary) -> void:
	_selected_item = item
	_info_popup.visible = true
	_buy_button.visible = true
	_buy_button.disabled = GameManager.coins < item.get("cost", 0)
	_info_label.text = "[b]%s[/b]\n%s\n[color=#ffd700]Cost: %d coins[/color]" % [
		item.get("name", ""), item.get("description", ""), item.get("cost", 0)
	]


func _on_buy_pressed() -> void:
	if _selected_item.is_empty():
		return
	var success := GameManager.buy_item(_selected_item)
	if success:
		_info_label.text = "[color=#9acd32]Purchased: %s[/color]" % _selected_item.get("name", "")
		_buy_button.disabled = true
		_update_coins()
	else:
		_info_label.text = "[color=#ff4444]Not enough coins![/color]"
