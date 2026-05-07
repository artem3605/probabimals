extends GutTest

const SHOP_PURCHASE_RESOLVER_PATH := "res://scripts/shop/shop_purchase_resolver.gd"
const TestData = preload("res://tests/support/test_data.gd")
const TestableGameManagerScript = preload("res://tests/support/testable_game_manager.gd")

var _manager: Variant
var _resolver: Variant


func before_each() -> void:
	_manager = TestableGameManagerScript.new()
	autoqfree(_manager)
	_resolver = _make_resolver()


func _make_resolver() -> Variant:
	var script: GDScript = ResourceLoader.load(SHOP_PURCHASE_RESOLVER_PATH)
	assert_not_null(script)
	if script == null:
		return null
	return script.new()


func test_purchase_catalogue_die_mutates_bag_and_reports_coin_change() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "loaded_die")
	var starting_size: int = _manager.dice_bag.size()
	_manager.coins = 50

	var result: Dictionary = _resolver.purchase_item(_manager, item)
	var bought_die: Die = _manager.dice_bag.get_die(_manager.dice_bag.size() - 1)

	assert_true(result.get("success", false))
	assert_true(result.get("coins_changed", false))
	assert_eq(_manager.coins, 25)
	assert_eq(_manager.dice_bag.size(), starting_size + 1)
	assert_eq(bought_die.color, "red")
	assert_eq(bought_die.get("rarity"), "rare")
	assert_eq_deep(bought_die.get_face_values(), [1, 5, 5, 6, 6, 6])


func test_purchase_item_rejects_insufficient_coins_without_mutating_bag() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "loaded_die")
	var starting_size: int = _manager.dice_bag.size()
	_manager.coins = 24

	var result: Dictionary = _resolver.purchase_item(_manager, item)

	assert_false(result.get("success", true))
	assert_false(result.get("coins_changed", true))
	assert_eq(_manager.coins, 24)
	assert_eq(_manager.dice_bag.size(), starting_size)


func test_purchase_scoring_modifier_adds_modifier_and_reports_coin_change() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "pair_boost")
	_manager.coins = 50

	var result: Dictionary = _resolver.purchase_item(_manager, item)

	assert_true(result.get("success", false))
	assert_true(result.get("coins_changed", false))
	assert_eq(_manager.coins, 40)
	assert_eq(_manager.modifiers.size(), 1)
	assert_eq(_manager.modifiers[0].effect, Modifier.Effect.ADD_MULT)
	assert_eq(_manager.modifiers[0].condition, "pair")


func test_purchase_reroll_modifier_increases_rerolls_without_adding_modifier() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "reroll_plus")
	_manager.coins = 50

	var result: Dictionary = _resolver.purchase_item(_manager, item)

	assert_true(result.get("success", false))
	assert_true(result.get("coins_changed", false))
	assert_eq(_manager.coins, 25)
	assert_eq(_manager.rerolls_per_hand, 4)
	assert_eq(_manager.modifiers.size(), 0)


func test_invalid_modifier_purchase_does_not_charge_coins() -> void:
	_manager.coins = 50
	var item := {
		"id": "bad_modifier",
		"name": "Bad Modifier",
		"category": "modifier",
		"cost": 25,
		"rarity": "common",
		"params":
		{
			"effect": "unknown_effect",
			"value": 1.0,
			"condition": "pair",
		},
	}

	var result: Dictionary = _resolver.purchase_item(_manager, item)

	assert_false(result.get("success", true))
	assert_false(result.get("coins_changed", true))
	assert_eq(_manager.coins, 50)
	assert_eq(_manager.modifiers.size(), 0)
	assert_eq(_manager.rerolls_per_hand, 3)


func test_purchase_face_swap_replaces_face_and_reports_coin_change() -> void:
	_manager.coins = 20
	_manager.dice_bag.add_die(Die.new())
	var new_face := TestData.basic_face(6)
	var die: Die = _manager.dice_bag.get_die(0)

	var result: Dictionary = _resolver.purchase_face_swap(_manager, 0, 0, new_face, 7)

	assert_true(result.get("success", false))
	assert_true(result.get("coins_changed", false))
	assert_eq(_manager.coins, 13)
	assert_eq(die.get_face(0).value, 6)


func test_purchase_face_swap_rejects_insufficient_coins_without_swapping() -> void:
	_manager.coins = 6
	_manager.dice_bag.add_die(Die.new())
	var new_face := TestData.basic_face(6)
	var die: Die = _manager.dice_bag.get_die(0)

	var result: Dictionary = _resolver.purchase_face_swap(_manager, 0, 0, new_face, 7)

	assert_false(result.get("success", true))
	assert_false(result.get("coins_changed", true))
	assert_eq(_manager.coins, 6)
	assert_eq(die.get_face(0).value, 1)
