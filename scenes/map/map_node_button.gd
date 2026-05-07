extends Button
class_name MapNodeButton

signal node_clicked(node_id: int)

const MapNodeRef := preload("res://scripts/map/map_node.gd")

const DARK := Color("1a1a1a")
const GOLD := Color("ffd700")
const BORDER_BLACK := Color("000000")
const BLUE := Color("4a9eff")
const GREEN := Color("9acd32")
const PINK := Color("ff69b4")
const CARD_BG := Color("c8e6f5")
const DISABLED_BG := Color("99a1af")
const DISABLED_TEXT := Color("4a5565")
const NODE_BORDER_WIDTH := 4
const NODE_MARGIN := 8
const NODE_FONT_SIZE := 14
const NODE_CAPTION_FONT_SIZE := 7
const ICON_VERTICAL_OFFSET := -7.0
const ICON_DIE_SIZE := Vector2(20, 20)
const ICON_SHOP_SIZE := Vector2(34, 30)
const ICON_CROWN_SIZE := Vector2(34, 24)

var node_id: int = -1
var node_type: int = MapNodeRef.NodeType.COMBAT
var state: String = "locked"
var _pixel_font: Font


func configure(p_id: int, p_type: int, p_state: String) -> void:
	node_id = p_id
	node_type = p_type
	state = p_state
	_apply_visual()
	disabled = state != "available"
	queue_redraw()


func _ready() -> void:
	_pixel_font = load("res://assets/fonts/PressStart2P-Regular.ttf")
	pressed.connect(_on_pressed)
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(56, 56)
	_apply_visual()


func _draw() -> void:
	var icon_color := _icon_color()
	match node_type:
		MapNodeRef.NodeType.COMBAT:
			_draw_rolling_dice_icon(icon_color)
		MapNodeRef.NodeType.SHOP:
			_draw_storefront_icon(icon_color)
		MapNodeRef.NodeType.BOSS:
			_draw_crown_icon(icon_color)
	_draw_caption(icon_color)


func _on_pressed() -> void:
	if state == "available":
		node_clicked.emit(node_id)


func _apply_visual() -> void:
	text = ""
	tooltip_text = _label_for_type(node_type)
	add_theme_font_override("font", _pixel_font)
	add_theme_font_size_override("font_size", NODE_FONT_SIZE)

	var bg := _bg_for_type(node_type)
	var border := BORDER_BLACK
	var font_col := DARK
	if state == "locked":
		bg = DISABLED_BG
		border = Color(0.28, 0.31, 0.36)
		font_col = DISABLED_TEXT
	elif state == "completed":
		bg = GREEN
	elif state == "available":
		border = GOLD

	add_theme_stylebox_override("normal", _make_style(bg, border))
	add_theme_stylebox_override("hover", _make_style(bg.lightened(0.12), border))
	add_theme_stylebox_override("pressed", _make_style(bg.darkened(0.12), BORDER_BLACK))
	add_theme_stylebox_override("disabled", _make_style(bg, border))
	add_theme_stylebox_override("focus", _make_focus_style())

	add_theme_color_override("font_color", font_col)
	add_theme_color_override("font_hover_color", font_col)
	add_theme_color_override("font_pressed_color", font_col)
	add_theme_color_override("font_focus_color", font_col)
	add_theme_color_override("font_disabled_color", font_col)
	queue_redraw()


func _make_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(NODE_BORDER_WIDTH)
	style.set_corner_radius_all(0)
	style.set_content_margin_all(NODE_MARGIN)
	return style


func _make_focus_style() -> StyleBoxFlat:
	var style := _make_style(Color(0, 0, 0, 0), GOLD)
	style.draw_center = false
	return style


func _bg_for_type(t: int) -> Color:
	match t:
		MapNodeRef.NodeType.COMBAT:
			return CARD_BG
		MapNodeRef.NodeType.SHOP:
			return BLUE
		MapNodeRef.NodeType.BOSS:
			return PINK
	return CARD_BG


func _label_for_type(t: int) -> String:
	match t:
		MapNodeRef.NodeType.COMBAT:
			return "Roll Dice"
		MapNodeRef.NodeType.SHOP:
			return "Shop"
		MapNodeRef.NodeType.BOSS:
			return "Boss"
	return "Unknown"


func get_visible_caption() -> String:
	match node_type:
		MapNodeRef.NodeType.COMBAT:
			return "ROLL"
		MapNodeRef.NodeType.SHOP:
			return "SHOP"
		MapNodeRef.NodeType.BOSS:
			return "BOSS"
	return "?"


func _icon_color() -> Color:
	if state == "locked":
		return DISABLED_TEXT
	return DARK


func _draw_caption(icon_color: Color) -> void:
	if _pixel_font == null:
		return
	draw_string(
		_pixel_font,
		Vector2(0, size.y - 7.0),
		get_visible_caption(),
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		NODE_CAPTION_FONT_SIZE,
		icon_color
	)


func _draw_rolling_dice_icon(icon_color: Color) -> void:
	var center := size * 0.5 + Vector2(0, ICON_VERTICAL_OFFSET)
	draw_arc(center, 18.0, PI * 1.05, PI * 1.65, 10, icon_color, 2.0)
	draw_line(center + Vector2(-16, -3), center + Vector2(-20, 1), icon_color, 2.0)
	draw_line(center + Vector2(-16, -3), center + Vector2(-11, -1), icon_color, 2.0)
	_draw_die(Vector2(center.x - 22, center.y - 8), icon_color, [Vector2(6, 6), Vector2(14, 14)])
	_draw_die(Vector2(center.x + 2, center.y - 12), icon_color, [Vector2(5, 5), Vector2(10, 10), Vector2(15, 15)])


func _draw_die(origin: Vector2, icon_color: Color, pips: Array[Vector2]) -> void:
	var rect := Rect2(origin, ICON_DIE_SIZE)
	draw_rect(rect, Color.WHITE)
	draw_rect(rect.grow(-3), Color("e4e4e4"))
	draw_rect(rect, icon_color, false, 4.0)
	for pip in pips:
		draw_rect(Rect2(origin + pip - Vector2(2, 2), Vector2(4, 4)), icon_color)


func _draw_storefront_icon(icon_color: Color) -> void:
	var origin := (size - ICON_SHOP_SIZE) * 0.5 + Vector2(0, ICON_VERTICAL_OFFSET)
	var body := Rect2(origin + Vector2(2, 11), Vector2(30, 19))
	var awning := Rect2(origin, Vector2(34, 12))
	var counter := Rect2(origin + Vector2(5, 17), Vector2(13, 8))
	var door := Rect2(origin + Vector2(22, 17), Vector2(7, 13))

	draw_rect(body, Color("f6f1dc"))
	draw_rect(body, icon_color, false, 4.0)
	draw_rect(awning, Color.WHITE)
	draw_rect(Rect2(origin, Vector2(7, 12)), GOLD)
	draw_rect(Rect2(origin + Vector2(14, 0), Vector2(7, 12)), GOLD)
	draw_rect(Rect2(origin + Vector2(28, 0), Vector2(6, 12)), GOLD)
	draw_rect(awning, icon_color, false, 3.0)
	draw_rect(counter, Color("9ce1ff"))
	draw_rect(counter, icon_color, false, 3.0)
	draw_rect(door, Color("d89b64"))
	draw_rect(door, icon_color, false, 3.0)
	draw_rect(Rect2(origin + Vector2(5, 28), Vector2(24, 3)), icon_color)


func _draw_crown_icon(icon_color: Color) -> void:
	var origin := (size - ICON_CROWN_SIZE) * 0.5 + Vector2(0, ICON_VERTICAL_OFFSET)
	var base_y := origin.y + ICON_CROWN_SIZE.y
	var points := PackedVector2Array(
		[
			Vector2(origin.x, base_y),
			Vector2(origin.x + 4, origin.y + 8),
			Vector2(origin.x + 12, origin.y + 14),
			Vector2(origin.x + 17, origin.y),
			Vector2(origin.x + 22, origin.y + 14),
			Vector2(origin.x + 30, origin.y + 8),
			Vector2(origin.x + 34, base_y),
		]
	)
	draw_colored_polygon(points, GOLD)
	draw_polyline(points, icon_color, 4.0)
	draw_line(Vector2(origin.x + 4, base_y), Vector2(origin.x + 30, base_y), icon_color, 4.0)
