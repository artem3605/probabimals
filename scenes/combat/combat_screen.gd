extends Control

var bg_texture: Texture2D
var combat_mgr: CombatManager
var dice_visuals: Array[Button] = []
var combo_label: Label
var score_label: Label
var target_label: Label
var hands_label: Label
var rerolls_label: Label
var roll_button: Button
var score_hand_button: Button
var result_overlay: ColorRect
var result_score_label: Label
var result_message: Label
var score_breakdown_label: RichTextLabel
var dice_container: HBoxContainer
var score_particles: CPUParticles2D
var roll_particles: CPUParticles2D

const DICE_PIPS := {
	1: "⚀", 2: "⚁", 3: "⚂", 4: "⚃", 5: "⚄", 6: "⚅"
}

func _ready() -> void:
	theme = ThemeSetup.game_theme
	bg_texture = load("res://assets/art/ui/felt_background.png")
	_build_ui()
	_setup_combat()

func _setup_combat() -> void:
	combat_mgr = CombatManager.new()
	add_child(combat_mgr)

	var dice := GameManager.dice_bag.draw(5)
	combat_mgr.start_combat(
		dice,
		GameManager.target_score,
		GameManager.hands_per_round,
		GameManager.rerolls_per_hand
	)

	combat_mgr.dice_rolled.connect(_on_dice_rolled)
	combat_mgr.die_held.connect(_on_die_held)
	combat_mgr.hand_scored.connect(_on_hand_scored)
	combat_mgr.combat_ended.connect(_on_combat_ended)
	combat_mgr.rerolls_changed.connect(_on_rerolls_changed)
	combat_mgr.hands_changed.connect(_on_hands_changed)

	_update_hud()
	_update_action_buttons()

func _build_ui() -> void:
	# Background
	var bg := TextureRect.new()
	bg.texture = bg_texture
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	margin.add_child(main_vbox)

	# HUD
	_build_hud(main_vbox)

	# Score breakdown area
	var score_panel := PanelContainer.new()
	score_panel.add_theme_stylebox_override("panel", ThemeSetup.make_panel_style(
		Color(0.05, 0.05, 0.08, 0.85), ThemeSetup.COLOR_BORDER, 8
	))
	score_panel.custom_minimum_size = Vector2(0, 50)
	main_vbox.add_child(score_panel)

	score_breakdown_label = RichTextLabel.new()
	score_breakdown_label.bbcode_enabled = true
	score_breakdown_label.fit_content = true
	score_breakdown_label.add_theme_font_override("normal_font", ThemeSetup.font_regular)
	score_breakdown_label.add_theme_font_override("bold_font", ThemeSetup.font_bold)
	score_breakdown_label.add_theme_font_size_override("normal_font_size", 22)
	score_breakdown_label.add_theme_font_size_override("bold_font_size", 26)
	score_breakdown_label.text = "[center]Roll the dice to begin![/center]"
	score_panel.add_child(score_breakdown_label)

	# Dice tray
	var tray_spacer_top := Control.new()
	tray_spacer_top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(tray_spacer_top)

	_build_dice_tray(main_vbox)

	# Combo label
	combo_label = Label.new()
	combo_label.text = ""
	combo_label.add_theme_font_size_override("font_size", 34)
	combo_label.add_theme_font_override("font", ThemeSetup.font_bold)
	combo_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(combo_label)

	var tray_spacer_bottom := Control.new()
	tray_spacer_bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(tray_spacer_bottom)

	# Action bar
	_build_action_bar(main_vbox)

	# Result overlay (hidden)
	_build_result_overlay()

	# Particles
	_create_particles()

	# Fade in
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)

func _build_hud(parent: VBoxContainer) -> void:
	var hud := HBoxContainer.new()
	hud.add_theme_constant_override("separation", 20)
	parent.add_child(hud)

	var round_label := Label.new()
	round_label.text = "COMBAT"
	round_label.add_theme_font_size_override("font_size", 28)
	round_label.add_theme_font_override("font", ThemeSetup.font_bold)
	round_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	hud.add_child(round_label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud.add_child(spacer)

	# Score
	var score_box := VBoxContainer.new()
	score_box.add_theme_constant_override("separation", 0)
	hud.add_child(score_box)

	var score_title := Label.new()
	score_title.text = "SCORE"
	score_title.add_theme_font_size_override("font_size", 12)
	score_title.add_theme_color_override("font_color", ThemeSetup.COLOR_TEXT_MUTED)
	score_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_box.add_child(score_title)

	score_label = Label.new()
	score_label.text = "0"
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.add_theme_font_override("font", ThemeSetup.font_bold)
	score_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_box.add_child(score_label)

	# Target
	var target_box := VBoxContainer.new()
	target_box.add_theme_constant_override("separation", 0)
	hud.add_child(target_box)

	var target_title := Label.new()
	target_title.text = "TARGET"
	target_title.add_theme_font_size_override("font_size", 12)
	target_title.add_theme_color_override("font_color", ThemeSetup.COLOR_TEXT_MUTED)
	target_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_box.add_child(target_title)

	target_label = Label.new()
	target_label.text = str(GameManager.target_score)
	target_label.add_theme_font_size_override("font_size", 32)
	target_label.add_theme_font_override("font", ThemeSetup.font_bold)
	target_label.add_theme_color_override("font_color", ThemeSetup.COLOR_RED)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_box.add_child(target_label)

	# Hands
	var hands_box := VBoxContainer.new()
	hands_box.add_theme_constant_override("separation", 0)
	hud.add_child(hands_box)

	var hands_title := Label.new()
	hands_title.text = "HANDS"
	hands_title.add_theme_font_size_override("font_size", 12)
	hands_title.add_theme_color_override("font_color", ThemeSetup.COLOR_TEXT_MUTED)
	hands_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hands_box.add_child(hands_title)

	hands_label = Label.new()
	hands_label.text = str(GameManager.hands_per_round)
	hands_label.add_theme_font_size_override("font_size", 32)
	hands_label.add_theme_font_override("font", ThemeSetup.font_bold)
	hands_label.add_theme_color_override("font_color", ThemeSetup.COLOR_CYAN)
	hands_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hands_box.add_child(hands_label)

	# Rerolls
	var rerolls_box := VBoxContainer.new()
	rerolls_box.add_theme_constant_override("separation", 0)
	hud.add_child(rerolls_box)

	var rerolls_title := Label.new()
	rerolls_title.text = "REROLLS"
	rerolls_title.add_theme_font_size_override("font_size", 12)
	rerolls_title.add_theme_color_override("font_color", ThemeSetup.COLOR_TEXT_MUTED)
	rerolls_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rerolls_box.add_child(rerolls_title)

	rerolls_label = Label.new()
	rerolls_label.text = str(GameManager.rerolls_per_hand)
	rerolls_label.add_theme_font_size_override("font_size", 32)
	rerolls_label.add_theme_font_override("font", ThemeSetup.font_bold)
	rerolls_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GREEN)
	rerolls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rerolls_box.add_child(rerolls_label)

func _build_dice_tray(parent: VBoxContainer) -> void:
	var tray_panel := PanelContainer.new()
	tray_panel.add_theme_stylebox_override("panel", ThemeSetup.make_panel_style(
		Color(0.04, 0.06, 0.04, 0.6), Color(0.4, 0.35, 0.15, 0.4), 12
	))
	tray_panel.custom_minimum_size = Vector2(0, 150)
	parent.add_child(tray_panel)

	var center := CenterContainer.new()
	tray_panel.add_child(center)

	dice_container = HBoxContainer.new()
	dice_container.add_theme_constant_override("separation", 20)
	center.add_child(dice_container)

	dice_visuals.clear()
	for i in range(5):
		var die_btn := _create_die_visual(i)
		dice_container.add_child(die_btn)
		dice_visuals.append(die_btn)

func _create_die_visual(index: int) -> Button:
	var btn := Button.new()
	btn.text = "?"
	btn.custom_minimum_size = Vector2(110, 110)
	btn.add_theme_font_size_override("font_size", 52)
	btn.add_theme_font_override("font", ThemeSetup.font_bold)

	var die_style := StyleBoxFlat.new()
	die_style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	die_style.border_color = Color(0.35, 0.3, 0.2, 0.6)
	die_style.set_border_width_all(3)
	die_style.set_corner_radius_all(16)
	die_style.set_content_margin_all(8)
	btn.add_theme_stylebox_override("normal", die_style)

	var hover := die_style.duplicate()
	hover.border_color = ThemeSetup.COLOR_GOLD_DARK
	btn.add_theme_stylebox_override("hover", hover)

	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", ThemeSetup.COLOR_GOLD)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(_on_die_clicked.bind(index))

	return btn

func _build_action_bar(parent: VBoxContainer) -> void:
	var bar_center := CenterContainer.new()
	parent.add_child(bar_center)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 24)
	bar_center.add_child(bar)

	roll_button = Button.new()
	roll_button.text = "ROLL"
	roll_button.custom_minimum_size = Vector2(200, 65)
	roll_button.add_theme_font_size_override("font_size", 30)
	roll_button.add_theme_font_override("font", ThemeSetup.font_bold)
	var roll_style := ThemeSetup.make_accent_button_style(Color(0.15, 0.45, 0.6, 0.9))
	roll_button.add_theme_stylebox_override("normal", roll_style)
	var roll_hover := roll_style.duplicate()
	roll_hover.bg_color = Color(0.2, 0.55, 0.7, 0.95)
	roll_button.add_theme_stylebox_override("hover", roll_hover)
	roll_button.add_theme_color_override("font_color", Color.WHITE)
	roll_button.pressed.connect(_on_roll_pressed)
	bar.add_child(roll_button)

	score_hand_button = Button.new()
	score_hand_button.text = "SCORE HAND"
	score_hand_button.custom_minimum_size = Vector2(200, 65)
	score_hand_button.add_theme_font_size_override("font_size", 26)
	score_hand_button.add_theme_font_override("font", ThemeSetup.font_bold)
	var score_style := ThemeSetup.make_accent_button_style(Color(0.15, 0.5, 0.2, 0.9))
	score_hand_button.add_theme_stylebox_override("normal", score_style)
	var score_hover := score_style.duplicate()
	score_hover.bg_color = Color(0.18, 0.6, 0.25, 0.95)
	score_hand_button.add_theme_stylebox_override("hover", score_hover)
	score_hand_button.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	score_hand_button.add_theme_color_override("font_hover_color", Color.WHITE)
	score_hand_button.pressed.connect(_on_score_pressed)
	bar.add_child(score_hand_button)

func _build_result_overlay() -> void:
	result_overlay = ColorRect.new()
	result_overlay.color = Color(0, 0, 0, 0.85)
	result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.visible = false
	add_child(result_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	result_message = Label.new()
	result_message.add_theme_font_size_override("font_size", 48)
	result_message.add_theme_font_override("font", ThemeSetup.font_bold)
	result_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(result_message)

	result_score_label = Label.new()
	result_score_label.add_theme_font_size_override("font_size", 64)
	result_score_label.add_theme_font_override("font", ThemeSetup.font_bold)
	result_score_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	result_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(result_score_label)

	var target_info := Label.new()
	target_info.text = "Target: " + str(GameManager.target_score)
	target_info.add_theme_font_size_override("font_size", 24)
	target_info.add_theme_color_override("font_color", ThemeSetup.COLOR_TEXT_MUTED)
	target_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	target_info.name = "TargetInfo"
	vbox.add_child(target_info)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var menu_btn := Button.new()
	menu_btn.text = "BACK TO MENU"
	menu_btn.custom_minimum_size = Vector2(280, 60)
	menu_btn.add_theme_font_size_override("font_size", 24)
	menu_btn.add_theme_font_override("font", ThemeSetup.font_bold)
	menu_btn.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)

# --- Signal handlers ---

func _on_die_clicked(index: int) -> void:
	if not combat_mgr.has_rolled:
		return
	combat_mgr.toggle_hold(index)

func _on_die_held(index: int, held: bool) -> void:
	if index < 0 or index >= dice_visuals.size():
		return
	var btn := dice_visuals[index]
	var style: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate()
	if held:
		style.border_color = ThemeSetup.COLOR_GOLD
		style.bg_color = Color(0.18, 0.16, 0.08, 0.95)
		btn.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	else:
		style.border_color = Color(0.35, 0.3, 0.2, 0.6)
		style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
		btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_stylebox_override("normal", style)

	# Bounce animation
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12)

func _on_roll_pressed() -> void:
	if not combat_mgr.can_roll():
		return
	_animate_roll()

func _animate_roll() -> void:
	roll_button.disabled = true

	# Shake and flicker animation
	var tween := create_tween()
	for i in range(5):
		if not combat_mgr.is_held(i):
			var btn := dice_visuals[i]
			tween.parallel().tween_property(btn, "rotation", randf_range(-0.2, 0.2), 0.05)
			tween.parallel().tween_property(btn, "scale", Vector2(0.85, 0.85), 0.05)

	# Flicker random values
	var flicker_count := 6
	for f in range(flicker_count):
		tween.tween_callback(_show_random_faces)
		tween.tween_interval(0.06)

	tween.tween_callback(_do_actual_roll)
	tween.tween_callback(_emit_roll_particles)
	tween.tween_interval(0.05)

	# Settle animation
	for i in range(5):
		if not combat_mgr.is_held(i):
			var btn := dice_visuals[i]
			tween.parallel().tween_property(btn, "rotation", 0.0, 0.15)
			tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.15)

	tween.tween_callback(func(): roll_button.disabled = false)

func _show_random_faces() -> void:
	for i in range(5):
		if not combat_mgr.is_held(i):
			var rval := randi_range(1, 6)
			dice_visuals[i].text = DICE_PIPS.get(rval, str(rval))

func _do_actual_roll() -> void:
	combat_mgr.roll_dice()

func _on_dice_rolled(results: Array[int]) -> void:
	for i in range(results.size()):
		if i < dice_visuals.size():
			dice_visuals[i].text = DICE_PIPS.get(results[i], str(results[i]))

	# Show current combo
	var combo := combat_mgr.get_current_combo()
	if not combo.is_empty():
		_show_combo(combo)

	_update_action_buttons()

func _show_combo(combo: Dictionary) -> void:
	var combo_name: String = combo.get("name", "")
	combo_label.text = combo_name

	var priority: int = combo.get("priority", 0)
	match priority:
		0, 1:
			combo_label.add_theme_color_override("font_color", ThemeSetup.COLOR_TEXT_MUTED)
		2, 3:
			combo_label.add_theme_color_override("font_color", ThemeSetup.COLOR_TEXT)
		4, 5:
			combo_label.add_theme_color_override("font_color", ThemeSetup.COLOR_CYAN)
		6, 7:
			combo_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
		8:
			combo_label.add_theme_color_override("font_color", ThemeSetup.COLOR_MAGENTA)

	# Pop animation
	combo_label.scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(combo_label, "scale", Vector2.ONE, 0.3)

func _on_score_pressed() -> void:
	if not combat_mgr.can_score():
		return
	var result := combat_mgr.score_hand(GameManager.modifiers)
	if result.is_empty():
		return

	var score_data: Dictionary = result.get("score_data", {})
	var combo: Dictionary = result.get("combo", {})

	# Balatro-style score breakdown
	var base: int = score_data.get("base", 0)
	var mult: int = score_data.get("multiplier", 1)
	var mod_mult: float = score_data.get("mod_multiplier", 1.0)
	var total: int = score_data.get("total", 0)

	_animate_score_breakdown(combo, base, mult, mod_mult, total)

func _animate_score_breakdown(combo: Dictionary, base: int, mult: int, mod_mult: float, total: int) -> void:
	var tween := create_tween()

	tween.tween_callback(func():
		score_breakdown_label.text = "[center][b]%s[/b][/center]" % combo.get("name", "")
	)
	tween.tween_interval(0.4)

	tween.tween_callback(func():
		score_breakdown_label.text = "[center][b]%s[/b]\n[color=#e8c832]%d[/color] base[/center]" % [
			combo.get("name", ""), base
		]
	)
	tween.tween_interval(0.3)

	tween.tween_callback(func():
		var mod_text := ""
		if mod_mult > 1.0:
			mod_text = " x [color=#e84cdc]%.1f[/color] mod" % mod_mult
		score_breakdown_label.text = "[center][b]%s[/b]\n[color=#e8c832]%d[/color] x [color=#3cddee]%d[/color] mult%s = [color=#e8c832][b]%d[/b][/color][/center]" % [
			combo.get("name", ""), base, mult, mod_text, total
		]
	)
	tween.tween_interval(0.3)

	# Particles and running score
	tween.tween_callback(func():
		_emit_score_particles(combo.get("priority", 0))
		_animate_score_counter(combat_mgr.running_score)
	)

	# Reset dice for next hand
	tween.tween_interval(0.8)
	tween.tween_callback(func():
		_reset_for_next_hand()
	)

func _animate_score_counter(target: int) -> void:
	var current := int(score_label.text)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	var counter := {"value": current}
	tween.tween_method(func(val: int):
		score_label.text = str(val)
	, current, target, 0.5)

	# Pulse effect on score
	tween.parallel().tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.2)

func _reset_for_next_hand() -> void:
	if combat_mgr.hands_remaining <= 0:
		return
	combo_label.text = ""
	for i in range(dice_visuals.size()):
		dice_visuals[i].text = "?"
		var style := dice_visuals[i].get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if style:
			style.border_color = Color(0.35, 0.3, 0.2, 0.6)
			style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
			dice_visuals[i].add_theme_stylebox_override("normal", style)
		dice_visuals[i].add_theme_color_override("font_color", Color.WHITE)
	score_breakdown_label.text = "[center]Roll the dice![/center]"
	_update_action_buttons()

func _on_hand_scored(_combo: Dictionary, _score_data: Dictionary) -> void:
	pass

func _on_rerolls_changed(remaining: int) -> void:
	rerolls_label.text = str(remaining)
	if remaining == 0:
		rerolls_label.add_theme_color_override("font_color", ThemeSetup.COLOR_RED)
	else:
		rerolls_label.add_theme_color_override("font_color", ThemeSetup.COLOR_GREEN)

func _on_hands_changed(remaining: int) -> void:
	hands_label.text = str(remaining)
	if remaining <= 1:
		hands_label.add_theme_color_override("font_color", ThemeSetup.COLOR_RED)

func _on_combat_ended(final_score: int, target_beaten: bool) -> void:
	GameManager.end_combat(final_score)
	_show_result_overlay(final_score, target_beaten)

func _show_result_overlay(final_score: int, target_beaten: bool) -> void:
	result_overlay.visible = true
	result_overlay.modulate.a = 0.0

	result_score_label.text = str(final_score)

	if target_beaten:
		result_message.text = "VICTORY!"
		result_message.add_theme_color_override("font_color", ThemeSetup.COLOR_GOLD)
	else:
		result_message.text = "DEFEAT"
		result_message.add_theme_color_override("font_color", ThemeSetup.COLOR_RED)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(result_overlay, "modulate:a", 1.0, 0.5)

func _update_hud() -> void:
	if score_label:
		score_label.text = str(combat_mgr.running_score)
	if hands_label:
		hands_label.text = str(combat_mgr.hands_remaining)
	if rerolls_label:
		rerolls_label.text = str(combat_mgr.rerolls_remaining)

func _update_action_buttons() -> void:
	if roll_button:
		roll_button.disabled = not combat_mgr.can_roll()
		if combat_mgr.has_rolled and combat_mgr.rerolls_remaining > 0:
			roll_button.text = "REROLL"
		else:
			roll_button.text = "ROLL"
	if score_hand_button:
		score_hand_button.disabled = not combat_mgr.can_score()

func _create_particles() -> void:
	score_particles = CPUParticles2D.new()
	score_particles.emitting = false
	score_particles.one_shot = true
	score_particles.amount = 30
	score_particles.lifetime = 1.2
	score_particles.explosiveness = 0.9
	score_particles.direction = Vector2(0, -1)
	score_particles.spread = 60.0
	score_particles.initial_velocity_min = 100
	score_particles.initial_velocity_max = 250
	score_particles.gravity = Vector2(0, 200)
	score_particles.scale_amount_min = 3.0
	score_particles.scale_amount_max = 6.0
	score_particles.color = ThemeSetup.COLOR_GOLD
	var gradient := Gradient.new()
	gradient.set_color(0, ThemeSetup.COLOR_GOLD)
	gradient.set_color(1, Color(ThemeSetup.COLOR_GOLD, 0.0))
	score_particles.color_ramp = gradient
	score_particles.z_index = 100
	add_child(score_particles)

	roll_particles = CPUParticles2D.new()
	roll_particles.emitting = false
	roll_particles.one_shot = true
	roll_particles.amount = 15
	roll_particles.lifetime = 0.6
	roll_particles.explosiveness = 0.8
	roll_particles.direction = Vector2(0, -1)
	roll_particles.spread = 180.0
	roll_particles.initial_velocity_min = 30
	roll_particles.initial_velocity_max = 80
	roll_particles.gravity = Vector2(0, 50)
	roll_particles.scale_amount_min = 2.0
	roll_particles.scale_amount_max = 4.0
	roll_particles.color = ThemeSetup.COLOR_CYAN
	var roll_gradient := Gradient.new()
	roll_gradient.set_color(0, Color(1, 1, 1, 0.8))
	roll_gradient.set_color(1, Color(ThemeSetup.COLOR_CYAN, 0.0))
	roll_particles.color_ramp = roll_gradient
	roll_particles.z_index = 100
	add_child(roll_particles)

func _emit_score_particles(combo_priority: int) -> void:
	score_particles.position = Vector2(size.x / 2, size.y * 0.35)
	score_particles.amount = 20 + combo_priority * 8
	if combo_priority >= 7:
		score_particles.color = ThemeSetup.COLOR_MAGENTA
		score_particles.amount = 60
	elif combo_priority >= 5:
		score_particles.color = ThemeSetup.COLOR_GOLD
	else:
		score_particles.color = ThemeSetup.COLOR_CYAN
	score_particles.restart()
	score_particles.emitting = true

func _emit_roll_particles() -> void:
	roll_particles.position = Vector2(size.x / 2, size.y * 0.5)
	roll_particles.restart()
	roll_particles.emitting = true

func _on_menu_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(GameManager.go_to_main_menu)
