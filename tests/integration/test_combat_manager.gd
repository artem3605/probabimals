extends GutTest

const ComboOddsHelperScript = preload("res://scripts/scoring/combo_odds_helper.gd")
const TestData = preload("res://tests/support/test_data.gd")

var _combo_rules: Array
var _odds_helper
var _scripted_rolls: Array = []

func before_each() -> void:
	_combo_rules = TestData.load_combo_rules()
	_odds_helper = ComboOddsHelperScript.new()
	_scripted_rolls.clear()

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
	var can_roll_on_reroll_updates: Array[bool] = []

	manager.rerolls_changed.connect(func(_remaining: int): can_roll_on_reroll_updates.append(manager.can_roll()))
	watch_signals(manager)
	manager.start_combat(dice, 999, 2, 2, _combo_rules, 4)
	manager.roll_dice()
	manager.toggle_hold(0)
	var result: Dictionary = manager.score_hand([])

	assert_eq(result["combo"]["type"], "yahtzee")
	assert_eq(result["score_data"]["total"], 300)
	assert_eq(manager.running_score, 300)
	assert_eq(manager.hands_remaining, 1)
	assert_eq(manager.rerolls_remaining, 4)
	assert_false(manager.has_rolled)
	assert_eq(manager.hand_state, CombatManager.HandState.HAND_TRANSITION)
	assert_false(manager.can_roll())
	assert_eq(manager.current_roll.size(), 0)
	assert_false(manager.is_held(0))
	assert_eq(can_roll_on_reroll_updates, [true, false])
	assert_signal_emitted_with_parameters(manager, "hands_changed", [1])
	assert_signal_emitted_with_parameters(manager, "rerolls_changed", [4], 1)
	assert_signal_emitted(manager, "hand_scored")

func test_transition_state_blocks_roll_until_next_hand_begins() -> void:
	var manager: CombatManager = CombatManager.new()
	autoqfree(manager)
	var dice: Array[Die] = [
		TestData.deterministic_die([6, 1]),
		TestData.deterministic_die([6, 2]),
		TestData.deterministic_die([6, 3]),
		TestData.deterministic_die([6, 4]),
		TestData.deterministic_die([6, 5]),
	]

	watch_signals(manager)
	manager.start_combat(dice, 999, 2, 1, _combo_rules, 4)
	manager.roll_dice()
	manager.score_hand([])

	assert_eq(manager.hand_state, CombatManager.HandState.HAND_TRANSITION)
	assert_eq(manager.rerolls_remaining, 4)
	assert_false(manager.can_roll())
	assert_false(manager.can_score())

	manager.roll_dice()

	assert_eq(manager.rerolls_remaining, 4)
	assert_eq(manager.current_roll.size(), 0)
	assert_signal_emit_count(manager, "dice_rolled", 1)

	manager.begin_next_hand()

	assert_eq(manager.hand_state, CombatManager.HandState.HAND_ACTIVE)
	assert_true(manager.can_roll())

	manager.roll_dice()

	assert_eq(manager.rerolls_remaining, 3)
	assert_eq_deep(manager.current_roll_values(), [1, 2, 3, 4, 5])
	assert_signal_emit_count(manager, "dice_rolled", 2)

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

	assert_eq(manager.hand_state, CombatManager.HandState.COMBAT_ENDED)
	assert_false(manager.can_roll())
	assert_signal_emitted_with_parameters(manager, "combat_ended", [300, true])

	manager.begin_next_hand()
	manager.roll_dice()

	assert_eq(manager.hand_state, CombatManager.HandState.COMBAT_ENDED)
	assert_eq(manager.rerolls_remaining, 1)
	assert_eq(manager.current_roll.size(), 0)
	assert_signal_emit_count(manager, "dice_rolled", 1)

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

	assert_eq(manager.hand_state, CombatManager.HandState.COMBAT_ENDED)
	assert_signal_emitted_with_parameters(manager, "combat_ended", [56, false])

func test_roll_provider_overrides_roll_sequence_without_breaking_hold_logic() -> void:
	var manager: CombatManager = CombatManager.new()
	autoqfree(manager)
	var dice: Array[Die] = [
		TestData.deterministic_die([1, 1]),
		TestData.deterministic_die([1, 1]),
		TestData.deterministic_die([1, 1]),
		TestData.deterministic_die([1, 1]),
		TestData.deterministic_die([1, 1]),
	]
	_scripted_rolls = [
		[6, 6, 2, 3, 4],
		[6, 6, 6, 6, 5],
	]

	manager.start_combat(dice, 999, 1, 2, _combo_rules, 2, Callable(self, "_roll_provider"))
	manager.roll_dice()
	manager.hold_die(0)
	manager.hold_die(1)
	manager.roll_dice()

	assert_eq_deep(manager.current_roll_values(), [6, 6, 6, 6, 5])

func test_probability_snapshot_updates_for_hold_unhold_reroll_and_hand_reset() -> void:
	var manager: CombatManager = CombatManager.new()
	autoqfree(manager)
	var dice: Array[Die] = [
		TestData.deterministic_die([2, 6]),
		TestData.deterministic_die([2, 6]),
		TestData.deterministic_die([3, 6]),
		TestData.deterministic_die([4, 6]),
		TestData.deterministic_die([6, 6]),
	]

	manager.start_combat(dice, 999, 2, 2, _combo_rules, 2)
	assert_eq_deep(manager.get_probability_snapshot(), {})

	manager.roll_dice()

	var expected_open_snapshot := _expected_probability_snapshot(manager, dice)
	assert_eq_deep(manager.get_probability_snapshot(), expected_open_snapshot)

	manager.hold_die(0)

	var held_snapshot := manager.get_probability_snapshot()
	var expected_held_snapshot := _expected_probability_snapshot(manager, dice)
	assert_eq_deep(held_snapshot, expected_held_snapshot)
	assert_ne(held_snapshot, expected_open_snapshot)

	manager.unhold_die(0)

	var unheld_snapshot := manager.get_probability_snapshot()
	assert_eq_deep(unheld_snapshot, _expected_probability_snapshot(manager, dice))
	assert_eq_deep(unheld_snapshot, expected_open_snapshot)

	manager.hold_die(0)
	manager.roll_dice()

	var rerolled_snapshot := manager.get_probability_snapshot()
	assert_eq_deep(manager.current_roll_values(), [2, 6, 6, 6, 6])
	assert_eq_deep(rerolled_snapshot, _expected_probability_snapshot(manager, dice))
	assert_eq_deep(rerolled_snapshot, held_snapshot)

	manager.score_hand([])

	assert_eq_deep(manager.get_probability_snapshot(), {})


func _roll_provider(roll_number: int, _held_dice: Array) -> Array[int]:
	var result: Array[int] = []
	for value in _scripted_rolls[roll_number]:
		result.append(int(value))
	return result

func _expected_probability_snapshot(manager: CombatManager, dice: Array[Die]) -> Dictionary:
	var die_face_options: Array = []
	for die in dice:
		var options: Array[DiceFace] = []
		for face in die.faces:
			options.append(face.duplicate_face())
		die_face_options.append(options)

	return _odds_helper.calculate_probabilities(
		manager.current_roll,
		manager.held_dice,
		_combo_rules,
		die_face_options
	)
