extends Control

signal next_pressed

var _highlight_targets: Array[Control] = []
var _avoid_targets: Array[Control] = []
var _panel: PanelContainer
var _title_label: Label
var _body_label: Label
var _next_btn: Button
var _btn_wrapper: CenterContainer
var _font: Font
var _step_panel_width: float = -1.0
var _step_panel_anchor: Variant = null


func _s(key: String) -> Variant:
	return TutorialManager.OVERLAY_STYLE[key]


func setup(pixel_font: Font) -> void:
	if _panel != null:
		return

	_font = pixel_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

	var panel_width: float = _s("panel_width")
	var content_margin: int = _s("panel_content_margin")

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(panel_width, 0)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override("panel",
		_make_style(_s("panel_bg"), _s("panel_border"), _s("panel_border_width"), content_margin))
	add_child(_panel)

	var content_hbox := HBoxContainer.new()
	content_hbox.add_theme_constant_override("separation", 16)
	_panel.add_child(content_hbox)

	var text_vbox := VBoxContainer.new()
	text_vbox.add_theme_constant_override("separation", 16)
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_hbox.add_child(text_vbox)

	_title_label = _make_label("", _s("title_font_size"), _s("panel_border"))
	text_vbox.add_child(_title_label)

	_body_label = _make_label("", _s("body_font_size"), Color.WHITE)
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.custom_minimum_size = Vector2(panel_width - content_margin * 2.0, 0)
	text_vbox.add_child(_body_label)

	_btn_wrapper = CenterContainer.new()
	_btn_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	content_hbox.add_child(_btn_wrapper)

	_next_btn = _make_green_button("NEXT", _s("next_btn_size"), _s("next_btn_font_size"))
	_next_btn.pressed.connect(func(): next_pressed.emit())
	_btn_wrapper.add_child(_next_btn)

	hide_overlay()


func show_step(title: String, body: String, highlight_targets: Variant = null,
		show_next: bool = false, next_text: String = "NEXT", avoid_targets: Variant = null) -> void:
	visible = true
	_highlight_targets = _normalize_targets(highlight_targets)
	_avoid_targets = _normalize_targets(avoid_targets)
	_title_label.text = title
	_body_label.text = body
	_btn_wrapper.visible = show_next
	_next_btn.text = next_text
	_update_panel_layout()
	queue_redraw()


func show_step_from_config(config: Dictionary, highlight_targets: Variant = null,
		avoid_targets: Variant = null) -> void:
	_step_panel_width = float(config.get("panel_width", -1.0))
	_step_panel_anchor = config.get("panel_anchor", null)
	show_step(
		config.get("title", ""),
		config.get("body", ""),
		highlight_targets,
		config.get("show_next", false),
		config.get("next_text", "NEXT"),
		avoid_targets,
	)


func hide_overlay() -> void:
	visible = false
	_highlight_targets.clear()
	_avoid_targets.clear()
	queue_redraw()


func _process(_delta: float) -> void:
	if visible:
		var parent_size := get_parent_area_size()
		if size != parent_size:
			size = parent_size
			position = Vector2.ZERO
		_update_panel_layout()
		queue_redraw()


func _draw() -> void:
	if not visible:
		return

	var pad: float = _s("highlight_padding")
	var cutouts: Array[Rect2] = []
	for ht in _highlight_targets:
		if not is_instance_valid(ht) or not ht.visible:
			continue
		cutouts.append(Rect2(
			ht.global_position - global_position - Vector2(pad, pad),
			ht.size + Vector2(pad * 2.0, pad * 2.0)
		))

	_draw_shade_with_cutouts(Rect2(Vector2.ZERO, size), cutouts)

	var border_color: Color = _s("highlight_border")
	for cutout in cutouts:
		draw_rect(cutout, border_color, false, 4.0)


func _draw_shade_with_cutouts(screen: Rect2, cutouts: Array[Rect2]) -> void:
	var shade: Color = _s("shade_color")
	if cutouts.is_empty():
		draw_rect(screen, shade)
		return

	var y_breaks: Array[float] = [screen.position.y, screen.end.y]
	for c in cutouts:
		y_breaks.append(maxf(c.position.y, screen.position.y))
		y_breaks.append(minf(c.end.y, screen.end.y))
	y_breaks.sort()

	for i in range(y_breaks.size() - 1):
		var band_top := y_breaks[i]
		var band_bottom := y_breaks[i + 1]
		if band_top >= band_bottom:
			continue

		var band_cutouts: Array[Rect2] = []
		for c in cutouts:
			if c.position.y < band_bottom and c.end.y > band_top:
				band_cutouts.append(c)

		if band_cutouts.is_empty():
			draw_rect(Rect2(screen.position.x, band_top, screen.size.x, band_bottom - band_top), shade)
		else:
			band_cutouts.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
			var x := screen.position.x
			for c in band_cutouts:
				if c.position.x > x:
					draw_rect(Rect2(x, band_top, c.position.x - x, band_bottom - band_top), shade)
				x = maxf(x, c.end.x)
			if x < screen.end.x:
				draw_rect(Rect2(x, band_top, screen.end.x - x, band_bottom - band_top), shade)


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

	var margin_l: float = _s("panel_margin_left")
	var margin_r: float = _s("panel_margin_right")
	var margin_t: float = _s("panel_margin_top")
	var margin_b: float = _s("panel_margin_bottom")
	var default_width: float = _s("panel_width")
	var content_margin: float = _s("panel_content_margin")
	var gap: float = _s("panel_gap")

	var panel_width := _step_panel_width if _step_panel_width > 0 else default_width

	var available_width := maxf(280.0, size.x - margin_l - margin_r)
	var btn_space := 0.0
	if _btn_wrapper.visible:
		btn_space = _s("next_btn_size").x + 16.0
	var label_width := maxf(200.0, minf(panel_width - content_margin * 2.0 - btn_space, available_width - content_margin * 2.0 - btn_space))
	_body_label.custom_minimum_size = Vector2(label_width, 0)
	_body_label.size.x = label_width
	_panel.custom_minimum_size = Vector2(minf(panel_width, available_width), 0)
	_panel.reset_size()

	var panel_size := _panel.get_combined_minimum_size()
	panel_size.x = clampf(panel_size.x, 240.0, available_width)
	panel_size.y = minf(panel_size.y, maxf(120.0, size.y - margin_t - margin_b))
	_panel.size = panel_size

	var max_x := maxf(margin_l, size.x - margin_r - panel_size.x)
	var max_y := maxf(margin_t, size.y - margin_b - panel_size.y)

	var t := _resolve_anchor(_step_panel_anchor if _step_panel_anchor != null else _s("panel_anchor"))
	var panel_pos := Vector2(
		lerpf(margin_l, max_x, t.x),
		lerpf(margin_t, max_y, t.y),
	)

	var avoid_bounds := _get_avoid_bounds()
	if avoid_bounds.size != Vector2.ZERO:
		var ab_cy := avoid_bounds.get_center().y - panel_size.y * 0.5
		var ax := panel_pos.x
		var candidate_positions := [
			Vector2(ax, avoid_bounds.end.y + gap),
			Vector2(ax, avoid_bounds.position.y - panel_size.y - gap),
			Vector2(avoid_bounds.end.x + gap, ab_cy),
			Vector2(ax, margin_t),
			Vector2(ax, max_y),
		]
		panel_pos = _choose_best_panel_position(candidate_positions, panel_size, avoid_bounds, max_x, max_y, margin_l, margin_t)

	_panel.position = panel_pos.round()


static func _resolve_anchor(anchor: Variant) -> Vector2:
	if anchor is Vector2:
		return anchor
	match str(anchor):
		"top_left":      return Vector2(0.0, 0.0)
		"top_center":    return Vector2(0.5, 0.0)
		"top_right":     return Vector2(1.0, 0.0)
		"center_left":   return Vector2(0.0, 0.5)
		"center":        return Vector2(0.5, 0.5)
		"center_right":  return Vector2(1.0, 0.5)
		"bottom_left":   return Vector2(0.0, 1.0)
		"bottom_center": return Vector2(0.5, 1.0)
		"bottom_right":  return Vector2(1.0, 1.0)
		_:               return Vector2(0.0, 1.0)


func _get_highlight_bounds(targets: Array[Control]) -> Rect2:
	var bounds := Rect2()
	var has_bounds := false
	var pad: float = _s("highlight_padding")

	for highlight_target in targets:
		if not is_instance_valid(highlight_target) or not highlight_target.visible:
			continue
		var target_rect := Rect2(
			highlight_target.global_position - global_position - Vector2(pad, pad),
			highlight_target.size + Vector2(pad * 2.0, pad * 2.0)
		)
		if not has_bounds:
			bounds = target_rect
			has_bounds = true
		else:
			bounds = bounds.merge(target_rect)

	return bounds if has_bounds else Rect2()


func _get_avoid_bounds() -> Rect2:
	return _get_highlight_bounds(_avoid_targets)


func _choose_best_panel_position(candidates: Array, panel_size: Vector2, highlight_bounds: Rect2,
		max_x: float, max_y: float, min_x: float, min_y: float) -> Vector2:
	var best_position := Vector2(min_x, max_y)
	var best_overlap := INF

	for candidate in candidates:
		var candidate_pos := Vector2(
			clampf(candidate.x, min_x, max_x),
			clampf(candidate.y, min_y, max_y)
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
