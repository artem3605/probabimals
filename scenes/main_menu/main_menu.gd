extends "res://scripts/ui/pixel_bg.gd"

var _time := 0.0

@onready var _title_label: Label = $TitleLabel
@onready var _title_underline: ColorRect = $TitleUnderline
@onready var _new_game_btn: Button = %NewGameButton
@onready var _continue_btn: Button = %ContinueButton
@onready var _settings_btn: Button = %SettingsButton
@onready var _exit_btn: Button = %ExitButton


func _ready() -> void:
	super._ready()
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	_continue_btn.pressed.connect(_on_continue_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_exit_btn.pressed.connect(_on_exit_pressed)

	_title_label.add_theme_font_override("font", _pixel_font)
	_title_underline.color = DARK
	for btn in [_new_game_btn, _continue_btn, _settings_btn, _exit_btn]:
		btn.add_theme_font_override("font", _pixel_font)
		btn.mouse_entered.connect(_on_btn_hover_enter.bind(btn))
		btn.mouse_exited.connect(_on_btn_hover_exit.bind(btn))


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_pixel_die()
	_draw_pixel_creature()
	_draw_pixel_coin()
	_draw_button_shadows(
		[_new_game_btn, _continue_btn, _settings_btn, _exit_btn]
	)


func _on_btn_hover_enter(btn: Button) -> void:
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.1).set_ease(Tween.EASE_OUT)


func _on_btn_hover_exit(btn: Button) -> void:
	var tw := create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE, 0.1).set_ease(Tween.EASE_OUT)


# -- Decorative pixel-art elements --------------------------------------------

func _draw_pixel_die() -> void:
	var c := Vector2(167, 298) + _bob(20)
	var s := 60.0
	var half := s * 0.5

	draw_rect(Rect2(c.x - half, c.y - half, s, s), Color.WHITE)
	var border_pts := PackedVector2Array([
		c + Vector2(-half, -half), c + Vector2(half, -half),
		c + Vector2(half, half), c + Vector2(-half, half),
		c + Vector2(-half, -half),
	])
	draw_polyline(border_pts, BORDER_BLACK, 4.0)

	var pip_r := 5.0
	var inset := 14.0
	var pip_col := DARK
	draw_circle(c + Vector2(-inset, -inset), pip_r, pip_col)
	draw_circle(c + Vector2(inset, -inset), pip_r, pip_col)
	draw_circle(c, pip_r, pip_col)
	draw_circle(c + Vector2(-inset, inset), pip_r, pip_col)
	draw_circle(c + Vector2(inset, inset), pip_r, pip_col)


func _draw_pixel_creature() -> void:
	var c := Vector2(932, 280) + _bob(21)
	var body_w := 40.0
	var body_h := 32.0
	var body_col := Color("ff4444")

	draw_rect(Rect2(c.x - body_w * 0.5, c.y - body_h * 0.5, body_w, body_h), body_col)
	draw_rect(Rect2(c.x - body_w * 0.5, c.y - body_h * 0.5, body_w, body_h), BORDER_BLACK, false, 3.0)

	var eye_size := 8.0
	var eye_y := c.y - 4.0
	for side_idx in 2:
		var side_f: float = -1.0 if side_idx == 0 else 1.0
		var ex: float = c.x + side_f * 8.0
		draw_rect(Rect2(ex - eye_size * 0.5, eye_y - eye_size * 0.5, eye_size, eye_size), Color.WHITE)
		draw_rect(Rect2(ex - 2.0, eye_y - 2.0, 4.0, 4.0), DARK)

	var tentacle_col := body_col.darkened(0.2)
	for i in 4:
		var tx := c.x - 15.0 + float(i) * 10.0
		var ty := c.y + body_h * 0.5
		var wobble := sin(_time * 2.0 + float(i)) * 3.0
		draw_line(Vector2(tx, ty), Vector2(tx + wobble, ty + 20.0), tentacle_col, 3.0)


func _draw_pixel_coin() -> void:
	var c := Vector2(254, 550) + _bob(22)
	var s := 24.0
	draw_rect(Rect2(c.x - s * 0.5, c.y - s * 0.5, s, s), GOLD)
	draw_rect(Rect2(c.x - s * 0.5, c.y - s * 0.5, s, s), BORDER_BLACK, false, 3.0)


# -- Helpers -------------------------------------------------------------------

func _bob(idx: int) -> Vector2:
	var p := float(idx) * 1.47
	return Vector2(sin(_time * 0.7 + p) * 3.0, cos(_time * 0.5 + p * 0.8) * 4.0)


# -- Button callbacks ----------------------------------------------------------

func _on_new_game_pressed() -> void:
	GameManager.start_game()


func _on_continue_pressed() -> void:
	pass


func _on_settings_pressed() -> void:
	pass


func _on_exit_pressed() -> void:
	get_tree().quit()
