extends "res://scripts/ui/pixel_bg.gd"

var _time := 0.0

@onready var _title_label: Label = $TitleLabel
@onready var _title_underline: ColorRect = $TitleUnderline
@onready var _new_game_btn: Button = %NewGameButton
@onready var _continue_btn: Button = %ContinueButton
@onready var _settings_btn: Button = %SettingsButton
@onready var _playtest_survey_btn: Button = %PlaytestSurveyButton
@onready var _exit_btn: Button = %ExitButton
@onready var _version_label: Label = $VersionLabel
@onready var _sun: Control = $Sun
@onready var _sun_image: TextureRect = $Sun/SunImage

var _sun_origin: Vector2
var _sun_state := 0
var _sun_textures: Array[Texture2D]

var _settings_overlay: ColorRect
var _master_slider: HSlider
var _music_slider: HSlider
var _sfx_slider: HSlider


func _ready() -> void:
	super._ready()
	_new_game_btn.pressed.connect(_on_new_game_pressed)
	_continue_btn.pressed.connect(_on_continue_pressed)
	_settings_btn.pressed.connect(_on_settings_pressed)
	_playtest_survey_btn.pressed.connect(_on_playtest_survey_pressed)
	_exit_btn.pressed.connect(_on_exit_pressed)

	AudioManager.play_music(&"menu")

	_title_label.add_theme_font_override("font", _pixel_font)
	_title_underline.color = DARK
	_version_label.add_theme_font_override("font", _pixel_font)
	_version_label.add_theme_font_size_override("font_size", 10)
	_version_label.add_theme_color_override("font_color", Color(0.102, 0.102, 0.102, 0.8))
	_version_label.text = "VERSION %s" % GameManager.get_app_version()
	_playtest_survey_btn.disabled = not GameManager.has_playtest_survey_url()
	_continue_btn.disabled = not GameManager.can_load_save()

	_sun_textures = [
		load("res://assets/art/decorations/sun_happy.svg"),
		load("res://assets/art/decorations/sun_neutral.svg"),
		load("res://assets/art/decorations/sun_sad.svg"),
	]
	_sun_origin = _sun.position
	_sun.pivot_offset = _sun.size * 0.5
	_sun.gui_input.connect(_on_sun_input)
	for btn in [_new_game_btn, _continue_btn, _settings_btn, _playtest_survey_btn, _exit_btn]:
		btn.add_theme_font_override("font", _pixel_font)
		btn.mouse_entered.connect(_on_btn_hover_enter.bind(btn))
		btn.mouse_exited.connect(_on_btn_hover_exit.bind(btn))
		_connect_button_sfx(btn)

	_build_settings_overlay()


func _process(delta: float) -> void:
	_time += delta
	var sun_sway := Vector2(sin(_time * 0.3) * 5.0, cos(_time * 0.2) * 6.0)
	_sun.position = _sun_origin + sun_sway
	_sun.rotation = sin(_time * 0.4) * 0.06
	queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_pixel_die()
	_draw_pixel_creature()
	_draw_pixel_coin()
	_draw_button_shadows(
		[_new_game_btn, _continue_btn, _settings_btn, _playtest_survey_btn, _exit_btn]
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
	GameManager.load_game()


func _on_settings_pressed() -> void:
	_settings_overlay.visible = true
	_master_slider.value = AudioManager.get_master_volume()
	_music_slider.value = AudioManager.get_music_volume()
	_sfx_slider.value = AudioManager.get_sfx_volume()


func _on_playtest_survey_pressed() -> void:
	GameManager.open_playtest_survey()


func _on_settings_close() -> void:
	_settings_overlay.visible = false
	AudioManager.save_volume_settings()


func _on_settings_tutorial_pressed() -> void:
	_on_settings_close()
	GameManager.start_tutorial_replay()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _build_settings_overlay() -> void:
	_settings_overlay = ColorRect.new()
	_settings_overlay.color = Color(0, 0, 0, 0.85)
	_settings_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.visible = false
	add_child(_settings_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_settings_overlay.add_child(center)

	var panel := _make_panel(DARK, GOLD, Vector2(480, 0), 32)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	panel.add_child(vbox)

	var title := _make_pixel_label("SETTINGS", 24, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_master_slider = _make_volume_row(vbox, "MASTER", AudioManager.get_master_volume())
	_master_slider.value_changed.connect(func(val: float): AudioManager.set_master_volume(val))

	_music_slider = _make_volume_row(vbox, "MUSIC", AudioManager.get_music_volume())
	_music_slider.value_changed.connect(func(val: float): AudioManager.set_music_volume(val))

	_sfx_slider = _make_volume_row(vbox, "SFX", AudioManager.get_sfx_volume())
	_sfx_slider.value_changed.connect(func(val: float): AudioManager.set_sfx_volume(val))

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	var tutorial_divider := ColorRect.new()
	tutorial_divider.color = GOLD.darkened(0.5)
	tutorial_divider.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(tutorial_divider)

	var tutorial_btn_center := CenterContainer.new()
	vbox.add_child(tutorial_btn_center)

	var tutorial_btn := _make_pixel_button("TUTORIAL", Vector2(240, 56), 14)
	tutorial_btn.pressed.connect(_on_settings_tutorial_pressed)
	tutorial_btn_center.add_child(tutorial_btn)

	var btn_center := CenterContainer.new()
	vbox.add_child(btn_center)
	var close_btn := _make_colored_button("CLOSE", Vector2(200, 56), GREEN, GREEN.lightened(0.15), 16)
	close_btn.pressed.connect(_on_settings_close)
	btn_center.add_child(close_btn)


func _make_volume_row(parent: VBoxContainer, label_text: String, initial: float) -> HSlider:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)

	var lbl := _make_pixel_label(label_text, 14, Color.WHITE)
	lbl.custom_minimum_size = Vector2(120, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial
	slider.custom_minimum_size = Vector2(240, 32)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var slider_style := StyleBoxFlat.new()
	slider_style.bg_color = Color(0.3, 0.3, 0.3)
	slider_style.set_corner_radius_all(0)
	slider_style.content_margin_top = 4
	slider_style.content_margin_bottom = 4

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = GOLD.darkened(0.3)
	fill_style.set_corner_radius_all(0)
	fill_style.content_margin_top = 4
	fill_style.content_margin_bottom = 4

	slider.add_theme_stylebox_override("grabber_area", fill_style)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_style)
	slider.add_theme_stylebox_override("slider", slider_style)
	slider.add_theme_icon_override("grabber", _create_grabber_texture(GOLD))
	slider.add_theme_icon_override("grabber_highlight", _create_grabber_texture(GOLD.lightened(0.2)))

	row.add_child(slider)
	return slider


func _create_grabber_texture(color: Color) -> ImageTexture:
	var img := Image.create(16, 24, false, Image.FORMAT_RGBA8)
	img.fill(color)
	return ImageTexture.create_from_image(img)


func _on_sun_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		AudioManager.play_sfx(&"ui_click")
		_sun_state = (_sun_state + 1) % _sun_textures.size()
		_sun_image.texture = _sun_textures[_sun_state]

		var tw := create_tween()
		tw.tween_property(_sun, "scale", Vector2(1.15, 1.15), 0.08).set_ease(Tween.EASE_OUT)
		tw.tween_property(_sun, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_IN_OUT)
