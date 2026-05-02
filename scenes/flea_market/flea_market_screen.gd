extends "res://scripts/ui/pixel_bg.gd"

const ItemCard = preload("res://scripts/ui/item_card.gd")
const ShopItemCard = preload("res://scripts/ui/shop_item_card.gd")
const ShopGeneratorScript = preload("res://scripts/shop/shop_generator.gd")
const ScoreFormat = preload("res://scripts/ui/score_format.gd")
const TutorialOverlay = preload("res://scripts/ui/tutorial_overlay.gd")
const SemanticMarkup = preload("res://scripts/ui/semantic_markup.gd")
const REROLL_COST := 10
const SHOP_SLOTS := ShopGeneratorScript.DEFAULT_SHOP_SLOTS
const FLEA_MARKET_CONTENT_SEPARATION := 48
const FLEA_MARKET_TOP_BAR_SEPARATION := 16
const FLEA_MARKET_STATS_SEPARATION := 12
const FLEA_MARKET_REROLL_BUTTON_SIZE := Vector2(220, 68)
const FLEA_MARKET_REROLL_FONT_SIZE := 16
const FLEA_MARKET_READY_BUTTON_SIZE := Vector2(0, 68)
const FLEA_MARKET_READY_FONT_SIZE := 16
const FLEA_MARKET_COIN_PANEL_SIZE := Vector2(124, 48)
const FLEA_MARKET_COIN_ROW_SEPARATION := 8
const FLEA_MARKET_COIN_LABEL_FONT_SIZE := 16
const FLEA_MARKET_MY_BAG_BUTTON_SIZE := Vector2(124, 44)
const FLEA_MARKET_MY_BAG_FONT_SIZE := 12
const FLEA_MARKET_SHOP_ROW_SEPARATION := 32
const FLEA_MARKET_DESC_PANEL_SIZE := Vector2(420, 0)
const FLEA_MARKET_DESC_PANEL_MARGIN := 16
const FLEA_MARKET_DESC_SEPARATION := 12
const FLEA_MARKET_DESC_TITLE_FONT_SIZE := 14
const FLEA_MARKET_DESC_BODY_FONT_SIZE := 12
const FLEA_MARKET_DESC_BODY_WIDTH := FLEA_MARKET_DESC_PANEL_SIZE.x - FLEA_MARKET_DESC_PANEL_MARGIN * 2
const FLEA_MARKET_SHOP_CARD_SHADOW_OFFSET := Vector2(4, 4)
const FLEA_MARKET_COIN_ICON_SIZE := Vector2(24, 24)
const FLEA_MARKET_FACE_SWAP_OUTER_SEPARATION := 32
const FLEA_MARKET_FACE_SWAP_CONTENT_SEPARATION := 32
const FLEA_MARKET_FACE_SWAP_TOP_SPACER := 80
const FLEA_MARKET_FACE_SWAP_TITLE_FONT_SIZE := 24
const FLEA_MARKET_FACE_SWAP_CARD_SEPARATION := 24
const FLEA_MARKET_FACE_SWAP_ACTION_BUTTON_SIZE := Vector2(200, 68)
const FLEA_MARKET_FACE_SWAP_ACTION_BUTTON_FONT_SIZE := 16
const FLEA_MARKET_EFFECT_LABEL_FONT_SIZE := 10
const FLEA_MARKET_EFFECT_LABEL_SIZE := Vector2(96, 16)

var _shop_offerings: Array[Dictionary] = []
var _sold: Array[bool] = []
var _shop_cards: Array = []
var _coin_label: Label
var _coin_panel: PanelContainer
var _shop_container: HBoxContainer
var _reroll_btn: Button
var _ready_btn: Button
var _my_dice_btn: Button
var _stats_vbox: VBoxContainer
var _desc_panel: PanelContainer
var _desc_title: RichTextLabel
var _desc_rarity: RichTextLabel
var _desc_body: RichTextLabel
var _all_buttons: Array = []

var _face_swap_overlay: ColorRect
var _face_swap_title: Label
var _face_swap_cards: HBoxContainer
var _face_swap_action_btn: Button
var _swap_desc_panel: PanelContainer
var _swap_desc_title: RichTextLabel
var _swap_desc_rarity: RichTextLabel
var _swap_desc_body: RichTextLabel
var _pending_face_item: Dictionary = {}
var _pending_shop_index: int = -1
var _selected_die_index: int = -1
var _tutorial_overlay: Control
var _shop_generator = ShopGeneratorScript.new()


func _ready() -> void:
	super._ready()
	_shop_generator.randomize_seed()
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
	var layout := _make_screen_layout(FLEA_MARKET_CONTENT_SEPARATION)
	var content: VBoxContainer = layout["content"]
	var action_bar: HBoxContainer = layout["action_bar"]

	_build_top_bar(content)
	_build_shop_row(content)
	_build_description_panel(content)

	_reroll_btn = _make_colored_button(
		"", FLEA_MARKET_REROLL_BUTTON_SIZE, PINK, PINK.lightened(0.15), FLEA_MARKET_REROLL_FONT_SIZE
	)
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
	rtl.add_theme_font_size_override("normal_font_size", FLEA_MARKET_REROLL_FONT_SIZE)
	rtl.add_theme_color_override("default_color", DARK)
	rtl.text = "[center]REFRESH [img=24]res://assets/art/ui/coin.png[/img]%d[/center]" % REROLL_COST
	_reroll_btn.add_child(rtl)
	_reroll_btn.pressed.connect(_on_reroll_pressed)
	action_bar.add_child(_reroll_btn)
	_all_buttons.append(_reroll_btn)

	_ready_btn = _make_colored_button(
		"READY!", FLEA_MARKET_READY_BUTTON_SIZE, GREEN, GREEN.lightened(0.15), FLEA_MARKET_READY_FONT_SIZE
	)
	_ready_btn.pressed.connect(_on_ready_pressed)
	action_bar.add_child(_ready_btn)
	_all_buttons.append(_ready_btn)

	_build_face_swap_overlay()
	_build_tutorial_overlay()


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", FLEA_MARKET_TOP_BAR_SEPARATION)
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

	_stats_vbox = VBoxContainer.new()
	_stats_vbox.add_theme_constant_override("separation", FLEA_MARKET_STATS_SEPARATION)
	right_wrapper.add_child(_stats_vbox)

	_coin_panel = _make_panel(GOLD, BORDER_BLACK, FLEA_MARKET_COIN_PANEL_SIZE)
	_stats_vbox.add_child(_coin_panel)

	var coin_hbox := HBoxContainer.new()
	coin_hbox.add_theme_constant_override("separation", FLEA_MARKET_COIN_ROW_SEPARATION)
	coin_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_coin_panel.add_child(coin_hbox)

	var coin_icon := _create_coin_icon()
	coin_hbox.add_child(coin_icon)

	_coin_label = _make_pixel_label("", FLEA_MARKET_COIN_LABEL_FONT_SIZE)
	coin_hbox.add_child(_coin_label)

	_my_dice_btn = _make_colored_button(
		"MY BAG", FLEA_MARKET_MY_BAG_BUTTON_SIZE, BLUE, BLUE.lightened(0.15), FLEA_MARKET_MY_BAG_FONT_SIZE
	)
	_my_dice_btn.mouse_entered.connect(_on_my_dice_hover_enter)
	_my_dice_btn.mouse_exited.connect(_on_my_dice_hover_exit)
	_stats_vbox.add_child(_my_dice_btn)
	_all_buttons.append(_my_dice_btn)


func _build_shop_row(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_shop_container = HBoxContainer.new()
	_shop_container.add_theme_constant_override("separation", FLEA_MARKET_SHOP_ROW_SEPARATION)
	center.add_child(_shop_container)


func _build_description_panel(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_desc_panel = _make_panel(DARK, GOLD, FLEA_MARKET_DESC_PANEL_SIZE, FLEA_MARKET_DESC_PANEL_MARGIN)
	_desc_panel.visible = false
	_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_desc_panel)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", FLEA_MARKET_DESC_SEPARATION)
	desc_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_panel.add_child(desc_vbox)

	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_vbox.add_child(title_row)

	_desc_title = _make_pixel_rtl(FLEA_MARKET_DESC_TITLE_FONT_SIZE, GOLD)
	_desc_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_desc_title)

	_desc_rarity = _make_pixel_rtl(FLEA_MARKET_DESC_TITLE_FONT_SIZE, Color.WHITE)
	_desc_rarity.autowrap_mode = TextServer.AUTOWRAP_OFF
	_desc_rarity.size_flags_horizontal = Control.SIZE_SHRINK_END
	_desc_rarity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(_desc_rarity)

	_desc_body = _make_pixel_rtl(FLEA_MARKET_DESC_BODY_FONT_SIZE, Color.WHITE)
	_configure_wrapped_description_body(_desc_body)
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

	_shop_offerings = _shop_generator.generate_offerings(catalogue, SHOP_SLOTS)
	for _i in range(_shop_offerings.size()):
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
		draw_rect(Rect2(gp + FLEA_MARKET_SHOP_CARD_SHADOW_OFFSET, child.size), SHADOW_COLOR)


func _create_coin_icon() -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = preload("res://assets/art/ui/coin.png")
	rect.custom_minimum_size = FLEA_MARKET_COIN_ICON_SIZE
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
				card.set_accent(_should_accent_tutorial_shop_item(item_id), GOLD)
				if allowed and GameManager.coins >= _shop_offerings[i].get("cost", 0):
					card.set_buy_status("buy")
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


func _should_accent_tutorial_shop_item(item_id: String) -> bool:
	if not TutorialManager.is_shop_item_allowed(item_id):
		return false
	return (
		TutorialManager.step_id
		not in [
			TutorialManager.STEP_BUY_LOADED_DIE,
			TutorialManager.STEP_BUY_EXTRA_SIX,
		]
	)


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
	_desc_title.add_theme_color_override("default_color", GOLD)
	_desc_rarity.text = ""
	var lines := ""
	for key: String in groups:
		var count: int = groups[key]
		if count > 1:
			lines += "%s x%d\n" % [key, count]
		else:
			lines += "%s\n" % key
	_set_description_body_text(_desc_body, lines.strip_edges())
	_desc_panel.visible = true


func _on_my_dice_hover_exit() -> void:
	_desc_panel.visible = false


func _on_card_hover_enter(card: Control) -> void:
	_desc_title.add_theme_color_override("default_color", GOLD)
	_desc_title.text = card.hover_name
	_desc_rarity.text = SemanticMarkup.format_rarity(card.hover_rarity)
	_set_description_body_text(_desc_body, SemanticMarkup.format_description(card.hover_description))
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
			(
				TutorialManager
				. report_action(
					"buy_item",
					{
						"item_id": item_id,
						"die_index": GameManager.dice_bag.size() - 1,
					}
				)
			)
		AudioManager.play_sfx(&"purchase")
		_sold[index] = true
		_desc_title.text = "Purchased!"
		_desc_title.add_theme_color_override("default_color", GREEN)
		_desc_rarity.text = ""
		_set_description_body_text(_desc_body, item.get("name", ""))
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
	outer.add_theme_constant_override("separation", FLEA_MARKET_FACE_SWAP_OUTER_SEPARATION)
	margin.add_child(outer)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", FLEA_MARKET_FACE_SWAP_CONTENT_SEPARATION)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(content)

	var top_spacer := Control.new()
	top_spacer.custom_minimum_size = Vector2(0, FLEA_MARKET_FACE_SWAP_TOP_SPACER)
	content.add_child(top_spacer)

	_face_swap_title = _make_pixel_label("", FLEA_MARKET_FACE_SWAP_TITLE_FONT_SIZE, GOLD)
	_face_swap_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(_face_swap_title)

	var cards_center := CenterContainer.new()
	content.add_child(cards_center)

	_face_swap_cards = HBoxContainer.new()
	_face_swap_cards.add_theme_constant_override("separation", FLEA_MARKET_FACE_SWAP_CARD_SEPARATION)
	cards_center.add_child(_face_swap_cards)

	var desc_center := CenterContainer.new()
	content.add_child(desc_center)

	_swap_desc_panel = _make_panel(DARK, GOLD, FLEA_MARKET_DESC_PANEL_SIZE, FLEA_MARKET_DESC_PANEL_MARGIN)
	_swap_desc_panel.visible = false
	_swap_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_center.add_child(_swap_desc_panel)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", FLEA_MARKET_DESC_SEPARATION)
	desc_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_swap_desc_panel.add_child(desc_vbox)

	var swap_title_row := HBoxContainer.new()
	swap_title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	swap_title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_vbox.add_child(swap_title_row)

	_swap_desc_title = _make_pixel_rtl(FLEA_MARKET_DESC_TITLE_FONT_SIZE, GOLD)
	_swap_desc_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	swap_title_row.add_child(_swap_desc_title)

	_swap_desc_rarity = _make_pixel_rtl(FLEA_MARKET_DESC_TITLE_FONT_SIZE, Color.WHITE)
	_swap_desc_rarity.autowrap_mode = TextServer.AUTOWRAP_OFF
	_swap_desc_rarity.size_flags_horizontal = Control.SIZE_SHRINK_END
	_swap_desc_rarity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	swap_title_row.add_child(_swap_desc_rarity)

	_swap_desc_body = _make_pixel_rtl(FLEA_MARKET_DESC_BODY_FONT_SIZE, Color.WHITE)
	_configure_wrapped_description_body(_swap_desc_body)
	desc_vbox.add_child(_swap_desc_body)

	var btn_center := CenterContainer.new()
	outer.add_child(btn_center)

	_face_swap_action_btn = _make_colored_button(
		"CANCEL",
		FLEA_MARKET_FACE_SWAP_ACTION_BUTTON_SIZE,
		PINK,
		PINK.lightened(0.15),
		FLEA_MARKET_FACE_SWAP_ACTION_BUTTON_FONT_SIZE
	)
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
	var tutorial_picking_swap_die := (
		TutorialManager.is_active() and TutorialManager.step_id == TutorialManager.STEP_CHOOSE_SWAP_DIE
	)
	for i in all_dice.size():
		var die: Die = all_dice[i]
		var card := ItemCard.new()
		card.setup_as_dice_item(die, _pixel_font)
		card.card_pressed.connect(_on_swap_die_selected.bind(i))
		card.card_hover_entered.connect(_on_swap_card_hover_enter.bind(card))
		card.card_hover_exited.connect(_on_swap_card_hover_exit)
		if tutorial_picking_swap_die:
			if TutorialManager.is_swap_die_allowed(die, i):
				card.set_accent(true, GOLD)
			else:
				_disable_swap_card(card)
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
					effect_text = ScoreFormat.prefixed_multiplier(face.effect_value)
				DiceFace.Type.WILD:
					effect_text = "WILD"
			var effect_label := Label.new()
			effect_label.text = effect_text
			effect_label.add_theme_font_override("font", _pixel_font)
			effect_label.add_theme_font_size_override("font_size", FLEA_MARKET_EFFECT_LABEL_FONT_SIZE)
			effect_label.add_theme_color_override("font_color", DARK)
			effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			effect_label.custom_minimum_size = FLEA_MARKET_EFFECT_LABEL_SIZE
			card.bottom_control = effect_label
			card._vbox.add_child(card.bottom_control)

		card.card_pressed.connect(_on_swap_face_selected.bind(i))
		_face_swap_cards.add_child(card)

	_face_swap_action_btn.text = "BACK"
	_reconnect_swap_btn(_on_face_swap_back)
	_refresh_tutorial_ui()


func _on_swap_die_selected(die_index: int) -> void:
	var die := GameManager.dice_bag.get_die(die_index)
	if TutorialManager.is_active() and (die == null or not TutorialManager.is_swap_die_allowed(die, die_index)):
		return
	if TutorialManager.is_active():
		(
			TutorialManager
			. report_action(
				"choose_swap_die",
				{
					"die_index": die_index,
					"die_color": die.color if die != null else "",
				}
			)
		)
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
	if success and TutorialManager.is_active():
		(
			TutorialManager
			. report_action(
				"swap_face",
				{
					"die_index": selected_die_index,
					"old_value": old_face.value,
				}
			)
		)
	_close_face_swap()
	if success:
		if TutorialManager.is_active():
			TutorialManager.improved_die_index = selected_die_index
		AudioManager.play_sfx(&"purchase")
		_sold[shop_idx] = true
		_desc_title.text = "Purchased!"
		_desc_title.add_theme_color_override("default_color", GREEN)
		_desc_rarity.text = ""
		_set_description_body_text(_desc_body, item_name)
		_desc_panel.visible = true
		_update_coins()
		_refresh_tutorial_ui()


func _on_face_swap_cancel() -> void:
	_close_face_swap()
	if TutorialManager.is_active():
		TutorialManager.report_action("cancel_face_item")
		_refresh_tutorial_ui()


func _on_face_swap_back() -> void:
	if TutorialManager.is_active():
		TutorialManager.report_action("back_face_item")
	_show_die_picker(_pending_face_item, _pending_shop_index)


func _close_face_swap() -> void:
	_face_swap_overlay.visible = false
	_swap_desc_panel.visible = false
	_pending_face_item = {}
	_pending_shop_index = -1
	_selected_die_index = -1
	_refresh_tutorial_ui()


func _on_swap_card_hover_enter(card: Control) -> void:
	_swap_desc_title.add_theme_color_override("default_color", GOLD)
	_swap_desc_title.text = card.hover_name
	_swap_desc_rarity.text = SemanticMarkup.format_rarity(card.hover_rarity)
	_set_description_body_text(_swap_desc_body, SemanticMarkup.format_description(card.hover_description))
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


func _disable_swap_card(card: Control) -> void:
	card.modulate = Color(1, 1, 1, 0.35)
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for descendant in card.find_children("*", "Control", true, false):
		(descendant as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _build_tutorial_overlay() -> void:
	_tutorial_overlay = TutorialOverlay.new()
	add_child(_tutorial_overlay)
	_tutorial_overlay.setup(_pixel_font)
	_tutorial_overlay.next_pressed.connect(_on_tutorial_next_pressed)
	_tutorial_overlay.skip_pressed.connect(_on_tutorial_skip_pressed)


func _refresh_tutorial_ui() -> void:
	if _tutorial_overlay == null:
		return

	_ready_btn.disabled = TutorialManager.is_active() and not TutorialManager.can_go_to_dice_select()

	if not TutorialManager.is_active() or TutorialManager.checkpoint_scene != TutorialManager.SCENE_FLEA_MARKET:
		_tutorial_overlay.hide_overlay()
		return

	if (
		_face_swap_overlay != null
		and _face_swap_overlay.visible
		and TutorialManager.step_id != TutorialManager.STEP_CHOOSE_SWAP_DIE
	):
		_tutorial_overlay.hide_overlay()
		return

	var config := TutorialManager.get_step_text()
	if config.is_empty():
		_tutorial_overlay.hide_overlay()
		return

	_tutorial_overlay.show_step_from_config(config, _get_tutorial_highlight_target())


func _get_tutorial_highlight_target() -> Variant:
	match TutorialManager.step_id:
		TutorialManager.STEP_MARKET_INTRO:
			return _shop_container
		TutorialManager.STEP_MARKET_SCORE:
			return _stats_vbox
		TutorialManager.STEP_BUY_LOADED_DIE:
			return _find_shop_action_target("loaded_die")
		TutorialManager.STEP_BUY_EXTRA_SIX:
			return _find_shop_action_target("extra_6")
		TutorialManager.STEP_CHOOSE_SWAP_DIE:
			return _find_first_swap_card(true)
		TutorialManager.STEP_GO_TO_DICE_SELECT:
			return _ready_btn
		_:
			return null


func _find_shop_action_target(item_id: String) -> Control:
	for i in range(_shop_offerings.size()):
		if _shop_offerings[i].get("id", "") == item_id and i < _shop_cards.size():
			return _shop_cards[i]
	return _shop_container


func _find_first_swap_card(allowed: bool) -> Control:
	for child in _face_swap_cards.get_children():
		if child is ItemCard and (child as ItemCard).is_accented() == allowed:
			return child
	return _face_swap_cards


func _on_tutorial_next_pressed() -> void:
	if (
		TutorialManager.step_id
		in [
			TutorialManager.STEP_MARKET_INTRO,
			TutorialManager.STEP_MARKET_SCORE,
		]
	):
		TutorialManager.report_action("advance_intro")


func _make_pixel_rtl(font_size: int, color: Color) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.add_theme_font_override("normal_font", _pixel_font)
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_color_override("default_color", color)
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rtl


func _configure_wrapped_description_body(rtl: RichTextLabel) -> void:
	rtl.fit_content = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.custom_minimum_size.x = FLEA_MARKET_DESC_BODY_WIDTH
	rtl.size.x = FLEA_MARKET_DESC_BODY_WIDTH


func _set_description_body_text(rtl: RichTextLabel, value: String) -> void:
	rtl.text = value
	rtl.size.x = FLEA_MARKET_DESC_BODY_WIDTH
	rtl.custom_minimum_size.y = maxf(float(FLEA_MARKET_DESC_BODY_FONT_SIZE), rtl.get_content_height())


func _on_tutorial_skip_pressed() -> void:
	GameManager.skip_active_tutorial()


func _on_tutorial_step_changed(_step: String) -> void:
	_update_buy_buttons()
	_refresh_tutorial_ui()


func _on_tutorial_state_changed() -> void:
	_update_buy_buttons()
	_refresh_tutorial_ui()
