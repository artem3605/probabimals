class_name CombatProbabilityPanel
extends PanelContainer
## Unified score + probability panel shown above the dice tray during combat.
## Top row surfaces the current combo name, running points, and the score
## breakdown. The bottom grid shows every combo's odds in three columns.
## See Figma: Probabimals – Combat Screen Redesign, node 28:909 (ScorePanel).

const RAIL_WIDTH := 978
const RAIL_HEIGHT := 180
const RAIL_BORDER_WIDTH := 0
const RAIL_PAD_TOP := 18
const RAIL_PAD_BOTTOM := 20
const RAIL_PAD_H := 24
const RAIL_SHADOW_OFFSET := Vector2(6, 6)

const SCORE_HEADER_HEIGHT := 48
const SCORE_COMBO_NAME_WIDTH := 240
const SCORE_COMBO_NAME_FONT_SIZE := 16
const SCORE_VALUE_IDLE_FONT_SIZE := 18
const SCORE_VALUE_PREVIEW_FONT_SIZE := 28
const SCORE_PTS_FONT_SIZE := 16
const SCORE_BREAKDOWN_WIDTH := 240
const SCORE_BREAKDOWN_FONT_SIZE := 14
const SCORE_PTS_SEPARATION := 6

const CONTENT_SEPARATION := 12
const BODY_COLUMN_GAP := 10
const BODY_ROW_SEPARATION := 4

const ROW_HEIGHT := 22
const ROW_BORDER_WIDTH := 2
const ROW_H_PADDING := 8
const ROW_V_PADDING := 3
const ROW_GAP := 5
const ROW_FONT_SIZE := 9
const ROW_NAME_WIDTH := 128
const ROW_MULT_WIDTH := 44
const ROW_BAR_WIDTH := 18
const ROW_BAR_HEIGHT := 4
const ROW_PCT_WIDTH := 36
const PATTERN_SQUARE := 7
const PATTERN_BORDER := 1
const PATTERN_GAP := 1

const RAIL_BG := Color("bfeeff")
const RAIL_BORDER := Color("1a1a1a")
const RAIL_SHADOW := Color(0, 0, 0, 0.55)
const HEADER_COLOR := Color("1a1a1a")
const BAR_TRACK := Color("333333")
const BAR_MUTED_FILL := Color("666666")

const GREY := Color("888888")
const ORANGE := Color("ff6b4a")
const BLUE := Color("4a9eff")
const GOLD := Color("ffd700")
const PINK := Color("ff69b4")
const GREEN := Color("9acd32")

const HIGHLIGHT_BG := Color(0.29, 0.62, 1.0, 0.22)
const HIGHLIGHT_BORDER := Color("4a9eff")
const HIGHLIGHT_NAME := Color("ffffff")

const PCT_LOW_MAX := 0.20
const PCT_MID_MAX := 0.50

var _pixel_font: Font
var _combo_rules: Array = []
var _row_entries: Array = []
var _current_combo_type: String = ""
var _status_text: String = "ROLL FIRST"
var _has_rolled: bool = false

var _score_header_row: HBoxContainer
var _combo_name_label: Label
var _score_value_label: Label
var _score_pts_suffix: Label
var _score_breakdown_label: Label
var _body_root: HBoxContainer


func setup(pixel_font: Font, combo_rules: Array) -> void:
	if not _row_entries.is_empty():
		return

	_pixel_font = pixel_font
	_combo_rules = _sort_by_priority_desc(combo_rules)

	name = "ProbabilityPanel"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(RAIL_WIDTH, RAIL_HEIGHT)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER

	add_theme_stylebox_override("panel", _build_rail_style())

	var content := VBoxContainer.new()
	content.name = "ProbabilityContent"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", CONTENT_SEPARATION)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(content)

	_build_score_header(content)
	_build_body(content)
	_refresh_rows({})


# -- Public API ---------------------------------------------------------------

func get_panel_node() -> PanelContainer:
	return self


func refresh_layout(_viewport_size: Vector2, _dice_y: float) -> void:
	# The rail now sits inline in the combat content stack, so no manual
	# positioning is required.
	pass


func refresh_snapshot(snapshot: Dictionary, held_count: int) -> void:
	if _row_entries.is_empty():
		return

	_has_rolled = not snapshot.is_empty()
	_refresh_rows(snapshot)

	if snapshot.is_empty():
		_status_text = "ROLL FIRST"
	elif held_count > 0:
		_status_text = "%d LOCKED" % held_count
	else:
		_status_text = "ALL OPEN"


func highlight_current_combo(combo_type: String) -> void:
	if _current_combo_type == combo_type:
		return
	_current_combo_type = combo_type
	_apply_row_styles()


func clear_current_combo_highlight() -> void:
	highlight_current_combo("")


# -- Accessors used by tests and combat screen -------------------------------

func get_combo_name_label() -> Label:
	return _combo_name_label


func get_score_value_label() -> Label:
	return _score_value_label


func get_score_pts_suffix_label() -> Label:
	return _score_pts_suffix


func get_score_breakdown_label() -> Label:
	return _score_breakdown_label


func get_status_text() -> String:
	return _status_text


func is_collapsed() -> bool:
	return false


func is_body_visible() -> bool:
	return true


func toggle_panel() -> void:
	pass


func get_toggle_right_x() -> float:
	return global_position.x + size.x


func get_row_text(combo_type: String) -> String:
	for entry in _row_entries:
		if entry["type"] == combo_type:
			return str(entry["pct_label"].text)
	return ""


func get_row_name_text(combo_type: String) -> String:
	for entry in _row_entries:
		if entry["type"] == combo_type:
			return str(entry["name_label"].text)
	return ""


func get_row_count() -> int:
	return _row_entries.size()


func get_display_snapshot() -> Dictionary:
	var snapshot := {}
	for entry in _row_entries:
		snapshot[entry["type"]] = str(entry["pct_label"].text)
	return snapshot


# -- Build helpers -----------------------------------------------------------

func _build_rail_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = RAIL_BG
	sb.border_color = RAIL_BORDER
	sb.set_border_width_all(RAIL_BORDER_WIDTH)
	sb.set_corner_radius_all(0)
	sb.content_margin_top = RAIL_PAD_TOP
	sb.content_margin_bottom = RAIL_PAD_BOTTOM
	sb.content_margin_left = RAIL_PAD_H
	sb.content_margin_right = RAIL_PAD_H
	sb.shadow_color = RAIL_SHADOW
	sb.shadow_size = 0
	sb.shadow_offset = RAIL_SHADOW_OFFSET
	return sb


func _build_score_header(parent: VBoxContainer) -> void:
	_score_header_row = HBoxContainer.new()
	_score_header_row.name = "ScoreHeader"
	_score_header_row.custom_minimum_size = Vector2(0, SCORE_HEADER_HEIGHT)
	_score_header_row.add_theme_constant_override("separation", 0)
	_score_header_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_score_header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score_header_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_score_header_row)

	var combo_slot := _make_header_slot(SCORE_COMBO_NAME_WIDTH, "ComboNameSlot")
	_score_header_row.add_child(combo_slot)

	_combo_name_label = _make_label("", SCORE_COMBO_NAME_FONT_SIZE, HEADER_COLOR)
	_combo_name_label.name = "ComboNameLabel"
	_combo_name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combo_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_combo_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combo_name_label.clip_text = true
	combo_slot.add_child(_combo_name_label)

	var pts_row := HBoxContainer.new()
	pts_row.name = "ScoreValueRow"
	pts_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pts_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pts_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pts_row.add_theme_constant_override("separation", SCORE_PTS_SEPARATION)
	pts_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_score_header_row.add_child(pts_row)

	_score_value_label = _make_label("ROLL!", SCORE_VALUE_IDLE_FONT_SIZE, HEADER_COLOR)
	_score_value_label.name = "ScoreValueLabel"
	_score_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pts_row.add_child(_score_value_label)

	_score_pts_suffix = _make_label("", SCORE_PTS_FONT_SIZE, HEADER_COLOR)
	_score_pts_suffix.name = "ScorePtsSuffix"
	_score_pts_suffix.size_flags_vertical = Control.SIZE_SHRINK_END
	_score_pts_suffix.visible = false
	pts_row.add_child(_score_pts_suffix)

	var breakdown_slot := _make_header_slot(SCORE_BREAKDOWN_WIDTH, "ScoreBreakdownSlot")
	_score_header_row.add_child(breakdown_slot)

	_score_breakdown_label = _make_label("", SCORE_BREAKDOWN_FONT_SIZE, HEADER_COLOR)
	_score_breakdown_label.name = "ScoreBreakdownLabel"
	_score_breakdown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_score_breakdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_score_breakdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_score_breakdown_label.clip_text = true
	breakdown_slot.add_child(_score_breakdown_label)


func _build_body(parent: VBoxContainer) -> void:
	_body_root = HBoxContainer.new()
	_body_root.name = "ProbabilityBody"
	_body_root.add_theme_constant_override("separation", BODY_COLUMN_GAP)
	_body_root.alignment = BoxContainer.ALIGNMENT_CENTER
	_body_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(_body_root)

	_row_entries.clear()
	var column_size := 3
	var column_count: int = int(ceil(float(_combo_rules.size()) / float(column_size)))
	for col in range(column_count):
		var column := VBoxContainer.new()
		column.name = "ProbabilityColumn%d" % col
		column.add_theme_constant_override("separation", BODY_ROW_SEPARATION)
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.size_flags_vertical = Control.SIZE_EXPAND_FILL
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_body_root.add_child(column)

		for row_index in range(column_size):
			var combo_index := col * column_size + row_index
			if combo_index >= _combo_rules.size():
				break
			var row_entry := _build_row(_combo_rules[combo_index])
			column.add_child(row_entry["panel"])
			_row_entries.append(row_entry)


func _build_row(combo: Dictionary) -> Dictionary:
	var combo_type: String = combo.get("type", "")
	var combo_name: String = str(combo.get("name", combo_type)).to_upper()
	var priority: int = int(combo.get("priority", 0))
	var mult: float = float(combo.get("combo_mult", 1.0))
	var priority_color := _priority_color(priority)

	var default_style := _build_row_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0))

	var panel := PanelContainer.new()
	panel.name = "ProbabilityRow_%s" % combo_type
	panel.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", default_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_GAP)
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)

	var name_label := _make_label(combo_name, ROW_FONT_SIZE, priority_color)
	name_label.custom_minimum_size = Vector2(ROW_NAME_WIDTH, 0)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	row.add_child(name_label)

	var pattern_row := HBoxContainer.new()
	pattern_row.add_theme_constant_override("separation", PATTERN_GAP)
	pattern_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	pattern_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pattern_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(pattern_row)

	var pattern_colors := _get_pattern_colors(combo_type)
	for color in pattern_colors:
		var square := PanelContainer.new()
		square.custom_minimum_size = Vector2(PATTERN_SQUARE, PATTERN_SQUARE)
		square.mouse_filter = Control.MOUSE_FILTER_IGNORE
		square.add_theme_stylebox_override("panel", _build_square_style(color))
		pattern_row.add_child(square)

	var mult_label := _make_label("x%.1f" % mult, ROW_FONT_SIZE, priority_color)
	mult_label.custom_minimum_size = Vector2(ROW_MULT_WIDTH, 0)
	mult_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mult_label.clip_text = true
	row.add_child(mult_label)

	var bar_wrapper := PanelContainer.new()
	bar_wrapper.custom_minimum_size = Vector2(ROW_BAR_WIDTH, ROW_BAR_HEIGHT)
	bar_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_wrapper.clip_contents = true
	bar_wrapper.add_theme_stylebox_override("panel", _build_bar_track_style())
	row.add_child(bar_wrapper)

	var bar_fill := ColorRect.new()
	bar_fill.color = BAR_MUTED_FILL
	bar_fill.custom_minimum_size = Vector2(0, ROW_BAR_HEIGHT)
	bar_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_wrapper.add_child(bar_fill)

	var pct_label := _make_label("--", ROW_FONT_SIZE, GREY)
	pct_label.custom_minimum_size = Vector2(ROW_PCT_WIDTH, 0)
	pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pct_label.clip_text = true
	row.add_child(pct_label)

	return {
		"panel": panel,
		"type": combo_type,
		"name_label": name_label,
		"mult_label": mult_label,
		"bar_wrapper": bar_wrapper,
		"bar_fill": bar_fill,
		"pct_label": pct_label,
		"priority_color": priority_color,
		"default_style": default_style,
	}


func _refresh_rows(snapshot: Dictionary) -> void:
	for entry in _row_entries:
		var combo_type: String = entry["type"]
		var pct_label: Label = entry["pct_label"]
		var bar_fill: ColorRect = entry["bar_fill"]
		var bar_wrapper: PanelContainer = entry["bar_wrapper"]

		var probability_value: Variant = null
		if snapshot.has(combo_type):
			probability_value = snapshot[combo_type]

		pct_label.text = _format_pct(probability_value)
		pct_label.add_theme_color_override("font_color", _pct_color(probability_value))

		var fill_color := _bar_fill_color(probability_value)
		bar_fill.color = fill_color
		var track_width := maxf(bar_wrapper.size.x, ROW_BAR_WIDTH)
		var pct := 0.0
		if probability_value != null:
			pct = clampf(float(probability_value), 0.0, 1.0)
		bar_fill.size = Vector2(track_width * pct, ROW_BAR_HEIGHT)

	_apply_row_styles()


func _apply_row_styles() -> void:
	for entry in _row_entries:
		var panel: PanelContainer = entry["panel"]
		var name_label: Label = entry["name_label"]
		if entry["type"] == _current_combo_type and not _current_combo_type.is_empty():
			panel.add_theme_stylebox_override(
				"panel",
				_build_row_style(HIGHLIGHT_BG, HIGHLIGHT_BORDER)
			)
			name_label.add_theme_color_override("font_color", HIGHLIGHT_NAME)
		else:
			panel.add_theme_stylebox_override("panel", entry["default_style"])
			name_label.add_theme_color_override("font_color", entry["priority_color"])


# -- Formatting helpers ------------------------------------------------------

func _format_pct(probability_value: Variant) -> String:
	if probability_value == null:
		return "--"
	var percentage := float(probability_value) * 100.0
	if is_equal_approx(percentage, 100.0):
		return "100%"
	if percentage >= 10.0:
		return "%d%%" % int(round(percentage))
	return "%.1f%%" % percentage


func _pct_color(probability_value: Variant) -> Color:
	if probability_value == null:
		return GREY
	var pct := clampf(float(probability_value), 0.0, 1.0)
	if pct <= PCT_LOW_MAX:
		return GREY
	if pct <= PCT_MID_MAX:
		return GOLD
	return GREEN


func _bar_fill_color(probability_value: Variant) -> Color:
	if probability_value == null:
		return BAR_MUTED_FILL
	var pct := clampf(float(probability_value), 0.0, 1.0)
	if pct <= PCT_LOW_MAX:
		return BAR_MUTED_FILL
	if pct <= PCT_MID_MAX:
		return GOLD
	return GREEN


func _priority_color(priority: int) -> Color:
	match priority:
		0, 1:
			return GREY
		2, 3:
			return ORANGE
		4, 5:
			return BLUE
		6, 7:
			return GOLD
		8:
			return PINK
	return HEADER_COLOR


func _get_pattern_colors(combo_type: String) -> Array:
	var a := BLUE
	var b := PINK
	var g := GREY
	var s := [BLUE.darkened(0.3), BLUE.darkened(0.15), BLUE, BLUE.lightened(0.15), BLUE.lightened(0.3)]
	match combo_type:
		"high_card":      return [a, g, g, g, g]
		"pair":           return [a, a, g, g, g]
		"two_pair":       return [a, a, b, b, g]
		"three_same":     return [a, a, a, g, g]
		"small_straight": return [s[0], s[1], s[2], s[3], g]
		"full_house":     return [a, a, a, b, b]
		"large_straight": return [s[0], s[1], s[2], s[3], s[4]]
		"four_same":      return [a, a, a, a, g]
		"yahtzee":        return [a, a, a, a, a]
	return [g, g, g, g, g]


func _sort_by_priority_desc(combo_rules: Array) -> Array:
	var out := combo_rules.duplicate(true)
	out.sort_custom(func(lhs, rhs):
		return int(lhs.get("priority", 0)) > int(rhs.get("priority", 0))
	)
	return out


# -- Style helpers -----------------------------------------------------------

func _build_row_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(ROW_BORDER_WIDTH)
	sb.set_corner_radius_all(0)
	sb.content_margin_left = ROW_H_PADDING
	sb.content_margin_right = ROW_H_PADDING
	sb.content_margin_top = ROW_V_PADDING
	sb.content_margin_bottom = ROW_V_PADDING
	return sb


func _build_square_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = RAIL_BORDER
	sb.set_border_width_all(PATTERN_BORDER)
	sb.set_corner_radius_all(0)
	return sb


func _build_bar_track_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = BAR_TRACK
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(0)
	return sb


func _make_header_slot(width: int, slot_name: String) -> Control:
	var slot := Control.new()
	slot.name = slot_name
	slot.custom_minimum_size = Vector2(width, 0)
	slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slot.clip_contents = true
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return slot


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", _pixel_font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl
