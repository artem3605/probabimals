extends GutTest

const TestData = preload("res://tests/support/test_data.gd")

var _combo_rules: Array

func before_each() -> void:
	_combo_rules = TestData.load_combo_rules()

func test_roll_hold_and_reroll_cycle_keeps_held_die_value() -> void:
	var manager: CombatManager = CombatManager.new()
	autoqfree(manager)
	var dice: Array[Die] = [
		TestData.deterministic_die([1, 6]),
		TestData.deterministic_die([2, 6]),
		TestData.deterministic_die([3, 6]),
		TestData.deterministic_die([4, 6]),
		TestData.deterministic_die([5, 6]),
	]

	watch_signals(manager)
	manager.start_combat(dice, 999, 2, 2, _combo_rules, 3)
	manager.roll_dice()
	manager.hold_die(0)
	manager.roll_dice()

	assert_eq_deep(manager.current_roll_values(), [1, 6, 6, 6, 6])
	assert_true(manager.is_held(0))
	assert_eq(manager.rerolls_remaining, 0)
	assert_signal_emit_count(manager, "dice_rolled", 2)
	assert_signal_emitted_with_parameters(manager, "dice_rolled", [[1, 6, 6, 6, 6]], 1)
	assert_signal_emitted_with_parameters(manager, "die_held", [0, true])

func test_score_hand_resets_roll_state_and_rerolls_to_configured_value() -> void:
	var manager: CombatManager = CombatManager.new()
	autoqfree(manager)
	var dice: Array[Die] = [
		TestData.deterministic_die([6]),
		TestData.deterministic_die([6]),
		TestData.deterministic_die([6]),
		TestData.deterministic_die([6]),
		TestData.deterministic_die([6]),
	]

	watch_signals(manager)
	manager.start_combat(dice, 999, 2, 1, _combo_rules, 4)
	manager.roll_dice()
	manager.toggle_hold(0)
	var result: Dictionary = manager.score_hand([])

	assert_eq(result["combo"]["type"], "yahtzee")
	assert_eq(result["score_data"]["total"], 300)
	assert_eq(manager.running_score, 300)
	assert_eq(manager.hands_remaining, 1)
	assert_eq(manager.rerolls_remaining, 4)
	assert_false(manager.has_rolled)
	assert_eq(manager.current_roll.size(), 0)
	assert_false(manager.is_held(0))
	assert_signal_emitted_with_parameters(manager, "hands_changed", [1])
	assert_signal_emitted_with_parameters(manager, "rerolls_changed", [4], 1)
	assert_signal_emitted(manager, "hand_scored")

func test_combat_ends_immediately_when_target_is_beaten() -> void:
	var manager: CombatManager = CombatManager.new()
	autoqfree(manager)
	var dice: Array[Die] = [
		TestData.deterministic_die([6]),
		TestData.deterministic_die([6]),
		TestData.deterministic_die([6]),
		TestData.deterministic_die([6]),
		TestData.deterministic_die([6]),
	]

	watch_signals(manager)
	manager.start_combat(dice, 100, 2, 1, _combo_rules, 1)
	manager.roll_dice()
	manager.score_hand([])

	assert_signal_emitted_with_parameters(manager, "combat_ended", [300, true])

func test_combat_ends_when_hands_run_out() -> void:
	var manager: CombatManager = CombatManager.new()
	autoqfree(manager)
	var dice: Array[Die] = [
		TestData.deterministic_die([1]),
		TestData.deterministic_die([2]),
		TestData.deterministic_die([3]),
		TestData.deterministic_die([4]),
		TestData.deterministic_die([6]),
	]

	watch_signals(manager)
	manager.start_combat(dice, 999, 1, 1, _combo_rules, 1)
	manager.roll_dice()
	manager.score_hand([])

	assert_signal_emitted_with_parameters(manager, "combat_ended", [56, false])
