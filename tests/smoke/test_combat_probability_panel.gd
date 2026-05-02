extends GutTest

const TestData = preload("res://tests/support/test_data.gd")
const COMBAT_SCENE := preload("res://scenes/combat/combat_screen.tscn")
const WIDE_VIEWPORT := Vector2(1440, 720)
const COMPACT_VIEWPORT := Vector2(1024, 720)


func before_each() -> void:
	GameManager.dice_bag = DiceBag.new()
	for _i in range(5):
		GameManager.dice_bag.add_die(Die.new())
	GameManager.current_round = 1
	GameManager.target_score = 150
	GameManager.hands_per_round = 2
	GameManager.rerolls_per_hand = 2
	GameManager.coins = 50
	GameManager.modifiers.clear()
	GameManager.selected_dice = [
		TestData.deterministic_die([2, 6]),
		TestData.deterministic_die([2, 6]),
		TestData.deterministic_die([3, 6]),
		TestData.deterministic_die([4, 6]),
		TestData.deterministic_die([6, 6]),
	]
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func after_each() -> void:
	GameManager.selected_dice.clear()
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func test_combat_probability_rail_renders_and_updates_with_hold_changes() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	assert_not_null(combat._probability_panel)
	assert_true(combat._probability_panel.is_inside_tree())
	var panel_style: StyleBoxFlat = combat._probability_panel.get_theme_stylebox("panel")
	assert_eq(panel_style.bg_color, Color("bfeeff"))
	assert_eq(panel_style.border_width_left, 0)
	assert_eq(panel_style.border_width_top, 0)
	assert_eq(panel_style.border_width_right, 0)
	assert_eq(panel_style.border_width_bottom, 0)
	assert_false(combat.is_probability_collapsed())
	assert_true(combat.is_probability_panel_body_visible())
	assert_eq(combat.get_probability_row_count(), DataManager.get_combo_rules().size())
	assert_eq(combat.get_probability_row_name_text("pair"), "PAIR")
	assert_eq(combat.get_probability_row_name_text("small_straight"), "SMALL STRAIGHT")
	assert_eq(combat.get_probability_row_name_text("large_straight"), "LARGE STRAIGHT")
	assert_eq(combat.get_probability_row_text("pair"), "37%")
	assert_eq(combat.get_probability_status_text(), "ALL OPEN")

	var tray_x_before: float = combat.get_dice_tray_global_x()
	var tray_center_before: float = combat.get_dice_tray_center_x()
	var score_panel_center: float = combat._score_panel.global_position.x + (combat._score_panel.size.x / 2.0)
	assert_eq(tray_center_before, score_panel_center)

	combat.combat_mgr.roll_dice()
	assert_eq(combat._score_panel.scale, Vector2.ONE)
	await wait_process_frames(1)

	var open_display: Dictionary = combat.get_probability_display_snapshot()
	var combo: Dictionary = combat.combat_mgr.get_current_combo()
	var expected_highlight_indices: Array[int] = []
	var in_combo: Array = combo.get("in_combo", [])
	for i in range(in_combo.size()):
		if bool(in_combo[i]):
			expected_highlight_indices.append(i)
	assert_eq(open_display.size(), DataManager.get_combo_rules().size())
	assert_eq(combat.get_probability_row_text("pair"), "37%")
	assert_eq(combat.get_probability_status_text(), "ALL OPEN")
	assert_eq_deep(combat.get_combo_highlight_indices(), expected_highlight_indices)
	assert_eq(combat.get_dice_tray_global_x(), tray_x_before)
	assert_eq(combat.get_dice_tray_center_x(), score_panel_center)

	combat.combat_mgr.hold_die(0)
	combat.combat_mgr.hold_die(1)
	await wait_process_frames(1)

	var held_display: Dictionary = combat.get_probability_display_snapshot()
	assert_eq(held_display.size(), DataManager.get_combo_rules().size())
	assert_ne(held_display, open_display)
	assert_eq(combat.get_probability_status_text(), "2 LOCKED")

	combat.combat_mgr.unhold_die(0)
	combat.combat_mgr.unhold_die(1)
	await wait_process_frames(1)

	assert_eq_deep(combat.get_probability_display_snapshot(), open_display)
	assert_eq(combat.get_probability_status_text(), "ALL OPEN")


func test_combat_probability_rail_does_not_shift_dice_tray_in_compact_layout() -> void:
	var scene: Dictionary = await _spawn_combat_scene(COMPACT_VIEWPORT)
	var combat = scene["combat"]
	var _root: Control = scene["root"]

	assert_false(combat.is_probability_collapsed())
	assert_true(combat.is_probability_panel_body_visible())

	var tray_x_before: float = combat.get_dice_tray_global_x()
	var score_center: float = combat._score_panel.global_position.x + (combat._score_panel.size.x / 2.0)

	combat.combat_mgr.roll_dice()
	await wait_process_frames(2)

	assert_eq(combat.get_dice_tray_global_x(), tray_x_before)
	assert_eq(combat.get_dice_tray_center_x(), score_center)


func test_two_pair_accents_group_matching_values_when_pairs_are_split() -> void:
	GameManager.selected_dice = [
		TestData.deterministic_die([5]),
		TestData.deterministic_die([4]),
		TestData.deterministic_die([6]),
		TestData.deterministic_die([4]),
		TestData.deterministic_die([5]),
	]
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	combat.combat_mgr.roll_dice()
	await wait_process_frames(1)

	var combo: Dictionary = combat.combat_mgr.get_current_combo()
	assert_eq(combo["type"], "two_pair")
	assert_eq_deep(combo["in_combo"], [true, true, false, true, true])
	assert_eq(_card_border_color(combat._dice_cards[0]), _card_border_color(combat._dice_cards[4]))
	assert_eq(_card_border_color(combat._dice_cards[1]), _card_border_color(combat._dice_cards[3]))
	assert_ne(_card_border_color(combat._dice_cards[0]), _card_border_color(combat._dice_cards[1]))
	assert_eq(_card_border_color(combat._dice_cards[2]), Color("000000"))


func test_hovering_dice_does_not_shift_action_buttons() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	var reroll_y_before: float = combat._reroll_btn.global_position.y
	var end_turn_y_before: float = combat._end_turn_btn.global_position.y

	combat._on_card_hover_enter(combat._dice_cards[0])
	await wait_process_frames(1)

	assert_eq(combat._reroll_btn.global_position.y, reroll_y_before)
	assert_eq(combat._end_turn_btn.global_position.y, end_turn_y_before)

	combat._on_card_hover_exit()
	await wait_process_frames(1)

	assert_eq(combat._reroll_btn.global_position.y, reroll_y_before)
	assert_eq(combat._end_turn_btn.global_position.y, end_turn_y_before)


func test_large_straight_row_name_has_enough_width_for_text() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]
	var large_row: PanelContainer = combat._probability_panel_ui.find_child(
		"ProbabilityRow_large_straight", true, false
	)
	assert_not_null(large_row)
	if large_row == null:
		return

	var row: HBoxContainer = large_row.get_child(0)
	var name_label: Label = row.get_child(0)
	var font: Font = name_label.get_theme_font("font")
	var font_size: int = name_label.get_theme_font_size("font_size")
	var required_width: float = (
		ceil(font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) + 1.0
	)

	assert_true(name_label.custom_minimum_size.x >= required_width)


func test_x_mult_score_breakdown_uses_compact_two_line_layout() -> void:
	GameManager.modifiers = [TestData.modifier("x_mult", 4.0, "always", "test_x_mult", "Test X Mult")]
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	combat.combat_mgr.roll_dice()
	await wait_process_frames(1)

	var label: RichTextLabel = combat._score_breakdown_label
	# SUM and MULT words appear alongside colorized numbers.
	var plain_text: String = label.get_parsed_text()
	assert_eq(plain_text, "17sum x 2mult\nx 4")

	var slot: Control = combat._probability_panel_ui.find_child("ScoreBreakdownSlot", true, false)
	assert_not_null(slot)
	if slot == null:
		return
	var font: Font = label.get_theme_font("normal_font")
	var font_size: int = label.get_theme_font_size("normal_font_size")
	for line in plain_text.split("\n"):
		var required_width: float = ceil(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) + 1.0
		assert_true(required_width <= slot.custom_minimum_size.x)


func test_combat_multiplier_formatter_hides_zero_decimal_for_integers() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	assert_eq(combat._format_tutorial_factor(2.0), "2")
	assert_eq(combat._format_tutorial_factor(15.0), "15")
	assert_eq(combat._format_tutorial_factor(2.5), "2.5")


func test_score_points_fly_to_score_bar_before_bar_updates() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	combat.combat_mgr.roll_dice()
	await wait_process_frames(1)

	combat._on_score_pressed()
	await wait_process_frames(1)

	var flight_label: Label = combat.find_child("ScoreFlightLabel", true, false)
	assert_not_null(flight_label)
	if flight_label != null:
		assert_eq(flight_label.text, "+34")
	assert_eq(combat._score_bar_label.text, "0/150")

	await wait_seconds(0.8)

	assert_eq(combat._score_bar_label.text, "34/150")
	assert_null(combat.find_child("ScoreFlightLabel", true, false))


func test_combo_hover_multiplier_includes_owned_scoring_modifiers() -> void:
	GameManager.modifiers = [
		TestData.modifier("add_mult", 1.0, "pair", "pair_boost", "Pair Boost"),
		TestData.modifier("x_mult", 3.0, "yahtzee", "yahtzee_hunter", "Yahtzee Hunter"),
		TestData.modifier("bonus", 7.0, "always", "golden_sum", "Golden Sum"),
	]
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	combat._on_combo_row_hover_enter("pair")
	assert_eq(combat._desc_combo_mult_label.text, "x3")

	combat._on_combo_row_hover_enter("yahtzee")
	assert_eq(combat._desc_combo_mult_label.text, "x45")


func test_last_reroll_suspense_only_triggers_for_final_roll_with_unheld_dice() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	assert_false(combat._should_use_last_reroll_suspense())

	combat.combat_mgr.rerolls_remaining = 1
	assert_true(combat._should_use_last_reroll_suspense())

	for i in range(combat._dice_cards.size()):
		combat.combat_mgr.held_dice[i] = true

	assert_false(combat._should_use_last_reroll_suspense())


func test_last_reroll_stop_delays_escalate_and_stay_short() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	var delays: Array[float] = combat._build_last_reroll_stop_delays([0, 1, 2, 3, 4])

	assert_eq(delays.size(), 5)
	assert_eq(delays[0], 0.0)
	for i in range(1, delays.size()):
		assert_gt(delays[i], delays[i - 1])
	assert_lte(delays[delays.size() - 1], 0.8)


func test_last_reroll_reveal_order_randomizes_stop_sequence() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	var ordered_indices: Array[int] = [0, 1, 2, 3, 4]
	seed(12345)

	var reveal_order: Array[int] = combat._build_last_reroll_reveal_order(ordered_indices)
	var sorted_reveal_order := reveal_order.duplicate()
	sorted_reveal_order.sort()

	assert_eq_deep(sorted_reveal_order, ordered_indices)
	assert_false(reveal_order == ordered_indices)
	assert_eq_deep(ordered_indices, [0, 1, 2, 3, 4])


func test_last_reroll_results_can_be_buffered_until_final_reveal() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	var hidden_values: Array[int] = [1, 1, 1, 1, 1]
	combat._current_values = hidden_values
	for i in range(5):
		combat._set_die_face(i, 1)

	var revealed_values: Array[int] = [2, 3, 4, 5, 6]
	var score_text_before_buffer: String = combat._score_value_label.text
	combat._begin_suspense_result_buffer()
	combat._on_dice_rolled(revealed_values)

	assert_eq_deep(combat._current_values, [1, 1, 1, 1, 1])
	assert_eq_deep(combat._suspense_final_results, [2, 3, 4, 5, 6])
	assert_eq(combat._score_value_label.text, score_text_before_buffer)

	combat._finish_suspense_result_buffer()
	combat._on_dice_rolled(revealed_values)

	assert_eq_deep(combat._current_values, [2, 3, 4, 5, 6])
	assert_true(combat._suspense_final_results.is_empty())


func test_last_reroll_suspense_blocks_scoring_until_reveal_finishes() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	combat._begin_suspense_result_buffer()
	combat.combat_mgr.roll_dice()
	combat._update_rerolls_display()

	assert_true(combat.combat_mgr.can_score())
	assert_true(combat._end_turn_btn.disabled)

	var hands_before: int = combat.combat_mgr.hands_remaining
	var score_before: int = combat.combat_mgr.running_score
	combat._on_score_pressed()

	assert_eq(combat.combat_mgr.hands_remaining, hands_before)
	assert_eq(combat.combat_mgr.running_score, score_before)

	combat._finish_suspense_result_buffer()
	combat._on_dice_rolled(combat._suspense_final_results)
	combat._update_rerolls_display()

	assert_false(combat._end_turn_btn.disabled)


func test_suspense_scramble_only_updates_requested_unrevealed_dice() -> void:
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	var current_values: Array[int] = [1, 1, 1, 1, 1]
	combat._current_values = current_values

	combat._show_random_faces_for_indices([2, 4])

	assert_eq(combat._current_values[0], 1)
	assert_eq(combat._current_values[1], 1)
	assert_between(combat._current_values[2], 1, 6)
	assert_eq(combat._current_values[3], 1)
	assert_between(combat._current_values[4], 1, 6)


func test_last_reroll_animation_reveals_values_and_refreshes_ui_after_settle() -> void:
	GameManager.rerolls_per_hand = 1
	GameManager.selected_dice = [
		TestData.deterministic_die([2]),
		TestData.deterministic_die([3]),
		TestData.deterministic_die([4]),
		TestData.deterministic_die([5]),
		TestData.deterministic_die([6]),
	]
	var scene: Dictionary = await _spawn_combat_scene(WIDE_VIEWPORT)
	var combat = scene["combat"]

	assert_true(await wait_until(func(): return not combat._animating, 1.0, 0.05, "combat intro settled"))

	combat._on_roll_pressed()

	assert_true(combat._animating)
	assert_true(
		await wait_until(
			func(): return combat._suspense_reveal_active, 1.0, 0.05, "last reroll suspense buffer started"
		)
	)

	assert_true(await wait_until(func(): return not combat._animating, 3.0, 0.05, "last reroll suspense settled"))

	assert_false(combat._suspense_reveal_active)
	assert_eq_deep(combat._current_values, [2, 3, 4, 5, 6])
	assert_eq_deep(combat.combat_mgr.current_roll_values(), [2, 3, 4, 5, 6])
	assert_eq(combat.combat_mgr.rerolls_remaining, 0)
	assert_true(combat._reroll_btn.disabled)
	assert_eq(combat.get_probability_status_text(), "ALL OPEN")
	assert_ne(combat._score_value_label.text, "ROLL!")


func _spawn_combat_scene(view_size: Vector2) -> Dictionary:
	var root := Control.new()
	root.size = view_size
	add_child_autofree(root)

	var combat = COMBAT_SCENE.instantiate()
	autoqfree(combat)
	root.add_child(combat)
	await wait_process_frames(3)

	return {
		"root": root,
		"combat": combat,
	}


func _card_border_color(card: Control) -> Color:
	var style: StyleBoxFlat = card.main_button.get_theme_stylebox("normal")
	return style.border_color
