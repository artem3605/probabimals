extends Control

var bg_texture: Texture2D

func _ready() -> void:
	theme = ThemeSetup.game_theme
	bg_texture = load("res://assets/art/ui/felt_background.png")
	_build_ui()

func _build_ui() -> void:
	# Background
	var bg := TextureRect.new()
	bg.texture = bg_texture
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Vignette overlay
	var vignette := ColorRect.new()
	vignette.color = Color(0, 0, 0, 0.15)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	# Title - shadow layer (offset behind main title for depth)
	var title_shadow := Label.new()
	title_shadow.text = "PROBABIMALS"
	title_shadow.add_theme_font_size_override("font_size", 72)
	title_shadow.add_theme_font_override("font", ThemeSetup.font_bold)
	title_shadow.add_theme_color_override("font_color", Color(0.25, 0.15, 0.0, 0.5))
	title_shadow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_shadow.position = Vector2(3, 3)
	vbox.add_child(title_shadow)

	# Title - main golden text (overlapping shadow via negative margin)
	var title := Label.new()
	title.text = "PROBABIMALS"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_font_override("font", ThemeSetup.font_bold)
	title.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	title.add_theme_color_override("font_shadow_color", Color(0.3, 0.18, 0.0, 0.6))
	vbox.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "A Dice Strategy Game"
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_font_override("font", ThemeSetup.font_regular)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.8, 0.65, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(spacer)

	# Start button
	var start_btn := Button.new()
	start_btn.text = "START GAME"
	start_btn.custom_minimum_size = Vector2(320, 70)
	start_btn.add_theme_font_size_override("font_size", 32)
	start_btn.add_theme_font_override("font", ThemeSetup.font_bold)

	var start_style := ThemeSetup.make_accent_button_style(Color(0.15, 0.5, 0.2, 0.9))
	start_btn.add_theme_stylebox_override("normal", start_style)
	var start_hover := start_style.duplicate()
	start_hover.bg_color = Color(0.18, 0.6, 0.25, 0.95)
	start_btn.add_theme_stylebox_override("hover", start_hover)
	var start_pressed := start_style.duplicate()
	start_pressed.bg_color = Color(0.1, 0.4, 0.15, 0.95)
	start_btn.add_theme_stylebox_override("pressed", start_pressed)
	start_btn.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	start_btn.add_theme_color_override("font_hover_color", Color.WHITE)
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)

	# Exit button
	var exit_btn := Button.new()
	exit_btn.text = "EXIT"
	exit_btn.custom_minimum_size = Vector2(220, 50)
	exit_btn.add_theme_font_size_override("font_size", 22)
	exit_btn.add_theme_color_override("font_color", ThemeSetup.COLOR_TEXT_MUTED)
	exit_btn.pressed.connect(_on_exit_pressed)
	vbox.add_child(exit_btn)

	# Version label
	var version := Label.new()
	version.text = "BASIC4 v0.1"
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_color_override("font_color", Color(1, 1, 1, 0.25))
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(version)

	# Entry animation
	vbox.modulate.a = 0.0
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(vbox, "modulate:a", 1.0, 1.0)

func _on_start_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(GameManager.start_game)

func _on_exit_pressed() -> void:
	get_tree().quit()
