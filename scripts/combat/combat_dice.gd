extends "res://scripts/ui/item_card.gd"
## Combat-specific dice card with procedurally drawn face, hold state, and roll helpers.

const DiceFacePanel = preload("res://scripts/ui/dice_face_panel.gd")
const COMBAT_CARD_SIZE := Vector2(110, 110)
const COMBAT_CARD_LABEL_FONT_SIZE := 12
const COMBAT_CARD_LABEL_HEIGHT := 18
const COMBO_REVEAL_BASE_POP := 1.04
const COMBO_REVEAL_POP_PER_TIER := 0.014

var _face_panel: Control
var _display_name: String = ""
var _combo_reveal_tween: Tween


func setup(die: Die, pixel_font: Font) -> void:
	_display_name = DIE_NAMES.get(die.color, "BASIC")

	var card_color: Color = DIE_COLORS.get(die.color, Color.WHITE)
	_setup_card(card_color, "", pixel_font, COMBAT_CARD_SIZE)

	_face_panel = DiceFacePanel.new()
	_face_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_button.add_child(_face_panel)
	_face_panel.set_face_color(card_color)

	hover_name = die.die_name
	var vals := die.get_face_values()
	var faces_str := ",".join(vals.map(func(f: int) -> String: return str(f)))
	hover_description = "%s\nFaces: (%s)" % [die.description, faces_str]

	var name_label := Label.new()
	name_label.text = _display_name
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", COMBAT_CARD_LABEL_FONT_SIZE)
	name_label.add_theme_color_override("font_color", DARK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(COMBAT_CARD_SIZE.x, COMBAT_CARD_LABEL_HEIGHT)
	bottom_control = name_label
	_vbox.add_child(bottom_control)


func set_face(value: int) -> void:
	_face_panel.set_value(value)


func set_held(held: bool) -> void:
	set_selected(held)
	if held:
		set_bottom_text("LOCKED", GOLD)
	else:
		set_bottom_text(_display_name, DARK)


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
	if main_button != null:
		main_button.scale = Vector2.ONE
		main_button.modulate = Color.WHITE
	set_face(0)
	set_held(false)


func get_display_name() -> String:
	return _display_name
