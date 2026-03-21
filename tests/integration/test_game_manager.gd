extends GutTest

const TestData = preload("res://tests/support/test_data.gd")
const TestableGameManagerScript = preload("res://tests/support/testable_game_manager.gd")

var _manager: Variant
var _temp_paths: Array[String] = []

func before_each() -> void:
	_manager = TestableGameManagerScript.new()
	autoqfree(_manager)

func after_each() -> void:
	for path in _temp_paths:
		_manager.delete_save(path)
	_temp_paths.clear()

func test_buy_item_adds_die_from_catalogue_entry() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "loaded_die")
	var starting_size: int = _manager.dice_bag.size()

	var success: bool = _manager.buy_item(item)
	var bought_die: Die = _manager.dice_bag.get_die(_manager.dice_bag.size() - 1)

	assert_true(success)
	assert_eq(_manager.coins, 25)
	assert_eq(_manager.dice_bag.size(), starting_size + 1)
	assert_eq(bought_die.color, "red")
	assert_eq_deep(bought_die.get_face_values(), [1, 5, 5, 6, 6, 6])

func test_buy_item_adds_scoring_modifier() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "pair_boost")

	assert_true(_manager.buy_item(item))
	assert_eq(_manager.modifiers.size(), 1)
	assert_eq(_manager.modifiers[0]["effect"], "add_mult")
	assert_eq(_manager.modifiers[0]["condition"], "pair")
	assert_almost_eq(_manager.modifiers[0]["value"], 4.0, 0.001)

func test_buy_item_increases_rerolls_for_reroll_modifier() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "reroll_plus")

	assert_true(_manager.buy_item(item))
	assert_eq(_manager.rerolls_per_hand, 4)
	assert_eq(_manager.modifiers.size(), 0)

func test_advance_round_updates_reward_target_and_phase() -> void:
	var selected_dice: Array[Die] = [TestData.die_from_values([1, 2, 3, 4, 5, 6])]
	_manager.current_round = 2
	_manager.coins = 50
	_manager.selected_dice = selected_dice

	_manager.advance_round()

	assert_eq(_manager.coins, 70)
	assert_eq(_manager.current_round, 3)
	assert_eq(_manager.target_score, 337)
	assert_eq(_manager.selected_dice.size(), 0)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.FLEA_MARKET])

func test_build_save_data_normalizes_combat_phase() -> void:
	_manager.current_phase = _manager.Phase.COMBAT

	var data: Dictionary = _manager.build_save_data()

	assert_eq(data["phase"], "FLEA_MARKET")

func test_build_and_apply_save_data_round_trip_preserves_state() -> void:
	_manager.current_phase = _manager.Phase.DICE_SELECT
	_manager.coins = 37
	_manager.total_score = 121
	_manager.target_score = 275
	_manager.hands_per_round = 5
	_manager.rerolls_per_hand = 4
	_manager.current_round = 3
	_manager.dice_bag = DiceBag.new()
	_manager.dice_bag.add_die(Die.new([
		TestData.basic_face(1),
		TestData.face("pip_6", 6, DiceFace.Type.PIP, 10.0),
		TestData.face("mult_2", 2, DiceFace.Type.MULT, 3.0),
		TestData.face("xmult_1", 1, DiceFace.Type.XMULT, 2.0),
		TestData.face("wild", 0, DiceFace.Type.WILD),
		TestData.basic_face(4),
	], "red", "Chaos Die", "Stateful test die"))
	_manager.modifiers = [
		TestData.modifier("x_mult", 3.0, "yahtzee", "yahtzee_hunter", "Yahtzee Hunter")
	]

	var data: Dictionary = _manager.build_save_data()
	var restored: Variant = TestableGameManagerScript.new()
	autoqfree(restored)
	var restored_phase: int = restored.apply_save_data(data)
	restored.current_phase = restored_phase

	assert_eq(restored_phase, restored.Phase.DICE_SELECT)
	assert_eq(restored.coins, 37)
	assert_eq(restored.total_score, 121)
	assert_eq(restored.target_score, 275)
	assert_eq(restored.hands_per_round, 5)
	assert_eq(restored.rerolls_per_hand, 4)
	assert_eq(restored.current_round, 3)
	assert_eq(restored.dice_bag.size(), 1)
	assert_eq(restored.dice_bag.get_die(0).color, "red")
	assert_eq(restored.dice_bag.get_die(0).get_face(1).id, "pip_6")
	assert_eq(restored.dice_bag.get_die(0).get_face(2).face_type, DiceFace.Type.MULT)
	assert_eq_deep(restored.build_save_data(), data)

func test_save_game_uses_override_path_instead_of_production_save() -> void:
	var default_path := "user://gut_default_save_%d.json" % Time.get_ticks_usec()
	var save_path := "user://gut_test_save_%d.json" % Time.get_ticks_usec()
	_temp_paths.append(default_path)
	_temp_paths.append(save_path)
	_manager.save_path = default_path
	_manager.current_phase = _manager.Phase.FLEA_MARKET
	_manager.coins = 99

	_manager.save_game(save_path)

	assert_true(_manager.has_save(save_path))
	assert_false(_manager.has_save())
