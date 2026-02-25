extends "res://scripts/ui/pixel_bg.gd"

var combat_mgr: CombatManager
var _dice_visuals: Array[Button] = []
var _current_values: Array[int] = []
var _lock_labels: Array[Label] = []
var _die_color_names: Array[String] = []
var _dice_face_textures: Array[AtlasTexture] = []
var _dice_sprites: Array[TextureRect] = []

var _menu_btn: Button
var _combo_name_label: Label
var _score_pts_label: Label
var _score_panel: PanelContainer
var _reroll_btn: Button
var _end_turn_btn: Button
var _dice_container: HBoxContainer

var _result_overlay: ColorRect
var _result_score_label: Label
var _result_message: Label

var _score_particles: CPUParticles2D
var _roll_particles: CPUParticles2D


func _ready() -> void:
	super._ready()
	_build_ui()
	_setup_combat()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_button_shadows([_menu_btn], Vector2(4, 4))
	_draw_score_panel_shadow()
	_draw_button_shadows([_reroll_btn], Vector2(6, 6))
	_draw_button_shadows([_end_turn_btn], Vector2(8, 8))


func _setup_combat() -> void:
	combat_mgr = CombatManager.new()
	add_child(combat_mgr)

	var dice: Array[Die] = GameManager.selected_dice if not GameManager.selected_dice.is_empty() else GameManager.dice_bag.draw(5)
	combat_mgr.start_combat(
		dice,
		GameManager.target_score,
		GameManager.hands_per_round,
		GameManager.rerolls_per_hand
	)

	_current_values.clear()
	_die_color_names.clear()
	for d in dice:
		_current_values.append(0)
		_die_color_names.append(DIE_NAMES.get(d.color, "BASIC"))

	for i in range(_lock_labels.size()):
		if i < _die_color_names.size():
			_lock_labels[i].text = _die_color_names[i]

	combat_mgr.dice_rolled.connect(_on_dice_rolled)
	combat_mgr.die_held.connect(_on_die_held)
	combat_mgr.combat_ended.connect(_on_combat_ended)
	combat_mgr.rerolls_changed.connect(_on_rerolls_changed)

	_update_rerolls_display()


func _build_ui() -> void:
	_dice_face_textures = _load_dice_sheet()

	var layout := _make_screen_layout(32)
	var content: VBoxContainer = layout["content"]
	var action_bar: HBoxContainer = layout["action_bar"]

	_build_top_bar(content)
	_build_score_panel(content)
	_build_dice_tray(content)

	_reroll_btn = _make_colored_button("REROLL\n3 left", Vector2(140, 68), PINK, PINK.lightened(0.15), 14)
	_reroll_btn.pressed.connect(_on_roll_pressed)
	action_bar.add_child(_reroll_btn)

	_end_turn_btn = _make_colored_button("END TURN", Vector2(200, 68), GREEN, GREEN.lightened(0.15), 16)
	_end_turn_btn.pressed.connect(_on_score_pressed)
	action_bar.add_child(_end_turn_btn)

	_build_result_overlay()
	_create_particles()

	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	parent.add_child(bar)

	_menu_btn = _make_menu_button()
	bar.add_child(_menu_btn)


func _build_score_panel(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_score_panel = _make_panel(Color.WHITE, BORDER_BLACK, Vector2(216, 107), 16)
	center.add_child(_score_panel)

	var score_vbox := VBoxContainer.new()
	score_vbox.add_theme_constant_override("separation", 4)
	score_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_score_panel.add_child(score_vbox)

	_combo_name_label = _make_pixel_label("", 18, Color("ff6b4a"))
	_combo_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_vbox.add_child(_combo_name_label)

	_score_pts_label = _make_pixel_label("ROLL!", 24)
	_score_pts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_vbox.add_child(_score_pts_label)


func _build_dice_tray(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_dice_container = HBoxContainer.new()
	_dice_container.add_theme_constant_override("separation", 24)
	center.add_child(_dice_container)

	_dice_visuals.clear()
	_lock_labels.clear()
	for i in range(5):
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		_dice_container.add_child(col)

		var die_btn := _create_die_button(i)
		col.add_child(die_btn)
		_dice_visuals.append(die_btn)

		var lock_lbl := _make_pixel_label("", 12)
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.custom_minimum_size = Vector2(128, 18)
		col.add_child(lock_lbl)
		_lock_labels.append(lock_lbl)


func _create_die_button(index: int) -> Button:
	var btn := _make_icon_button(Vector2(128, 128))

	var sprite := TextureRect.new()
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.visible = false
	btn.add_child(sprite)
	_dice_sprites.append(sprite)

	btn.pressed.connect(_on_die_clicked.bind(index))
	return btn


func _set_die_face(index: int, value: int) -> void:
	if index < 0 or index >= _dice_sprites.size():
		return
	var sprite := _dice_sprites[index]
	if value <= 0 or value > 6:
		sprite.visible = false
		return
	sprite.texture = _dice_face_textures[value - 1]
	sprite.visible = true


func _build_result_overlay() -> void:
	_result_overlay = ColorRect.new()
	_result_overlay.color = Color(0, 0, 0, 0.85)
	_result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.visible = false
	add_child(_result_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	_result_message = _make_pixel_label("", 36)
	_result_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_message)

	_result_score_label = _make_pixel_label("", 48, GOLD)
	_result_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_score_label)

	var target_info := _make_pixel_label("Target: " + str(GameManager.target_score), 16, Color("aaaaaa"))
	target_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(target_info)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var menu_btn := _make_pixel_button("BACK TO MENU", Vector2(280, 60), 14)
	menu_btn.pressed.connect(_go_to_main_menu)
	vbox.add_child(menu_btn)


# -- Drawing helpers -----------------------------------------------------------

func _draw_score_panel_shadow() -> void:
	if not is_instance_valid(_score_panel) or not _score_panel.visible:
		return
	var gp := _score_panel.global_position - global_position
	draw_rect(Rect2(gp + Vector2(8, 8), _score_panel.size), SHADOW_COLOR)


# -- HUD updates --------------------------------------------------------------

func _update_rerolls_display() -> void:
	var remaining := combat_mgr.rerolls_remaining
	if _reroll_btn:
		_reroll_btn.disabled = not combat_mgr.can_roll()
		_reroll_btn.text = "REROLL\n%d left" % remaining
	if _end_turn_btn:
		_end_turn_btn.disabled = not combat_mgr.can_score()


# -- Signal handlers -----------------------------------------------------------

func _on_die_clicked(index: int) -> void:
	if not combat_mgr.has_rolled:
		return
	combat_mgr.toggle_hold(index)


func _on_die_held(index: int, held: bool) -> void:
	if index < 0 or index >= _dice_visuals.size():
		return
	var btn := _dice_visuals[index]

	if held:
		btn.add_theme_stylebox_override("normal", _make_style(Color.TRANSPARENT, GOLD))
	else:
		btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())

	if index < _lock_labels.size():
		var die_name := _die_color_names[index] if index < _die_color_names.size() else ""
		_lock_labels[index].text = "LOCKED" if held else die_name
		_lock_labels[index].add_theme_color_override("font_color", GOLD if held else DARK)

	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12)


func _on_roll_pressed() -> void:
	if not combat_mgr.can_roll():
		return
	_animate_roll()


func _animate_roll() -> void:
	_reroll_btn.disabled = true

	var tween := create_tween()
	for i in range(5):
		if not combat_mgr.is_held(i):
			var btn := _dice_visuals[i]
			tween.parallel().tween_property(btn, "rotation", randf_range(-0.2, 0.2), 0.05)
			tween.parallel().tween_property(btn, "scale", Vector2(0.85, 0.85), 0.05)

	for f in range(6):
		tween.tween_callback(_show_random_faces)
		tween.tween_interval(0.06)

	tween.tween_callback(_do_actual_roll)
	tween.tween_callback(_emit_roll_particles)
	tween.tween_interval(0.05)

	for i in range(5):
		if not combat_mgr.is_held(i):
			var btn := _dice_visuals[i]
			tween.parallel().tween_property(btn, "rotation", 0.0, 0.15)
			tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.15)

	tween.tween_callback(_update_rerolls_display)


func _show_random_faces() -> void:
	for i in range(5):
		if not combat_mgr.is_held(i) and i < _current_values.size():
			_current_values[i] = randi_range(1, 6)
			_set_die_face(i, _current_values[i])


func _do_actual_roll() -> void:
	combat_mgr.roll_dice()


func _on_dice_rolled(results: Array[int]) -> void:
	for i in range(results.size()):
		if i < _current_values.size():
			_current_values[i] = results[i]
			_set_die_face(i, results[i])

	var combo := combat_mgr.get_current_combo()
	if not combo.is_empty():
		_show_combo(combo)
	else:
		_combo_name_label.text = ""
		_score_pts_label.text = "NO COMBO"

	_update_rerolls_display()


func _show_combo(combo: Dictionary) -> void:
	var combo_name: String = combo.get("name", "")
	_combo_name_label.text = combo_name.to_upper()

	var priority: int = combo.get("priority", 0)
	match priority:
		0, 1:
			_combo_name_label.add_theme_color_override("font_color", Color("888888"))
		2, 3:
			_combo_name_label.add_theme_color_override("font_color", Color("ff6b4a"))
		4, 5:
			_combo_name_label.add_theme_color_override("font_color", BLUE)
		6, 7:
			_combo_name_label.add_theme_color_override("font_color", GOLD)
		8:
			_combo_name_label.add_theme_color_override("font_color", PINK)

	var base: int = combo.get("base_score", 0)
	var mult: int = combo.get("multiplier", 1)
	var dice_sum := 0
	for v in combat_mgr.current_roll:
		dice_sum += v
	var pts: int = (base + dice_sum) * mult
	_score_pts_label.text = "%d PTS" % pts

	_score_panel.scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(_score_panel, "scale", Vector2.ONE, 0.25)


func _on_score_pressed() -> void:
	if not combat_mgr.can_score():
		return
	var result := combat_mgr.score_hand(GameManager.modifiers)
	if result.is_empty():
		return

	var combo: Dictionary = result.get("combo", {})
	var total: int = result.get("score_data", {}).get("total", 0)

	_animate_score(combo, total)


func _animate_score(combo: Dictionary, total: int) -> void:
	var tween := create_tween()

	tween.tween_callback(func():
		_combo_name_label.text = combo.get("name", "").to_upper()
		_score_pts_label.text = "+%d PTS" % total
		_score_pts_label.add_theme_color_override("font_color", GREEN)
	)
	tween.tween_interval(0.5)

	tween.tween_callback(func():
		_emit_score_particles(combo.get("priority", 0))
	)
	tween.tween_interval(1.0)

	tween.tween_callback(func():
		_score_pts_label.add_theme_color_override("font_color", DARK)
		_reset_for_next_hand()
	)


func _reset_for_next_hand() -> void:
	if combat_mgr.hands_remaining <= 0:
		return

	_combo_name_label.text = ""
	_score_pts_label.text = "ROLL!"

	for i in range(_current_values.size()):
		_current_values[i] = 0
		_set_die_face(i, 0)
	for i in range(_dice_visuals.size()):
		_dice_visuals[i].add_theme_stylebox_override("normal", StyleBoxEmpty.new())

	for i in range(_lock_labels.size()):
		_lock_labels[i].text = _die_color_names[i] if i < _die_color_names.size() else ""
		_lock_labels[i].add_theme_color_override("font_color", DARK)

	_update_rerolls_display()


func _on_rerolls_changed(_remaining: int) -> void:
	_update_rerolls_display()


func _on_combat_ended(final_score: int, target_beaten: bool) -> void:
	GameManager.end_combat(final_score)
	_show_result_overlay(final_score, target_beaten)


func _show_result_overlay(final_score: int, target_beaten: bool) -> void:
	_result_overlay.visible = true
	_result_overlay.modulate.a = 0.0

	_result_score_label.text = str(final_score) + " PTS"

	if target_beaten:
		_result_message.text = "VICTORY!"
		_result_message.add_theme_color_override("font_color", GOLD)
	else:
		_result_message.text = "DEFEAT"
		_result_message.add_theme_color_override("font_color", DIE_COLORS["red"])

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_result_overlay, "modulate:a", 1.0, 0.5)


# -- Particles -----------------------------------------------------------------

func _create_particles() -> void:
	_score_particles = _make_burst_particles(30, 1.2, 0.9, 60.0, 100, 250, Vector2(0, 200), 3.0, 6.0, GOLD)
	add_child(_score_particles)

	_roll_particles = _make_burst_particles(15, 0.6, 0.8, 180.0, 30, 80, Vector2(0, 50), 2.0, 4.0, BLUE)
	var roll_gradient := Gradient.new()
	roll_gradient.set_color(0, Color(1, 1, 1, 0.8))
	roll_gradient.set_color(1, Color(BLUE, 0.0))
	_roll_particles.color_ramp = roll_gradient
	add_child(_roll_particles)


func _make_burst_particles(amount: int, lifetime: float, explosiveness: float,
		spread: float, vel_min: float, vel_max: float, gravity: Vector2,
		scale_min: float, scale_max: float, color: Color) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.amount = amount
	p.lifetime = lifetime
	p.explosiveness = explosiveness
	p.direction = Vector2(0, -1)
	p.spread = spread
	p.initial_velocity_min = vel_min
	p.initial_velocity_max = vel_max
	p.gravity = gravity
	p.scale_amount_min = scale_min
	p.scale_amount_max = scale_max
	p.color = color
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color, 0.0))
	p.color_ramp = gradient
	p.z_index = 100
	return p


func _emit_score_particles(combo_priority: int) -> void:
	_score_particles.position = Vector2(size.x / 2, size.y * 0.25)
	_score_particles.amount = 20 + combo_priority * 8
	if combo_priority >= 7:
		_score_particles.color = PINK
		_score_particles.amount = 60
	elif combo_priority >= 5:
		_score_particles.color = GOLD
	else:
		_score_particles.color = BLUE
	_score_particles.restart()
	_score_particles.emitting = true


func _emit_roll_particles() -> void:
	_roll_particles.position = Vector2(size.x / 2, size.y * 0.5)
	_roll_particles.restart()
	_roll_particles.emitting = true


# -- Navigation ----------------------------------------------------------------

func _go_to_main_menu() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(GameManager.go_to_main_menu)
