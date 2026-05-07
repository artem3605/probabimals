extends "res://scripts/ui/pixel_bg.gd"

const ItemCard = preload("res://scripts/ui/item_card.gd")
const TutorialOverlay = preload("res://scripts/ui/tutorial_overlay.gd")
const SemanticMarkup = preload("res://scripts/ui/semantic_markup.gd")
const MAX_SELECTION := 5
const DICE_SELECT_CONTENT_SEPARATION := 32
const DICE_SELECT_TOP_BAR_SEPARATION := 16
const DICE_SELECT_CONFIRM_BUTTON_SIZE := Vector2(216, 64)
const DICE_SELECT_CONFIRM_BUTTON_FONT_SIZE := 16
const DICE_SELECT_RIGHT_PLACEHOLDER_SIZE := Vector2(96, 0)
const DICE_SELECT_SUBTITLE_FONT_SIZE := 14
const DICE_SELECT_GRID_COLUMNS := 7
const DICE_SELECT_GRID_H_SEPARATION := 32
const DICE_SELECT_GRID_V_SEPARATION := 24
const DICE_SELECT_DESC_PANEL_SIZE := Vector2(420, 0)
const DICE_SELECT_DESC_PANEL_MARGIN := 16
const DICE_SELECT_DESC_SEPARATION := 12
const DICE_SELECT_DESC_TITLE_FONT_SIZE := 14
const DICE_SELECT_DESC_BODY_FONT_SIZE := 12
const DICE_SELECT_DESC_BODY_WIDTH := DICE_SELECT_DESC_PANEL_SIZE.x - DICE_SELECT_DESC_PANEL_MARGIN * 2

var _groups: Array[Dictionary] = []
var _subtitle_label: Label
var _confirm_btn: Button
var _menu_btn: Button
var _dice_container: GridContainer
var _desc_panel: PanelContainer
var _desc_title: RichTextLabel
var _desc_rarity: RichTextLabel
var _desc_body: RichTextLabel
var _tutorial_overlay: Control


func _ready() -> void:
	super._ready()
	_build_ui()
	_update_state()
	TutorialManager.step_changed.connect(_on_tutorial_step_changed)
	TutorialManager.state_changed.connect(_refresh_tutorial_ui)
	if TutorialManager.is_active():
		TutorialManager.enter_scene(TutorialManager.SCENE_DICE_SELECT)
	_refresh_tutorial_ui()
	AudioManager.play_music(&"menu")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_button_shadows([_menu_btn], Vector2(4, 4))
	_draw_button_shadows([_confirm_btn], Vector2(8, 8))


func _build_ui() -> void:
	var layout := _make_screen_layout(DICE_SELECT_CONTENT_SEPARATION, true)
	var content: VBoxContainer = layout["content"]
	var action_bar: HBoxContainer = layout["action_bar"]

	_build_top_bar(content)
	_build_subtitle(content)
	_build_dice_grid(content)
	_build_description_panel(content)
	_build_tutorial_overlay()

	_confirm_btn = _make_colored_button(
		"CONFIRM", DICE_SELECT_CONFIRM_BUTTON_SIZE, GREEN, GREEN.lightened(0.15), DICE_SELECT_CONFIRM_BUTTON_FONT_SIZE
	)
	_confirm_btn.add_theme_stylebox_override("disabled", _make_style(Color("121212"), Color("262626")))
	_confirm_btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.1))
	_confirm_btn.disabled = true
	_confirm_btn.pressed.connect(_on_confirm_pressed)
	action_bar.add_child(_confirm_btn)


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", DICE_SELECT_TOP_BAR_SEPARATION)
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
	right_placeholder.custom_minimum_size = DICE_SELECT_RIGHT_PLACEHOLDER_SIZE
	bar.add_child(right_placeholder)


func _build_subtitle(parent: VBoxContainer) -> void:
	_subtitle_label = _make_pixel_label("", DICE_SELECT_SUBTITLE_FONT_SIZE)
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(_subtitle_label)


func _build_dice_grid(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_dice_container = GridContainer.new()
	_dice_container.columns = DICE_SELECT_GRID_COLUMNS
	_dice_container.add_theme_constant_override("h_separation", DICE_SELECT_GRID_H_SEPARATION)
	_dice_container.add_theme_constant_override("v_separation", DICE_SELECT_GRID_V_SEPARATION)
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
		_connect_button_sfx(counter["minus_btn"])
		_connect_button_sfx(counter["plus_btn"])
		group["card"] = card
		group["counter_label"] = counter["label"]
		group["minus_btn"] = counter["minus_btn"]
		group["plus_btn"] = counter["plus_btn"]
		_dice_container.add_child(card)


func _build_groups() -> void:
	_groups.clear()
	var all_dice := GameManager.dice_bag.get_all()
	var key_order: Array[String] = []
	var key_map: Dictionary = {}
	for i in all_dice.size():
		var die: Die = all_dice[i]
		var key := _die_group_key(die)
		if not key_map.has(key):
			key_map[key] = {"die": die, "color": die.color, "total": 0, "selected": 0, "indices": []}
			key_order.append(key)
		key_map[key]["total"] += 1
		key_map[key]["indices"].append(i)
	for k in key_order:
		_groups.append(key_map[k])


func _die_group_key(die: Die) -> String:
	var parts: Array[String] = []
	for f: DiceFace in die.faces:
		parts.append("%d:%d:%.2f" % [f.value, f.face_type, f.effect_value])
	parts.sort()
	return "%s|%s" % [die.color, "|".join(parts)]


# -- State management ----------------------------------------------------------


func _total_selected() -> int:
	var total := 0
	for g in _groups:
		total += int(g["selected"])
	return total


func _update_state() -> void:
	if TutorialManager.is_active():
		_subtitle_label.text = (
			"Choose %d dice. Include the Loaded Die and your upgraded die. (%d/%d)"
			% [MAX_SELECTION, _total_selected(), MAX_SELECTION]
		)
	else:
		_subtitle_label.text = "Choose %d dice (%d/%d)" % [MAX_SELECTION, _total_selected(), MAX_SELECTION]
	_update_counter_visuals()
	_update_confirm_button()
	_refresh_tutorial_ui()


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
		card.set_accent(false)
		card.set_selected(sel > 0)


func _update_confirm_button() -> void:
	if _confirm_btn == null:
		return
	if TutorialManager.is_active():
		_confirm_btn.disabled = not TutorialManager.selection_meets_requirements(_get_selected_indices())
	else:
		_confirm_btn.disabled = _total_selected() != MAX_SELECTION


func _build_description_panel(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_desc_panel = _make_panel(DARK, GOLD, DICE_SELECT_DESC_PANEL_SIZE, DICE_SELECT_DESC_PANEL_MARGIN)
	_desc_panel.visible = false
	_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_desc_panel)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", DICE_SELECT_DESC_SEPARATION)
	desc_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_panel.add_child(desc_vbox)

	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_vbox.add_child(title_row)

	_desc_title = _make_pixel_rtl(DICE_SELECT_DESC_TITLE_FONT_SIZE, GOLD)
	_desc_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_desc_title)

	_desc_rarity = _make_pixel_rtl(DICE_SELECT_DESC_TITLE_FONT_SIZE, Color.WHITE)
	_desc_rarity.autowrap_mode = TextServer.AUTOWRAP_OFF
	_desc_rarity.size_flags_horizontal = Control.SIZE_SHRINK_END
	_desc_rarity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(_desc_rarity)

	_desc_body = _make_pixel_rtl(DICE_SELECT_DESC_BODY_FONT_SIZE, Color.WHITE)
	_configure_wrapped_description_body(_desc_body)
	desc_vbox.add_child(_desc_body)


# -- Callbacks -----------------------------------------------------------------


func _on_card_hover_enter(card: Control) -> void:
	_desc_title.add_theme_color_override("default_color", GOLD)
	_desc_title.text = card.hover_name
	_desc_rarity.text = SemanticMarkup.format_rarity(card.hover_rarity)
	_set_description_body_text(_desc_body, SemanticMarkup.format_description(card.hover_description))
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
	var selected_indices: Array[int] = []
	for g in _groups:
		var count: int = int(g["selected"])
		if count <= 0:
			continue
		var indices: Array = g["indices"]
		for j in count:
			var bag_index := int(indices[j])
			selected.append(all_dice[bag_index])
			selected_indices.append(bag_index)

	if TutorialManager.is_active():
		if not TutorialManager.selection_meets_requirements(selected_indices):
			return
		TutorialManager.report_action("confirm_selection", {"selected_indices": selected_indices})

	GameManager.selected_dice = selected
	GameManager.go_to_combat()


func _go_to_main_menu() -> void:
	if GameManager.current_run != null:
		GameManager.abandon_run()
	GameManager.go_to_main_menu()


func _group_is_required(group: Dictionary) -> bool:
	if not TutorialManager.is_active():
		return false
	var required_indices := TutorialManager.get_required_bag_indices()
	for bag_index in group["indices"]:
		if required_indices.has(int(bag_index)):
			return true
	return false


func _get_selected_indices() -> Array[int]:
	var indices: Array[int] = []
	for g in _groups:
		var count: int = int(g["selected"])
		if count <= 0:
			continue
		var group_indices: Array = g["indices"]
		for j in count:
			indices.append(int(group_indices[j]))
	return indices


func _build_tutorial_overlay() -> void:
	_tutorial_overlay = TutorialOverlay.new()
	add_child(_tutorial_overlay)
	_tutorial_overlay.setup(_pixel_font)


func _refresh_tutorial_ui() -> void:
	if _tutorial_overlay == null:
		return
	if not TutorialManager.is_active() or TutorialManager.checkpoint_scene != TutorialManager.SCENE_DICE_SELECT:
		_tutorial_overlay.hide_overlay()
		return

	var config := TutorialManager.get_step_text()
	if config.is_empty():
		_tutorial_overlay.hide_overlay()
		return

	if _total_selected() == MAX_SELECTION and TutorialManager.selection_meets_requirements(_get_selected_indices()):
		var ready_config := {
			"title": "GO TO COMBAT!",
			"body": "You've picked your five! Hit Confirm to enter the battle.",
			"panel_width": 710,
			"panel_anchor": Vector2(0.5, 0.82),
		}
		_tutorial_overlay.show_step_from_config(ready_config, _confirm_btn)
	else:
		_tutorial_overlay.show_step_from_config(config, _dice_container)


func _find_required_group_targets() -> Array[Control]:
	var targets: Array[Control] = []
	for g in _groups:
		if _group_is_required(g):
			targets.append(g["card"])
	if targets.is_empty():
		targets.append(_dice_container)
	return targets


func _on_tutorial_step_changed(_step: String) -> void:
	_refresh_tutorial_ui()


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
	rtl.custom_minimum_size.x = DICE_SELECT_DESC_BODY_WIDTH
	rtl.size.x = DICE_SELECT_DESC_BODY_WIDTH


func _set_description_body_text(rtl: RichTextLabel, value: String) -> void:
	rtl.text = value
	rtl.size.x = DICE_SELECT_DESC_BODY_WIDTH
	rtl.custom_minimum_size.y = maxf(float(DICE_SELECT_DESC_BODY_FONT_SIZE), rtl.get_content_height())
