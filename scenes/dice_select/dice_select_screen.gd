extends "res://scripts/ui/pixel_bg.gd"

const MAX_SELECTION := 5

const DIE_COLORS := {
	"colorless": Color.WHITE,
	"red": Color("ff4444"),
	"green": Color("9acd32"),
	"blue": Color("4a9eff"),
	"gold": Color("ffd700"),
	"purple": Color("9b59b6"),
}

const DIE_NAMES := {
	"colorless": "Basic Die",
	"red": "Red Die",
	"green": "Green Die",
	"blue": "Blue Die",
	"gold": "Gold Die",
	"purple": "Purple Die",
}

const DICE_SHEET_COLS := 3
const DICE_SHEET_ROWS := 2

var _selected_indices: Array[int] = []
var _subtitle_label: Label
var _confirm_btn: Button
var _back_btn: Button
var _dice_cards: Array[Button] = []
var _grid_container: GridContainer
var _all_buttons: Array = []
var _dice_face_textures: Array[AtlasTexture] = []


func _ready() -> void:
	super._ready()
	_build_ui()
	_update_state()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_button_shadows([_back_btn], Vector2(4, 4))
	_draw_button_shadows([_confirm_btn], Vector2(8, 8))


func _load_dice_sheet() -> void:
	var sheet: Texture2D = load("res://assets/art/dice/dice_sheet.png")
	var cell_w := sheet.get_width() / float(DICE_SHEET_COLS)
	var cell_h := sheet.get_height() / float(DICE_SHEET_ROWS)
	for row in DICE_SHEET_ROWS:
		for col in DICE_SHEET_COLS:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(col * cell_w, row * cell_h, cell_w, cell_h)
			_dice_face_textures.append(atlas)


func _build_ui() -> void:
	_load_dice_sheet()

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 64)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 32)
	margin.add_child(vbox)

	_build_top_bar(vbox)
	_build_subtitle(vbox)
	_build_dice_grid(vbox)
	_build_confirm_bar(vbox)


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 56)
	parent.add_child(bar)

	_back_btn = _make_pixel_button("BACK", Vector2(96, 56), 14)
	_back_btn.pressed.connect(_on_back_pressed)
	_back_btn.position = Vector2.ZERO
	bar.add_child(_back_btn)
	_all_buttons.append(_back_btn)

	var title_center := CenterContainer.new()
	title_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(title_center)

	var title_vbox := VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 8)
	title_center.add_child(title_vbox)

	var title := Label.new()
	title.text = "SELECT DICE"
	title.add_theme_font_override("font", _pixel_font)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DARK)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_vbox.add_child(title)

	var underline := ColorRect.new()
	underline.custom_minimum_size = Vector2(296, 4)
	underline.color = DARK
	title_vbox.add_child(underline)


func _build_subtitle(parent: VBoxContainer) -> void:
	_subtitle_label = Label.new()
	_subtitle_label.add_theme_font_override("font", _pixel_font)
	_subtitle_label.add_theme_font_size_override("font_size", 14)
	_subtitle_label.add_theme_color_override("font_color", DARK)
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

	var card_btn := Button.new()
	card_btn.custom_minimum_size = Vector2(110, 110)
	card_btn.text = ""

	var empty := StyleBoxEmpty.new()
	card_btn.add_theme_stylebox_override("normal", empty)
	card_btn.add_theme_stylebox_override("hover", empty)
	card_btn.add_theme_stylebox_override("pressed", empty)
	card_btn.add_theme_stylebox_override("focus", empty)

	var sprite := TextureRect.new()
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = _dice_face_textures[0]
	card_btn.add_child(sprite)

	card_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card_btn.pressed.connect(_on_die_card_pressed.bind(index))
	col.add_child(card_btn)
	_dice_cards.append(card_btn)

	var name_label := Label.new()
	name_label.text = DIE_NAMES.get(die.color, "Basic Die")
	name_label.add_theme_font_override("font", _pixel_font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", DARK)
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
			var sel_style := StyleBoxFlat.new()
			sel_style.bg_color = Color.TRANSPARENT
			sel_style.border_color = GOLD
			sel_style.set_border_width_all(4)
			sel_style.set_corner_radius_all(0)
			card_btn.add_theme_stylebox_override("normal", sel_style)
		else:
			card_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())


func _update_confirm_button() -> void:
	if _confirm_btn == null:
		return
	var ready := _selected_indices.size() == MAX_SELECTION
	_confirm_btn.disabled = not ready

	var style := StyleBoxFlat.new()
	style.set_border_width_all(4)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(8)
	style.border_color = BORDER_BLACK

	if ready:
		style.bg_color = Color("9acd32")
		_confirm_btn.add_theme_color_override("font_color", DARK)
	else:
		style.bg_color = Color("99a1af")
		_confirm_btn.add_theme_color_override("font_color", Color("4a5565"))

	_confirm_btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	if ready:
		hover.bg_color = Color("b0dd48")
	_confirm_btn.add_theme_stylebox_override("hover", hover)


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
	_all_buttons.append(_confirm_btn)


# -- Callbacks -----------------------------------------------------------------

func _on_back_pressed() -> void:
	GameManager.go_to_flea_market()


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
