extends "res://scripts/ui/item_card.gd"
## Combat-specific dice card with face sprite overlay, hold state, and roll helpers.

var _face_sprite: TextureRect
var _face_textures: Array[AtlasTexture] = []
var _display_name: String = ""

const COMBAT_CARD_SIZE := Vector2(110, 110)


func setup(die: Die, pixel_font: Font, textures: Array[AtlasTexture]) -> void:
	_face_textures = textures
	_display_name = DIE_NAMES.get(die.color, "BASIC")

	var card_color: Color = DIE_COLORS.get(die.color, Color.WHITE)
	_setup_card(card_color, "D", pixel_font, COMBAT_CARD_SIZE)

	_face_sprite = TextureRect.new()
	_face_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	_face_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face_sprite.visible = false
	main_button.add_child(_face_sprite)

	hover_name = die.die_name
	hover_description = die.description

	var name_label := Label.new()
	name_label.text = _display_name
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", DARK)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(COMBAT_CARD_SIZE.x, 18)
	bottom_control = name_label
	add_child(bottom_control)


func set_face(value: int) -> void:
	if value <= 0 or value > 6:
		_face_sprite.visible = false
		main_button.text = "D"
		return
	_face_sprite.texture = _face_textures[value - 1]
	_face_sprite.visible = true
	main_button.text = ""


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
