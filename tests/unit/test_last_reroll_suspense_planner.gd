extends GutTest

const LAST_REROLL_SUSPENSE_PLANNER_PATH := "res://scripts/combat/last_reroll_suspense_planner.gd"

var _planner


func before_each() -> void:
	var script: GDScript = ResourceLoader.load(LAST_REROLL_SUSPENSE_PLANNER_PATH)
	assert_not_null(script)
	if script == null:
		return
	_planner = script.new()


func test_suspense_only_applies_to_final_reroll_with_unheld_dice() -> void:
	assert_false(_planner.should_use(2, [false, false, false, false, false]))
	assert_true(_planner.should_use(1, [false, true, true, true, true]))
	assert_false(_planner.should_use(1, [true, true, true, true, true]))
	assert_false(_planner.should_use(0, [false, false, false, false, false]))


func test_unheld_indices_follow_dice_order() -> void:
	assert_eq(_planner.unheld_indices([true, false, true, false, false]), [1, 3, 4])


func test_stop_delays_escalate_before_one_second() -> void:
	var delays: Array[float] = _planner.build_stop_delays([0, 1, 2, 3, 4])

	assert_eq(delays, [0.0, 0.16, 0.34, 0.52, 0.7])
	assert_lte(delays[delays.size() - 1], 0.8)


func test_stop_delays_cap_long_reveal_sequences() -> void:
	var delays: Array[float] = _planner.build_stop_delays([0, 1, 2, 3, 4, 5, 6])

	assert_eq(delays[5], 0.8)
	assert_eq(delays[6], 0.8)


func test_reveal_order_is_a_copy_of_input_indices() -> void:
	var ordered_indices: Array[int] = [0, 1, 2, 3, 4]
	seed(12345)

	var reveal_order: Array[int] = _planner.build_reveal_order(ordered_indices)
	var sorted_reveal_order := reveal_order.duplicate()
	sorted_reveal_order.sort()

	assert_eq_deep(sorted_reveal_order, ordered_indices)
	assert_eq_deep(ordered_indices, [0, 1, 2, 3, 4])
