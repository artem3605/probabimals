extends "res://scripts/ui/pixel_bg.gd"

const CombatDice = preload("res://scripts/combat/combat_dice.gd")
const CombatProbabilityPanelScript = preload("res://scripts/combat/combat_probability_panel.gd")
const ComboRevealFxScript = preload("res://scripts/ui/combo_reveal_fx.gd")
const ScoreFormat = preload("res://scripts/ui/score_format.gd")
const TutorialOverlay = preload("res://scripts/ui/tutorial_overlay.gd")
const SemanticMarkup = preload("res://scripts/ui/semantic_markup.gd")
const SemanticColors = preload("res://scripts/ui/semantic_colors.gd")
const COMBAT_CONTENT_SEPARATION := 32
const COMBAT_TOP_BAR_SEPARATION := 16
const COMBAT_MENU_SHADOW_OFFSET := Vector2(4, 4)
const COMBAT_SCORE_PANEL_SHADOW_OFFSET := Vector2(8, 8)
const COMBAT_REROLL_SHADOW_OFFSET := Vector2(6, 6)
const COMBAT_END_TURN_SHADOW_OFFSET := Vector2(8, 8)
const COMBAT_REROLL_BUTTON_SIZE := Vector2(152, 68)
const COMBAT_REROLL_BUTTON_FONT_SIZE := 14
const COMBAT_END_TURN_BUTTON_SIZE := Vector2(168, 68)
const COMBAT_END_TURN_BUTTON_FONT_SIZE := 16
const COMBAT_HAND_INFO_FONT_SIZE := 14
const COMBAT_TOP_BAR_CLUSTER_MIN_WIDTH := 320
const COMBAT_SCORE_LABEL_FONT_SIZE := 14
const COMBAT_SCORE_VALUE_IDLE_FONT_SIZE := 18
const COMBAT_SCORE_VALUE_PREVIEW_FONT_SIZE := 28
const COMBAT_SCORE_BREAKDOWN_FONT_SIZE := 16
const COMBAT_SCORE_BREAKDOWN_X_MULT_FONT_SIZE := 16
const COMBAT_SCORE_BAR_SEPARATION := 10
const COMBAT_SCORE_BAR_TRACK_SIZE := Vector2(170, 20)
const COMBAT_SCORE_BAR_FILL_OFFSET := Vector2(2, 2)
const COMBAT_SCORE_BAR_FILL_HEIGHT := 16
const COMBAT_SCORE_BAR_TRACK_INSET := 4
const COMBAT_SCORE_FLIGHT_FONT_SIZE := 22
const COMBAT_SCORE_FLIGHT_DURATION := 0.48
const COMBAT_SCORE_FLIGHT_ARC_HEIGHT := 58.0
const COMBAT_SCORE_BAR_POP_SCALE := Vector2(1.08, 1.08)
const COMBAT_LAST_REROLL_STOP_BASE_DELAY := 0.16
const COMBAT_LAST_REROLL_STOP_EXTRA_DELAY := 0.02
const COMBAT_LAST_REROLL_MAX_LAST_STOP_DELAY := 0.8
const COMBAT_LAST_REROLL_POST_REVEAL_DELAY := 0.18
const COMBAT_LAST_REROLL_FINAL_POP_SCALE := Vector2(1.14, 1.14)
const COMBAT_LAST_REROLL_NORMAL_POP_SCALE := Vector2(1.08, 1.08)
const COMBAT_LAST_REROLL_SCRAMBLE_STEP := 0.05
const COMBAT_TURN_PILL_LABEL_FONT_SIZE := 12
const COMBAT_TURN_PILL_VALUE_FONT_SIZE := 16
const COMBAT_TURN_PILL_SEPARATION := 8
const COMBAT_TURN_PILL_MARGIN := 10
const COMBAT_TURN_PILL_BORDER_WIDTH := 4
const COMBAT_WORKSPACE_SEPARATION := 16
const COMBAT_DICE_TRAY_SEPARATION := 24
const COMBAT_DESC_PANEL_SIZE := Vector2(420, 96)
const COMBAT_DESC_PANEL_MARGIN := 16
const COMBAT_DESC_SEPARATION := 12
const COMBAT_DESC_TITLE_FONT_SIZE := 14
const COMBAT_DESC_BODY_FONT_SIZE := 12
const COMBAT_DESC_BODY_WIDTH := COMBAT_DESC_PANEL_SIZE.x - COMBAT_DESC_PANEL_MARGIN * 2
const COMBAT_DESC_COMBO_SQUARE_SIZE := 20
const COMBAT_DESC_COMBO_SQUARE_GAP := 4
const COMBAT_DESC_COMBO_SQUARE_BORDER := 1
const COMBAT_DESC_COMBO_MULT_FONT_SIZE := 18
const COMBAT_DESC_COMBO_ROW_SEPARATION := 16
const COMBAT_RESULT_PANEL_SIZE := Vector2(760, 0)
const COMBAT_RESULT_PANEL_MARGIN := 24
const COMBAT_RESULT_SEPARATION := 20
const COMBAT_RESULT_MESSAGE_FONT_SIZE := 32
const COMBAT_RESULT_MESSAGE_WIDTH := Vector2(660, 0)
const COMBAT_RESULT_SCORE_FONT_SIZE := 40
const COMBAT_RESULT_SUB_FONT_SIZE := 16
const COMBAT_RESULT_COINS_FONT_SIZE := 20
const COMBAT_RESULT_BUTTON_SPACER_HEIGHT := 12
const COMBAT_RESULT_BUTTON_SIZE := Vector2(280, 60)
const COMBAT_RESULT_NEXT_BUTTON_FONT_SIZE := 16
const COMBAT_RESULT_RETRY_BUTTON_FONT_SIZE := 14
const COMBAT_RESULT_SURVEY_BUTTON_FONT_SIZE := 14
const COMBAT_RESULT_MENU_BUTTON_FONT_SIZE := 14
const COMBAT_PAUSE_SEPARATION := 24
const COMBAT_PAUSE_TITLE_FONT_SIZE := 36
const COMBAT_PAUSE_BUTTON_SPACER_HEIGHT := 20
const COMBAT_PAUSE_BUTTON_SIZE := Vector2(280, 60)
const COMBAT_PAUSE_RESUME_BUTTON_FONT_SIZE := 16
const COMBAT_PAUSE_QUIT_BUTTON_FONT_SIZE := 14

var combat_mgr: CombatManager
var _dice_cards: Array = []
var _current_values: Array[int] = []

var _menu_btn: Button
var _top_bar_right_cluster: HBoxContainer
var _combo_name_label: Label
var _score_value_label: Label
var _score_pts_suffix: Label
var _score_breakdown_label: RichTextLabel
var _score_panel: PanelContainer
var _reroll_btn: Button
var _end_turn_btn: Button
var _turn_pill: PanelContainer
var _dice_container: HBoxContainer
var _desc_panel: PanelContainer
var _desc_title: RichTextLabel
var _desc_rarity: RichTextLabel
var _desc_body: RichTextLabel
var _desc_combo_row: HBoxContainer
var _desc_combo_squares: Array[PanelContainer] = []
var _desc_combo_mult_label: Label
var _probability_panel_ui
var _probability_dock: Control
var _probability_panel: PanelContainer
var _combo_reveal_fx
var _pending_combo_reveal: Dictionary = {}
var _combo_hud_tween: Tween
var _score_flight_label: Label

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
var _result_coins_label: RichTextLabel
var _result_next_btn: Button
var _result_retry_btn: Button
var _result_survey_btn: Button
var _result_menu_btn: Button
var _result_final_score: int = 0
var _result_target_beaten: bool = false

var _pause_overlay: ColorRect

var _animating: bool = false
var _suspense_reveal_active: bool = false
var _suspense_final_results: Array[int] = []
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


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
		call_deferred("_refresh_responsive_layout")


func _process(_delta: float) -> void:
	if _animating:
		queue_redraw()


func _draw() -> void:
	_draw_all_bg()
	_draw_button_shadows([_menu_btn], COMBAT_MENU_SHADOW_OFFSET)
	_draw_panel_shadow(_score_panel, COMBAT_SCORE_PANEL_SHADOW_OFFSET)
	_draw_button_shadows([_reroll_btn], COMBAT_REROLL_SHADOW_OFFSET)
	_draw_button_shadows([_end_turn_btn], COMBAT_END_TURN_SHADOW_OFFSET)


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
	_refresh_probability_panel()
	_refresh_tutorial_dice_accents()


func _build_ui() -> void:
	var layout := _make_screen_layout(COMBAT_CONTENT_SEPARATION)
	var content: VBoxContainer = layout["content"]
	var action_bar: HBoxContainer = layout["action_bar"]

	_build_top_bar(content)
	_build_probability_panel(content)
	_build_combat_workspace(content)

	_reroll_btn = _make_colored_button(
		"",
		COMBAT_REROLL_BUTTON_SIZE,
		PINK,
		PINK.lightened(0.15),
		COMBAT_REROLL_BUTTON_FONT_SIZE
	)
	_reroll_btn.pressed.connect(_on_roll_pressed)
	action_bar.add_child(_reroll_btn)

	_end_turn_btn = _make_colored_button(
		"",
		COMBAT_END_TURN_BUTTON_SIZE,
		GREEN,
		GREEN.lightened(0.15),
		COMBAT_END_TURN_BUTTON_FONT_SIZE
	)
	_end_turn_btn.pressed.connect(_on_score_pressed)
	action_bar.add_child(_end_turn_btn)

	_build_combo_reveal_fx()
	_build_result_overlay()
	_build_pause_overlay()
	_build_tutorial_overlay()
	call_deferred("_refresh_responsive_layout")
	modulate.a = 0.0
	_animating = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	tween.tween_callback(func(): _animating = false; queue_redraw())


func _build_top_bar(parent: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", COMBAT_TOP_BAR_SEPARATION)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(bar)

	var left_cluster := HBoxContainer.new()
	left_cluster.name = "TopBarLeft"
	left_cluster.add_theme_constant_override("separation", COMBAT_TOP_BAR_SEPARATION)
	left_cluster.alignment = BoxContainer.ALIGNMENT_BEGIN
	left_cluster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_cluster.custom_minimum_size = Vector2(COMBAT_TOP_BAR_CLUSTER_MIN_WIDTH, 0)
	bar.add_child(left_cluster)

	_menu_btn = _make_menu_button()
	_menu_btn.pressed.disconnect(_go_to_main_menu)
	_menu_btn.pressed.connect(_on_pause_pressed)
	left_cluster.add_child(_menu_btn)

	_build_turn_pill(left_cluster)

	_title_bar_vbox = _make_title_bar("COMBAT")
	_title_bar_vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.add_child(_title_bar_vbox)

	_top_bar_right_cluster = HBoxContainer.new()
	_top_bar_right_cluster.name = "TopBarRight"
	_top_bar_right_cluster.add_theme_constant_override("separation", COMBAT_TOP_BAR_SEPARATION)
	_top_bar_right_cluster.alignment = BoxContainer.ALIGNMENT_END
	_top_bar_right_cluster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_bar_right_cluster.custom_minimum_size = Vector2(COMBAT_TOP_BAR_CLUSTER_MIN_WIDTH, 0)
	bar.add_child(_top_bar_right_cluster)

	_build_score_bar(_top_bar_right_cluster)


func _build_turn_pill(parent: HBoxContainer) -> void:
	_turn_pill = PanelContainer.new()
	_turn_pill.name = "TurnPill"
	_turn_pill.custom_minimum_size = Vector2(0, MENU_BUTTON_SIZE.y)
	_turn_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_turn_pill.add_theme_stylebox_override(
		"panel",
		_make_style(DARK, BORDER_BLACK, COMBAT_TURN_PILL_BORDER_WIDTH, COMBAT_TURN_PILL_MARGIN)
	)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", COMBAT_TURN_PILL_SEPARATION)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_turn_pill.add_child(row)

	var label := _make_pixel_label("TURN", COMBAT_TURN_PILL_LABEL_FONT_SIZE, GOLD)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)

	_hand_info_label = _make_pixel_label("", COMBAT_TURN_PILL_VALUE_FONT_SIZE, Color.WHITE)
	_hand_info_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_hand_info_label)

	parent.add_child(_turn_pill)


func _build_score_bar(parent: HBoxContainer) -> void:
	_score_bar_container = HBoxContainer.new()
	_score_bar_container.add_theme_constant_override("separation", COMBAT_SCORE_BAR_SEPARATION)
	_score_bar_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(_score_bar_container)

	var score_label := _make_pixel_label("SCORE", COMBAT_HAND_INFO_FONT_SIZE, DARK)
	score_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_score_bar_container.add_child(score_label)

	var track_wrapper := Control.new()
	track_wrapper.custom_minimum_size = COMBAT_SCORE_BAR_TRACK_SIZE
	track_wrapper.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	track_wrapper.clip_contents = true
	_score_bar_container.add_child(track_wrapper)

	_score_bar_track = ColorRect.new()
	_score_bar_track.color = DARK
	_score_bar_track.set_anchors_preset(Control.PRESET_FULL_RECT)
	track_wrapper.add_child(_score_bar_track)

	_score_bar_fill = ColorRect.new()
	_score_bar_fill.color = GREEN
	_score_bar_fill.position = COMBAT_SCORE_BAR_FILL_OFFSET
	_score_bar_fill.size = Vector2(0, COMBAT_SCORE_BAR_FILL_HEIGHT)
	track_wrapper.add_child(_score_bar_fill)

	_score_bar_label = _make_pixel_label("0/" + str(GameManager.target_score), COMBAT_SCORE_LABEL_FONT_SIZE, DARK)
	_score_bar_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_score_bar_container.add_child(_score_bar_label)


func _build_combat_workspace(parent: VBoxContainer) -> void:
	var center_stack := VBoxContainer.new()
	center_stack.name = "CombatWorkspace"
	center_stack.add_theme_constant_override("separation", COMBAT_WORKSPACE_SEPARATION)
	center_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(center_stack)

	_build_dice_tray(center_stack)
	_build_description_panel(center_stack)


func _build_probability_panel(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	center.name = "ProbabilityPanelDock"
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(center)

	_probability_panel_ui = CombatProbabilityPanelScript.new()
	center.add_child(_probability_panel_ui)
	_probability_panel_ui.setup(_pixel_font, DataManager.get_combo_rules())
	_probability_panel_ui.combo_row_hover_entered.connect(_on_combo_row_hover_enter)
	_probability_panel_ui.combo_row_hover_exited.connect(_on_combo_row_hover_exit)
	_probability_dock = center
	_probability_panel = _probability_panel_ui.get_panel_node()

	_score_panel = _probability_panel
	_combo_name_label = _probability_panel_ui.get_combo_name_label()
	_score_value_label = _probability_panel_ui.get_score_value_label()
	_score_pts_suffix = _probability_panel_ui.get_score_pts_suffix_label()
	_score_breakdown_label = _probability_panel_ui.get_score_breakdown_label()


func _refresh_responsive_layout() -> void:
	# The probability rail is laid out inline by the content VBox now, so no
	# manual responsive positioning is required.
	pass


func _build_dice_tray(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	parent.add_child(center)

	_dice_container = HBoxContainer.new()
	_dice_container.add_theme_constant_override("separation", COMBAT_DICE_TRAY_SEPARATION)
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


func _build_combo_reveal_fx() -> void:
	_combo_reveal_fx = ComboRevealFxScript.new()
	_combo_reveal_fx.name = "ComboRevealFx"
	_combo_reveal_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combo_reveal_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_combo_reveal_fx)


func _set_die_face(index: int, value: int) -> void:
	if index < 0 or index >= _dice_cards.size():
		return
	_dice_cards[index].set_face(value)


func _apply_revealed_die_value(index: int, results: Array[int]) -> void:
	if index < 0 or index >= results.size() or index >= _current_values.size():
		return
	_current_values[index] = results[index]
	_set_die_face(index, results[index])


func _play_die_landing_bounce(index: int, final_die: bool = false) -> void:
	if index < 0 or index >= _dice_cards.size():
		return
	var btn: Button = _dice_cards[index].main_button
	var pop_scale := COMBAT_LAST_REROLL_FINAL_POP_SCALE if final_die else COMBAT_LAST_REROLL_NORMAL_POP_SCALE
	var tween := create_tween()
	tween.parallel().tween_property(btn, "rotation", 0.0, 0.08)
	tween.parallel().tween_property(btn, "scale", pop_scale, 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(btn, "scale", Vector2(1.04, 0.96), 0.06)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.10) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _build_description_panel(parent: VBoxContainer) -> void:
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(0, COMBAT_DESC_PANEL_SIZE.y)
	parent.add_child(center)

	_desc_panel = _make_panel(DARK, GOLD, COMBAT_DESC_PANEL_SIZE, COMBAT_DESC_PANEL_MARGIN)
	_desc_panel.visible = false
	_desc_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_desc_panel)

	var desc_vbox := VBoxContainer.new()
	desc_vbox.add_theme_constant_override("separation", COMBAT_DESC_SEPARATION)
	desc_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_panel.add_child(desc_vbox)

	var title_row := HBoxContainer.new()
	title_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_vbox.add_child(title_row)

	_desc_title = _make_pixel_rtl(COMBAT_DESC_TITLE_FONT_SIZE, GOLD)
	_desc_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(_desc_title)

	_desc_rarity = _make_pixel_rtl(COMBAT_DESC_TITLE_FONT_SIZE, Color.WHITE)
	_desc_rarity.autowrap_mode = TextServer.AUTOWRAP_OFF
	_desc_rarity.size_flags_horizontal = Control.SIZE_SHRINK_END
	_desc_rarity.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	title_row.add_child(_desc_rarity)

	_desc_body = _make_pixel_rtl(COMBAT_DESC_BODY_FONT_SIZE, Color.WHITE)
	_configure_wrapped_description_body(_desc_body)
	desc_vbox.add_child(_desc_body)

	_desc_combo_row = HBoxContainer.new()
	_desc_combo_row.add_theme_constant_override("separation", COMBAT_DESC_COMBO_ROW_SEPARATION)
	_desc_combo_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_desc_combo_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_combo_row.visible = false
	desc_vbox.add_child(_desc_combo_row)

	var squares_row := HBoxContainer.new()
	squares_row.add_theme_constant_override("separation", COMBAT_DESC_COMBO_SQUARE_GAP)
	squares_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	squares_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	squares_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_combo_row.add_child(squares_row)

	_desc_combo_squares.clear()
	for _i in range(5):
		var square := PanelContainer.new()
		square.custom_minimum_size = Vector2(COMBAT_DESC_COMBO_SQUARE_SIZE, COMBAT_DESC_COMBO_SQUARE_SIZE)
		square.mouse_filter = Control.MOUSE_FILTER_IGNORE
		square.add_theme_stylebox_override("panel", _make_combo_square_style(Color.WHITE))
		squares_row.add_child(square)
		_desc_combo_squares.append(square)

	_desc_combo_mult_label = _make_pixel_label("", COMBAT_DESC_COMBO_MULT_FONT_SIZE, GOLD)
	_desc_combo_mult_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_desc_combo_mult_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_desc_combo_row.add_child(_desc_combo_mult_label)


func _make_combo_square_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = Color("1a1a1a")
	sb.set_border_width_all(COMBAT_DESC_COMBO_SQUARE_BORDER)
	sb.set_corner_radius_all(0)
	return sb


func _build_result_overlay() -> void:
	_result_overlay = ColorRect.new()
	_result_overlay.color = Color(0, 0, 0, 0.85)
	_result_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.visible = false
	add_child(_result_overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_overlay.add_child(center)

	_result_panel = _make_panel(
		Color(0.12, 0.12, 0.12, 0.98),
		GOLD,
		COMBAT_RESULT_PANEL_SIZE,
		COMBAT_RESULT_PANEL_MARGIN
	)
	_result_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	center.add_child(_result_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", COMBAT_RESULT_SEPARATION)
	_result_panel.add_child(vbox)

	_result_message = _make_pixel_label("", COMBAT_RESULT_MESSAGE_FONT_SIZE)
	_result_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_message.custom_minimum_size = COMBAT_RESULT_MESSAGE_WIDTH
	_result_message.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(_result_message)

	_result_score_label = _make_pixel_label("", COMBAT_RESULT_SCORE_FONT_SIZE, GOLD)
	_result_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_score_label.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(_result_score_label)

	_result_sub_label = _make_pixel_label("", COMBAT_RESULT_SUB_FONT_SIZE, Color("aaaaaa"))
	_result_sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_sub_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_sub_label.custom_minimum_size = COMBAT_RESULT_MESSAGE_WIDTH
	_result_sub_label.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(_result_sub_label)

	_result_coins_label = _make_pixel_rtl(COMBAT_RESULT_COINS_FONT_SIZE, GOLD)
	_result_coins_label.size_flags_horizontal = Control.SIZE_FILL
	vbox.add_child(_result_coins_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, COMBAT_RESULT_BUTTON_SPACER_HEIGHT)
	vbox.add_child(spacer)

	_result_next_btn = _make_pixel_button(
		"NEXT ROUND",
		COMBAT_RESULT_BUTTON_SIZE,
		COMBAT_RESULT_NEXT_BUTTON_FONT_SIZE
	)
	_result_next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_result_next_btn.pressed.connect(_on_next_round_pressed)
	_result_next_btn.visible = false
	vbox.add_child(_result_next_btn)

	_result_retry_btn = _make_colored_button(
		"RETRY TUTORIAL",
		COMBAT_RESULT_BUTTON_SIZE,
		PINK,
		PINK.lightened(0.15),
		COMBAT_RESULT_RETRY_BUTTON_FONT_SIZE
	)
	_result_retry_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_result_retry_btn.pressed.connect(_on_retry_tutorial_pressed)
	_result_retry_btn.visible = false
	vbox.add_child(_result_retry_btn)

	_result_survey_btn = _make_pixel_button(
		"TAKE SURVEY",
		COMBAT_RESULT_BUTTON_SIZE,
		COMBAT_RESULT_SURVEY_BUTTON_FONT_SIZE
	)
	_result_survey_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_result_survey_btn.pressed.connect(_on_playtest_survey_pressed)
	_result_survey_btn.disabled = not GameManager.has_playtest_survey_url()
	_result_survey_btn.visible = false
	vbox.add_child(_result_survey_btn)

	_result_menu_btn = _make_pixel_button(
		"BACK TO MENU",
		COMBAT_RESULT_BUTTON_SIZE,
		COMBAT_RESULT_MENU_BUTTON_FONT_SIZE
	)
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
	vbox.add_theme_constant_override("separation", COMBAT_PAUSE_SEPARATION)
	center.add_child(vbox)

	var title := _make_pixel_label("PAUSED", COMBAT_PAUSE_TITLE_FONT_SIZE, GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, COMBAT_PAUSE_BUTTON_SPACER_HEIGHT)
	vbox.add_child(spacer)

	var resume_btn := _make_colored_button(
		"RESUME",
		COMBAT_PAUSE_BUTTON_SIZE,
		GREEN,
		GREEN.lightened(0.15),
		COMBAT_PAUSE_RESUME_BUTTON_FONT_SIZE
	)
	resume_btn.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_btn)

	var quit_btn := _make_pixel_button(
		"QUIT TO MENU",
		COMBAT_PAUSE_BUTTON_SIZE,
		COMBAT_PAUSE_QUIT_BUTTON_FONT_SIZE
	)
	quit_btn.pressed.connect(_on_pause_quit_pressed)
	vbox.add_child(quit_btn)


func _on_pause_pressed() -> void:
	if _result_overlay.visible:
		return
	if TutorialManager.is_active():
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
		_end_turn_btn.disabled = not _can_score_current_hand()


func _can_score_current_hand() -> bool:
	return combat_mgr != null and combat_mgr.can_score() and not _suspense_reveal_active


func _refresh_probability_panel() -> void:
	if _probability_panel_ui == null or combat_mgr == null:
		return

	var snapshot := combat_mgr.get_probability_snapshot()
	var held_count := _count_held_dice()
	_probability_panel_ui.refresh_snapshot(snapshot, held_count)

	var current_type := ""
	if combat_mgr.has_rolled:
		current_type = combat_mgr.get_current_combo().get("type", "")
	_probability_panel_ui.highlight_current_combo(current_type)


func _count_held_dice() -> int:
	if combat_mgr == null:
		return 0
	var held_count := 0
	for i in range(_dice_cards.size()):
		if combat_mgr.is_held(i):
			held_count += 1
	return held_count


func _should_use_last_reroll_suspense() -> bool:
	return combat_mgr != null \
		and combat_mgr.rerolls_remaining == 1 \
		and not _get_unheld_dice_indices().is_empty()


func _get_unheld_dice_indices() -> Array[int]:
	var indices: Array[int] = []
	if combat_mgr == null:
		return indices
	for i in range(_dice_cards.size()):
		if not combat_mgr.is_held(i):
			indices.append(i)
	return indices


func _build_last_reroll_stop_delays(indices: Array) -> Array[float]:
	var delays: Array[float] = []
	for stop_index in range(indices.size()):
		var delay := float(stop_index) * COMBAT_LAST_REROLL_STOP_BASE_DELAY
		delay += float(maxi(stop_index - 1, 0)) * COMBAT_LAST_REROLL_STOP_EXTRA_DELAY
		delays.append(minf(delay, COMBAT_LAST_REROLL_MAX_LAST_STOP_DELAY))
	return delays


func _build_last_reroll_reveal_order(indices: Array[int]) -> Array[int]:
	var reveal_order := indices.duplicate()
	reveal_order.shuffle()
	return reveal_order


func _begin_suspense_result_buffer() -> void:
	_suspense_reveal_active = true
	_suspense_final_results.clear()


func _finish_suspense_result_buffer() -> void:
	_suspense_reveal_active = false


func _update_hand_display() -> void:
	if _hand_info_label:
		var current_hand := _total_hands - combat_mgr.hands_remaining + 1
		_hand_info_label.text = "%d/%d" % [current_hand, _total_hands]


func _update_score_bar() -> void:
	if not _score_bar_fill or not _score_bar_label or not _score_bar_track:
		return
	var running := combat_mgr.running_score
	var target := combat_mgr.target_score
	_score_bar_label.text = "%d/%d" % [running, target]

	var track_w := _score_bar_track.size.x - COMBAT_SCORE_BAR_TRACK_INSET
	var ratio := clampf(float(running) / float(target), 0.0, 1.0)
	_score_bar_fill.size = Vector2(track_w * ratio, COMBAT_SCORE_BAR_FILL_HEIGHT)


func _control_global_center(control: Control) -> Vector2:
	return control.global_position + (control.size * 0.5)


func _score_bar_target_center() -> Vector2:
	if _score_bar_track != null and is_instance_valid(_score_bar_track):
		return _control_global_center(_score_bar_track)
	if _score_bar_container != null and is_instance_valid(_score_bar_container):
		return _control_global_center(_score_bar_container)
	return _control_global_center(self)


func _show_combo(combo: Dictionary) -> void:
	var combo_name: String = combo.get("name", "")
	_combo_name_label.text = combo_name.to_upper()

	var combo_type: String = combo.get("type", "")
	_combo_name_label.add_theme_color_override("font_color", _get_combo_display_color(combo_type))

	var preview := _calculate_combo_preview(combo)

	var face_sum: int = int(preview.get("face_sum", 0))
	var mult: float = preview.get("mult", 1.0)
	var x_mult: float = preview.get("x_mult", 1.0)
	var pts: int = preview.get("total", 0)

	_score_value_label.add_theme_font_size_override("font_size", COMBAT_SCORE_VALUE_PREVIEW_FONT_SIZE)
	_score_value_label.text = str(pts)
	_score_pts_suffix.text = "PTS"
	_score_pts_suffix.visible = true

	var sum_bb := "[color=%s]%dsum[/color]" % [SemanticColors.ADDITIVE_HEX, face_sum]
	var mult_bb := "[color=%s]%smult[/color]" % [SemanticColors.MULTIPLICATIVE_HEX, ScoreFormat.multiplier(mult)]
	if x_mult > 1.0:
		_score_breakdown_label.add_theme_font_size_override("normal_font_size", COMBAT_SCORE_BREAKDOWN_X_MULT_FONT_SIZE)
		var x_mult_bb := "[color=%s]%s[/color]" % [SemanticColors.MULTIPLICATIVE_HEX, ScoreFormat.multiplier(x_mult)]
		_score_breakdown_label.text = "[right]%s x %s\nx %s[/right]" % [sum_bb, mult_bb, x_mult_bb]
	else:
		_score_breakdown_label.add_theme_font_size_override("normal_font_size", COMBAT_SCORE_BREAKDOWN_FONT_SIZE)
		_score_breakdown_label.text = "[right]%s x %s[/right]" % [sum_bb, mult_bb]


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
	return ScoreFormat.multiplier(value)


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
	_refresh_probability_panel()
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
	_pending_combo_reveal.clear()
	AudioManager.play_sfx(&"dice_roll")

	var tween := create_tween()

	# Phase 1 — LIFT: scale down + slight rotation
	for i in range(_dice_cards.size()):
		if not combat_mgr.is_held(i):
			var btn: Button = _dice_cards[i].main_button
			tween.parallel().tween_property(btn, "rotation", randf_range(-0.2, 0.2), 0.05)
			tween.parallel().tween_property(btn, "scale", Vector2(0.85, 0.85), 0.05)

	# Phase 2 — TUMBLE: rapid face cycling with position jitter
	tween.tween_callback(func(): if _probability_panel_ui: _probability_panel_ui.start_scramble())
	for f in range(8):
		tween.tween_callback(_show_random_faces)
		tween.tween_callback(_jitter_unheld_dice)
		tween.tween_interval(0.05)

	if _should_use_last_reroll_suspense():
		_queue_last_reroll_suspense_settle(tween)
	else:
		_queue_normal_roll_settle(tween)


func _queue_normal_roll_settle(tween: Tween) -> void:
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

	tween.tween_callback(_play_pending_combo_reveal)
	tween.tween_callback(_update_rerolls_display)
	tween.tween_callback(func(): _animating = false)


func _queue_last_reroll_suspense_settle(tween: Tween) -> void:
	var reveal_indices := _build_last_reroll_reveal_order(_get_unheld_dice_indices())
	var delays := _build_last_reroll_stop_delays(reveal_indices)

	tween.tween_callback(_begin_suspense_result_buffer)
	tween.tween_callback(_do_actual_roll)

	for stop_index in range(reveal_indices.size()):
		var die_index := reveal_indices[stop_index]
		var delay := delays[stop_index]
		if delay > 0.0:
			_queue_suspense_scramble_interval(
				tween,
				delay - delays[stop_index - 1],
				reveal_indices.slice(stop_index)
			)
		var is_final_die := stop_index == reveal_indices.size() - 1
		tween.tween_callback(func(index := die_index, final_die := is_final_die):
			_apply_revealed_die_value(index, _suspense_final_results)
			_play_die_landing_bounce(index, final_die)
		)

	tween.tween_interval(COMBAT_LAST_REROLL_POST_REVEAL_DELAY)
	tween.tween_callback(_finish_suspense_result_buffer)
	tween.tween_callback(func():
		var final_results := _suspense_final_results.duplicate()
		_suspense_final_results.clear()
		_on_dice_rolled(final_results)
	)
	tween.tween_callback(_play_pending_combo_reveal)
	tween.tween_callback(_update_rerolls_display)
	tween.tween_callback(func(): _animating = false)


func _queue_suspense_scramble_interval(tween: Tween, duration: float, indices: Array) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		var step_indices := indices.duplicate()
		tween.tween_callback(func(scramble_indices := step_indices):
			_show_random_faces_for_indices(scramble_indices)
			_jitter_dice_indices(scramble_indices)
		)
		var step := minf(COMBAT_LAST_REROLL_SCRAMBLE_STEP, duration - elapsed)
		tween.tween_interval(step)
		elapsed += step


func _jitter_unheld_dice() -> void:
	_jitter_dice_indices(_get_unheld_dice_indices())


func _jitter_dice_indices(indices: Array) -> void:
	for index in indices:
		var i := int(index)
		if i < 0 or i >= _dice_cards.size():
			continue
		var btn: Button = _dice_cards[i].main_button
		btn.rotation = randf_range(-0.12, 0.12)
		var s := randf_range(0.84, 0.92)
		btn.scale = Vector2(s, s)


func _show_random_faces() -> void:
	_show_random_faces_for_indices(_get_unheld_dice_indices())


func _show_random_faces_for_indices(indices: Array) -> void:
	for index in indices:
		var i := int(index)
		if i < 0 or i >= _current_values.size():
			continue
		_current_values[i] = randi_range(1, 6)
		_set_die_face(i, _current_values[i])


func _do_actual_roll() -> void:
	combat_mgr.roll_dice()


func _on_dice_rolled(results: Array[int]) -> void:
	if _suspense_reveal_active:
		_suspense_final_results = results.duplicate()
		return
	_suspense_final_results.clear()

	if _probability_panel_ui:
		_probability_panel_ui.stop_scramble()
	for i in range(results.size()):
		if i < _current_values.size():
			_current_values[i] = results[i]
			_set_die_face(i, results[i])

	var combo := combat_mgr.get_current_combo()
	if not combo.is_empty():
		_pending_combo_reveal = combo.duplicate(true)
		_show_combo(combo)
	else:
		_pending_combo_reveal.clear()
		_combo_name_label.text = ""
		_score_value_label.add_theme_font_size_override("font_size", COMBAT_SCORE_VALUE_IDLE_FONT_SIZE)
		_score_value_label.text = "NO COMBO"
		_score_pts_suffix.text = ""
		_score_pts_suffix.visible = false
		_score_breakdown_label.add_theme_font_size_override("normal_font_size", COMBAT_SCORE_BREAKDOWN_FONT_SIZE)
		_score_breakdown_label.text = ""

	_update_rerolls_display()
	_refresh_probability_panel()
	_refresh_tutorial_dice_accents()
	if TutorialManager.is_active():
		TutorialManager.report_action("combat_roll", {"roll_number": _tutorial_rolls_seen})
		_tutorial_rolls_seen += 1
		_refresh_tutorial_ui()


func _play_pending_combo_reveal() -> void:
	if _pending_combo_reveal.is_empty() or _combo_reveal_fx == null:
		return

	var combo := _pending_combo_reveal.duplicate(true)
	_pending_combo_reveal.clear()
	var priority := int(combo.get("priority", 0))
	var color := _get_combo_display_color(combo.get("type", ""))
	var in_combo: Array = combo.get("in_combo", [])

	AudioManager.play_sfx(&"combo_detect")
	_combo_reveal_fx.play(combo, _dice_cards, color)
	_pulse_combo_hud(color, priority)

	var hit_index := 0
	for i in range(_dice_cards.size()):
		if i >= in_combo.size() or not bool(in_combo[i]):
			continue
		var card = _dice_cards[i]
		if card is CombatDice:
			(card as CombatDice).play_combo_reveal_hit(color, priority, float(hit_index) * 0.035)
			hit_index += 1

	if priority >= 6:
		var audio_tween := create_tween()
		audio_tween.tween_interval(0.12)
		audio_tween.tween_callback(func(): AudioManager.play_sfx(&"score_tick", -5.0))


func _pulse_combo_hud(color: Color, priority: int) -> void:
	if _combo_hud_tween != null and _combo_hud_tween.is_valid():
		_combo_hud_tween.kill()

	if _combo_name_label != null:
		_combo_name_label.scale = Vector2.ONE
		_combo_name_label.modulate = Color.WHITE
		_combo_name_label.pivot_offset = Vector2(0.0, _combo_name_label.size.y * 0.5)
	if _score_value_label != null:
		_score_value_label.scale = Vector2.ONE
		_score_value_label.modulate = Color.WHITE
		_score_value_label.pivot_offset = _score_value_label.size * 0.5
	if _score_panel != null:
		_score_panel.modulate = Color.WHITE

	var clamped_priority := clampi(priority, 0, 8)
	var combo_scale := 1.04 + float(clamped_priority) * 0.025
	var score_scale := 1.03 + float(clamped_priority) * 0.018
	var pulse_color := color.lightened(0.25)

	_combo_hud_tween = create_tween()
	_combo_hud_tween.set_parallel(true)
	if _combo_name_label != null:
		_combo_hud_tween.tween_property(_combo_name_label, "scale", Vector2(combo_scale, combo_scale), 0.09) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		_combo_hud_tween.tween_property(_combo_name_label, "modulate", pulse_color, 0.09)
	if _score_value_label != null:
		_combo_hud_tween.tween_property(_score_value_label, "scale", Vector2(score_scale, score_scale), 0.09) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if priority >= 6 and _score_panel != null:
		_combo_hud_tween.tween_property(_score_panel, "modulate", color.lightened(0.38), 0.09)

	_combo_hud_tween.chain()
	if _combo_name_label != null:
		_combo_hud_tween.tween_property(_combo_name_label, "scale", Vector2.ONE, 0.18) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		_combo_hud_tween.parallel().tween_property(_combo_name_label, "modulate", Color.WHITE, 0.18)
	if _score_value_label != null:
		_combo_hud_tween.parallel().tween_property(_score_value_label, "scale", Vector2.ONE, 0.18) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	if _score_panel != null:
		_combo_hud_tween.parallel().tween_property(_score_panel, "modulate", Color.WHITE, 0.18)


func _make_score_flight_label(total: int) -> Label:
	if _score_flight_label != null and is_instance_valid(_score_flight_label):
		_score_flight_label.queue_free()

	var label := _make_pixel_label("+%d" % total, COMBAT_SCORE_FLIGHT_FONT_SIZE, GREEN)
	label.name = "ScoreFlightLabel"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 80
	label.modulate = Color.WHITE
	add_child(label)
	label.reset_size()
	label.size = label.get_minimum_size()
	label.pivot_offset = label.size * 0.5
	_score_flight_label = label
	return label


func _animate_score_flight(tween: Tween, total: int) -> void:
	var label := _make_score_flight_label(total)
	var start := _control_global_center(_score_value_label) - global_position
	var end := _score_bar_target_center() - global_position
	var lift := Vector2(0, -COMBAT_SCORE_FLIGHT_ARC_HEIGHT)
	label.position = start - label.pivot_offset
	label.scale = Vector2(1.1, 1.1)

	tween.tween_property(
		label,
		"position",
		((start + end) * 0.5) + lift - label.pivot_offset,
		COMBAT_SCORE_FLIGHT_DURATION * 0.45
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(
		label,
		"scale",
		Vector2(1.2, 1.2),
		COMBAT_SCORE_FLIGHT_DURATION * 0.45
	)
	tween.tween_property(
		label,
		"position",
		end - label.pivot_offset,
		COMBAT_SCORE_FLIGHT_DURATION * 0.55
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(
		label,
		"scale",
		Vector2(0.82, 0.82),
		COMBAT_SCORE_FLIGHT_DURATION * 0.55
	)
	tween.parallel().tween_property(
		label,
		"modulate:a",
		0.15,
		COMBAT_SCORE_FLIGHT_DURATION * 0.55
	)
	tween.tween_callback(func():
		_update_score_bar()
		_pop_score_bar()
		if label != null and is_instance_valid(label):
			label.queue_free()
		if _score_flight_label == label:
			_score_flight_label = null
	)


func _pop_score_bar() -> void:
	if _score_bar_container == null or not is_instance_valid(_score_bar_container):
		return
	_score_bar_container.pivot_offset = _score_bar_container.size * 0.5
	var pop := create_tween()
	pop.tween_property(_score_bar_container, "scale", COMBAT_SCORE_BAR_POP_SCALE, 0.08) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	pop.tween_property(_score_bar_container, "scale", Vector2.ONE, 0.14) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _on_score_pressed() -> void:
	if not _can_score_current_hand():
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
		_score_breakdown_label.add_theme_font_size_override("normal_font_size", COMBAT_SCORE_BREAKDOWN_FONT_SIZE)
		_score_breakdown_label.text = ""
		_update_hand_display()
	)
	tween.tween_interval(0.12)
	_animate_score_flight(tween, total)

	tween.tween_interval(0.45)

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

	_pending_combo_reveal.clear()
	_combo_name_label.text = ""
	_score_value_label.add_theme_font_size_override("font_size", COMBAT_SCORE_VALUE_IDLE_FONT_SIZE)
	_score_value_label.text = "ROLL!"
	_score_pts_suffix.text = ""
	_score_pts_suffix.visible = false
	_score_breakdown_label.add_theme_font_size_override("normal_font_size", COMBAT_SCORE_BREAKDOWN_FONT_SIZE)
	_score_breakdown_label.text = ""

	for i in range(_current_values.size()):
		_current_values[i] = 0
	for i in range(_dice_cards.size()):
		_dice_cards[i].reset_die()

	_update_rerolls_display()
	_refresh_probability_panel()
	_refresh_tutorial_dice_accents()


func _on_rerolls_changed(_remaining: int) -> void:
	_update_rerolls_display()


func _on_card_hover_enter(card: Control) -> void:
	_desc_title.add_theme_color_override("default_color", GOLD)
	_desc_title.text = card.hover_name
	_desc_rarity.text = SemanticMarkup.format_rarity(card.hover_rarity)
	_set_description_body_text(_desc_body, SemanticMarkup.format_description(card.hover_description))
	_desc_body.visible = true
	_desc_combo_row.visible = false
	_desc_panel.visible = true


func _on_card_hover_exit() -> void:
	_desc_panel.visible = false


func _on_combo_row_hover_enter(combo_type: String) -> void:
	if _probability_panel_ui == null:
		return
	var info: Dictionary = _probability_panel_ui.get_combo_row_info(combo_type)
	if info.is_empty():
		return
	_desc_title.add_theme_color_override("default_color", GOLD)
	_desc_title.text = str(info.get("name", ""))
	_desc_rarity.text = ""
	_desc_body.visible = false
	var pattern_colors: Array = info.get("pattern_colors", [])
	for i in range(_desc_combo_squares.size()):
		var color: Color = pattern_colors[i] if i < pattern_colors.size() else Color.TRANSPARENT
		_desc_combo_squares[i].add_theme_stylebox_override("panel", _make_combo_square_style(color))
	_desc_combo_mult_label.text = ScoreFormat.prefixed_multiplier(
		_combo_hover_multiplier(combo_type, float(info.get("mult", 1.0)))
	)
	_desc_combo_row.visible = true
	_desc_panel.visible = true


func _combo_hover_multiplier(combo_type: String, base_mult: float) -> float:
	var scorer: ScoringEngine = combat_mgr.scoring_engine if combat_mgr != null else ScoringEngine.new()
	var score_data := scorer.calculate_score(
		{"type": combo_type, "combo_mult": base_mult},
		[],
		[],
		GameManager.modifiers
	)
	return float(score_data.get("mult", base_mult)) * float(score_data.get("x_mult", 1.0))


func _on_combo_row_hover_exit() -> void:
	_desc_panel.visible = false
	_desc_combo_row.visible = false


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
	_result_survey_btn.disabled = not GameManager.has_playtest_survey_url()

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
		_result_coins_label.text = "[center]+%d%s[/center]" % [reward, SemanticMarkup.coin_icon(COMBAT_RESULT_COINS_FONT_SIZE + 4)]
		_result_coins_label.visible = true
		_result_next_btn.visible = true
		_result_retry_btn.visible = false
		_result_survey_btn.visible = false
		_result_menu_btn.visible = false
	else:
		if TutorialManager.is_active():
			_result_message.text = "NOT QUITE!"
			_result_message.add_theme_color_override("font_color", DIE_COLORS["red"])
			_result_sub_label.text = "No worries -- give it another shot! The tutorial is here to help you practice."
			_result_coins_label.visible = false
			_result_next_btn.visible = false
			_result_retry_btn.visible = true
			_result_survey_btn.visible = false
			_result_menu_btn.visible = true
		else:
			_result_message.text = "GAME OVER"
			_result_message.add_theme_color_override("font_color", DIE_COLORS["red"])
			_result_sub_label.text = "Reached Round %d" % GameManager.current_round
			_result_coins_label.visible = false
			_result_next_btn.visible = false
			_result_retry_btn.visible = false
			_result_survey_btn.visible = true
			_result_menu_btn.visible = true

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(_result_overlay, "modulate:a", 1.0, 0.5)


func _get_pattern_colors(combo_type: String) -> Array:
	var a := BLUE
	var b := PINK
	var g := Color("888888")
	var s := [BLUE.darkened(0.3), BLUE.darkened(0.15), BLUE, BLUE.lightened(0.15), BLUE.lightened(0.3)]

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


# -- Navigation ----------------------------------------------------------------

func _on_next_round_pressed() -> void:
	if TutorialManager.is_active():
		TutorialManager.report_action("combat_next_round")
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): GameManager.end_combat(_result_final_score, true))


func _on_playtest_survey_pressed() -> void:
	GameManager.open_playtest_survey()


func _go_to_main_menu() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): GameManager.end_combat(_result_final_score, false))


func _build_tutorial_overlay() -> void:
	_tutorial_overlay = TutorialOverlay.new()
	add_child(_tutorial_overlay)
	_tutorial_overlay.setup(_pixel_font)
	_tutorial_overlay.next_pressed.connect(_on_tutorial_next_pressed)
	_tutorial_overlay.skip_pressed.connect(_on_tutorial_skip_pressed)


func _refresh_tutorial_ui() -> void:
	if _tutorial_overlay == null:
		return
	if not TutorialManager.is_active() or TutorialManager.checkpoint_scene != TutorialManager.SCENE_COMBAT:
		_tutorial_overlay.hide_overlay()
		return
	if _result_overlay.visible and not _result_target_beaten:
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


func _get_tutorial_highlight_target() -> Variant:
	match TutorialManager.step_id:
		TutorialManager.STEP_INTRO_ROLL, TutorialManager.STEP_COMBAT_GOOD_LUCK: return _reroll_btn
		TutorialManager.STEP_INTRO_HOLD: return _find_required_hold_targets()
		TutorialManager.STEP_INTRO_REROLL: return _reroll_btn
		TutorialManager.STEP_INTRO_FINISH: return [_turn_pill, _end_turn_btn]
		TutorialManager.STEP_INTRO_WIN: return _result_next_btn
		TutorialManager.STEP_INTRO_WELCOME:
			var targets: Array[Control] = [_title_bar_vbox, _score_bar_container]
			return targets
		TutorialManager.STEP_INTRO_PAIR:
			if _probability_panel_ui != null:
				return _probability_panel_ui
			return null
		_: return null


func _get_tutorial_avoid_target() -> Variant:
	return null


func _refresh_tutorial_dice_accents() -> void:
	var show_tutorial_accents := false
	if TutorialManager.is_active():
		show_tutorial_accents = TutorialManager.step_id not in [
			TutorialManager.STEP_INTRO_WELCOME,
			TutorialManager.STEP_INTRO_ROLL,
			TutorialManager.STEP_INTRO_PAIR,
			TutorialManager.STEP_INTRO_FINISH,
			TutorialManager.STEP_INTRO_WIN,
			TutorialManager.STEP_COMBAT_GOOD_LUCK,
		]

	var in_combo: Array[bool] = []
	var combo_colors_by_index: Array = []
	if combat_mgr != null and combat_mgr.has_rolled:
		var combo := combat_mgr.get_current_combo()
		in_combo = combo.get("in_combo", [])
		combo_colors_by_index = _get_combo_accent_colors_by_index(combo, combat_mgr.current_roll_values())

	for i in range(_dice_cards.size()):
		var card = _dice_cards[i]
		if card is CombatDice:
			var combo_accent := false
			var combo_accent_color := GOLD
			if i < in_combo.size() and in_combo[i]:
				combo_accent = true
				if i < combo_colors_by_index.size():
					combo_accent_color = combo_colors_by_index[i]

			var tutorial_accent := show_tutorial_accents and TutorialManager.required_combat_hold_indices.has(i)
			if tutorial_accent:
				(card as CombatDice).set_accent(true, BLUE)
			elif combo_accent:
				(card as CombatDice).set_accent(true, combo_accent_color)
			else:
				(card as CombatDice).set_accent(false)


func _get_combo_accent_colors_by_index(combo: Dictionary, values: Array[int]) -> Array:
	var in_combo: Array = combo.get("in_combo", [])
	var colors: Array = []
	colors.resize(values.size())
	for i in range(colors.size()):
		colors[i] = GOLD

	var combo_type := str(combo.get("type", ""))
	if combo_type == "two_pair":
		var pair_colors := _get_matching_value_colors(values, in_combo, [BLUE, PINK], 2)
		for i in range(colors.size()):
			if pair_colors.has(i):
				colors[i] = pair_colors[i]
		return colors

	var pattern_colors := _get_pattern_colors(combo_type)
	var combo_color_index := 0
	for i in range(mini(in_combo.size(), colors.size())):
		if not bool(in_combo[i]):
			continue
		if combo_color_index < pattern_colors.size():
			colors[i] = pattern_colors[combo_color_index]
		combo_color_index += 1
	return colors


func _get_matching_value_colors(values: Array[int], in_combo: Array, group_colors: Array,
		min_count: int) -> Dictionary:
	var counts := {}
	for i in range(mini(values.size(), in_combo.size())):
		if not bool(in_combo[i]):
			continue
		var value := values[i]
		counts[value] = counts.get(value, 0) + 1

	var color_by_value := {}
	var group_index := 0
	for value in counts:
		if int(counts[value]) >= min_count and group_index < group_colors.size():
			color_by_value[value] = group_colors[group_index]
			group_index += 1

	var colors_by_index := {}
	for i in range(mini(values.size(), in_combo.size())):
		if bool(in_combo[i]) and color_by_value.has(values[i]):
			colors_by_index[i] = color_by_value[values[i]]
	return colors_by_index


func _provide_tutorial_roll(roll_number: int, _held_dice: Array) -> Array[int]:
	return TutorialManager.get_scripted_roll_values(roll_number)


func get_combo_highlight_indices() -> Array[int]:
	var highlighted: Array[int] = []
	for i in range(_dice_cards.size()):
		var card = _dice_cards[i]
		if card is CombatDice and (card as CombatDice).is_accented():
			highlighted.append(i)
	return highlighted


func get_probability_status_text() -> String:
	return _probability_panel_ui.get_status_text() if _probability_panel_ui != null else ""


func is_probability_collapsed() -> bool:
	return _probability_panel_ui.is_collapsed() if _probability_panel_ui != null else true


func is_probability_panel_body_visible() -> bool:
	return _probability_panel_ui.is_body_visible() if _probability_panel_ui != null else false


func get_probability_toggle_right_x() -> float:
	return _probability_panel_ui.get_toggle_right_x() if _probability_panel_ui != null else 0.0


func get_probability_row_text(combo_type: String) -> String:
	return _probability_panel_ui.get_row_text(combo_type) if _probability_panel_ui != null else ""


func get_probability_row_name_text(combo_type: String) -> String:
	return _probability_panel_ui.get_row_name_text(combo_type) if _probability_panel_ui != null else ""


func get_probability_row_count() -> int:
	return _probability_panel_ui.get_row_count() if _probability_panel_ui != null else 0


func get_probability_display_snapshot() -> Dictionary:
	return _probability_panel_ui.get_display_snapshot() if _probability_panel_ui != null else {}


func toggle_probability_panel() -> void:
	if _probability_panel_ui != null:
		_probability_panel_ui.toggle_panel()


func get_dice_tray_global_x() -> float:
	if _dice_container == null:
		return 0.0
	return _dice_container.global_position.x


func get_dice_tray_center_x() -> float:
	if _dice_container == null:
		return 0.0
	return _dice_container.global_position.x + (_dice_container.size.x / 2.0)


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


func _make_pixel_rtl(font_size: int, color: Color) -> RichTextLabel:
	var rtl := RichTextLabel.new()
	rtl.bbcode_enabled = true
	rtl.fit_content = true
	rtl.scroll_active = false
	rtl.add_theme_font_override("normal_font", _pixel_font)
	rtl.add_theme_font_size_override("normal_font_size", font_size)
	rtl.add_theme_color_override("default_color", color)
	rtl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rtl


func _configure_wrapped_description_body(rtl: RichTextLabel) -> void:
	rtl.fit_content = false
	rtl.autowrap_mode = TextServer.AUTOWRAP_WORD
	rtl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rtl.custom_minimum_size.x = COMBAT_DESC_BODY_WIDTH
	rtl.size.x = COMBAT_DESC_BODY_WIDTH


func _set_description_body_text(rtl: RichTextLabel, value: String) -> void:
	rtl.text = value
	rtl.size.x = COMBAT_DESC_BODY_WIDTH
	rtl.custom_minimum_size.y = maxf(
		float(COMBAT_DESC_BODY_FONT_SIZE),
		rtl.get_content_height()
	)


func _get_combo_display_color(combo_type: String) -> Color:
	if _probability_panel_ui == null or String(combo_type).is_empty():
		return Color.WHITE
	return _probability_panel_ui.get_combo_color(combo_type)


func _on_retry_tutorial_pressed() -> void:
	if TutorialManager.is_replay():
		GameManager.start_tutorial_replay()
	else:
		GameManager.start_game()


func _on_tutorial_next_pressed() -> void:
	match TutorialManager.step_id:
		TutorialManager.STEP_INTRO_WELCOME, TutorialManager.STEP_INTRO_PAIR:
			TutorialManager.report_action("advance_intro")


func _on_tutorial_skip_pressed() -> void:
	GameManager.skip_active_tutorial()


func _on_tutorial_step_changed(_step: String) -> void:
	_refresh_tutorial_ui()
