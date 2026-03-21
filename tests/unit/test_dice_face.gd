extends GutTest

const TestData = preload("res://tests/support/test_data.gd")

func test_basic_face_has_expected_defaults() -> void:
	var face := DiceFace.make_basic(6)

	assert_eq(face.get_combo_value(), 6)
	assert_almost_eq(face.get_face_sum_contribution(), 6.0, 0.001)
	assert_almost_eq(face.get_add_mult(), 0.0, 0.001)
	assert_almost_eq(face.get_x_mult(), 1.0, 0.001)
	assert_false(face.is_wild())

func test_pip_face_adds_to_face_sum() -> void:
	var face := TestData.face("pip_5", 5, DiceFace.Type.PIP, 8.0)

	assert_almost_eq(face.get_face_sum_contribution(), 13.0, 0.001)
	assert_almost_eq(face.get_add_mult(), 0.0, 0.001)
	assert_almost_eq(face.get_x_mult(), 1.0, 0.001)

func test_mult_face_only_contributes_additive_multiplier() -> void:
	var face := TestData.face("mult_2", 2, DiceFace.Type.MULT, 3.0)

	assert_almost_eq(face.get_face_sum_contribution(), 2.0, 0.001)
	assert_almost_eq(face.get_add_mult(), 3.0, 0.001)
	assert_almost_eq(face.get_x_mult(), 1.0, 0.001)

func test_xmult_face_only_contributes_multiplicative_multiplier() -> void:
	var face := TestData.face("xmult_1", 1, DiceFace.Type.XMULT, 2.0)

	assert_almost_eq(face.get_face_sum_contribution(), 1.0, 0.001)
	assert_almost_eq(face.get_add_mult(), 0.0, 0.001)
	assert_almost_eq(face.get_x_mult(), 2.0, 0.001)

func test_wild_face_reports_wild_combo_behavior() -> void:
	var face := TestData.face("wild", 0, DiceFace.Type.WILD)

	assert_eq(face.get_combo_value(), -1)
	assert_true(face.is_wild())
	assert_almost_eq(face.get_face_sum_contribution(), 0.0, 0.001)

func test_duplicate_face_is_independent_copy() -> void:
	var original := TestData.face("pip_6", 6, DiceFace.Type.PIP, 10.0, "rare", 15)
	var duplicate := original.duplicate_face()

	duplicate.value = 1
	duplicate.effect_value = 3.0
	duplicate.rarity = "common"

	assert_eq(original.id, "pip_6")
	assert_eq(original.value, 6)
	assert_almost_eq(original.effect_value, 10.0, 0.001)
	assert_eq(original.rarity, "rare")

func test_type_from_string_maps_known_types() -> void:
	assert_eq(DiceFace.type_from_string("basic"), DiceFace.Type.BASIC)
	assert_eq(DiceFace.type_from_string("pip"), DiceFace.Type.PIP)
	assert_eq(DiceFace.type_from_string("mult"), DiceFace.Type.MULT)
	assert_eq(DiceFace.type_from_string("xmult"), DiceFace.Type.XMULT)
	assert_eq(DiceFace.type_from_string("wild"), DiceFace.Type.WILD)
