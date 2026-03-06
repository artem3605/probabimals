extends "res://scripts/ui/pixel_bg.gd"

const ItemCard = preload("res://scripts/ui/item_card.gd")
const ShopItemCard = preload("res://scripts/ui/shop_item_card.gd")
const REROLL_COST := 10
const SHOP_SLOTS := 7

var _shop_offerings: Array[Dictionary] = []
var _sold: Array[bool] = []
var _coin_label: Label
var _shop_container: HBoxContainer
var _reroll_btn: Button
var _ready_btn: Button
var _my_dice_btn: Button
var _desc_panel: PanelContainer
var _desc_title: Label
var _desc_body: Label
var _all_buttons: Array = []

var _face_swap_overlay: ColorRect
var _face_swap_title: Label
var _face_swap_cards: HBoxContainer
var _face_swap_action_btn: Button
var _pending_face_item: Dictionary = {}
var _pending_shop_index: int = -1
var _selected_die_index: int = -1


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

	_build_face_swap_overlay()


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
	coin_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
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
	_sold.clear()
	var catalogue := DataManager.get_shop_catalogue()
	if catalogue.is_empty():
		return

	var shuffled := catalogue.duplicate()
	shuffled.shuffle()
	var count := mini(SHOP_SLOTS, shuffled.size())
	for i in count:
		_shop_offerings.append(shuffled[i])
		_sold.append(false)

	_refresh_shop_display()


func _refresh_shop_display() -> void:
	for child in _shop_container.get_children():
		child.queue_free()

	for i in _shop_offerings.size():
		var item := _shop_offerings[i]
		var card := ShopItemCard.new()
		card.setup_as_shop_item(item, _pixel_font)
		card.buy_pressed.connect(_on_shop_item_buy.bind(i))
		card.card_hover_entered.connect(_on_card_hover_enter.bind(card))
		card.card_hover_exited.connect(_on_card_hover_exit)
		_shop_container.add_child(card)

	_update_buy_buttons()


func _draw_shop_card_shadows() -> void:
	for child in _shop_container.get_children():
		if not child is ItemCard or not child.visible:
			continue
		var gp: Vector2 = child.global_position - global_position
		draw_rect(
			Rect2(gp + Vector2(4, 4), child.size),
			SHADOW_COLOR
		)


func _create_coin_icon() -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = preload("res://assets/art/ui/coin.png")
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
	_update_buy_buttons()


func _update_buy_buttons() -> void:
	var cards := _shop_container.get_children()
	for i in mini(cards.size(), _shop_offerings.size()):
		var card = cards[i]
		if card is ShopItemCard:
			if _sold[i]:
				card.set_buy_status("sold")
			elif GameManager.coins < _shop_offerings[i].get("cost", 0):
				card.set_buy_status("no_money")
			else:
				card.set_buy_status("buy")


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
		var vals := d.get_face_values().duplicate()
		vals.sort()
		var faces_str := "(%s)" % ",".join(vals.map(func(f: int) -> String: return str(f)))
		var key := "%s %s" % [d.die_name, faces_str]
		if not groups.has(key):
			groups[key] = 0
		groups[key] += 1

	_desc_title.text = "MY DICE"
	_desc_title.add_theme_color_override("font_color", GOLD)
	var lines := ""
	for key: String in groups:
		var count: int = groups[key]
		if count > 1:
			lines += "%s x%d\n" % [key, count]
		else:
			lines += "%s\n" % key
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


func _on_shop_item_buy(index: int) -> void:
	if index < 0 or index >= _shop_offerings.size() or _sold[index]:
		return
	var item := _shop_offerings[index]

	if item.get("category", "") == "face":
		if GameManager.coins < item.get("cost", 0):
			return
		_show_die_picker(item, index)
		return

	var success := GameManager.buy_item(item)
	if success:
		_sold[index] = true
		_desc_title.text = "Purchased!"
		_desc_title.add_theme_color_override("font_color", GREEN)
		_desc_body.text = item.get("name", "")
		_desc_panel.visible = true
		_update_coins()


# -- Face swap overlay ---------------------------------------------------------

func _build_face_swap_overlay() -> void:
	_face_swap_overlay = ColorRect.new()
	_face_swap_overlay.color = Color(0, 0, 0, 0.85)
	_face_swap_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face_swap_overlay.visible = false
	add_child(_face_swap_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face_swap_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 32)
	center.add_child(vbox)

	_face_swap_title = _make_pixel_label("", 24, GOLD)
	_face_swap_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_face_swap_title)

	var cards_center := CenterContainer.new()
	vbox.add_child(cards_center)

	_face_swap_cards = HBoxContainer.new()
	_face_swap_cards.add_theme_constant_override("separation", 24)
	cards_center.add_child(_face_swap_cards)

	var btn_center := CenterContainer.new()
	vbox.add_child(btn_center)

	_face_swap_action_btn = _make_colored_button("CANCEL", Vector2(200, 56), PINK, PINK.lightened(0.15), 14)
	_face_swap_action_btn.pressed.connect(_on_face_swap_cancel)
	btn_center.add_child(_face_swap_action_btn)


func _show_die_picker(item: Dictionary, shop_index: int) -> void:
	_pending_face_item = item
	_pending_shop_index = shop_index
	_selected_die_index = -1

	var new_value: int = item.get("params", {}).get("value", 0)
	_face_swap_title.text = "Choose a die to replace a face with %d" % new_value

	_clear_swap_cards()
	var all_dice := GameManager.dice_bag.get_all()
	for i in all_dice.size():
		var die: Die = all_dice[i]
		var card := ItemCard.new()
		card.setup_as_dice_item(die, _pixel_font)
		card.card_pressed.connect(_on_swap_die_selected.bind(i))
		_face_swap_cards.add_child(card)

	_face_swap_action_btn.text = "CANCEL"
	_reconnect_swap_btn(_on_face_swap_cancel)

	_face_swap_overlay.visible = true


func _show_face_picker(die_index: int) -> void:
	_selected_die_index = die_index
	var die := GameManager.dice_bag.get_die(die_index)
	if die == null:
		return

	var new_value: int = _pending_face_item.get("params", {}).get("value", 0)
	_face_swap_title.text = "%s\nReplace which face with %d?" % [die.die_name.to_upper(), new_value]

	_clear_swap_cards()
	var card_color: Color = DIE_COLORS.get(die.color, Color.WHITE)
	for i in range(die.faces.size()):
		var face: DiceFace = die.faces[i]
		var label_text := str(face.value)
		if face.face_type != DiceFace.Type.BASIC:
			match face.face_type:
				DiceFace.Type.PIP:
					label_text += "\n+%d" % int(face.effect_value)
				DiceFace.Type.MULT:
					label_text += "\n+%dM" % int(face.effect_value)
				DiceFace.Type.XMULT:
					label_text += "\nx%s" % str(face.effect_value)
				DiceFace.Type.WILD:
					label_text = "W"

		var card := ItemCard.new()
		card._setup_card(card_color, label_text, _pixel_font)
		card.card_pressed.connect(_on_swap_face_selected.bind(i))
		_face_swap_cards.add_child(card)

	_face_swap_action_btn.text = "BACK"
	_reconnect_swap_btn(_on_face_swap_back)


func _on_swap_die_selected(die_index: int) -> void:
	_show_face_picker(die_index)


func _on_swap_face_selected(face_index: int) -> void:
	var params: Dictionary = _pending_face_item.get("params", {})
	var face_id: String = params.get("face_id", "")
	var face_value: int = int(params.get("value", 1))
	var cost: int = _pending_face_item.get("cost", 0)
	var shop_idx := _pending_shop_index
	var item_name: String = _pending_face_item.get("name", "")

	var new_face := DataManager.get_dice_face(face_id)
	if new_face == null:
		new_face = DiceFace.make_basic(face_value)

	var success := GameManager.buy_face_swap(_selected_die_index, face_index, new_face, cost)
	_close_face_swap()
	if success:
		_sold[shop_idx] = true
		_desc_title.text = "Purchased!"
		_desc_title.add_theme_color_override("font_color", GREEN)
		_desc_body.text = item_name
		_desc_panel.visible = true
		_update_coins()


func _on_face_swap_cancel() -> void:
	_close_face_swap()


func _on_face_swap_back() -> void:
	_show_die_picker(_pending_face_item, _pending_shop_index)


func _close_face_swap() -> void:
	_face_swap_overlay.visible = false
	_pending_face_item = {}
	_pending_shop_index = -1
	_selected_die_index = -1


func _reconnect_swap_btn(target: Callable) -> void:
	for conn in _face_swap_action_btn.pressed.get_connections():
		_face_swap_action_btn.pressed.disconnect(conn["callable"])
	_face_swap_action_btn.pressed.connect(target)


func _clear_swap_cards() -> void:
	for child in _face_swap_cards.get_children():
		child.queue_free()
