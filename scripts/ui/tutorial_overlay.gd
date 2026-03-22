extends Control

signal next_pressed

const PANEL_BG := Color("1a1a1a")
const PANEL_BORDER := Color("ffd700")
const SHADE_COLOR := Color(0, 0, 0, 0.45)
const HIGHLIGHT_FILL := Color(0.29, 0.62, 1.0, 0.16)
const HIGHLIGHT_BORDER := Color("ffd700")
const PANEL_MIN_WIDTH := 620.0
const PANEL_MARGIN_LEFT := 32.0
const PANEL_MARGIN_RIGHT := 32.0
const PANEL_MARGIN_TOP := 48.0
const PANEL_MARGIN_BOTTOM := 24.0
const PANEL_CONTENT_MARGIN := 20.0
const PANEL_GAP := 24.0
const HIGHLIGHT_PADDING := 8.0

var _highlight_targets: Array[Control] = []
var _avoid_targets: Array[Control] = []
var _panel: PanelContainer
var _title_label: Label
var _body_label: Label
var _next_btn: Button
var _font: Font


func setup(pixel_font: Font) -> void:
	if _panel != null:
		return

	_font = pixel_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(PANEL_MIN_WIDTH, 0)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel", _make_style(PANEL_BG, PANEL_BORDER, 4, int(PANEL_CONTENT_MARGIN)))
	add_child(_panel)

	var panel_vbox := VBoxContainer.new()
	panel_vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(panel_vbox)

	_title_label = _make_label("", 18, PANEL_BORDER)
	panel_vbox.add_child(_title_label)

	_body_label = _make_label("", 12, Color.WHITE)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.custom_minimum_size = Vector2(580, 0)
	panel_vbox.add_child(_body_label)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 12)
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	panel_vbox.add_child(btn_row)

	_next_btn = _make_green_button("NEXT", Vector2(164, 52), 14)
	_next_btn.pressed.connect(func(): next_pressed.emit())
	btn_row.add_child(_next_btn)

	hide_overlay()


func show_step(title: String, body: String, highlight_targets: Variant = null,
		show_next: bool = false, next_text: String = "NEXT", avoid_targets: Variant = null) -> void:
	visible = true
	_highlight_targets = _normalize_targets(highlight_targets)
	_avoid_targets = _normalize_targets(avoid_targets)
	_title_label.text = title
	_body_label.text = body
	_next_btn.visible = show_next
	_next_btn.text = next_text
	_update_panel_layout()
	queue_redraw()


func hide_overlay() -> void:
	visible = false
	_highlight_targets.clear()
	_avoid_targets.clear()
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		_update_panel_layout()
		queue_redraw()


func _draw() -> void:
	if not visible:
		return
	draw_rect(Rect2(Vector2.ZERO, size), SHADE_COLOR)

	for highlight_target in _highlight_targets:
		if not is_instance_valid(highlight_target) or not highlight_target.visible:
			continue
		var highlight_rect := Rect2(
			highlight_target.global_position - global_position - Vector2(HIGHLIGHT_PADDING, HIGHLIGHT_PADDING),
			highlight_target.size + Vector2(HIGHLIGHT_PADDING * 2.0, HIGHLIGHT_PADDING * 2.0)
		)
		draw_rect(highlight_rect, HIGHLIGHT_FILL)
		draw_rect(highlight_rect, HIGHLIGHT_BORDER, false, 4.0)


func _normalize_targets(raw_targets: Variant) -> Array[Control]:
	var targets: Array[Control] = []
	if raw_targets == null:
		return targets
	if raw_targets is Control:
		targets.append(raw_targets as Control)
		return targets
	if raw_targets is Array:
		for entry in raw_targets:
			if entry is Control:
				targets.append(entry as Control)
	return targets


func _update_panel_layout() -> void:
	if _panel == null:
		return

	var available_width := maxf(280.0, size.x - PANEL_MARGIN_LEFT - PANEL_MARGIN_RIGHT)
	var label_width := maxf(240.0, minf(580.0, available_width - PANEL_CONTENT_MARGIN * 2.0))
	_body_label.custom_minimum_size = Vector2(label_width, 0)
	_body_label.size.x = label_width
	_panel.custom_minimum_size = Vector2(minf(PANEL_MIN_WIDTH, available_width), 0)
	_panel.reset_size()

	var panel_size := _panel.get_combined_minimum_size()
	panel_size.x = clampf(panel_size.x, 240.0, available_width)
	panel_size.y = minf(panel_size.y, maxf(120.0, size.y - PANEL_MARGIN_TOP - PANEL_MARGIN_BOTTOM))
	_panel.size = panel_size

	var max_x := maxf(PANEL_MARGIN_LEFT, size.x - PANEL_MARGIN_RIGHT - panel_size.x)
	var max_y := maxf(PANEL_MARGIN_TOP, size.y - PANEL_MARGIN_BOTTOM - panel_size.y)
	var highlight_bounds := _get_highlight_bounds(_highlight_targets)
	var avoid_bounds := _get_avoid_bounds()
	var panel_pos := Vector2(PANEL_MARGIN_LEFT, max_y)

	if avoid_bounds.size != Vector2.ZERO:
		var center_x := avoid_bounds.get_center().x - panel_size.x * 0.5
		var center_y := avoid_bounds.get_center().y - panel_size.y * 0.5
		var candidate_positions := [
			Vector2(center_x, avoid_bounds.end.y + PANEL_GAP),
			Vector2(center_x, avoid_bounds.position.y - panel_size.y - PANEL_GAP),
			Vector2(avoid_bounds.position.x - panel_size.x - PANEL_GAP, center_y),
			Vector2(avoid_bounds.end.x + PANEL_GAP, center_y),
			Vector2(PANEL_MARGIN_LEFT, PANEL_MARGIN_TOP),
			Vector2(max_x, PANEL_MARGIN_TOP),
			Vector2(PANEL_MARGIN_LEFT, max_y),
			Vector2(max_x, max_y),
		]
		panel_pos = _choose_best_panel_position(candidate_positions, panel_size, avoid_bounds, max_x, max_y)

	_panel.position = panel_pos.round()


func _get_highlight_bounds(targets: Array[Control]) -> Rect2:
	var bounds := Rect2()
	var has_bounds := false

	for highlight_target in targets:
		if not is_instance_valid(highlight_target) or not highlight_target.visible:
			continue
		var target_rect := Rect2(
			highlight_target.global_position - global_position - Vector2(HIGHLIGHT_PADDING, HIGHLIGHT_PADDING),
			highlight_target.size + Vector2(HIGHLIGHT_PADDING * 2.0, HIGHLIGHT_PADDING * 2.0)
		)
		if not has_bounds:
			bounds = target_rect
			has_bounds = true
		else:
			bounds = bounds.merge(target_rect)

	return bounds if has_bounds else Rect2()


func _get_avoid_bounds() -> Rect2:
	var targets: Array[Control] = []
	targets.append_array(_highlight_targets)
	targets.append_array(_avoid_targets)
	return _get_highlight_bounds(targets)


func _choose_best_panel_position(candidates: Array, panel_size: Vector2, highlight_bounds: Rect2,
		max_x: float, max_y: float) -> Vector2:
	var best_position := Vector2(PANEL_MARGIN_LEFT, max_y)
	var best_overlap := INF

	for candidate in candidates:
		var candidate_pos := Vector2(
			clampf(candidate.x, PANEL_MARGIN_LEFT, max_x),
			clampf(candidate.y, PANEL_MARGIN_TOP, max_y)
		)
		var panel_rect := Rect2(candidate_pos, panel_size)
		var overlap_rect := panel_rect.intersection(highlight_bounds)
		var overlap_area := overlap_rect.size.x * overlap_rect.size.y

		if overlap_area < best_overlap:
			best_overlap = overlap_area
			best_position = candidate_pos
			if is_zero_approx(overlap_area):
				break

	return best_position


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_green_button(text: String, min_size: Vector2, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_stylebox_override("normal", _make_style(Color("9acd32"), Color("000000"), 4, 16))
	button.add_theme_stylebox_override("hover", _make_style(Color("b5e067"), Color("000000"), 4, 16))
	button.add_theme_stylebox_override("pressed", _make_style(Color("84a528"), Color("000000"), 4, 16))
	button.add_theme_color_override("font_color", Color("1a1a1a"))
	button.add_theme_color_override("font_hover_color", Color("1a1a1a"))
	return button


func _make_style(bg_color: Color, border_color: Color, border_width: int, margin: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(margin)
	return style
