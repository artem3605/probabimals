extends "res://scripts/ui/pixel_bg.gd"

const ItemCard = preload("res://scripts/ui/item_card.gd")
const MAX_SELECTION := 5

var _selected_indices: Array[int] = []
var _subtitle_label: Label
var _confirm_btn: Button
var _menu_btn: Button
var _dice_cards: Array[ItemCard] = []
var _grid_container: GridContainer
var _desc_panel: PanelContainer
var _desc_title: Label
var _desc_body: Label


func _ready() -> void:
	super._ready()
	_build_ui()
	_update_state()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_button_shadows([_menu_btn], Vector2(4, 4))
	_draw_button_shadows([_confirm_btn], Vector2(8, 8))


func _build_ui() -> void:
	var layout := _make_screen_layout(32, true)
	var content: VBoxContainer = layout["content"]
	var action_bar: HBoxContainer = layout["action_bar"]

	_build_top_bar(content)
	_build_subtitle(content)
	_build_dice_grid(content)
	_build_description_panel(content)

	_confirm_btn = _make_colored_button("CONFIRM", Vector2(216, 64), GREEN, GREEN.lightened(0.15), 16)
	_confirm_btn.add_theme_stylebox_override("disabled", _make_style(Color("121212"), Color("262626")))
	_confirm_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.1))
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	action_bar.add_child(_confirm_btn)


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(bar)

	_menu_btn = _make_menu_button()
	bar.add_child(_menu_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	bar.add_child(_make_title_bar("SELECT DICE"))

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer2)

	var right_placeholder := Control.new()
	right_placeholder.custom_minimum_size = Vector2(96, 0)
	bar.add_child(right_placeholder)


func _build_subtitle(parent: VBoxContainer) -> void:
	_subtitle_label = _make_pixel_label("", 14)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(_subtitle_label)


func _build_dice_grid(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_grid_container = GridContainer.new()
	_grid_container.columns = 4
	_grid_container.add_theme_constant_override("h_separation", 24)
	_grid_container.add_theme_constant_override("v_separation", 24)
	center.add_child(_grid_container)

	_dice_cards.clear()
	var all_dice := GameManager.dice_bag.get_all()
	for i in all_dice.size():
		var die: Die = all_dice[i]
		var card := ItemCard.new()
		card.setup_as_dice_item(die, _pixel_font)
		card.card_pressed.connect(_on_die_card_pressed.bind(i))
		card.card_hover_entered.connect(_on_card_hover_enter.bind(card))
		card.card_hover_exited.connect(_on_card_hover_exit)
		_grid_container.add_child(card)
		_dice_cards.append(card)


# -- State management ----------------------------------------------------------

func _update_state() -> void:
	_subtitle_label.text = "Choose 5 dice (%d/%d)" % [_selected_indices.size(), MAX_SELECTION]
	_update_card_visuals()
	_update_confirm_button()


func _update_card_visuals() -> void:
	for i in _dice_cards.size():
		_dice_cards[i].set_selected(i in _selected_indices)


func _update_confirm_button() -> void:
	if _confirm_btn == null:
		return
	_confirm_btn.disabled = _selected_indices.size() != MAX_SELECTION


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


# -- Callbacks -----------------------------------------------------------------


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


func _on_die_card_pressed(index: int) -> void:
	if index in _selected_indices:
		_selected_indices.erase(index)
	else:
		if _selected_indices.size() >= MAX_SELECTION:
			return
		_selected_indices.append(index)
	_update_state()


func _on_confirm_pressed() -> void:
	if _selected_indices.size() != MAX_SELECTION:
		return

	var all_dice := GameManager.dice_bag.get_all()
	var selected: Array[Die] = []
	for idx in _selected_indices:
		if idx >= 0 and idx < all_dice.size():
			selected.append(all_dice[idx])

	GameManager.selected_dice = selected
	GameManager.go_to_combat()
