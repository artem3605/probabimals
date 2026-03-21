extends GutTest

const TestData = preload("res://tests/support/test_data.gd")

var _engine: ScoringEngine

func before_each() -> void:
	_engine = ScoringEngine.new()

func test_calculate_score_applies_all_three_layers() -> void:
	var combo := {"type": "pair", "combo_mult": 1.5}
	var faces: Array[DiceFace] = [
		TestData.face("pip_5", 5, DiceFace.Type.PIP, 8.0),
		TestData.face("mult_2", 2, DiceFace.Type.MULT, 3.0),
		TestData.face("xmult_1", 1, DiceFace.Type.XMULT, 2.0),
		TestData.basic_face(4),
		TestData.basic_face(6),
	]
	var modifiers := [
		TestData.modifier("bonus", 5.0, "pair"),
		TestData.modifier("add_mult", 1.0, "pair"),
		TestData.modifier("x_mult", 2.0, "pair"),
		TestData.modifier("add_mult", 10.0, "yahtzee"),
	]
	var result := _engine.calculate_score(combo, faces, [true, true, false, false, false], modifiers)

	assert_almost_eq(result["face_sum"], 31.0, 0.001)
	assert_almost_eq(result["mult"], 5.5, 0.001)
	assert_almost_eq(result["x_mult"], 4.0, 0.001)
	assert_eq(result["total"], 682)

func test_non_matching_modifiers_are_ignored() -> void:
	var combo := {"type": "full_house", "combo_mult": 4.0}
	var faces: Array[DiceFace] = TestData.faces_from_values([3, 3, 3, 5, 5])
	var modifiers := [
		TestData.modifier("bonus", 7.0, "pair"),
		TestData.modifier("add_mult", 3.0, "pair"),
		TestData.modifier("x_mult", 9.0, "pair"),
	]
	var result := _engine.calculate_score(combo, faces, [true, true, true, true, true], modifiers)

	assert_almost_eq(result["face_sum"], 19.0, 0.001)
	assert_almost_eq(result["mult"], 4.0, 0.001)
	assert_almost_eq(result["x_mult"], 1.0, 0.001)
	assert_eq(result["total"], 76)

func test_total_is_floored_after_all_math() -> void:
	var combo := {"type": "high_card", "combo_mult": 1.3}
	var faces: Array[DiceFace] = TestData.faces_from_values([1, 2, 3])
	var modifiers := [TestData.modifier("x_mult", 1.1)]
	var result := _engine.calculate_score(combo, faces, [false, false, true], modifiers)

	assert_eq(result["total"], 8)
