class_name CombatProbabilityPanel
extends PanelContainer
## Unified score + probability panel shown above the dice tray during combat.
## Top row surfaces the current combo name, running points, and the score
## breakdown. The bottom grid shows every combo's odds in three columns.
## See Figma: Probabimals – Combat Screen Redesign, node 28:909 (ScorePanel).

signal combo_row_hover_entered(combo_type: String)
signal combo_row_hover_exited

const RAIL_WIDTH := 700
const RAIL_HEIGHT := 150
const RAIL_BORDER_WIDTH := 0
const RAIL_PAD_TOP := 12
const RAIL_PAD_BOTTOM := 14
const RAIL_PAD_H := 16
const RAIL_SHADOW_OFFSET := Vector2(6, 6)

const SCORE_HEADER_HEIGHT := 40
const SCORE_COMBO_NAME_WIDTH := 240
const SCORE_COMBO_NAME_FONT_SIZE := 16
const SCORE_VALUE_IDLE_FONT_SIZE := 18
const SCORE_VALUE_PREVIEW_FONT_SIZE := 28
const SCORE_PTS_FONT_SIZE := 16
const SCORE_BREAKDOWN_WIDTH := 260
const SCORE_BREAKDOWN_FONT_SIZE := 14
const SCORE_PTS_SEPARATION := 6

const CONTENT_SEPARATION := 8
const BODY_COLUMN_GAP := 10
const BODY_ROW_SEPARATION := 4

const ROW_HEIGHT := 22
const ROW_BORDER_WIDTH := 2
const ROW_H_PADDING := 8
const ROW_V_PADDING := 3
const ROW_GAP := 5
const ROW_FONT_SIZE := 9
const ROW_NAME_WIDTH := 128
const ROW_PCT_WIDTH := 56

const RAIL_BG := Color("bfeeff")
const RAIL_BORDER := Color("1a1a1a")
const RAIL_SHADOW := Color(0, 0, 0, 0.55)
const HEADER_COLOR := Color("1a1a1a")

const GREY := Color("888888")
const BLUE := Color("4a9eff")
const PINK := Color("ff69b4")
const ORANGE := Color("ff8c33")

const HIGHLIGHT_BG := Color(0.29, 0.62, 1.0, 0.22)
const HIGHLIGHT_BORDER := Color("4a9eff")
const HIGHLIGHT_NAME := Color("ffffff")

const PCT_GRADIENT_LOW := Color("b8c4cc")
const PCT_GRADIENT_HIGH := Color("000000")
const PCT_NULL_COLOR := Color("b8c4cc")

const SCRAMBLE_INTERVAL := 0.05

var _pixel_font: Font
var _combo_rules: Array = []
var _row_entries: Array = []
var _current_combo_type: String = ""
var _status_text: String = "ROLL FIRST"
var _has_rolled: bool = false
var _scramble_timer: Timer

var _score_header_row: HBoxContainer
var _combo_name_label: Label
var _score_value_label: Label
var _score_pts_suffix: Label
var _score_breakdown_label: RichTextLabel
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


func start_scramble() -> void:
	if _row_entries.is_empty():
		return
	if _scramble_timer == null:
		_scramble_timer = Timer.new()
		_scramble_timer.wait_time = SCRAMBLE_INTERVAL
		_scramble_timer.one_shot = false
		_scramble_timer.timeout.connect(_scramble_tick)
		add_child(_scramble_timer)
	_scramble_tick()
	_scramble_timer.start()


func stop_scramble() -> void:
	if _scramble_timer != null and not _scramble_timer.is_stopped():
		_scramble_timer.stop()


func _scramble_tick() -> void:
	for entry in _row_entries:
		var pct_label: Label = entry["pct_label"]
		var fake_value := randf()
		pct_label.text = _format_pct(fake_value)
		pct_label.add_theme_color_override("font_color", _pct_color(fake_value))


# -- Accessors used by tests and combat screen -------------------------------


func get_combo_name_label() -> Label:
	return _combo_name_label


func get_score_value_label() -> Label:
	return _score_value_label


func get_score_pts_suffix_label() -> Label:
	return _score_pts_suffix


func get_score_breakdown_label() -> RichTextLabel:
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


func get_combo_color(combo_type: String) -> Color:
	for entry in _row_entries:
		if entry["type"] == combo_type:
			return entry["column_color"]
	return HEADER_COLOR


func get_combo_row_info(combo_type: String) -> Dictionary:
	for entry in _row_entries:
		if entry["type"] == combo_type:
			return {
				"name": entry["name"],
				"mult": entry["mult"],
				"pattern_colors": entry["pattern_colors"],
			}
	return {}


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

	_score_breakdown_label = _make_rtl(SCORE_BREAKDOWN_FONT_SIZE, HEADER_COLOR)
	_score_breakdown_label.name = "ScoreBreakdownLabel"
	_score_breakdown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_score_breakdown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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
			var row_entry := _build_row(_combo_rules[combo_index], col)
			column.add_child(row_entry["panel"])
			_row_entries.append(row_entry)


func _build_row(combo: Dictionary, column_index: int = 0) -> Dictionary:
	var combo_type: String = combo.get("type", "")
	var combo_name: String = str(combo.get("name", combo_type)).to_upper()
	var mult: float = float(combo.get("combo_mult", 1.0))
	var priority_color := _column_color(column_index)
	var pattern_colors := _get_pattern_colors(combo_type)

	var default_style := _build_row_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0))

	var panel := PanelContainer.new()
	panel.name = "ProbabilityRow_%s" % combo_type
	panel.custom_minimum_size = Vector2(0, ROW_HEIGHT)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", default_style)
	panel.mouse_entered.connect(func(): combo_row_hover_entered.emit(combo_type))
	panel.mouse_exited.connect(func(): combo_row_hover_exited.emit())

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

	var pct_label := _make_label("--", ROW_FONT_SIZE, PCT_NULL_COLOR)
	pct_label.custom_minimum_size = Vector2(ROW_PCT_WIDTH, 0)
	pct_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pct_label.clip_text = true
	row.add_child(pct_label)

	return {
		"panel": panel,
		"type": combo_type,
		"name": combo_name,
		"mult": mult,
		"pattern_colors": pattern_colors,
		"name_label": name_label,
		"pct_label": pct_label,
		"priority_color": priority_color,
		"column_color": priority_color,
		"default_style": default_style,
	}


func _refresh_rows(snapshot: Dictionary) -> void:
	for entry in _row_entries:
		var combo_type: String = entry["type"]
		var pct_label: Label = entry["pct_label"]

		var probability_value: Variant = null
		if snapshot.has(combo_type):
			probability_value = snapshot[combo_type]

		pct_label.text = _format_pct(probability_value)
		pct_label.add_theme_color_override("font_color", _pct_color(probability_value))

	_apply_row_styles()


func _apply_row_styles() -> void:
	for entry in _row_entries:
		var panel: PanelContainer = entry["panel"]
		var name_label: Label = entry["name_label"]
		if entry["type"] == _current_combo_type and not _current_combo_type.is_empty():
			panel.add_theme_stylebox_override("panel", _build_row_style(HIGHLIGHT_BG, HIGHLIGHT_BORDER))
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
		return PCT_NULL_COLOR
	var pct := clampf(float(probability_value), 0.0, 1.0)
	var t := clampf(pct / 0.5, 0.0, 1.0)
	return PCT_GRADIENT_LOW.lerp(PCT_GRADIENT_HIGH, t)


func _column_color(column_index: int) -> Color:
	match column_index:
		0:
			return PINK
		1:
			return BLUE
		2:
			return ORANGE
	return HEADER_COLOR


func _get_pattern_colors(combo_type: String) -> Array:
	var a := BLUE
	var b := PINK
	var g := GREY
	var s := [BLUE.darkened(0.3), BLUE.darkened(0.15), BLUE, BLUE.lightened(0.15), BLUE.lightened(0.3)]
	match combo_type:
		"high_card":
			return [a, g, g, g, g]
		"pair":
			return [a, a, g, g, g]
		"two_pair":
			return [a, a, b, b, g]
		"three_same":
			return [a, a, a, g, g]
		"small_straight":
			return [s[0], s[1], s[2], s[3], g]
		"full_house":
			return [a, a, a, b, b]
		"large_straight":
			return [s[0], s[1], s[2], s[3], s[4]]
		"four_same":
			return [a, a, a, a, g]
		"yahtzee":
			return [a, a, a, a, a]
	return [g, g, g, g, g]


func _sort_by_priority_desc(combo_rules: Array) -> Array:
	var out := combo_rules.duplicate(true)
	out.sort_custom(func(lhs, rhs): return int(lhs.get("priority", 0)) > int(rhs.get("priority", 0)))
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


func _make_rtl(font_size: int, color: Color) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_OFF
	rtl.add_theme_font_override("normal_font", _pixel_font)
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_color_override("default_color", color)
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rtl
