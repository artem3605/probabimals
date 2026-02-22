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

var _selected_indices: Array[int] = []
var _subtitle_label: Label
var _confirm_btn: Button
var _back_btn: Button
var _dice_cards: Array[Button] = []
var _grid_container: GridContainer
var _all_buttons: Array = []


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
	_draw_dice_card_shadows()


func _build_ui() -> void:
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
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	parent.add_child(bar)

	_back_btn = _make_pixel_button("BACK", Vector2(96, 56), 14)
	_back_btn.pressed.connect(_on_back_pressed)
	bar.add_child(_back_btn)
	_all_buttons.append(_back_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	var title_vbox := VBoxContainer.new()
	title_vbox.add_theme_constant_override("separation", 8)
	bar.add_child(title_vbox)

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

	# Right spacer to balance the BACK button
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer2.custom_minimum_size = Vector2(128, 0)
	bar.add_child(spacer2)


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
	card_btn.custom_minimum_size = Vector2(96, 96)
	card_btn.text = ""

	var bg_color: Color = DIE_COLORS.get(die.color, Color.WHITE)
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = bg_color
	card_style.border_color = BORDER_BLACK
	card_style.set_border_width_all(4)
	card_style.set_corner_radius_all(0)
	card_style.set_content_margin_all(4)
	card_btn.add_theme_stylebox_override("normal", card_style)

	var hover_style := card_style.duplicate()
	hover_style.border_color = GOLD
	card_btn.add_theme_stylebox_override("hover", hover_style)

	var selected_style := card_style.duplicate()
	selected_style.border_color = GOLD
	selected_style.set_border_width_all(6)
	card_btn.add_theme_stylebox_override("focus", selected_style)

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


func _draw_dice_card_shadows() -> void:
	for card_btn in _dice_cards:
		if is_instance_valid(card_btn) and card_btn.visible:
			var gp := card_btn.global_position - global_position
			draw_rect(
				Rect2(gp + Vector2(6, 6), card_btn.size),
				SHADOW_COLOR
			)


# -- State management ----------------------------------------------------------

func _update_state() -> void:
	_subtitle_label.text = "Choose 5 dice (%d/%d)" % [_selected_indices.size(), MAX_SELECTION]
	_update_card_visuals()
	_update_confirm_button()


func _update_card_visuals() -> void:
	var all_dice := GameManager.dice_bag.get_all()
	for i in _dice_cards.size():
		var card_btn := _dice_cards[i]
		var is_selected := i in _selected_indices
		var die: Die = all_dice[i] if i < all_dice.size() else null
		var bg_color: Color = DIE_COLORS.get(die.color, Color.WHITE) if die else Color.WHITE

		var style := StyleBoxFlat.new()
		style.bg_color = bg_color
		style.set_corner_radius_all(0)
		style.set_content_margin_all(4)

		if is_selected:
			style.border_color = GOLD
			style.set_border_width_all(6)
		else:
			style.border_color = BORDER_BLACK
			style.set_border_width_all(4)

		card_btn.add_theme_stylebox_override("normal", style)


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
