extends "res://scripts/ui/pixel_bg.gd"

const ItemCard = preload("res://scripts/ui/item_card.gd")
const MAX_SELECTION := 5

var _groups: Array[Dictionary] = []
var _subtitle_label: Label
var _confirm_btn: Button
var _menu_btn: Button
var _dice_container: GridContainer
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

	_dice_container = GridContainer.new()
	_dice_container.columns = 7
	_dice_container.add_theme_constant_override("h_separation", 32)
	_dice_container.add_theme_constant_override("v_separation", 24)
	center.add_child(_dice_container)

	_build_groups()

	for gi in _groups.size():
		var group: Dictionary = _groups[gi]
		var die: Die = group["die"]
		var card := ItemCard.new()
		card.setup_as_dice_item(die, _pixel_font)
		card.setup_frame()
		card.card_hover_entered.connect(_on_card_hover_enter.bind(card))
		card.card_hover_exited.connect(_on_card_hover_exit)
		var counter := card.create_counter_row(_pixel_font)
		counter["minus_btn"].pressed.connect(_on_minus_pressed.bind(gi))
		counter["plus_btn"].pressed.connect(_on_plus_pressed.bind(gi))
		group["card"] = card
		group["counter_label"] = counter["label"]
		group["minus_btn"] = counter["minus_btn"]
		group["plus_btn"] = counter["plus_btn"]
		_dice_container.add_child(card)


func _build_groups() -> void:
	_groups.clear()
	var all_dice := GameManager.dice_bag.get_all()
	var color_order: Array[String] = []
	var color_map: Dictionary = {}
	for die: Die in all_dice:
		if not color_map.has(die.color):
			color_map[die.color] = {"die": die, "color": die.color, "total": 0, "selected": 0}
			color_order.append(die.color)
		color_map[die.color]["total"] += 1
	for c in color_order:
		_groups.append(color_map[c])


# -- State management ----------------------------------------------------------

func _total_selected() -> int:
	var total := 0
	for g in _groups:
		total += int(g["selected"])
	return total


func _update_state() -> void:
	_subtitle_label.text = "Choose %d dice (%d/%d)" % [MAX_SELECTION, _total_selected(), MAX_SELECTION]
	_update_counter_visuals()
	_update_confirm_button()


func _update_counter_visuals() -> void:
	var ts := _total_selected()
	for g in _groups:
		var sel: int = int(g["selected"])
		var total: int = int(g["total"])
		var lbl: Label = g["counter_label"]
		lbl.text = "%d/%d" % [sel, total]
		var minus_btn: Button = g["minus_btn"]
		minus_btn.disabled = sel <= 0
		var plus_btn: Button = g["plus_btn"]
		plus_btn.disabled = sel >= total or ts >= MAX_SELECTION
		var card: ItemCard = g["card"]
		card.set_selected(sel > 0)


func _update_confirm_button() -> void:
	if _confirm_btn == null:
		return
	_confirm_btn.disabled = _total_selected() != MAX_SELECTION


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


func _on_plus_pressed(group_index: int) -> void:
	var g := _groups[group_index]
	if int(g["selected"]) < int(g["total"]) and _total_selected() < MAX_SELECTION:
		g["selected"] = int(g["selected"]) + 1
	_update_state()


func _on_minus_pressed(group_index: int) -> void:
	var g := _groups[group_index]
	if int(g["selected"]) > 0:
		g["selected"] = int(g["selected"]) - 1
	_update_state()


func _on_confirm_pressed() -> void:
	if _total_selected() != MAX_SELECTION:
		return

	var all_dice := GameManager.dice_bag.get_all()
	var selected: Array[Die] = []
	for g in _groups:
		var count: int = int(g["selected"])
		var color: String = g["color"]
		if count <= 0:
			continue
		var picked := 0
		for die: Die in all_dice:
			if die.color == color and picked < count:
				selected.append(die)
				picked += 1

	GameManager.selected_dice = selected
	GameManager.go_to_combat()
