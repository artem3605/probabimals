extends "res://scripts/ui/pixel_bg.gd"

const ItemCard = preload("res://scripts/ui/item_card.gd")
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
	var layout := _make_screen_layout(48)
	var content: VBoxContainer = layout["content"]
	var action_bar: HBoxContainer = layout["action_bar"]

	_build_top_bar(content)
	_build_shop_row(content)
	_build_description_panel(content)

	_reroll_btn = _make_colored_button("REROLL\n%d coins" % REROLL_COST, Vector2(152, 68), PINK, PINK.lightened(0.15), 14)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	action_bar.add_child(_reroll_btn)
	_all_buttons.append(_reroll_btn)

	_ready_btn = _make_colored_button("READY!", Vector2(168, 68), GREEN, GREEN.lightened(0.15), 16)
	_ready_btn.pressed.connect(_on_ready_pressed)
	action_bar.add_child(_ready_btn)
	_all_buttons.append(_ready_btn)


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

	var coin_icon := _create_coin_icon()
	coin_hbox.add_child(coin_icon)

	_coin_label = _make_pixel_label("", 16)
	coin_hbox.add_child(_coin_label)

	_my_dice_btn = _make_colored_button("MY DICE", Vector2(124, 44), BLUE, BLUE.lightened(0.15), 12)
	_my_dice_btn.mouse_entered.connect(_on_my_dice_hover_enter)
	_my_dice_btn.mouse_exited.connect(_on_my_dice_hover_exit)
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
		var card := ItemCard.new()
		card.setup_as_shop_item(item, _pixel_font)
		card.card_pressed.connect(_on_shop_item_clicked.bind(item))
		card.card_hover_entered.connect(_on_card_hover_enter.bind(card))
		card.card_hover_exited.connect(_on_card_hover_exit)
		_shop_container.add_child(card)


func _draw_shop_card_shadows() -> void:
	for child in _shop_container.get_children():
		if not child is ItemCard:
			continue
		var card: Control = child
		if card.get("main_button") == null:
			continue
		var btn: Button = card.get("main_button")
		if is_instance_valid(btn) and btn.visible:
			var gp: Vector2 = btn.global_position - global_position
			draw_rect(
				Rect2(gp + Vector2(4, 4), btn.size),
				SHADOW_COLOR
			)


func _create_coin_icon() -> TextureRect:
	var s := 16
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var gold := Color("ffd700")
	var highlight := Color("fff176")
	var shadow := Color("b8860b")
	var outline := Color("1a1a1a")

	var cx := 7.5
	var cy := 7.5
	for x in s:
		for y in s:
			var dx := x - cx
			var dy := y - cy
			var dist := sqrt(dx * dx + dy * dy)
			if dist <= 5.0:
				if dx + dy < -3.0:
					img.set_pixel(x, y, highlight)
				elif dx + dy > 3.0:
					img.set_pixel(x, y, shadow)
				else:
					img.set_pixel(x, y, gold)
			elif dist <= 6.5:
				img.set_pixel(x, y, outline)

	var tex := ImageTexture.create_from_image(img)
	var rect := TextureRect.new()
	rect.texture = tex
	rect.custom_minimum_size = Vector2(24, 24)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return rect


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


func _on_my_dice_hover_enter() -> void:
	var dice := GameManager.dice_bag.get_all()
	var groups: Dictionary = {}
	for d: Die in dice:
		var key := d.die_name
		if not groups.has(key):
			groups[key] = { "faces": d.faces.duplicate(), "count": 0 }
		groups[key]["count"] += 1

	var max_name := 0
	var max_faces := 0
	var entries: Array[Dictionary] = []
	for key: String in groups:
		var g: Dictionary = groups[key]
		var faces_str := "(%s)" % ",".join(g["faces"].map(func(f: int) -> String: return str(f)))
		if key.length() > max_name:
			max_name = key.length()
		if faces_str.length() > max_faces:
			max_faces = faces_str.length()
		entries.append({ "name": key, "faces": faces_str, "count": g["count"] })

	_desc_title.text = "MY DICE"
	_desc_title.add_theme_color_override("font_color", GOLD)
	var lines := ""
	for e: Dictionary in entries:
		var padded_name: String = e["name"]
		while padded_name.length() < max_name:
			padded_name += " "
		var padded_faces: String = e["faces"]
		while padded_faces.length() < max_faces:
			padded_faces += " "
		lines += "%s %s x%d\n" % [padded_name, padded_faces, e["count"]]
	_desc_body.text = lines.strip_edges()
	_desc_panel.visible = true


func _on_my_dice_hover_exit() -> void:
	_desc_panel.visible = false


func _on_card_hover_enter(card: Control) -> void:
	_desc_title.add_theme_color_override("font_color", GOLD)
	if card.hover_cost >= 0:
		_desc_title.text = "%s  -  %d coins" % [card.hover_name, card.hover_cost]
	else:
		_desc_title.text = card.hover_name
	_desc_body.text = card.hover_description
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
