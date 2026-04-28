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
