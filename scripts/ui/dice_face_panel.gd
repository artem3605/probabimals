extends Control
## Procedurally drawn dice face: inner colored rectangle with square pips.
## Matches the flat pixel-art style from the Figma design.

var _value: int = 0
var _face_color: Color = Color.WHITE
const PIP_COLOR := Color("1a1a1a")
const FACE_INSET := 0.12
const PIP_SIZE_FRAC := 0.14
const FACE_DARKEN := 0.12

const PIP_LAYOUTS := {
	1: [Vector2(0.5, 0.5)],
	2: [Vector2(0.27, 0.27), Vector2(0.73, 0.73)],
	3: [Vector2(0.73, 0.27), Vector2(0.5, 0.5), Vector2(0.27, 0.73)],
	4: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	5: [Vector2(0.27, 0.27), Vector2(0.73, 0.27), Vector2(0.5, 0.5),
		Vector2(0.27, 0.73), Vector2(0.73, 0.73)],
	6: [Vector2(0.27, 0.22), Vector2(0.73, 0.22), Vector2(0.27, 0.5),
		Vector2(0.73, 0.5), Vector2(0.27, 0.78), Vector2(0.73, 0.78)],
}


func set_value(v: int) -> void:
	_value = clampi(v, 0, 6)
	queue_redraw()


func set_face_color(c: Color) -> void:
	_face_color = c
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var s := size
	if s.x < 1.0 or s.y < 1.0:
		return
	var inset := s * FACE_INSET
	var inner_pos := inset
	var inner_size := s - inset * 2.0

	var inner_color := _face_color.darkened(FACE_DARKEN)
	draw_rect(Rect2(inner_pos, inner_size), inner_color)

	if _value <= 0 or _value > 6:
		return

	var pip_sz := inner_size.x * PIP_SIZE_FRAC
	var positions: Array = PIP_LAYOUTS[_value]
	for pos: Vector2 in positions:
		var px := inner_pos.x + pos.x * inner_size.x - pip_sz * 0.5
		var py := inner_pos.y + pos.y * inner_size.y - pip_sz * 0.5
		draw_rect(Rect2(px, py, pip_sz, pip_sz), PIP_COLOR)
