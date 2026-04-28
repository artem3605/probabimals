extends GutTest

const BalanceSimulatorScript = preload("res://scripts/balance/balance_simulator.gd")
const TestData = preload("res://tests/support/test_data.gd")

var _simulator

func before_each() -> void:
	_simulator = BalanceSimulatorScript.new()

func test_compare_modifier_reports_score_delta_trigger_rate_and_cost_efficiency() -> void:
	var pair_boost := TestData.find_item_by_id(TestData.load_shop_catalogue(), "pair_boost")
	var report: Dictionary = _simulator.compare_modifier({
		"dice": _fixed_dice([6, 6, 1, 2, 3]),
		"combo_rules": TestData.load_combo_rules(),
		"modifier_item": pair_boost,
		"simulations": 3,
		"seed": 123,
		"target_score": 50,
		"roll_policy": "score_immediately",
		"preset": "unit_pair",
	})

	assert_eq(report["simulations"], 3)
	assert_eq(report["seed"], 123)
	assert_eq(report["preset"], "unit_pair")
	assert_eq(report["roll_policy"], "score_immediately")
	assert_eq(report["modifiers"], ["pair_boost"])
	assert_almost_eq(report["baseline_average_score"], 27.0, 0.001)
	assert_almost_eq(report["average_score"], 45.0, 0.001)
	assert_almost_eq(report["average_delta_vs_baseline"], 18.0, 0.001)
	assert_almost_eq(report["median_delta_vs_baseline"], 18.0, 0.001)
	assert_almost_eq(report["win_rate_delta_vs_baseline"], 0.0, 0.001)
	assert_almost_eq(report["cost_efficiency"], 1.8, 0.001)
	assert_almost_eq(report["modifier_trigger_rates"]["pair_boost"], 1.0, 0.001)
	assert_eq(report["combo_distribution"], {"pair": 3})

func test_exact_condition_does_not_trigger_pair_modifier_on_full_house() -> void:
	var pair_boost := TestData.find_item_by_id(TestData.load_shop_catalogue(), "pair_boost")
	var report: Dictionary = _simulator.compare_modifier({
		"dice": _fixed_dice([6, 6, 6, 5, 5]),
		"combo_rules": TestData.load_combo_rules(),
		"modifier_item": pair_boost,
		"simulations": 2,
		"seed": 456,
		"target_score": 50,
		"roll_policy": "score_immediately",
		"preset": "unit_full_house",
	})

	assert_almost_eq(report["baseline_average_score"], 112.0, 0.001)
	assert_almost_eq(report["average_score"], 112.0, 0.001)
	assert_almost_eq(report["average_delta_vs_baseline"], 0.0, 0.001)
	assert_almost_eq(report["median_delta_vs_baseline"], 0.0, 0.001)
	assert_almost_eq(report["modifier_trigger_rates"]["pair_boost"], 0.0, 0.001)
	assert_eq(report["combo_distribution"], {"full_house": 2})

func test_same_seed_produces_stable_report_for_random_dice() -> void:
	var yahtzee_hunter := TestData.find_item_by_id(TestData.load_shop_catalogue(), "yahtzee_hunter")
	var config := {
		"dice": _standard_dice(),
		"combo_rules": TestData.load_combo_rules(),
		"modifier_item": yahtzee_hunter,
		"simulations": 8,
		"seed": 789,
		"target_score": 150,
		"roll_policy": "score_immediately",
		"preset": "unit_standard",
	}

	var first: Dictionary = _simulator.compare_modifier(config)
	var second: Dictionary = _simulator.compare_modifier(config)

	assert_eq_deep(first, second)

func test_reroll_modifier_reports_baseline_distribution_for_consistency_comparison() -> void:
	var reroll_plus := TestData.find_item_by_id(TestData.load_shop_catalogue(), "reroll_plus")
	var report: Dictionary = _simulator.compare_modifier({
		"dice": _swingy_binary_dice(),
		"combo_rules": TestData.load_combo_rules(),
		"modifier_item": reroll_plus,
		"simulations": 30,
		"seed": 321,
		"target_score": 150,
		"roll_policy": "greedy_best_combo",
		"preset": "unit_reroll",
		"rerolls_per_hand": 0,
	})

	assert_eq(report["modifiers"], ["reroll_plus"])
	assert_eq(report["rerolls_per_hand"], 0)
	assert_eq(report["modified_rerolls_per_hand"], 1)
	assert_true(report.has("baseline_combo_distribution"))
	assert_true(report["combo_distribution"].size() > 0)
	assert_true(report["baseline_combo_distribution"].size() > 0)

func test_exact_pair_boost_description_has_no_condition_warning() -> void:
	var pair_boost := TestData.find_item_by_id(TestData.load_shop_catalogue(), "pair_boost")
	var report: Dictionary = _simulator.compare_modifier({
		"dice": _fixed_dice([6, 6, 1, 2, 3]),
		"combo_rules": TestData.load_combo_rules(),
		"modifier_item": pair_boost,
		"simulations": 1,
		"seed": 654,
		"target_score": 50,
		"roll_policy": "score_immediately",
		"preset": "unit_pair",
	})

	assert_eq(report["condition_warnings"], [])

func _fixed_dice(values: Array[int]) -> Array[Die]:
	var dice: Array[Die] = []
	for value in values:
		dice.append(TestData.die_from_values([value]))
	return dice

func _standard_dice() -> Array[Die]:
	var dice: Array[Die] = []
	for _i in range(5):
		dice.append(TestData.die_from_values([1, 2, 3, 4, 5, 6]))
	return dice

func _swingy_binary_dice() -> Array[Die]:
	var dice: Array[Die] = []
	for _i in range(5):
		dice.append(TestData.die_from_values([1, 6]))
	return dice
