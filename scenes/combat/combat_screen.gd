extends "res://scripts/ui/pixel_bg.gd"

const CombatDice = preload("res://scripts/ui/combat_dice.gd")

var combat_mgr: CombatManager
var _dice_cards: Array = []
var _current_values: Array[int] = []

var _menu_btn: Button
var _combo_name_label: Label
var _score_value_label: Label
var _score_pts_suffix: Label
var _score_breakdown_label: Label
var _score_panel: PanelContainer
var _reroll_btn: Button
var _end_turn_btn: Button
var _dice_container: HBoxContainer
var _desc_panel: PanelContainer
var _desc_title: Label
var _desc_body: Label

var _hand_info_label: Label

var _score_bar_fill: ColorRect
var _score_bar_track: ColorRect
var _score_bar_label: Label

var _total_hands: int = 4

var _result_overlay: ColorRect
var _result_score_label: Label
var _result_message: Label
var _result_sub_label: Label
var _result_coins_label: Label
var _result_next_btn: Button
var _result_menu_btn: Button
var _result_final_score: int = 0
var _result_target_beaten: bool = false

var _pause_overlay: ColorRect

var _animating: bool = false


func _ready() -> void:
	super._ready()
	_build_ui()
	_setup_combat()
	AudioManager.play_music(&"menu")


func _process(_delta: float) -> void:
	if _animating:
		queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_button_shadows([_menu_btn], Vector2(4, 4))
	_draw_panel_shadow(_score_panel, Vector2(8, 8))
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
	for d in dice:
		_current_values.append(0)

	_total_hands = GameManager.hands_per_round

	combat_mgr.dice_rolled.connect(_on_dice_rolled)
	combat_mgr.die_held.connect(_on_die_held)
	combat_mgr.combat_ended.connect(_on_combat_ended)
	combat_mgr.rerolls_changed.connect(_on_rerolls_changed)
	combat_mgr.hands_changed.connect(_on_hands_changed)

	_update_rerolls_display()
	_update_hand_display()
	_update_score_bar()


func _build_ui() -> void:
	var layout := _make_screen_layout(32)
	var content: VBoxContainer = layout["content"]
	var action_bar: HBoxContainer = layout["action_bar"]

	_build_top_bar(content)
	_build_hand_subtitle(content)
	_build_score_panel(content)
	_build_dice_tray(content)
	_build_description_panel(content)

	var outer := content.get_parent()
	var action_center := action_bar.get_parent()
	_build_score_bar(outer, action_center)

	_reroll_btn = _make_colored_button("", Vector2(152, 68), PINK, PINK.lightened(0.15), 14)
	_reroll_btn.pressed.connect(_on_roll_pressed)
	action_bar.add_child(_reroll_btn)

	_end_turn_btn = _make_colored_button("", Vector2(168, 68), GREEN, GREEN.lightened(0.15), 16)
	_end_turn_btn.pressed.connect(_on_score_pressed)
	action_bar.add_child(_end_turn_btn)

	_build_result_overlay()
	_build_pause_overlay()
	modulate.a = 0.0
	_animating = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func(): _animating = false; queue_redraw())


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(bar)

	_menu_btn = _make_menu_button()
	_menu_btn.pressed.disconnect(_go_to_main_menu)
	_menu_btn.pressed.connect(_on_pause_pressed)
	bar.add_child(_menu_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	bar.add_child(_make_title_bar("COMBAT"))

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer2)

	var right_placeholder := Control.new()
	right_placeholder.custom_minimum_size = Vector2(96, 0)
	bar.add_child(right_placeholder)


func _build_hand_subtitle(parent: VBoxContainer) -> void:
	_hand_info_label = _make_pixel_label("", 14)
	_hand_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(_hand_info_label)


func _build_score_panel(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_score_panel = _make_panel(CARD_BG, CARD_BG, Vector2(780, 56), 12)
	center.add_child(_score_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	_score_panel.add_child(row)

	_combo_name_label = _make_pixel_label("", 16, DARK)
	_combo_name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_combo_name_label)

	var pts_row := HBoxContainer.new()
	pts_row.add_theme_constant_override("separation", 6)
	pts_row.alignment = BoxContainer.ALIGNMENT_CENTER
	pts_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pts_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(pts_row)

	_score_value_label = _make_pixel_label("ROLL!", 18, DARK)
	_score_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pts_row.add_child(_score_value_label)

	_score_pts_suffix = _make_pixel_label("", 16, DARK)
	_score_pts_suffix.size_flags_vertical = Control.SIZE_SHRINK_END
	_score_pts_suffix.visible = false
	pts_row.add_child(_score_pts_suffix)

	_score_breakdown_label = _make_pixel_label("", 14, DARK)
	_score_breakdown_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_score_breakdown_label)


func _build_score_bar(outer: VBoxContainer, before: Control) -> void:
	var center := CenterContainer.new()
	outer.add_child(center)
	outer.move_child(center, before.get_index())

	var bar_container := HBoxContainer.new()
	bar_container.add_theme_constant_override("separation", 12)
	bar_container.custom_minimum_size = Vector2(500, 0)
	center.add_child(bar_container)

	var score_label := _make_pixel_label("SCORE", 14, DARK)
	score_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_container.add_child(score_label)

	var track_wrapper := Control.new()
	track_wrapper.custom_minimum_size = Vector2(300, 24)
	track_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	track_wrapper.clip_contents = true
	bar_container.add_child(track_wrapper)

	_score_bar_track = ColorRect.new()
	_score_bar_track.color = DARK
	_score_bar_track.set_anchors_preset(Control.PRESET_FULL_RECT)
	track_wrapper.add_child(_score_bar_track)

	_score_bar_fill = ColorRect.new()
	_score_bar_fill.color = GREEN
	_score_bar_fill.position = Vector2(2, 2)
	_score_bar_fill.size = Vector2(0, 20)
	track_wrapper.add_child(_score_bar_fill)

	_score_bar_label = _make_pixel_label("0/" + str(GameManager.target_score), 16, DARK)
	_score_bar_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar_container.add_child(_score_bar_label)


func _build_dice_tray(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_dice_container = HBoxContainer.new()
	_dice_container.add_theme_constant_override("separation", 24)
	center.add_child(_dice_container)

	_dice_cards.clear()
	var all_dice: Array[Die] = GameManager.selected_dice if not GameManager.selected_dice.is_empty() else GameManager.dice_bag.draw(5)
	for i in range(all_dice.size()):
		var die: Die = all_dice[i]
		var card := CombatDice.new()
		card.setup(die, _pixel_font)
		card.card_pressed.connect(_on_die_clicked.bind(i))
		card.card_hover_entered.connect(_on_card_hover_enter.bind(card))
		card.card_hover_exited.connect(_on_card_hover_exit)
		_dice_container.add_child(card)
		_dice_cards.append(card)


func _set_die_face(index: int, value: int) -> void:
	if index < 0 or index >= _dice_cards.size():
		return
	_dice_cards[index].set_face(value)


func _build_description_panel(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_desc_panel = _make_panel(DARK, GOLD, Vector2(420, 0), 16)
	_desc_panel.visible = false
	_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_desc_panel)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", 12)
	desc_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_panel.add_child(desc_vbox)

	_desc_title = _make_pixel_label("", 14, GOLD)
	_desc_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc_vbox.add_child(_desc_title)

	_desc_body = _make_pixel_label("", 12, Color.WHITE)
	_desc_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_body.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_vbox.add_child(_desc_body)


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
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	_result_message = _make_pixel_label("", 36)
	_result_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_message)

	_result_score_label = _make_pixel_label("", 48, GOLD)
	_result_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_score_label)

	_result_sub_label = _make_pixel_label("", 16, Color("aaaaaa"))
	_result_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_sub_label)

	_result_coins_label = _make_pixel_label("", 20, GOLD)
	_result_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_coins_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	_result_next_btn = _make_pixel_button("NEXT ROUND", Vector2(280, 60), 16)
	_result_next_btn.pressed.connect(_on_next_round_pressed)
	_result_next_btn.visible = false
	vbox.add_child(_result_next_btn)

	_result_menu_btn = _make_pixel_button("BACK TO MENU", Vector2(280, 60), 14)
	_result_menu_btn.pressed.connect(_go_to_main_menu)
	_result_menu_btn.visible = false
	vbox.add_child(_result_menu_btn)


func _build_pause_overlay() -> void:
	_pause_overlay = ColorRect.new()
	_pause_overlay.color = Color(0, 0, 0, 0.85)
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.visible = false
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	var title := _make_pixel_label("PAUSED", 36, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)

	var resume_btn := _make_colored_button("RESUME", Vector2(280, 60), GREEN, GREEN.lightened(0.15), 16)
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)

	var quit_btn := _make_pixel_button("QUIT TO MENU", Vector2(280, 60), 14)
	quit_btn.pressed.connect(_on_pause_quit_pressed)
	vbox.add_child(quit_btn)


func _on_pause_pressed() -> void:
	if _result_overlay.visible:
		return
	get_tree().paused = true
	PokiSDK.gameplay_stop()
	_pause_overlay.visible = true


func _on_resume_pressed() -> void:
	_pause_overlay.visible = false
	get_tree().paused = false
	PokiSDK.gameplay_start()


func _on_pause_quit_pressed() -> void:
	_pause_overlay.visible = false
	get_tree().paused = false
	_result_final_score = combat_mgr.running_score
	_result_target_beaten = false
	_go_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _pause_overlay.visible:
			_on_resume_pressed()
		elif not _result_overlay.visible:
			_on_pause_pressed()


# -- Drawing helpers -----------------------------------------------------------

func _draw_panel_shadow(panel: Control, offset: Vector2) -> void:
	if not is_instance_valid(panel) or not panel.visible:
		return
	var gp := panel.global_position - global_position
	draw_rect(Rect2(gp + offset, panel.size), SHADOW_COLOR)


# -- HUD updates --------------------------------------------------------------

func _update_rerolls_display() -> void:
	if _reroll_btn:
		_reroll_btn.text = "ROLL DICE (%d left)" % combat_mgr.rerolls_remaining
		_reroll_btn.disabled = not combat_mgr.can_roll()
	if _end_turn_btn:
		_end_turn_btn.text = "END TURN"
		_end_turn_btn.disabled = not combat_mgr.can_score()


func _update_hand_display() -> void:
	if _hand_info_label:
		var current_hand := _total_hands - combat_mgr.hands_remaining + 1
		_hand_info_label.text = "Hand %d/%d" % [current_hand, _total_hands]


func _update_score_bar() -> void:
	if not _score_bar_fill or not _score_bar_label or not _score_bar_track:
		return
	var running := combat_mgr.running_score
	var target := combat_mgr.target_score
	_score_bar_label.text = "%d/%d" % [running, target]

	var track_w := _score_bar_track.size.x - 4
	var ratio := clampf(float(running) / float(target), 0.0, 1.0)
	_score_bar_fill.size = Vector2(track_w * ratio, 20)


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

	var in_combo: Array[bool] = combo.get("in_combo", [])
	var preview := combat_mgr.scoring_engine.calculate_score(
		combo, combat_mgr.current_roll, in_combo, GameManager.modifiers)

	var face_sum: int = int(preview.get("face_sum", 0))
	var mult: float = preview.get("mult", 1.0)
	var x_mult: float = preview.get("x_mult", 1.0)
	var pts: int = preview.get("total", 0)

	_score_value_label.add_theme_font_size_override("font_size", 28)
	_score_value_label.text = str(pts)
	_score_pts_suffix.text = "PTS"
	_score_pts_suffix.visible = true

	if x_mult > 1.0:
		_score_breakdown_label.text = "%d SUM x%.1f MULT x%.1f" % [face_sum, mult, x_mult]
	else:
		_score_breakdown_label.text = "%d SUM x%.1f MULT" % [face_sum, mult]

	AudioManager.play_sfx(&"combo_detect")

	_score_panel.scale = Vector2(0.8, 0.8)
	_animating = true
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)
	tween.tween_property(_score_panel, "scale", Vector2.ONE, 0.25)
	tween.tween_callback(func(): _animating = false)


# -- Signal handlers -----------------------------------------------------------

func _on_die_clicked(index: int) -> void:
	if not combat_mgr.has_rolled:
		return
	combat_mgr.toggle_hold(index)


func _on_die_held(index: int, held: bool) -> void:
	if index < 0 or index >= _dice_cards.size():
		return
	AudioManager.play_sfx(&"dice_hold" if held else &"dice_release")
	var card: Control = _dice_cards[index]
	card.set_held(held)

	var btn: Button = card.main_button
	_animating = true
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12)
	tween.tween_callback(func(): _animating = false)


func _on_roll_pressed() -> void:
	if not combat_mgr.can_roll():
		return
	_animate_roll()


func _animate_roll() -> void:
	_reroll_btn.disabled = true
	_animating = true
	AudioManager.play_sfx(&"dice_roll")

	var tween := create_tween()

	# Phase 1 — LIFT: scale down + slight rotation
	for i in range(_dice_cards.size()):
		if not combat_mgr.is_held(i):
			var btn: Button = _dice_cards[i].main_button
			tween.parallel().tween_property(btn, "rotation", randf_range(-0.2, 0.2), 0.05)
			tween.parallel().tween_property(btn, "scale", Vector2(0.85, 0.85), 0.05)

	# Phase 2 — TUMBLE: rapid face cycling with position jitter
	for f in range(8):
		tween.tween_callback(_show_random_faces)
		tween.tween_callback(_jitter_unheld_dice)
		tween.tween_interval(0.05)

	# Phase 3 — LAND: set final value, bounce scale, snap rotation
	tween.tween_callback(_do_actual_roll)
	for i in range(_dice_cards.size()):
		if not combat_mgr.is_held(i):
			var btn: Button = _dice_cards[i].main_button
			tween.parallel().tween_property(btn, "rotation", 0.0, 0.08)
			tween.parallel().tween_property(btn, "scale", Vector2(1.08, 1.08), 0.08) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	tween.tween_interval(0.06)

	for i in range(_dice_cards.size()):
		if not combat_mgr.is_held(i):
			var btn: Button = _dice_cards[i].main_button
			tween.parallel().tween_property(btn, "scale", Vector2(1.04, 0.96), 0.06)

	for i in range(_dice_cards.size()):
		if not combat_mgr.is_held(i):
			var btn: Button = _dice_cards[i].main_button
			tween.parallel().tween_property(btn, "scale", Vector2.ONE, 0.10) \
				.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	tween.tween_callback(_update_rerolls_display)
	tween.tween_callback(func(): _animating = false)


func _jitter_unheld_dice() -> void:
	for i in range(_dice_cards.size()):
		if not combat_mgr.is_held(i):
			var btn: Button = _dice_cards[i].main_button
			btn.rotation = randf_range(-0.12, 0.12)
			var s := randf_range(0.84, 0.92)
			btn.scale = Vector2(s, s)


func _show_random_faces() -> void:
	for i in range(_dice_cards.size()):
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
		_score_value_label.add_theme_font_size_override("font_size", 18)
		_score_value_label.text = "NO COMBO"
		_score_pts_suffix.text = ""
		_score_pts_suffix.visible = false
		_score_breakdown_label.text = ""

	_update_rerolls_display()


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
	_animating = true
	AudioManager.play_sfx(&"score_tick")
	var tween := create_tween()

	tween.tween_callback(func():
		_combo_name_label.text = combo.get("name", "").to_upper()
		_score_value_label.text = "+%d" % total
		_score_value_label.add_theme_color_override("font_color", GREEN)
		_score_pts_suffix.text = "PTS"
		_score_pts_suffix.visible = true
		_score_pts_suffix.add_theme_color_override("font_color", GREEN)
		_score_breakdown_label.text = ""
		_update_score_bar()
		_update_hand_display()
	)
	tween.tween_interval(0.5)

	tween.tween_interval(1.0)

	tween.tween_callback(func():
		_score_value_label.add_theme_color_override("font_color", DARK)
		_score_pts_suffix.add_theme_color_override("font_color", DARK)
		_reset_for_next_hand()
		_animating = false
	)


func _reset_for_next_hand() -> void:
	if combat_mgr.hands_remaining <= 0:
		return

	_combo_name_label.text = ""
	_score_value_label.add_theme_font_size_override("font_size", 18)
	_score_value_label.text = "ROLL!"
	_score_pts_suffix.text = ""
	_score_pts_suffix.visible = false
	_score_breakdown_label.text = ""

	for i in range(_current_values.size()):
		_current_values[i] = 0
	for i in range(_dice_cards.size()):
		_dice_cards[i].reset_die()

	_update_rerolls_display()


func _on_rerolls_changed(_remaining: int) -> void:
	_update_rerolls_display()


func _on_card_hover_enter(card: Control) -> void:
	_desc_title.add_theme_color_override("font_color", GOLD)
	_desc_title.text = card.hover_name
	_desc_body.text = card.hover_description
	_desc_panel.visible = true


func _on_card_hover_exit() -> void:
	_desc_panel.visible = false


func _on_hands_changed(_remaining: int) -> void:
	_update_hand_display()


func _on_combat_ended(final_score: int, target_beaten: bool) -> void:
	_result_final_score = final_score
	_result_target_beaten = target_beaten
	_show_result_overlay(final_score, target_beaten)


func _show_result_overlay(final_score: int, target_beaten: bool) -> void:
	_result_overlay.visible = true
	_result_overlay.modulate.a = 0.0
	AudioManager.play_sfx(&"round_win" if target_beaten else &"game_over")

	_result_score_label.text = str(final_score) + " PTS"

	if target_beaten:
		_result_message.text = "ROUND %d CLEARED!" % GameManager.current_round
		_result_message.add_theme_color_override("font_color", GOLD)
		_result_sub_label.text = "Target: %d" % GameManager.target_score
		var reward := GameManager.get_round_reward()
		_result_coins_label.text = "+%d coins" % reward
		_result_coins_label.visible = true
		_result_next_btn.visible = true
		_result_menu_btn.visible = false
	else:
		_result_message.text = "GAME OVER"
		_result_message.add_theme_color_override("font_color", DIE_COLORS["red"])
		_result_sub_label.text = "Reached Round %d" % GameManager.current_round
		_result_coins_label.visible = false
		_result_next_btn.visible = false
		_result_menu_btn.visible = true

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_result_overlay, "modulate:a", 1.0, 0.5)


# -- Navigation ----------------------------------------------------------------

func _on_next_round_pressed() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): GameManager.end_combat(_result_final_score, true))

func _go_to_main_menu() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): GameManager.end_combat(_result_final_score, false))
