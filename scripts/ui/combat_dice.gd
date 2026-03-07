extends "res://scripts/ui/item_card.gd"
## Combat-specific dice card with procedurally drawn face, hold state, and roll helpers.

const DiceFacePanel = preload("res://scripts/ui/dice_face_panel.gd")

var _face_panel: Control
var _display_name: String = ""
const COMBAT_CARD_SIZE := Vector2(110, 110)


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
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", DARK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(COMBAT_CARD_SIZE.x, 18)
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


func reset_die() -> void:
	set_face(0)
	set_held(false)


func get_display_name() -> String:
	return _display_name	