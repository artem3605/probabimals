class_name CombatProbabilityPanel
extends Control

const PROBABILITY_TOGGLE_WIDTH := 32
const PROBABILITY_TOGGLE_HEIGHT := 56
const PROBABILITY_PANEL_WIDTH := 196
const PROBABILITY_PANEL_MIN_HEIGHT := 344
const PROBABILITY_NOTICE_CHIP_WIDTH := 116
const PROBABILITY_SLIDE_SEC := 0.18
const PROBABILITY_PANEL_MARGIN := 4
const PROBABILITY_PANEL_TOP_PAD := 10
const PROBABILITY_SHADOW_OFFSET := 4.0
const PROBABILITY_DOCK_BOTTOM_PAD := 8.0
const PROBABILITY_CONTENT_SPACING := 6
const PROBABILITY_HEADER_SPACING := 8
const PROBABILITY_LIST_SPACING := 3
const PROBABILITY_ROW_GAP := 6
const PROBABILITY_ROW_MARGIN := 6
const PROBABILITY_ROW_VALUE_WIDTH := 52
const PROBABILITY_ROW_PANEL_WIDTH := PROBABILITY_PANEL_WIDTH - (PROBABILITY_PANEL_MARGIN * 2)
const PROBABILITY_ROW_NAME_WIDTH := PROBABILITY_ROW_PANEL_WIDTH - (PROBABILITY_ROW_MARGIN * 2) - PROBABILITY_ROW_GAP - PROBABILITY_ROW_VALUE_WIDTH
const PROBABILITY_TITLE_FONT_SIZE := 14
const PROBABILITY_STATUS_FONT_SIZE := 10
const PROBABILITY_ROW_NAME_FONT_SIZE := 12
const PROBABILITY_ROW_VALUE_FONT_SIZE := 12
const PROBABILITY_TOGGLE_FONT_SIZE := 14
const PROBABILITY_TOGGLE_MARGIN := 8
const PROBABILITY_DIVIDER_HEIGHT := 2
const PROBABILITY_VALUE_MIN_COLOR := Color("666666")
const PROBABILITY_VALUE_MAX_COLOR := Color("ffffff")

const DARK := Color("1a1a1a")
const GOLD := Color("ffd700")
const BORDER_BLACK := Color("000000")
const SHADOW_COLOR := Color(0, 0, 0, 0.5)
const BLUE := Color("4a9eff")
const PINK := Color("ff69b4")

var _pixel_font: Font
var _combo_rules: Array = []

var _probability_panel: PanelContainer
var _probability_shadow: ColorRect
var _probability_toggle_btn: Button
var _probability_notice_chip: PanelContainer
var _probability_notice_label: Label
var _probability_list_box: VBoxContainer
var _probability_row_entries: Array = []
var _probability_panel_collapsed: bool = true
var _probability_slide_tween: Tween
var _last_viewport_size: Vector2 = Vector2.ZERO
var _last_dice_y: float = 0.0


func setup(pixel_font: Font, combo_rules: Array) -> void:
	if _probability_panel != null:
		return

	_pixel_font = pixel_font
	_combo_rules = combo_rules.duplicate(true)
	name = "ProbabilityPanelDock"
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_probability_shadow = ColorRect.new()
	_probability_shadow.color = SHADOW_COLOR
	_probability_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_probability_shadow)

	_probability_panel = _make_panel(
		Color(0.11, 0.12, 0.14, 0.92),
		Color(0.22, 0.24, 0.27, 0.92),
		Vector2(PROBABILITY_PANEL_WIDTH, PROBABILITY_PANEL_MIN_HEIGHT),
		PROBABILITY_PANEL_MARGIN
	)
	_probability_panel.name = "ProbabilityPanel"
	_probability_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_probability_panel.clip_contents = true
	var panel_sb: StyleBoxFlat = _probability_panel.get_theme_stylebox("panel")
	panel_sb.content_margin_top = PROBABILITY_PANEL_TOP_PAD
	add_child(_probability_panel)

	_probability_toggle_btn = _make_pixel_button(
		"<",
		Vector2(PROBABILITY_TOGGLE_WIDTH, PROBABILITY_TOGGLE_HEIGHT),
		PROBABILITY_TOGGLE_FONT_SIZE
	)
	_probability_toggle_btn.name = "ProbabilityPanelToggle"
	_probability_toggle_btn.pressed.connect(_on_probability_toggle_pressed)
	add_child(_probability_toggle_btn)

	var vbox := VBoxContainer.new()
	vbox.name = "ProbabilityPanelContent"
	vbox.custom_minimum_size = Vector2(PROBABILITY_ROW_PANEL_WIDTH, 0)
	vbox.add_theme_constant_override("separation", PROBABILITY_CONTENT_SPACING)
	_probability_panel.add_child(vbox)

	var header := VBoxContainer.new()
	header.add_theme_constant_override("separation", PROBABILITY_HEADER_SPACING)
	vbox.add_child(header)

	var title := _make_pixel_label("ODDS", PROBABILITY_TITLE_FONT_SIZE, GOLD)
	title.name = "ProbabilityPanelTitle"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(title)

	_probability_notice_chip = PanelContainer.new()
	_probability_notice_chip.name = "ProbabilityPanelNoticeChip"
	_probability_notice_chip.custom_minimum_size = Vector2(PROBABILITY_NOTICE_CHIP_WIDTH, 0)
	_probability_notice_chip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header.add_child(_probability_notice_chip)

	_probability_notice_label = _make_pixel_label("ROLL FIRST", PROBABILITY_STATUS_FONT_SIZE, Color("bbbbbb"))
	_probability_notice_label.name = "ProbabilityPanelNotice"
	_probability_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_probability_notice_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_probability_notice_chip.add_child(_probability_notice_label)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0, PROBABILITY_DIVIDER_HEIGHT)
	divider.color = Color(1, 1, 1, 0.08)
	vbox.add_child(divider)

	_probability_list_box = VBoxContainer.new()
	_probability_list_box.name = "ProbabilityPanelList"
	_probability_list_box.custom_minimum_size = Vector2(PROBABILITY_ROW_PANEL_WIDTH, 0)
	_probability_list_box.add_theme_constant_override("separation", PROBABILITY_LIST_SPACING)
	vbox.add_child(_probability_list_box)

	_probability_row_entries.clear()
	for combo in _combo_rules:
		var row_data := _make_probability_row(combo)
		_probability_list_box.add_child(row_data["panel"])
		_probability_row_entries.append(row_data)

	_update_probability_rows({})
	_update_probability_panel_visibility(false)


func get_panel_node() -> PanelContainer:
	return _probability_panel


func refresh_layout(viewport_size: Vector2, dice_y: float) -> void:
	if _probability_panel == null:
		return
	_last_viewport_size = viewport_size
	_last_dice_y = dice_y
	if _probability_slide_tween != null and _probability_slide_tween.is_valid():
		_probability_slide_tween.kill()
		_probability_slide_tween = null
	_update_probability_panel_visibility(false)
	_position_probability_overlay()


func refresh_snapshot(snapshot: Dictionary, held_count: int) -> void:
	if _probability_panel == null:
		return

	if snapshot.is_empty():
		_update_probability_rows({})
		_set_probability_notice(
			"ROLL FIRST",
			Color("9ca3af"),
			Color(1, 1, 1, 0.04),
			Color(1, 1, 1, 0.12)
		)
		return

	_update_probability_rows(snapshot)

	if held_count > 0:
		_set_probability_notice(
			"%d LOCKED" % held_count,
			GOLD,
			Color(GOLD.r, GOLD.g, GOLD.b, 0.12),
			Color(GOLD.r, GOLD.g, GOLD.b, 0.36)
		)
	else:
		_set_probability_notice(
			"ALL OPEN",
			BLUE.lightened(0.15),
			Color(BLUE.r, BLUE.g, BLUE.b, 0.12),
			Color(BLUE.r, BLUE.g, BLUE.b, 0.32)
		)


func get_status_text() -> String:
	return str(_probability_notice_label.text)


func is_collapsed() -> bool:
	return _probability_panel_collapsed


func is_body_visible() -> bool:
	return not _probability_panel_collapsed


func get_toggle_right_x() -> float:
	if _probability_toggle_btn == null:
		return 0.0
	return _probability_toggle_btn.global_position.x + _probability_toggle_btn.size.x


func get_row_text(combo_type: String) -> String:
	for entry in _probability_row_entries:
		if entry["type"] == combo_type:
			return str(entry["value_label"].text)
	return ""


func get_row_name_text(combo_type: String) -> String:
	for entry in _probability_row_entries:
		if entry["type"] == combo_type:
			return str(entry["name_label"].text)
	return ""


func get_row_count() -> int:
	return _probability_row_entries.size()


func get_display_snapshot() -> Dictionary:
	var snapshot := {}
	for entry in _probability_row_entries:
		snapshot[entry["type"]] = str(entry["value_label"].text)
	return snapshot


func toggle_panel() -> void:
	_on_probability_toggle_pressed()


func _position_probability_overlay() -> void:
	if _last_viewport_size.x <= 0.0 or _last_viewport_size.y <= 0.0:
		return

	var layout := _get_probability_overlay_layout()
	var panel_x: float = float(layout["collapsed_panel_x"]) if _probability_panel_collapsed else float(layout["expanded_panel_x"])
	var toggle_x: float = float(layout["collapsed_toggle_x"]) if _probability_panel_collapsed else float(layout["expanded_toggle_x"])
	_set_probability_overlay_geometry(panel_x, toggle_x, layout)
	_probability_shadow.visible = not _probability_panel_collapsed


func _get_probability_overlay_layout() -> Dictionary:
	var panel_size := _probability_panel.get_combined_minimum_size()
	var panel_width := PROBABILITY_PANEL_WIDTH
	var panel_height := maxi(int(ceil(panel_size.y)), PROBABILITY_PANEL_MIN_HEIGHT)
	var toggle_size := _probability_toggle_btn.get_combined_minimum_size()

	var expanded_panel_x := int(_last_viewport_size.x) - panel_width
	var collapsed_panel_x := int(_last_viewport_size.x)
	var expanded_toggle_x := expanded_panel_x - int(toggle_size.x)
	var collapsed_toggle_x := int(_last_viewport_size.x) - int(toggle_size.x)
	var toggle_y := maxi(0, int(round((panel_height - toggle_size.y) / 2.0)))

	var available := _last_viewport_size.y - _last_dice_y
	var dock_y := roundf(_last_dice_y + (available - panel_height) / 2.0)

	return {
		"panel_width": panel_width,
		"panel_height": panel_height,
		"dock_y": dock_y,
		"expanded_panel_x": expanded_panel_x,
		"collapsed_panel_x": collapsed_panel_x,
		"expanded_toggle_x": expanded_toggle_x,
		"collapsed_toggle_x": collapsed_toggle_x,
		"toggle_y": toggle_y,
	}


func _set_probability_overlay_geometry(panel_x: float, toggle_x: float, layout: Dictionary) -> void:
	var panel_width: float = float(layout["panel_width"])
	var panel_height: float = float(layout["panel_height"])
	var dock_y: float = float(layout["dock_y"])
	var toggle_y: float = float(layout["toggle_y"])

	position = Vector2(0, dock_y)
	size = Vector2(_last_viewport_size.x, panel_height + PROBABILITY_DOCK_BOTTOM_PAD)
	_probability_panel.position = Vector2(panel_x, 0)
	_probability_panel.size = Vector2(panel_width, panel_height)
	_probability_toggle_btn.position = Vector2(toggle_x, toggle_y)
	_probability_shadow.position = Vector2(panel_x + PROBABILITY_SHADOW_OFFSET, PROBABILITY_SHADOW_OFFSET)
	_probability_shadow.size = Vector2(panel_width, panel_height)


func _animate_probability_overlay() -> void:
	if _last_viewport_size.x <= 0.0 or _last_viewport_size.y <= 0.0:
		return

	var layout := _get_probability_overlay_layout()
	var target_panel_x: float = float(layout["collapsed_panel_x"]) if _probability_panel_collapsed else float(layout["expanded_panel_x"])
	var target_toggle_x: float = float(layout["collapsed_toggle_x"]) if _probability_panel_collapsed else float(layout["expanded_toggle_x"])
	var toggle_y: float = float(layout["toggle_y"])
	var panel_width: float = float(layout["panel_width"])
	var panel_height: float = float(layout["panel_height"])
	var dock_y: float = float(layout["dock_y"])

	size = Vector2(_last_viewport_size.x, panel_height + PROBABILITY_DOCK_BOTTOM_PAD)
	position = Vector2(0, dock_y)
	_probability_panel.size = Vector2(panel_width, panel_height)
	_probability_toggle_btn.position.y = toggle_y
	_probability_shadow.size = Vector2(panel_width, panel_height)
	_probability_shadow.position.y = PROBABILITY_SHADOW_OFFSET

	if _probability_slide_tween != null and _probability_slide_tween.is_valid():
		_probability_slide_tween.kill()

	_probability_shadow.visible = true
	_probability_slide_tween = create_tween()
	_probability_slide_tween.set_parallel(true)
	_probability_slide_tween.set_ease(Tween.EASE_OUT)
	_probability_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_probability_slide_tween.tween_property(_probability_panel, "position:x", target_panel_x, PROBABILITY_SLIDE_SEC)
	_probability_slide_tween.tween_property(_probability_toggle_btn, "position:x", target_toggle_x, PROBABILITY_SLIDE_SEC)
	_probability_slide_tween.tween_property(_probability_shadow, "position:x", float(target_panel_x) + PROBABILITY_SHADOW_OFFSET, PROBABILITY_SLIDE_SEC)
	_probability_slide_tween.chain().tween_callback(func():
		_probability_slide_tween = null
		_set_probability_overlay_geometry(target_panel_x, target_toggle_x, layout)
		_probability_shadow.visible = not _probability_panel_collapsed
		queue_redraw()
	)


func _make_probability_row(combo: Dictionary) -> Dictionary:
	var combo_type: String = combo.get("type", "")
	var combo_name := _format_probability_row_name(str(combo.get("name", combo_type)).to_upper())

	var panel := PanelContainer.new()
	panel.name = "ProbabilityRow_%s" % combo_type
	panel.custom_minimum_size = Vector2(PROBABILITY_ROW_PANEL_WIDTH, 0)
	panel.add_theme_stylebox_override("panel", _make_style(Color(1, 1, 1, 0.03), Color(1, 1, 1, 0), 0, PROBABILITY_ROW_MARGIN))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", PROBABILITY_ROW_GAP)
	panel.add_child(row)

	var name_label := _make_pixel_label(combo_name, PROBABILITY_ROW_NAME_FONT_SIZE, Color.WHITE)
	name_label.custom_minimum_size = Vector2(PROBABILITY_ROW_NAME_WIDTH, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_FILL
	row.add_child(name_label)

	var value_label := _make_pixel_label("--", PROBABILITY_ROW_VALUE_FONT_SIZE, PROBABILITY_VALUE_MIN_COLOR)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.custom_minimum_size = Vector2(PROBABILITY_ROW_VALUE_WIDTH, 0)
	row.add_child(value_label)

	return {
		"panel": panel,
		"type": combo_type,
		"name_label": name_label,
		"value_label": value_label,
	}


func _format_probability_row_name(combo_name: String) -> String:
	var words := combo_name.split(" ", false)
	if words.size() <= 1:
		return combo_name

	var best_split := 1
	var best_delta := INF
	for split_index in range(1, words.size()):
		var left := " ".join(words.slice(0, split_index))
		var right := " ".join(words.slice(split_index))
		var delta := absf(float(left.length() - right.length()))
		if delta < best_delta:
			best_delta = delta
			best_split = split_index

	return "%s\n%s" % [
		" ".join(words.slice(0, best_split)),
		" ".join(words.slice(best_split)),
	]


func _set_probability_notice(text: String, font_color: Color, bg_color: Color, border_color: Color) -> void:
	_probability_notice_label.text = text
	_probability_notice_label.add_theme_color_override("font_color", font_color)
	_probability_notice_chip.add_theme_stylebox_override("panel", _make_style(bg_color, border_color, 2, PROBABILITY_HEADER_SPACING))


func _update_probability_panel_visibility(refresh_layout: bool = true) -> void:
	if _probability_toggle_btn == null or _probability_panel == null:
		return
	_probability_panel.visible = true
	_probability_toggle_btn.text = "<" if _probability_panel_collapsed else ">"
	queue_redraw()
	if refresh_layout:
		_animate_probability_overlay()


func _on_probability_toggle_pressed() -> void:
	_probability_panel_collapsed = not _probability_panel_collapsed
	_update_probability_panel_visibility()


func _update_probability_rows(snapshot: Dictionary) -> void:
	for entry in _probability_row_entries:
		var combo_type: String = entry["type"]
		var value_label: Label = entry["value_label"]
		var probability_value: Variant = null
		if snapshot.has(combo_type):
			probability_value = snapshot[combo_type]
		value_label.text = _format_probability(probability_value)
		value_label.add_theme_color_override("font_color", _get_probability_value_color(probability_value))


func _format_probability(probability_value: Variant) -> String:
	if probability_value == null:
		return "--"
	var percentage := float(probability_value) * 100.0
	if is_equal_approx(percentage, 100.0):
		return "100%"
	return "%.1f%%" % percentage


func _get_probability_value_color(probability_value: Variant) -> Color:
	if probability_value == null:
		return PROBABILITY_VALUE_MIN_COLOR

	var strength := clampf(float(probability_value), 0.0, 1.0)
	return PROBABILITY_VALUE_MIN_COLOR.lerp(PROBABILITY_VALUE_MAX_COLOR, strength)


func _get_combo_priority_color(priority: int) -> Color:
	match priority:
		0, 1:
			return Color("888888")
		2, 3:
			return Color("ff6b4a")
		4, 5:
			return BLUE
		6, 7:
			return GOLD
		8:
			return PINK
	return Color.WHITE


func _make_panel(bg_color: Color, border_color: Color, min_size: Vector2, margin: int = 8) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = min_size
	panel.add_theme_stylebox_override("panel", _make_style(bg_color, border_color, 4, margin))
	return panel


func _make_pixel_label(text: String, font_size: int, color: Color = DARK) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", _pixel_font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	return lbl


func _make_pixel_button(text: String, min_size: Vector2, font_size: int = 16) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = min_size
	btn.add_theme_font_override("font", _pixel_font)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_stylebox_override("normal", _make_style(DARK, BORDER_BLACK, 4, PROBABILITY_TOGGLE_MARGIN))
	btn.add_theme_stylebox_override("hover", _make_style(Color(0.25, 0.25, 0.25), Color(0.4, 0.4, 0.4), 4, PROBABILITY_TOGGLE_MARGIN))
	btn.add_theme_stylebox_override("pressed", _make_style(Color(0.04, 0.04, 0.04), BORDER_BLACK, 4, PROBABILITY_TOGGLE_MARGIN))
	btn.add_theme_stylebox_override("disabled", _make_style(Color(0.07, 0.07, 0.07), Color(0.15, 0.15, 0.15), 4, PROBABILITY_TOGGLE_MARGIN))

	var focus := _make_style(Color(0, 0, 0, 0), GOLD, 4, PROBABILITY_TOGGLE_MARGIN)
	focus.draw_center = false
	btn.add_theme_stylebox_override("focus", focus)

	btn.add_theme_color_override("font_color", GOLD)
	btn.add_theme_color_override("font_hover_color", GOLD)
	btn.add_theme_color_override("font_pressed_color", Color(0.8, 0.667, 0))
	btn.add_theme_color_override("font_focus_color", GOLD)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.35, 0.1))
	return btn


func _make_style(bg_color: Color, border_color: Color = BORDER_BLACK, border_width: int = 4, margin: int = 20) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(margin)
	return sb
