extends "res://scripts/ui/pixel_bg.gd"

const REROLL_COST := 10
const SHOP_SLOTS := 7

var _shop_offerings: Array[Dictionary] = []
var _coin_label: Label
var _shop_container: HBoxContainer
var _reroll_btn: Button
var _ready_btn: Button
var _my_dice_btn: Button
var _desc_panel: PanelContainer
var _desc_title: Label
var _desc_body: Label
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
	var margin := _make_screen_margin()
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 48)
	margin.add_child(vbox)

	_build_top_bar(vbox)
	_build_shop_row(vbox)
	_build_description_panel(vbox)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	_build_action_bar(vbox)


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(bar)

	var menu_btn := _make_menu_button()
	bar.add_child(menu_btn)
	_all_buttons.append(menu_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	bar.add_child(_make_title_bar("FLEA MARKET"))

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer2)

	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 12)
	bar.add_child(right_vbox)

	var coin_panel := _make_panel(GOLD, BORDER_BLACK, Vector2(124, 48))
	right_vbox.add_child(coin_panel)

	var coin_hbox := HBoxContainer.new()
	coin_hbox.add_theme_constant_override("separation", 8)
	coin_panel.add_child(coin_hbox)

	var coin_icon := ColorRect.new()
	coin_icon.custom_minimum_size = Vector2(20, 20)
	coin_icon.color = Color("b8960a")
	coin_hbox.add_child(coin_icon)

	_coin_label = _make_pixel_label("", 16)
	coin_hbox.add_child(_coin_label)

	_my_dice_btn = _make_colored_button("MY DICE", Vector2(124, 44), BLUE, BLUE.lightened(0.15), 12)
	_my_dice_btn.pressed.connect(_on_my_dice_pressed)
	right_vbox.add_child(_my_dice_btn)
	_all_buttons.append(_my_dice_btn)


func _build_shop_row(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_shop_container = HBoxContainer.new()
	_shop_container.add_theme_constant_override("separation", 32)
	center.add_child(_shop_container)


func _build_description_panel(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_desc_panel = _make_panel(DARK, GOLD, Vector2(420, 0), 16)
	_desc_panel.visible = false
	_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_desc_panel)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 12)
	desc_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_panel.add_child(desc_vbox)

	_desc_title = _make_pixel_label("", 14, GOLD)
	_desc_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_vbox.add_child(_desc_title)

	_desc_body = _make_pixel_label("", 12, Color.WHITE)
	_desc_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_vbox.add_child(_desc_body)


func _build_action_bar(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 24)
	center.add_child(hbox)

	_reroll_btn = _make_colored_button("REROLL\n%d coins" % REROLL_COST, Vector2(152, 68), PINK, PINK.lightened(0.15), 14)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	hbox.add_child(_reroll_btn)
	_all_buttons.append(_reroll_btn)

	_ready_btn = _make_colored_button("READY!", Vector2(168, 68), GREEN, GREEN.lightened(0.15), 16)
	_ready_btn.pressed.connect(_on_ready_pressed)
	hbox.add_child(_ready_btn)
	_all_buttons.append(_ready_btn)


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

	var card_color := _get_item_color(item)
	var text_color := _get_text_color(card_color)

	var card_btn := Button.new()
	card_btn.custom_minimum_size = Vector2(96, 96)
	card_btn.add_theme_stylebox_override("normal", _make_style(card_color, BORDER_BLACK, 4, 4))
	card_btn.add_theme_stylebox_override("hover", _make_style(card_color, GOLD, 4, 4))
	card_btn.add_theme_font_override("font", _pixel_font)
	card_btn.add_theme_font_size_override("font_size", 24)
	card_btn.add_theme_color_override("font_color", text_color)
	card_btn.add_theme_color_override("font_hover_color", text_color)
	card_btn.text = _get_card_label(item)
	card_btn.pressed.connect(_on_shop_item_clicked.bind(item))
	card_btn.mouse_entered.connect(_on_card_hover_enter.bind(item))
	card_btn.mouse_exited.connect(_on_card_hover_exit)
	col.add_child(card_btn)

	var price_style := _make_style(GOLD, BORDER_BLACK, 4, 4)
	var price_btn := Button.new()
	price_btn.custom_minimum_size = Vector2(56, 32)
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
				return DIE_COLORS["red"]
			elif "balanced" in die_id:
				return DIE_COLORS["green"]
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
	var dice := GameManager.dice_bag.get_all()
	_desc_title.text = "MY DICE"
	var lines := ""
	for i in dice.size():
		var d: Die = dice[i]
		lines += "Die %d: %s (%s)\n" % [i + 1, str(d.faces), d.color]
	_desc_body.text = lines
	_desc_panel.visible = true


func _on_card_hover_enter(item: Dictionary) -> void:
	_desc_title.add_theme_color_override("font_color", GOLD)
	_desc_title.text = "%s  -  %d coins" % [item.get("name", ""), item.get("cost", 0)]
	_desc_body.text = item.get("description", "")
	_desc_panel.visible = true


func _on_card_hover_exit() -> void:
	_desc_panel.visible = false


func _on_shop_item_clicked(item: Dictionary) -> void:
	var success := GameManager.buy_item(item)
	if success:
		_desc_title.text = "Purchased!"
		_desc_title.add_theme_color_override("font_color", GREEN)
		_desc_body.text = item.get("name", "")
		_desc_panel.visible = true
		_update_coins()
	else:
		_desc_title.text = "Not enough coins!"
		_desc_title.add_theme_color_override("font_color", Color("ff4444"))
		_desc_body.text = ""
		_desc_panel.visible = true
