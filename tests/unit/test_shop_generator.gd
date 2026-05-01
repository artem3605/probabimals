extends GutTest

const ShopGeneratorScript = preload("res://scripts/shop/shop_generator.gd")
const TestData = preload("res://tests/support/test_data.gd")

var _generator

func before_each() -> void:
	_generator = ShopGeneratorScript.new()
	_generator.set_seed(1234)

func test_default_shop_size_is_five() -> void:
	assert_eq(ShopGeneratorScript.DEFAULT_SHOP_SLOTS, 5)

func test_shop_catalogue_items_have_rarity_and_weight_metadata() -> void:
	for item in TestData.load_shop_catalogue():
		assert_true(item.has("rarity"), "%s should define rarity" % item.get("id", "unknown"))
		assert_true(item.has("shop_weight"), "%s should define shop_weight" % item.get("id", "unknown"))
		assert_gt(float(item.get("shop_weight", 0.0)), 0.0)

func test_face_swap_items_have_lower_average_weight_than_dice_and_modifiers() -> void:
	var catalogue := TestData.load_shop_catalogue()
	var face_weights := _weights_for_category(catalogue, "face")
	var die_weights := _weights_for_category(catalogue, "die")
	var modifier_weights := _weights_for_category(catalogue, "modifier")

	assert_lt(_average(face_weights), _average(die_weights))
	assert_lt(_average(face_weights), _average(modifier_weights))

func test_shop_catalogue_includes_missing_low_face_swaps() -> void:
	for value in [1, 2, 3]:
		var item := TestData.find_item_by_id(TestData.load_shop_catalogue(), "extra_%d" % value)
		assert_false(item.is_empty(), "extra_%d should exist" % value)
		assert_eq(item.get("category", ""), "face")
		assert_eq(int(item.get("params", {}).get("value", 0)), value)
		assert_eq(str(item.get("params", {}).get("face_id", "")), "extra_%d" % value)

func test_double_three_copy_does_not_include_double_word() -> void:
	var item := TestData.find_item_by_id(TestData.load_shop_catalogue(), "double_3")

	assert_false(item.is_empty(), "double_3 should exist")
	assert_eq(item.get("name", ""), "Three")
	assert_eq(item.get("description", ""), "Replace a face with a 3")

func test_shop_catalogue_includes_permanent_sum_bonus_modifiers() -> void:
	var expected := {
		"steady_sum": {"value": 2.0, "rarity": "common", "cost": 12, "shop_weight": 7},
		"solid_sum": {"value": 4.0, "rarity": "uncommon", "cost": 22, "shop_weight": 5},
		"golden_sum": {"value": 7.0, "rarity": "rare", "cost": 36, "shop_weight": 2},
	}
	for item_id in expected.keys():
		var item := TestData.find_item_by_id(TestData.load_shop_catalogue(), item_id)
		var expectation: Dictionary = expected[item_id]
		assert_false(item.is_empty(), "%s should exist" % item_id)
		assert_eq(item.get("category", ""), "modifier")
		assert_eq(item.get("rarity", ""), expectation["rarity"])
		assert_eq(int(item.get("cost", 0)), expectation["cost"])
		assert_eq(int(item.get("shop_weight", 0)), expectation["shop_weight"])
		assert_eq(item.get("params", {}).get("effect", ""), "bonus")
		assert_eq(item.get("params", {}).get("condition", ""), "always")
		assert_almost_eq(float(item.get("params", {}).get("value", 0.0)), expectation["value"], 0.001)

func test_combo_catalogue_uses_integer_multiplier_ladder() -> void:
	var expected := {
		"high_card": 1.0,
		"pair": 2.0,
		"two_pair": 3.0,
		"three_same": 4.0,
		"small_straight": 5.0,
		"full_house": 6.0,
		"large_straight": 8.0,
		"four_same": 10.0,
		"yahtzee": 15.0,
	}
	for combo in TestData.load_combo_rules():
		var combo_type := str(combo.get("type", ""))
		assert_true(expected.has(combo_type), "%s should be part of the integer ladder" % combo_type)
		var mult := float(combo.get("combo_mult", 0.0))
		assert_almost_eq(mult, expected.get(combo_type, 0.0), 0.001)
		assert_eq(mult, float(int(mult)), "%s should use an integer multiplier" % combo_type)

func test_generate_offerings_draws_weighted_unique_items_with_required_categories() -> void:
	var offerings: Array[Dictionary] = _generator.generate_offerings(TestData.load_shop_catalogue())

	assert_eq(offerings.size(), ShopGeneratorScript.DEFAULT_SHOP_SLOTS)
	assert_eq(_unique_id_count(offerings), offerings.size())
	assert_true(_has_category(offerings, "die"))
	assert_true(_has_category(offerings, "modifier"))

func _weights_for_category(catalogue: Array, category: String) -> Array[float]:
	var weights: Array[float] = []
	for item in catalogue:
		if item.get("category", "") == category:
			weights.append(float(item.get("shop_weight", 0.0)))
	return weights

func _average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for value in values:
		total += value
	return total / float(values.size())

func _unique_id_count(items: Array[Dictionary]) -> int:
	var ids := {}
	for item in items:
		ids[item.get("id", "")] = true
	return ids.size()

func _has_category(items: Array[Dictionary], category: String) -> bool:
	for item in items:
		if item.get("category", "") == category:
			return true
	return false
