extends "res://scripts/ui/pixel_bg.gd"

const CombatDice = preload("res://scripts/ui/combat_dice.gd")
const TutorialOverlay = preload("res://scripts/ui/tutorial_overlay.gd")

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
var _score_bar_container: HBoxContainer
var _title_bar_vbox: VBoxContainer

var _total_hands: int = 4

var _result_overlay: ColorRect
var _result_panel: PanelContainer
var _result_score_label: Label
var _result_message: Label
var _result_sub_label: Label
var _result_coins_label: Label
var _result_next_btn: Button
var _result_retry_btn: Button
var _result_menu_btn: Button
var _result_final_score: int = 0
var _result_target_beaten: bool = false

var _pause_overlay: ColorRect

var _combo_overlay: ColorRect
var _combo_btn: Button
var _combo_dialog: VBoxContainer
var _combo_row_panels: Array = []

var _animating: bool = false
var _tutorial_overlay: Control
var _tutorial_rolls_seen: int = 0


func _ready() -> void:
	super._ready()
	_build_ui()
	TutorialManager.step_changed.connect(_on_tutorial_step_changed)
	TutorialManager.state_changed.connect(_refresh_tutorial_ui)
	if TutorialManager.is_active():
		TutorialManager.enter_scene(TutorialManager.SCENE_COMBAT)
	_setup_combat()
	_refresh_tutorial_ui()
	AudioManager.play_music(&"menu")


func _process(_delta: float) -> void:
	if _animating:
		queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_button_shadows([_menu_btn, _combo_btn], Vector2(4, 4))
	_draw_panel_shadow(_score_panel, Vector2(8, 8))
	_draw_button_shadows([_reroll_btn], Vector2(6, 6))
	_draw_button_shadows([_end_turn_btn], Vector2(8, 8))


func _setup_combat() -> void:
	combat_mgr = CombatManager.new()
	add_child(combat_mgr)

	var dice: Array[Die] = GameManager.selected_dice if not GameManager.selected_dice.is_empty() else GameManager.dice_bag.draw(5)
	var roll_provider := Callable()
	if TutorialManager.should_use_scripted_rolls():
		roll_provider = Callable(self, "_provide_tutorial_roll")
	combat_mgr.start_combat(
		dice,
		GameManager.target_score,
		GameManager.hands_per_round,
		GameManager.rerolls_per_hand,
		DataManager.get_combo_rules(),
		GameManager.rerolls_per_hand,
		roll_provider
	)
	_tutorial_rolls_seen = 0

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
	_refresh_tutorial_dice_accents()


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
	_build_combo_overlay()
	_build_tutorial_overlay()
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

	_title_bar_vbox = _make_title_bar("COMBAT")
	bar.add_child(_title_bar_vbox)

	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer2)

	_combo_btn = _make_pixel_button("COMBOS", Vector2(96, 56), 10)
	_combo_btn.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_combo_btn.pressed.connect(_on_combo_btn_pressed)
	bar.add_child(_combo_btn)


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

	_score_bar_container = HBoxContainer.new()
	_score_bar_container.add_theme_constant_override("separation", 12)
	_score_bar_container.custom_minimum_size = Vector2(500, 0)
	center.add_child(_score_bar_container)

	var score_label := _make_pixel_label("SCORE", 14, DARK)
	score_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_score_bar_container.add_child(score_label)

	var track_wrapper := Control.new()
	track_wrapper.custom_minimum_size = Vector2(300, 24)
	track_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	track_wrapper.clip_contents = true
	_score_bar_container.add_child(track_wrapper)

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
	_score_bar_container.add_child(_score_bar_label)


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

	_result_panel = _make_panel(Color(0.12, 0.12, 0.12, 0.98), GOLD, Vector2(760, 0), 24)
	_result_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(_result_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	_result_panel.add_child(vbox)

	_result_message = _make_pixel_label("", 32)
	_result_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_message.custom_minimum_size = Vector2(660, 0)
	_result_message.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(_result_message)

	_result_score_label = _make_pixel_label("", 40, GOLD)
	_result_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_score_label.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(_result_score_label)

	_result_sub_label = _make_pixel_label("", 16, Color("aaaaaa"))
	_result_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_sub_label.custom_minimum_size = Vector2(660, 0)
	_result_sub_label.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(_result_sub_label)

	_result_coins_label = _make_pixel_label("", 20, GOLD)
	_result_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_coins_label.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(_result_coins_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(spacer)

	_result_next_btn = _make_pixel_button("NEXT ROUND", Vector2(280, 60), 16)
	_result_next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_result_next_btn.pressed.connect(_on_next_round_pressed)
	_result_next_btn.visible = false
	vbox.add_child(_result_next_btn)

	_result_retry_btn = _make_colored_button("RETRY TUTORIAL", Vector2(280, 60), PINK, PINK.lightened(0.15), 14)
	_result_retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_result_retry_btn.pressed.connect(_on_retry_tutorial_pressed)
	_result_retry_btn.visible = false
	vbox.add_child(_result_retry_btn)

	_result_menu_btn = _make_pixel_button("BACK TO MENU", Vector2(280, 60), 14)
	_result_menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
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


func _build_combo_overlay() -> void:
	_combo_overlay = ColorRect.new()
	_combo_overlay.color = Color(0, 0, 0, 0.85)
	_combo_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combo_overlay.visible = false
	add_child(_combo_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combo_overlay.add_child(center)

	_combo_dialog = VBoxContainer.new()
	_combo_dialog.alignment = BoxContainer.ALIGNMENT_CENTER
	_combo_dialog.add_theme_constant_override("separation", 6)
	center.add_child(_combo_dialog)

	var title := _make_pixel_label("COMBOS", 20, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_dialog.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	_combo_dialog.add_child(spacer)

	_combo_row_panels.clear()
	var combos := DataManager.get_combo_rules()
	for combo in combos:
		var row_data := _make_combo_row(combo)
		_combo_dialog.add_child(row_data["panel"])
		_combo_row_panels.append({
			"panel": row_data["panel"],
			"type": combo.get("type", ""),
			"default_style": row_data["default_style"],
		})

	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 12)
	_combo_dialog.add_child(spacer2)

	var close_btn := _make_colored_button("CLOSE", Vector2(200, 52), GREEN, GREEN.lightened(0.15), 14)
	close_btn.pressed.connect(_on_combo_close_pressed)
	_combo_dialog.add_child(close_btn)


func _on_pause_pressed() -> void:
	if _result_overlay.visible:
		return
	if _combo_overlay.visible:
		_request_close_combo_overlay()
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
		if _combo_overlay.visible:
			if _request_close_combo_overlay():
				return
		elif _pause_overlay.visible:
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
		_hand_info_label.text = "Turn %d/%d" % [current_hand, _total_hands]


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

	var preview := _calculate_combo_preview(combo)

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


func _calculate_combo_preview(combo: Dictionary) -> Dictionary:
	if combat_mgr == null or combo.is_empty():
		return {}
	var in_combo: Array[bool] = combo.get("in_combo", [])
	return combat_mgr.scoring_engine.calculate_score(
		combo, combat_mgr.current_roll, in_combo, GameManager.modifiers)


func _build_combo_tutorial_body() -> String:
	if combat_mgr == null:
		return "The highlighted row is the combo you match."

	var combo := combat_mgr.get_current_combo()
	if combo.is_empty():
		return "The highlighted row is the combo you match."

	var preview := _calculate_combo_preview(combo)
	var rolled_values := combat_mgr.current_roll_values()
	var face_parts: PackedStringArray = []
	for value in rolled_values:
		face_parts.append(str(value))

	var combo_name: String = str(combo.get("name", "Combo"))
	var in_combo: Array[bool] = combo.get("in_combo", [])
	var matched_values: PackedStringArray = []
	for i in range(mini(in_combo.size(), rolled_values.size())):
		if in_combo[i]:
			matched_values.append(str(rolled_values[i]))
	var matched_summary := ", ".join(matched_values)
	if matched_values.size() == 2 and matched_values[0] == matched_values[1]:
		matched_summary = "two %ss" % matched_values[0]

	var face_sum := int(preview.get("face_sum", 0))
	var mult := float(preview.get("mult", 1.0))
	var x_mult := float(preview.get("x_mult", 1.0))
	var total := int(preview.get("total", 0))

	var body_lines := [
		"This roll matches %s because %s line up." % [combo_name.to_upper(), matched_summary],
		"%s = %d face sum." % [" + ".join(face_parts), face_sum],
		"%d x %s %s mult = %d pts." % [face_sum, _format_tutorial_factor(mult), combo_name.to_lower(), total],
	]
	if x_mult > 1.0:
		body_lines.append("%d x %s X-mult = %d pts total." % [int(floor(face_sum * mult)), _format_tutorial_factor(x_mult), total])
	else:
		body_lines.append("That is exactly what you would bank if you scored now.")
	return "\n".join(body_lines)


func _format_tutorial_factor(value: float) -> String:
	return "%.1f" % value


# -- Signal handlers -----------------------------------------------------------

func _on_die_clicked(index: int) -> void:
	if not combat_mgr.has_rolled:
		return
	if TutorialManager.is_active():
		var held_after_click := _held_indices_after_toggle(index)
		if not TutorialManager.is_combat_hold_allowed(index, held_after_click):
			return
	combat_mgr.toggle_hold(index)


func _on_die_held(index: int, held: bool) -> void:
	if index < 0 or index >= _dice_cards.size():
		return
	AudioManager.play_sfx(&"dice_hold" if held else &"dice_release")
	var card: Control = _dice_cards[index]
	card.set_held(held)
	_refresh_tutorial_dice_accents()
	if TutorialManager.is_active():
		TutorialManager.report_action("hold_changed", {"held_indices": _current_held_indices()})
		_refresh_tutorial_ui()

	var btn: Button = card.main_button
	_animating = true
	var tween := create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.08)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.12)
	tween.tween_callback(func(): _animating = false)


func _on_roll_pressed() -> void:
	if not combat_mgr.can_roll():
		return
	if TutorialManager.is_active() and not TutorialManager.is_combat_roll_allowed():
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
	_update_combo_highlight()
	_refresh_tutorial_dice_accents()
	if TutorialManager.is_active():
		TutorialManager.report_action("combat_roll", {"roll_number": _tutorial_rolls_seen})
		_tutorial_rolls_seen += 1
		_refresh_tutorial_ui()


func _on_score_pressed() -> void:
	if not combat_mgr.can_score():
		return
	if TutorialManager.is_active() and not TutorialManager.is_combat_score_allowed():
		return
	if TutorialManager.is_active():
		TutorialManager.report_action("combat_score")
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
		if combat_mgr.hand_state == CombatManager.HandState.HAND_TRANSITION:
			combat_mgr.begin_next_hand()
			_reset_for_next_hand()
		_animating = false
	)


func _reset_for_next_hand() -> void:
	if combat_mgr.hand_state != CombatManager.HandState.HAND_ACTIVE:
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
	_update_combo_highlight()
	_refresh_tutorial_dice_accents()


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
	if TutorialManager.is_active() and target_beaten:
		TutorialManager.report_action("combat_win")
	_result_final_score = final_score
	_result_target_beaten = target_beaten
	_show_result_overlay(final_score, target_beaten)
	_refresh_tutorial_ui()


func _show_result_overlay(final_score: int, target_beaten: bool) -> void:
	_result_overlay.visible = true
	_result_overlay.modulate.a = 0.0
	AudioManager.play_sfx(&"round_win" if target_beaten else &"game_over")

	_result_score_label.text = str(final_score) + " PTS"

	if target_beaten:
		if GameManager.current_round == 0:
			_result_message.text = "ROUND CLEARED!"
		else:
			_result_message.text = "ROUND %d CLEARED!" % GameManager.current_round
		_result_message.add_theme_color_override("font_color", GOLD)
		if TutorialManager.step_id == TutorialManager.STEP_INTRO_WIN:
			_result_sub_label.text = "Great start! Now let's head to the Flea Market and upgrade your dice."
		elif TutorialManager.is_active():
			_result_sub_label.text = "Great job! You improved your dice, held a strong pair, and turned it into a big combo. You've got the basics down!"
		else:
			_result_sub_label.text = "Target: %d" % GameManager.target_score
		var reward := GameManager.get_round_reward()
		_result_coins_label.text = "+%d coins" % reward
		_result_coins_label.visible = true
		_result_next_btn.visible = true
		_result_retry_btn.visible = false
		_result_menu_btn.visible = false
	else:
		if TutorialManager.is_active():
			_result_message.text = "NOT QUITE!"
			_result_message.add_theme_color_override("font_color", DIE_COLORS["red"])
			_result_sub_label.text = "No worries -- give it another shot! The tutorial is here to help you practice."
			_result_coins_label.visible = false
			_result_next_btn.visible = false
			_result_retry_btn.visible = true
			_result_menu_btn.visible = true
		else:
			_result_message.text = "GAME OVER"
			_result_message.add_theme_color_override("font_color", DIE_COLORS["red"])
			_result_sub_label.text = "Reached Round %d" % GameManager.current_round
			_result_coins_label.visible = false
			_result_next_btn.visible = false
			_result_retry_btn.visible = false
			_result_menu_btn.visible = true

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_result_overlay, "modulate:a", 1.0, 0.5)


func _make_combo_row(combo: Dictionary) -> Dictionary:
	var combo_type: String = combo.get("type", "")
	var combo_name: String = combo.get("name", "")
	var priority: int = combo.get("priority", 0)

	var default_style := _make_style(Color(0.1, 0.1, 0.1, 0.6), Color(0.2, 0.2, 0.2, 0.4), 2, 8)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	panel.add_theme_stylebox_override("panel", default_style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var name_label := _make_pixel_label(combo_name.to_upper(), 10, Color.WHITE)
	name_label.custom_minimum_size = Vector2(180, 0)
	row.add_child(name_label)

	var pattern_box := HBoxContainer.new()
	pattern_box.add_theme_constant_override("separation", 4)
	var colors := _get_pattern_colors(combo_type)
	for c in colors:
		var sq := ColorRect.new()
		sq.custom_minimum_size = Vector2(14, 14)
		sq.color = c
		pattern_box.add_child(sq)
	row.add_child(pattern_box)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var mult_data := _get_effective_mult(combo)
	if mult_data["modified"]:
		var mult_box := HBoxContainer.new()
		mult_box.add_theme_constant_override("separation", 6)
		var base_label := _make_pixel_label("x%.1f" % mult_data["base"], 9, Color(0.5, 0.5, 0.5))
		mult_box.add_child(base_label)
		var eff_label := _make_pixel_label("x%.1f" % mult_data["effective"], 10, GOLD)
		mult_box.add_child(eff_label)
		row.add_child(mult_box)
	else:
		var mult_color := Color.WHITE
		match priority:
			0, 1: mult_color = Color("888888")
			2, 3: mult_color = Color("ff6b4a")
			4, 5: mult_color = BLUE
			6, 7: mult_color = GOLD
			8: mult_color = PINK
		var mult_label := _make_pixel_label("x%.1f" % mult_data["base"], 10, mult_color)
		row.add_child(mult_label)

	return { "panel": panel, "default_style": default_style }


func _get_pattern_colors(combo_type: String) -> Array:
	var a := BLUE
	var b := PINK
	var g := Color("888888")
	var s := [GREEN.darkened(0.3), GREEN.darkened(0.15), GREEN, GREEN.lightened(0.15), GREEN.lightened(0.3)]

	match combo_type:
		"high_card":      return [a, g, g, g, g]
		"pair":           return [a, a, g, g, g]
		"two_pair":       return [a, a, b, b, g]
		"three_same":     return [a, a, a, g, g]
		"small_straight": return [s[0], s[1], s[2], s[3], g]
		"full_house":     return [a, a, a, b, b]
		"large_straight": return [s[0], s[1], s[2], s[3], s[4]]
		"four_same":      return [a, a, a, a, g]
		"yahtzee":        return [a, a, a, a, a]
		_:                return [g, g, g, g, g]


func _get_effective_mult(combo: Dictionary) -> Dictionary:
	var base: float = combo.get("combo_mult", 1.0)
	var effective: float = base
	var combo_type: String = combo.get("type", "")
	for mod in GameManager.modifiers:
		if mod.get("effect", "") == "add_mult":
			var condition: String = mod.get("condition", "")
			if condition.is_empty() or condition == "always" or condition == combo_type:
				effective += mod.get("value", 0.0)
	return { "base": base, "effective": effective, "modified": not is_equal_approx(base, effective) }


func _on_combo_btn_pressed() -> void:
	if _result_overlay.visible or _pause_overlay.visible:
		return
	if TutorialManager.is_active():
		if TutorialManager.step_id in [TutorialManager.STEP_INTRO_WIN, TutorialManager.STEP_INTRO_FINISH]:
			pass
		elif TutorialManager.step_id not in [
			TutorialManager.STEP_INTRO_PAIR,
		]:
			return
		match TutorialManager.step_id:
			TutorialManager.STEP_INTRO_PAIR:
				if _combo_overlay.visible:
					_combo_overlay.visible = false
					TutorialManager.report_action("combo_overlay_closed")
				else:
					_open_combo_overlay()
				_refresh_tutorial_ui()
				return
	if _combo_overlay.visible:
		_request_close_combo_overlay()
	else:
		_open_combo_overlay()


func _update_combo_highlight() -> void:
	var current_type := ""
	if combat_mgr and combat_mgr.has_rolled:
		var combo := combat_mgr.get_current_combo()
		current_type = combo.get("type", "")

	var highlight_style := _make_style(Color(0.29, 0.62, 1.0, 0.2), BLUE, 2, 8)
	for entry in _combo_row_panels:
		if entry["type"] == current_type and not current_type.is_empty():
			entry["panel"].add_theme_stylebox_override("panel", highlight_style)
		else:
			entry["panel"].add_theme_stylebox_override("panel", entry["default_style"])


# -- Navigation ----------------------------------------------------------------

func _on_next_round_pressed() -> void:
	if TutorialManager.is_active():
		TutorialManager.report_action("combat_next_round")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): GameManager.end_combat(_result_final_score, true))

func _go_to_main_menu() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): GameManager.end_combat(_result_final_score, false))


func _build_tutorial_overlay() -> void:
	_tutorial_overlay = TutorialOverlay.new()
	add_child(_tutorial_overlay)
	_tutorial_overlay.setup(_pixel_font)
	_tutorial_overlay.next_pressed.connect(_on_tutorial_next_pressed)


func _refresh_tutorial_ui() -> void:
	if _tutorial_overlay == null:
		return
	_update_tutorial_action_gating()
	if not TutorialManager.is_active() or TutorialManager.checkpoint_scene != TutorialManager.SCENE_COMBAT:
		_tutorial_overlay.hide_overlay()
		return
	if _result_overlay.visible and not _result_target_beaten:
		_tutorial_overlay.hide_overlay()
		return
	if _combo_overlay.visible and TutorialManager.step_id == TutorialManager.STEP_INTRO_PAIR:
		_tutorial_overlay.hide_overlay()
		return
	if TutorialManager.step_id == TutorialManager.STEP_INTRO_WIN and not _result_overlay.visible:
		_tutorial_overlay.hide_overlay()
		return

	var config := TutorialManager.get_step_text()
	if config.is_empty():
		_tutorial_overlay.hide_overlay()
		return

	var highlight: Variant = _get_tutorial_highlight_target()
	var avoid: Variant = _get_tutorial_avoid_target()
	_tutorial_overlay.show_step_from_config(config, highlight, avoid)


func _update_tutorial_action_gating() -> void:
	if _combo_btn == null:
		return
	if not TutorialManager.is_active() or TutorialManager.checkpoint_scene != TutorialManager.SCENE_COMBAT:
		_combo_btn.disabled = false
		return
	_combo_btn.disabled = TutorialManager.step_id not in [
		TutorialManager.STEP_INTRO_PAIR,
		TutorialManager.STEP_INTRO_WIN,
	]


func _get_tutorial_highlight_target() -> Variant:
	match TutorialManager.step_id:
		TutorialManager.STEP_INTRO_ROLL, TutorialManager.STEP_COMBAT_GOOD_LUCK: return _reroll_btn
		TutorialManager.STEP_INTRO_HOLD: return _find_required_hold_targets()
		TutorialManager.STEP_INTRO_REROLL: return _reroll_btn
		TutorialManager.STEP_INTRO_FINISH: return _end_turn_btn
		TutorialManager.STEP_INTRO_WIN: return _result_next_btn
		TutorialManager.STEP_INTRO_WELCOME:
			var targets: Array[Control] = [_title_bar_vbox, _score_bar_container]
			return targets
		TutorialManager.STEP_INTRO_PAIR: return _combo_btn
		_: return null


func _get_tutorial_avoid_target() -> Variant:
	return null


func _refresh_tutorial_dice_accents() -> void:
	if not TutorialManager.is_active():
		return
	var show_accents := TutorialManager.step_id not in [
		TutorialManager.STEP_INTRO_WELCOME,
		TutorialManager.STEP_INTRO_ROLL,
		TutorialManager.STEP_INTRO_PAIR,
		TutorialManager.STEP_INTRO_FINISH,
		TutorialManager.STEP_INTRO_WIN,
		TutorialManager.STEP_COMBAT_GOOD_LUCK,
	]
	for i in range(_dice_cards.size()):
		var card = _dice_cards[i]
		if card is CombatDice:
			var accent := show_accents and TutorialManager.required_combat_hold_indices.has(i)
			(card as CombatDice).set_accent(accent, BLUE)


func _provide_tutorial_roll(roll_number: int, _held_dice: Array) -> Array[int]:
	return TutorialManager.get_scripted_roll_values(roll_number)


func _current_held_indices() -> Array[int]:
	var held_indices: Array[int] = []
	for i in range(_dice_cards.size()):
		if combat_mgr.is_held(i):
			held_indices.append(i)
	return held_indices


func _held_indices_after_toggle(index: int) -> Array[int]:
	var held_indices := _current_held_indices()
	if held_indices.has(index):
		held_indices.erase(index)
	else:
		held_indices.append(index)
	held_indices.sort()
	return held_indices


func _find_required_hold_targets() -> Array[Control]:
	var targets: Array[Control] = []
	for i in TutorialManager.required_combat_hold_indices:
		if i >= 0 and i < _dice_cards.size():
			targets.append(_dice_cards[i])
	if targets.is_empty():
		targets.append(_dice_container)
	return targets


func _find_current_combo_row_panel() -> Control:
	var combo := combat_mgr.get_current_combo()
	var combo_type: String = combo.get("type", "")
	for entry in _combo_row_panels:
		if entry["type"] == combo_type:
			return entry["panel"]
	return _combo_btn


func _open_combo_overlay() -> void:
	_combo_overlay.visible = true
	_update_combo_highlight()


func _request_close_combo_overlay() -> bool:
	_combo_overlay.visible = false
	if TutorialManager.is_active() and TutorialManager.step_id == TutorialManager.STEP_INTRO_PAIR:
		TutorialManager.report_action("combo_overlay_closed")
		_refresh_tutorial_ui()
	return true


func _on_combo_close_pressed() -> void:
	_request_close_combo_overlay()


func _on_retry_tutorial_pressed() -> void:
	if TutorialManager.is_replay():
		GameManager.start_tutorial_replay()
	else:
		GameManager.start_game()


func _on_tutorial_next_pressed() -> void:
	match TutorialManager.step_id:
		TutorialManager.STEP_INTRO_WELCOME:
			TutorialManager.report_action("advance_intro")


func _on_tutorial_step_changed(_step: String) -> void:
	_refresh_tutorial_ui()
