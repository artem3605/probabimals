extends GutTest

const TestData = preload("res://tests/support/test_data.gd")

func test_from_values_creates_die_with_faces_and_metadata() -> void:
	var die := Die.from_values([1, 2, 3, 4, 5, 6], "red", "Loaded Die", "High-roll bias")

	assert_eq_deep(die.get_face_values(), [1, 2, 3, 4, 5, 6])
	assert_eq(die.color, "red")
	assert_eq(die.die_name, "Loaded Die")
	assert_eq(die.description, "High-roll bias")

func test_swap_face_uses_a_copy_of_the_supplied_face() -> void:
	var die := Die.new()
	var new_face := TestData.face("pip_6", 6, DiceFace.Type.PIP, 10.0)

	die.swap_face(0, new_face)
	new_face.value = 1
	new_face.effect_value = 0.0

	assert_eq(die.get_face(0).id, "pip_6")
	assert_eq(die.get_face(0).value, 6)
	assert_almost_eq(die.get_face(0).effect_value, 10.0, 0.001)

func test_get_face_returns_null_for_invalid_index() -> void:
	var die := Die.new()

	assert_null(die.get_face(-1))
	assert_null(die.get_face(99))

func test_duplicate_die_creates_deep_copy() -> void:
	var die := Die.new([
		TestData.basic_face(1),
		TestData.face("pip_6", 6, DiceFace.Type.PIP, 10.0),
		TestData.face("mult_2", 2, DiceFace.Type.MULT, 3.0),
		TestData.face("xmult_1", 1, DiceFace.Type.XMULT, 2.0),
		TestData.face("wild", 0, DiceFace.Type.WILD),
		TestData.basic_face(4),
	], "blue", "Chaos Die", "Test description")
	var duplicate := die.duplicate_die()

	duplicate.swap_face(0, TestData.basic_face(6))

	assert_eq_deep(die.get_face_values(), [1, 6, 2, 1, 0, 4])
	assert_eq_deep(duplicate.get_face_values(), [6, 6, 2, 1, 0, 4])
	assert_eq(die.color, duplicate.color)
	assert_eq(die.die_name, duplicate.die_name)
