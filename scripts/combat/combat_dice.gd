extends "res://scripts/ui/item_card.gd"
## Combat-specific dice card with procedurally drawn face, hold state, and roll helpers.

const DiceFacePanel = preload("res://scripts/ui/dice_face_panel.gd")
const COMBAT_CARD_SIZE := Vector2(110, 110)
const COMBAT_CARD_LABEL_FONT_SIZE := 12
const COMBAT_CARD_LABEL_HEIGHT := 18
const COMBO_REVEAL_BASE_POP := 1.04
const COMBO_REVEAL_POP_PER_TIER := 0.014
const HELD_BADGE_FONT_SIZE := 10
const HELD_BADGE_PADDING := Vector2(6, 2)
const HELD_BADGE_BOTTOM_OFFSET := 14.0
const HELD_LIFT_AMOUNT := 8.0
const HELD_TWEEN_DURATION := 0.12

var _face_panel: Control
var _display_name: String = ""
var _combo_reveal_tween: Tween
var _held_badge: PanelContainer
var _held_tween: Tween


func setup(die: Die, pixel_font: Font) -> void:
	_display_name = DIE_NAMES.get(die.color, "BASIC")

	var card_color: Color = DIE_COLORS.get(die.color, Color.WHITE)
	_setup_card(card_color, "", pixel_font, COMBAT_CARD_SIZE)
	main_button.add_theme_stylebox_override("hover",
		_make_style(card_color, BORDER_BLACK, ITEM_CARD_MAIN_BORDER_WIDTH, ITEM_CARD_MAIN_MARGIN))

	_face_panel = DiceFacePanel.new()
	_face_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_button.add_child(_face_panel)
	_face_panel.set_face_color(card_color)

	hover_name = die.die_name
	var vals := die.get_face_values()
	var faces_bb := SemanticMarkup.format_faces_list(vals)
	hover_description = "Faces: (%s)" % faces_bb
	hover_rarity = _normalize_rarity(die.rarity).to_upper()

	var name_label := Label.new()
	name_label.text = _display_name
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", COMBAT_CARD_LABEL_FONT_SIZE)
	name_label.add_theme_color_override("font_color", DARK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(COMBAT_CARD_SIZE.x, COMBAT_CARD_LABEL_HEIGHT)
	bottom_control = name_label
	_vbox.add_child(bottom_control)

	_build_held_badge(pixel_font)


func _build_held_badge(pixel_font: Font) -> void:
	_held_badge = PanelContainer.new()
	_held_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_badge.visible = false
	_held_badge.top_level = false
	_held_badge.modulate = Color(1, 1, 1, 0)

	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = GOLD
	badge_style.border_color = BORDER_BLACK
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(0)
	badge_style.set_content_margin(SIDE_LEFT, HELD_BADGE_PADDING.x)
	badge_style.set_content_margin(SIDE_RIGHT, HELD_BADGE_PADDING.x)
	badge_style.set_content_margin(SIDE_TOP, HELD_BADGE_PADDING.y)
	badge_style.set_content_margin(SIDE_BOTTOM, HELD_BADGE_PADDING.y)
	_held_badge.add_theme_stylebox_override("panel", badge_style)

	var label := Label.new()
	label.text = "HELD"
	label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", HELD_BADGE_FONT_SIZE)
	label.add_theme_color_override("font_color", DARK)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_held_badge.add_child(label)

	main_button.add_child(_held_badge)
	_held_badge.resized.connect(_position_held_badge)
	main_button.resized.connect(_position_held_badge)
	_position_held_badge()


func _position_held_badge() -> void:
	if _held_badge == null or main_button == null:
		return
	var btn_width := main_button.size.x if main_button.size.x > 0.0 else COMBAT_CARD_SIZE.x
	var badge_size := _held_badge.size
	_held_badge.position = Vector2(
		(btn_width - badge_size.x) * 0.5,
		HELD_BADGE_BOTTOM_OFFSET - badge_size.y
	)


func set_face(value: int) -> void:
	_face_panel.set_value(value)


func set_held(held: bool) -> void:
	if _held_tween != null and _held_tween.is_valid():
		_held_tween.kill()

	if _held_badge != null:
		if held:
			_held_badge.visible = true
		_position_held_badge()

	_held_tween = create_tween()
	_held_tween.set_parallel(true)
	if main_button != null:
		var target_y := -HELD_LIFT_AMOUNT if held else 0.0
		_held_tween.tween_property(main_button, "position:y", target_y, HELD_TWEEN_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if _held_badge != null:
		var target_alpha := 1.0 if held else 0.0
		_held_tween.tween_property(_held_badge, "modulate:a", target_alpha, HELD_TWEEN_DURATION)
		if not held:
			_held_tween.chain().tween_callback(func():
				if _held_badge != null and _held_badge.modulate.a <= 0.01:
					_held_badge.visible = false
			)


func play_combo_reveal_hit(color: Color, tier: int, delay: float) -> void:
	if main_button == null:
		return
	if _combo_reveal_tween != null and _combo_reveal_tween.is_valid():
		_combo_reveal_tween.kill()

	main_button.scale = Vector2.ONE
	main_button.modulate = Color.WHITE
	var pop := COMBO_REVEAL_BASE_POP + float(clampi(tier, 0, 8)) * COMBO_REVEAL_POP_PER_TIER
	var hit_color := color.lightened(0.3)

	_combo_reveal_tween = create_tween()
	if delay > 0.0:
		_combo_reveal_tween.tween_interval(delay)
	_combo_reveal_tween.tween_property(main_button, "scale", Vector2(pop, pop), 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_combo_reveal_tween.parallel().tween_property(main_button, "modulate", hit_color, 0.08)
	_combo_reveal_tween.tween_property(main_button, "scale", Vector2.ONE, 0.14) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_combo_reveal_tween.parallel().tween_property(main_button, "modulate", Color.WHITE, 0.14)
	if tier >= 6:
		_combo_reveal_tween.tween_property(main_button, "scale", Vector2(1.05, 1.05), 0.06)
		_combo_reveal_tween.tween_property(main_button, "scale", Vector2.ONE, 0.12) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func reset_die() -> void:
	if _combo_reveal_tween != null and _combo_reveal_tween.is_valid():
		_combo_reveal_tween.kill()
	if _held_tween != null and _held_tween.is_valid():
		_held_tween.kill()
	if main_button != null:
		main_button.scale = Vector2.ONE
		main_button.modulate = Color.WHITE
		main_button.position.y = 0.0
	if _held_badge != null:
		_held_badge.visible = false
		_held_badge.modulate.a = 0.0
	set_face(0)


func get_display_name() -> String:
	return _display_name


func _refresh_button_frame() -> void:
	if main_button == null:
		return
	var border := _accent_color if _accent_active else BORDER_BLACK
	main_button.add_theme_stylebox_override("normal",
		_make_style(_card_color, border, ITEM_CARD_MAIN_BORDER_WIDTH, ITEM_CARD_MAIN_MARGIN))
	main_button.add_theme_stylebox_override("hover",
		_make_style(_card_color, border, ITEM_CARD_MAIN_BORDER_WIDTH, ITEM_CARD_MAIN_MARGIN))
