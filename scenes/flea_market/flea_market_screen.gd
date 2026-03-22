extends "res://scripts/ui/pixel_bg.gd"

const ItemCard = preload("res://scripts/ui/item_card.gd")
const ShopItemCard = preload("res://scripts/ui/shop_item_card.gd")
const TutorialOverlay = preload("res://scripts/ui/tutorial_overlay.gd")
const REROLL_COST := 10
const SHOP_SLOTS := 7

var _shop_offerings: Array[Dictionary] = []
var _sold: Array[bool] = []
var _shop_cards: Array = []
var _coin_label: Label
var _coin_panel: PanelContainer
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
var _swap_desc_panel: PanelContainer
var _swap_desc_title: Label
var _swap_desc_body: Label
var _pending_face_item: Dictionary = {}
var _pending_shop_index: int = -1
var _selected_die_index: int = -1
var _tutorial_overlay: Control


func _ready() -> void:
	super._ready()
	_build_ui()
	_generate_offerings()
	_update_coins()
	GameManager.coins_changed.connect(func(_a: int): _update_coins())
	TutorialManager.step_changed.connect(_on_tutorial_step_changed)
	TutorialManager.state_changed.connect(_on_tutorial_state_changed)
	if TutorialManager.is_active():
		TutorialManager.enter_scene(TutorialManager.SCENE_FLEA_MARKET)
	_refresh_tutorial_ui()
	AudioManager.play_music(&"menu")


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

	_reroll_btn = _make_colored_button("", Vector2(220, 68), PINK, PINK.lightened(0.15), 16)
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rtl.set_anchors_preset(Control.PRESET_CENTER)
	rtl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	rtl.grow_vertical = Control.GROW_DIRECTION_BOTH
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rtl.add_theme_font_override("normal_font", _pixel_font)
	rtl.add_theme_font_size_override("normal_font_size", 16)
	rtl.add_theme_color_override("default_color", DARK)
	rtl.text = "[center]REFRESH [img=24]res://assets/art/ui/coin.png[/img]%d[/center]" % REROLL_COST
	_reroll_btn.add_child(rtl)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	action_bar.add_child(_reroll_btn)
	_all_buttons.append(_reroll_btn)

	_ready_btn = _make_colored_button("READY!", Vector2(0, 68), GREEN, GREEN.lightened(0.15), 16)
	_ready_btn.pressed.connect(_on_ready_pressed)
	action_bar.add_child(_ready_btn)
	_all_buttons.append(_ready_btn)

	_build_face_swap_overlay()
	_build_tutorial_overlay()


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(bar)

	var left_box := HBoxContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(left_box)
	var menu_btn := _make_menu_button()
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left_box.add_child(menu_btn)
	_all_buttons.append(menu_btn)

	bar.add_child(_make_title_bar("FLEA MARKET"))

	var right_wrapper := HBoxContainer.new()
	right_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_wrapper.alignment = BoxContainer.ALIGNMENT_END
	bar.add_child(right_wrapper)

	var right_vbox := VBoxContainer.new()
	right_vbox.add_theme_constant_override("separation", 12)
	right_wrapper.add_child(right_vbox)

	_coin_panel = _make_panel(GOLD, BORDER_BLACK, Vector2(124, 48))
	right_vbox.add_child(_coin_panel)

	var coin_hbox := HBoxContainer.new()
	coin_hbox.add_theme_constant_override("separation", 8)
	coin_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_coin_panel.add_child(coin_hbox)

	var coin_icon := _create_coin_icon()
	coin_hbox.add_child(coin_icon)

	_coin_label = _make_pixel_label("", 16)
	coin_hbox.add_child(_coin_label)

	_my_dice_btn = _make_colored_button("MY BAG", Vector2(124, 44), BLUE, BLUE.lightened(0.15), 12)
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
	if TutorialManager.is_active():
		_shop_offerings = TutorialManager.get_fixed_shop_offerings()
		for _i in range(_shop_offerings.size()):
			_sold.append(false)
		_refresh_shop_display()
		return

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
	_shop_cards.clear()
	for child in _shop_container.get_children():
		_shop_container.remove_child(child)
		child.queue_free()

	for i in _shop_offerings.size():
		var item := _shop_offerings[i]
		var card := ShopItemCard.new()
		card.setup_as_shop_item(item, _pixel_font)
		card.buy_pressed.connect(_on_shop_item_buy.bind(i))
		card.card_hover_entered.connect(_on_card_hover_enter.bind(card))
		card.card_hover_exited.connect(_on_card_hover_exit)
		_shop_container.add_child(card)
		_shop_cards.append(card)

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
		_reroll_btn.disabled = GameManager.coins < REROLL_COST or TutorialManager.is_active()
	_update_buy_buttons()
	_refresh_tutorial_ui()


func _update_buy_buttons() -> void:
	var cards := _shop_cards
	for i in mini(cards.size(), _shop_offerings.size()):
		var card: ShopItemCard = cards[i]
		if card is ShopItemCard:
			if _sold[i]:
				card.set_buy_status("sold")
				card.set_accent(false)
			elif TutorialManager.is_active():
				var item_id := str(_shop_offerings[i].get("id", ""))
				var allowed := TutorialManager.is_shop_item_allowed(item_id)
				card.set_accent(allowed, GOLD)
				if allowed and GameManager.coins >= _shop_offerings[i].get("cost", 0):
					card.set_buy_status("guide")
				elif allowed:
					card.set_buy_status("no_money")
				else:
					card.set_buy_status("locked")
			elif GameManager.coins < _shop_offerings[i].get("cost", 0):
				card.set_buy_status("no_money")
				card.set_accent(false)
			else:
				card.set_buy_status("buy")
				card.set_accent(false)


# -- Callbacks -----------------------------------------------------------------


func _on_reroll_pressed() -> void:
	if TutorialManager.is_active():
		return
	if GameManager.coins < REROLL_COST:
		return
	GameManager.coins -= REROLL_COST
	GameManager.coins_changed.emit(GameManager.coins)
	_generate_offerings()
	_update_coins()


func _on_ready_pressed() -> void:
	if TutorialManager.is_active() and not TutorialManager.can_go_to_dice_select():
		return
	if TutorialManager.is_active():
		TutorialManager.report_action("go_to_dice_select")
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

	_desc_title.text = "MY BAG"
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
	var item_id := str(item.get("id", ""))

	if TutorialManager.is_active() and not TutorialManager.is_shop_item_allowed(item_id):
		return

	if item.get("category", "") == "face":
		if GameManager.coins < item.get("cost", 0):
			return
		if TutorialManager.is_active():
			TutorialManager.report_action("open_face_item", {"item_id": item_id})
		_show_die_picker(item, index)
		_refresh_tutorial_ui()
		return

	var success := GameManager.buy_item(item)
	if success:
		if TutorialManager.is_active() and item_id == "loaded_die":
			TutorialManager.report_action("buy_item", {
				"item_id": item_id,
				"die_index": GameManager.dice_bag.size() - 1,
			})
		AudioManager.play_sfx(&"purchase")
		_sold[index] = true
		_desc_title.text = "Purchased!"
		_desc_title.add_theme_color_override("font_color", GREEN)
		_desc_body.text = item.get("name", "")
		_desc_panel.visible = true
		_update_coins()
		_refresh_tutorial_ui()


# -- Face swap overlay ---------------------------------------------------------

func _build_face_swap_overlay() -> void:
	_face_swap_overlay = ColorRect.new()
	_face_swap_overlay.color = Color(0, 0, 0, 0.85)
	_face_swap_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face_swap_overlay.visible = false
	add_child(_face_swap_overlay)

	var margin := _make_screen_margin()
	_face_swap_overlay.add_child(margin)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 32)
	margin.add_child(outer)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 32)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(content)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 80)
	content.add_child(top_spacer)

	_face_swap_title = _make_pixel_label("", 24, GOLD)
	_face_swap_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_face_swap_title)

	var cards_center := CenterContainer.new()
	content.add_child(cards_center)

	_face_swap_cards = HBoxContainer.new()
	_face_swap_cards.add_theme_constant_override("separation", 24)
	cards_center.add_child(_face_swap_cards)

	var desc_center := CenterContainer.new()
	content.add_child(desc_center)

	_swap_desc_panel = _make_panel(DARK, GOLD, Vector2(420, 0), 16)
	_swap_desc_panel.visible = false
	_swap_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_center.add_child(_swap_desc_panel)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 12)
	desc_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swap_desc_panel.add_child(desc_vbox)

	_swap_desc_title = _make_pixel_label("", 14, GOLD)
	_swap_desc_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_vbox.add_child(_swap_desc_title)

	_swap_desc_body = _make_pixel_label("", 12, Color.WHITE)
	_swap_desc_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swap_desc_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_vbox.add_child(_swap_desc_body)

	var btn_center := CenterContainer.new()
	outer.add_child(btn_center)

	_face_swap_action_btn = _make_colored_button("CANCEL", Vector2(200, 68), PINK, PINK.lightened(0.15), 16)
	_face_swap_action_btn.pressed.connect(_on_face_swap_cancel)
	btn_center.add_child(_face_swap_action_btn)


func _show_die_picker(item: Dictionary, shop_index: int) -> void:
	_pending_face_item = item
	_pending_shop_index = shop_index
	_selected_die_index = -1

	var new_value: int = item.get("params", {}).get("value", 0)
	_face_swap_title.text = "Choose a die to replace a face with %d" % new_value

	_clear_swap_cards()
	_swap_desc_panel.visible = false
	var all_dice := GameManager.dice_bag.get_all()
	for i in all_dice.size():
		var die: Die = all_dice[i]
		var card := ItemCard.new()
		card.setup_as_dice_item(die, _pixel_font)
		var allowed := true
		if TutorialManager.is_active():
			allowed = TutorialManager.is_swap_die_allowed(die, i)
			card.set_accent(allowed, BLUE)
			card.modulate = Color(1, 1, 1, 1) if allowed else Color(0.75, 0.75, 0.75, 1)
		card.card_pressed.connect(_on_swap_die_selected.bind(i))
		card.card_hover_entered.connect(_on_swap_card_hover_enter.bind(card))
		card.card_hover_exited.connect(_on_swap_card_hover_exit)
		_face_swap_cards.add_child(card)

	_face_swap_action_btn.text = "CANCEL"
	_reconnect_swap_btn(_on_face_swap_cancel)

	_face_swap_overlay.visible = true
	_refresh_tutorial_ui()


func _show_face_picker(die_index: int) -> void:
	_selected_die_index = die_index
	var die := GameManager.dice_bag.get_die(die_index)
	if die == null:
		return

	var new_value: int = _pending_face_item.get("params", {}).get("value", 0)
	_face_swap_title.text = "%s\nReplace which face with %d?" % [die.die_name.to_upper(), new_value]

	const DiceFacePanel = preload("res://scripts/ui/dice_face_panel.gd")
	_clear_swap_cards()
	_swap_desc_panel.visible = false
	var card_color: Color = DIE_COLORS.get(die.color, Color.WHITE)
	for i in range(die.faces.size()):
		var face: DiceFace = die.faces[i]

		var card := ItemCard.new()
		card._setup_card(card_color, "", _pixel_font)

		var face_panel := DiceFacePanel.new()
		face_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		face_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.main_button.add_child(face_panel)
		face_panel.set_face_color(card_color)
		face_panel.set_value(face.value)

		if face.face_type != DiceFace.Type.BASIC:
			var effect_text := ""
			match face.face_type:
				DiceFace.Type.PIP:
					effect_text = "+%d" % int(face.effect_value)
				DiceFace.Type.MULT:
					effect_text = "+%dM" % int(face.effect_value)
				DiceFace.Type.XMULT:
					effect_text = "x%s" % str(face.effect_value)
				DiceFace.Type.WILD:
					effect_text = "WILD"
			var effect_label := Label.new()
			effect_label.text = effect_text
			effect_label.add_theme_font_override("font", _pixel_font)
			effect_label.add_theme_font_size_override("font_size", 10)
			effect_label.add_theme_color_override("font_color", DARK)
			effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			effect_label.custom_minimum_size = Vector2(96, 16)
			card.bottom_control = effect_label
			card._vbox.add_child(card.bottom_control)

		card.card_pressed.connect(_on_swap_face_selected.bind(i))
		if TutorialManager.is_active():
			var allowed := TutorialManager.is_swap_face_allowed(die_index, face)
			card.set_accent(allowed, BLUE)
			card.modulate = Color(1, 1, 1, 1) if allowed else Color(0.75, 0.75, 0.75, 1)
		_face_swap_cards.add_child(card)

	_face_swap_action_btn.text = "BACK"
	_reconnect_swap_btn(_on_face_swap_back)
	_refresh_tutorial_ui()


func _on_swap_die_selected(die_index: int) -> void:
	var die := GameManager.dice_bag.get_die(die_index)
	if TutorialManager.is_active() and (die == null or not TutorialManager.is_swap_die_allowed(die, die_index)):
		return
	if TutorialManager.is_active():
		TutorialManager.report_action("choose_swap_die", {
			"die_index": die_index,
			"die_color": die.color if die != null else "",
		})
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

	var die := GameManager.dice_bag.get_die(_selected_die_index)
	if die == null:
		return
	var old_face := die.get_face(face_index)
	if TutorialManager.is_active() and not TutorialManager.is_swap_face_allowed(_selected_die_index, old_face):
		return

	var selected_die_index := _selected_die_index
	var success := GameManager.buy_face_swap(selected_die_index, face_index, new_face, cost)
	_close_face_swap()
	if success:
		if TutorialManager.is_active():
			TutorialManager.report_action("swap_face", {
				"die_index": selected_die_index,
				"old_value": old_face.value,
			})
		AudioManager.play_sfx(&"purchase")
		_sold[shop_idx] = true
		_desc_title.text = "Purchased!"
		_desc_title.add_theme_color_override("font_color", GREEN)
		_desc_body.text = item_name
		_desc_panel.visible = true
		_update_coins()
		_refresh_tutorial_ui()


func _on_face_swap_cancel() -> void:
	_close_face_swap()


func _on_face_swap_back() -> void:
	_show_die_picker(_pending_face_item, _pending_shop_index)


func _close_face_swap() -> void:
	_face_swap_overlay.visible = false
	_swap_desc_panel.visible = false
	_pending_face_item = {}
	_pending_shop_index = -1
	_selected_die_index = -1
	_refresh_tutorial_ui()


func _on_swap_card_hover_enter(card: Control) -> void:
	_swap_desc_title.add_theme_color_override("font_color", GOLD)
	_swap_desc_title.text = card.hover_name
	_swap_desc_body.text = card.hover_description
	_swap_desc_panel.visible = true


func _on_swap_card_hover_exit() -> void:
	_swap_desc_panel.visible = false


func _reconnect_swap_btn(target: Callable) -> void:
	for conn in _face_swap_action_btn.pressed.get_connections():
		_face_swap_action_btn.pressed.disconnect(conn["callable"])
	_face_swap_action_btn.pressed.connect(target)


func _clear_swap_cards() -> void:
	for child in _face_swap_cards.get_children():
		child.queue_free()


func _build_tutorial_overlay() -> void:
	_tutorial_overlay = TutorialOverlay.new()
	add_child(_tutorial_overlay)
	_tutorial_overlay.setup(_pixel_font)
	_tutorial_overlay.next_pressed.connect(_on_tutorial_next_pressed)


func _refresh_tutorial_ui() -> void:
	if _tutorial_overlay == null:
		return

	_ready_btn.disabled = TutorialManager.is_active() and not TutorialManager.can_go_to_dice_select()

	if not TutorialManager.is_active() or TutorialManager.checkpoint_scene != TutorialManager.SCENE_FLEA_MARKET:
		_tutorial_overlay.hide_overlay()
		return

	match TutorialManager.step_id:
		TutorialManager.STEP_MARKET_INTRO:
			_tutorial_overlay.show_step(
				"HOW A ROUND WORKS",
				"Each round has three stops: Flea Market to improve your bag, Select Dice to choose five dice, and Combat to turn those choices into points.",
				_shop_container,
				true
			)
		TutorialManager.STEP_MARKET_GOAL:
			_tutorial_overlay.show_step(
				"WHAT YOU ARE TRYING TO DO",
				"Combat gives you only a few hands. In each hand you roll, hold what looks promising, reroll the rest, and try to reach the round target before hands run out.",
				null,
				true
			)
		TutorialManager.STEP_MARKET_SCORE:
			_tutorial_overlay.show_step(
				"HOW SCORES AND COINS CONNECT",
				"Points come from the combo you make plus the values and bonuses on the faces you keep. Clearing the round pays coins, and coins buy better odds back here.",
				_coin_panel,
				true
			)
		TutorialManager.STEP_BUY_LOADED_DIE:
			_tutorial_overlay.show_step(
				"BUY THE LOADED DIE",
				"The red Loaded Die already leans high. More 5s and 6s means pairs and multiples happen more often.",
				_find_shop_action_target("loaded_die")
			)
		TutorialManager.STEP_BUY_EXTRA_SIX:
			_tutorial_overlay.show_step(
				"ADD AN EXTRA SIX",
				"Now buy Extra Six. We will tune one basic die so it can join the Loaded Die on big rolls.",
				_find_shop_action_target("extra_6")
			)
		TutorialManager.STEP_CHOOSE_SWAP_DIE:
			_tutorial_overlay.show_step(
				"UPGRADE A BASIC DIE",
				"Pick one white basic die to upgrade. Keep the red Loaded Die unchanged.",
				_find_first_swap_card(true)
			)
		TutorialManager.STEP_CHOOSE_SWAP_FACE:
			_tutorial_overlay.show_step(
				"REPLACE A WEAK FACE",
				"Swap out a weak face: 1, 2, or 3. This shifts that die closer to the combo you want.",
				_find_first_swap_card(true)
			)
		TutorialManager.STEP_GO_TO_DICE_SELECT:
			_tutorial_overlay.show_step(
				"BAG READY",
				"You now have one die that starts strong and one die you tuned yourself. Move on and choose your five combat dice.",
				_ready_btn
			)
		_:
			_tutorial_overlay.hide_overlay()


func _find_shop_action_target(item_id: String) -> Control:
	for i in range(_shop_offerings.size()):
		if _shop_offerings[i].get("id", "") == item_id and i < _shop_cards.size():
			return _shop_cards[i].buy_button
	return _shop_container


func _find_first_swap_card(allowed: bool) -> Control:
	for child in _face_swap_cards.get_children():
		if child is ItemCard and (child as ItemCard).is_accented() == allowed:
			return child
	return _face_swap_cards


func _on_tutorial_next_pressed() -> void:
	if TutorialManager.step_id in [
		TutorialManager.STEP_MARKET_INTRO,
		TutorialManager.STEP_MARKET_GOAL,
		TutorialManager.STEP_MARKET_SCORE,
	]:
		TutorialManager.report_action("advance_intro")


func _on_tutorial_step_changed(_step: String) -> void:
	_update_buy_buttons()
	_refresh_tutorial_ui()


func _on_tutorial_state_changed() -> void:
	_update_buy_buttons()
	_refresh_tutorial_ui()
