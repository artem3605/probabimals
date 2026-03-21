extends GutTest

const TestData = preload("res://tests/support/test_data.gd")

const COMBO_CASES = [
	{
		"values": [1, 2, 3, 5, 6],
		"expected_type": "high_card",
		"expected_in_combo": [false, false, false, false, true],
	},
	{
		"values": [2, 2, 3, 5, 6],
		"expected_type": "pair",
		"expected_in_combo": [true, true, false, false, false],
	},
	{
		"values": [2, 2, 5, 5, 6],
		"expected_type": "two_pair",
		"expected_in_combo": [true, true, true, true, false],
	},
	{
		"values": [4, 4, 4, 2, 6],
		"expected_type": "three_same",
		"expected_in_combo": [true, true, true, false, false],
	},
	{
		"values": [1, 2, 3, 4, 4],
		"expected_type": "small_straight",
		"expected_in_combo": [true, true, true, true, false],
	},
	{
		"values": [3, 3, 3, 5, 5],
		"expected_type": "full_house",
		"expected_in_combo": [true, true, true, true, true],
	},
	{
		"values": [2, 3, 4, 5, 6],
		"expected_type": "large_straight",
		"expected_in_combo": [true, true, true, true, true],
	},
	{
		"values": [6, 6, 6, 6, 2],
		"expected_type": "four_same",
		"expected_in_combo": [true, true, true, true, false],
	},
	{
		"values": [5, 5, 5, 5, 5],
		"expected_type": "yahtzee",
		"expected_in_combo": [true, true, true, true, true],
	}
]

var _detector: ComboDetector

func before_each() -> void:
	_detector = ComboDetector.new()
	_detector.set_combo_rules(TestData.load_combo_rules())

func test_empty_roll_returns_none_combo() -> void:
	var combo := _detector.detect_best_combo([])

	assert_eq(combo["type"], "none")
	assert_eq(combo["name"], "None")

func test_detects_all_current_combos(case_data = use_parameters(COMBO_CASES)) -> void:
	var combo := _detector.detect_best_combo(TestData.faces_from_values(case_data["values"]))

	assert_eq(combo["type"], case_data["expected_type"])
	assert_eq_deep(combo["in_combo"], case_data["expected_in_combo"])

func test_higher_priority_combo_wins_when_roll_matches_multiple_patterns() -> void:
	var combo := _detector.detect_best_combo(TestData.faces_from_values([1, 2, 3, 4, 5]))

	assert_eq(combo["type"], "large_straight")
	assert_eq(combo["priority"], 6)

func test_wild_face_chooses_best_assignment() -> void:
	var faces: Array[DiceFace] = [
		TestData.face("wild", 0, DiceFace.Type.WILD),
		TestData.basic_face(2),
		TestData.basic_face(2),
		TestData.basic_face(3),
		TestData.basic_face(3),
	]
	var combo := _detector.detect_best_combo(faces)

	assert_eq(combo["type"], "full_house")
	assert_eq_deep(combo["in_combo"], [true, true, true, true, true])
