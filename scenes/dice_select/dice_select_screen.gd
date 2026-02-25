extends "res://scripts/ui/pixel_bg.gd"

const MAX_SELECTION := 5

var _selected_indices: Array[int] = []
var _subtitle_label: Label
var _confirm_btn: Button
var _menu_btn: Button
var _dice_cards: Array[Button] = []
var _grid_container: GridContainer
var _dice_face_textures: Array[AtlasTexture] = []


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
	_dice_face_textures = _load_dice_sheet()

	var margin := _make_screen_margin()
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 32)
	margin.add_child(vbox)

	_build_top_bar(vbox)
	_build_subtitle(vbox)
	_build_dice_grid(vbox)
	_build_confirm_bar(vbox)


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
		var card := _create_dice_card(die, i)
		_grid_container.add_child(card)


func _create_dice_card(die: Die, index: int) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)

	var card_btn := _make_icon_button(Vector2(110, 110))

	var sprite := TextureRect.new()
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = _dice_face_textures[0]
	card_btn.add_child(sprite)

	card_btn.pressed.connect(_on_die_card_pressed.bind(index))
	col.add_child(card_btn)
	_dice_cards.append(card_btn)

	var name_label := _make_pixel_label(DIE_NAMES.get(die.color, "BASIC"), 12)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(120, 18)
	col.add_child(name_label)

	return col


# -- State management ----------------------------------------------------------

func _update_state() -> void:
	_subtitle_label.text = "Choose 5 dice (%d/%d)" % [_selected_indices.size(), MAX_SELECTION]
	_update_card_visuals()
	_update_confirm_button()


func _update_card_visuals() -> void:
	for i in _dice_cards.size():
		var card_btn := _dice_cards[i]
		var is_selected := i in _selected_indices

		if is_selected:
			var sel_style := _make_style(Color.TRANSPARENT, GOLD)
			card_btn.add_theme_stylebox_override("normal", sel_style)
		else:
			card_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())


func _update_confirm_button() -> void:
	if _confirm_btn == null:
		return
	var ready := _selected_indices.size() == MAX_SELECTION
	_confirm_btn.disabled = not ready

	if ready:
		_confirm_btn.add_theme_stylebox_override("normal", _make_style(GREEN))
		_confirm_btn.add_theme_stylebox_override("hover", _make_style(GREEN.lightened(0.15)))
		_confirm_btn.add_theme_color_override("font_color", DARK)
	else:
		_confirm_btn.add_theme_stylebox_override("normal", _make_style(DISABLED_BG))
		_confirm_btn.add_theme_stylebox_override("hover", _make_style(DISABLED_BG))
		_confirm_btn.add_theme_color_override("font_color", DISABLED_TEXT)


func _build_confirm_bar(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_confirm_btn = Button.new()
	_confirm_btn.text = "CONFIRM"
	_confirm_btn.custom_minimum_size = Vector2(216, 64)
	_confirm_btn.add_theme_font_override("font", _pixel_font)
	_confirm_btn.add_theme_font_size_override("font_size", 16)
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	center.add_child(_confirm_btn)


# -- Callbacks -----------------------------------------------------------------


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
