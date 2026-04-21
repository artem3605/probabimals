extends GutTest

const ComboOddsHelperScript = preload("res://scripts/scoring/combo_odds_helper.gd")
const TestData = preload("res://tests/support/test_data.gd")

const COMBO_TYPES = [
	"high_card",
	"pair",
	"two_pair",
	"three_same",
	"small_straight",
	"full_house",
	"large_straight",
	"four_same",
	"yahtzee",
]

var _helper
var _combo_rules: Array

func before_each() -> void:
	_helper = ComboOddsHelperScript.new()
	_combo_rules = TestData.load_combo_rules()

func test_fully_open_roll_matches_exact_standard_distribution() -> void:
	var probabilities: Dictionary = _helper.calculate_probabilities(
		TestData.faces_from_values([1, 1, 1, 1, 1]),
		[false, false, false, false, false],
		_combo_rules
	)

	assert_eq(probabilities.size(), COMBO_TYPES.size())
	assert_almost_eq(_sum_probabilities(probabilities), 1.0, 0.001)
	assert_almost_eq(probabilities["high_card"], 240.0 / 7776.0, 0.001)
	assert_almost_eq(probabilities["pair"], 2880.0 / 7776.0, 0.001)
	assert_almost_eq(probabilities["two_pair"], 1800.0 / 7776.0, 0.001)
	assert_almost_eq(probabilities["three_same"], 1200.0 / 7776.0, 0.001)
	assert_almost_eq(probabilities["small_straight"], 960.0 / 7776.0, 0.001)
	assert_almost_eq(probabilities["full_house"], 300.0 / 7776.0, 0.001)
	assert_almost_eq(probabilities["large_straight"], 240.0 / 7776.0, 0.001)
	assert_almost_eq(probabilities["four_same"], 150.0 / 7776.0, 0.001)
	assert_almost_eq(probabilities["yahtzee"], 6.0 / 7776.0, 0.001)

func test_held_dice_only_reroll_unlocked_positions() -> void:
	var probabilities: Dictionary = _helper.calculate_probabilities(
		TestData.faces_from_values([2, 2, 3, 4, 6]),
		[true, true, false, false, false],
		_combo_rules
	)

	assert_almost_eq(_sum_probabilities(probabilities), 1.0, 0.001)
	assert_almost_eq(probabilities["high_card"], 0.0, 0.001)
	assert_almost_eq(probabilities["pair"], 48.0 / 216.0, 0.001)
	assert_almost_eq(probabilities["two_pair"], 60.0 / 216.0, 0.001)
	assert_almost_eq(probabilities["three_same"], 60.0 / 216.0, 0.001)
	assert_almost_eq(probabilities["small_straight"], 12.0 / 216.0, 0.001)
	assert_almost_eq(probabilities["full_house"], 20.0 / 216.0, 0.001)
	assert_almost_eq(probabilities["large_straight"], 0.0, 0.001)
	assert_almost_eq(probabilities["four_same"], 15.0 / 216.0, 0.001)
	assert_almost_eq(probabilities["yahtzee"], 1.0 / 216.0, 0.001)

func test_fully_locked_roll_returns_current_combo_with_certainty() -> void:
	var probabilities: Dictionary = _helper.calculate_probabilities(
		TestData.faces_from_values([3, 3, 3, 5, 5]),
		[true, true, true, true, true],
		_combo_rules
	)

	assert_almost_eq(_sum_probabilities(probabilities), 1.0, 0.001)
	for combo_type in COMBO_TYPES:
		var expected := 1.0 if combo_type == "full_house" else 0.0
		assert_almost_eq(probabilities[combo_type], expected, 0.001)

func _sum_probabilities(probabilities: Dictionary) -> float:
	var total := 0.0
	for value in probabilities.values():
		total += float(value)
	return total
