extends GutTest

const TestData = preload("res://tests/support/test_data.gd")
const TestableGameManagerScript = preload("res://tests/support/testable_game_manager.gd")

var _manager: Variant
var _temp_paths: Array[String] = []


func before_each() -> void:
	_manager = TestableGameManagerScript.new()
	autoqfree(_manager)
	var save_path := "user://gut_game_manager_%d.json" % Time.get_ticks_usec()
	_manager.save_path = save_path
	_temp_paths.append(save_path)
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func after_each() -> void:
	for path in _temp_paths:
		_manager.delete_save(path)
	_temp_paths.clear()
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func _build_test_run_state() -> RunState:
	var state := RunState.new()
	state.nodes = {
		1: MapNode.new(1, MapNode.NodeType.COMBAT, 1, [2, 3] as Array[int]),
		2: MapNode.new(2, MapNode.NodeType.COMBAT, 2, [4] as Array[int]),
		3: MapNode.new(3, MapNode.NodeType.SHOP, 2, [4] as Array[int]),
		4: MapNode.new(4, MapNode.NodeType.BOSS, 3, [] as Array[int]),
	}
	state.current_node_id = -1
	state.seed = 42
	return state


func test_phase_map_exists() -> void:
	assert_true(GameManager.Phase.keys().has("MAP"))


func test_initial_run_state_is_null() -> void:
	assert_null(_manager.current_run)
	assert_eq_deep(_manager.last_run_result, {})


func test_start_game_creates_run() -> void:
	_manager.last_run_result = {"victory": true}

	await _manager.start_game(true)

	assert_not_null(_manager.current_run)
	assert_eq(_manager.current_run.current_node_id, -1)
	assert_true(_manager.current_run.nodes.size() >= 2)
	assert_eq_deep(_manager.last_run_result, {})
	assert_eq(_manager.current_phase, _manager.Phase.MAP)


func test_buy_item_adds_die_from_catalogue_entry() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "loaded_die")
	var starting_size: int = _manager.dice_bag.size()
	_manager.coins = 50

	var success: bool = _manager.buy_item(item)
	var bought_die: Die = _manager.dice_bag.get_die(_manager.dice_bag.size() - 1)

	assert_true(success)
	assert_eq(_manager.coins, 25)
	assert_eq(_manager.dice_bag.size(), starting_size + 1)
	assert_eq(bought_die.color, "red")
	assert_eq(bought_die.get("rarity"), "rare")
	assert_eq_deep(bought_die.get_face_values(), [1, 5, 5, 6, 6, 6])


func test_buy_item_adds_scoring_modifier() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "pair_boost")

	assert_true(_manager.buy_item(item))
	assert_eq(_manager.modifiers.size(), 1)
	assert_eq(_manager.modifiers[0].effect, Modifier.Effect.ADD_MULT)
	assert_eq(_manager.modifiers[0].condition, "pair")
	assert_almost_eq(_manager.modifiers[0].value, 1.0, 0.001)
	assert_eq(_manager.modifiers[0].rarity, "common")


func test_buy_item_rejects_invalid_modifier_without_charging_coins() -> void:
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

	assert_false(_manager.buy_item(item))
	assert_eq(_manager.coins, 50)
	assert_eq(_manager.modifiers.size(), 0)
	assert_eq(_manager.rerolls_per_hand, 3)


func test_buy_item_increases_rerolls_for_reroll_modifier() -> void:
	var item: Dictionary = TestData.find_item_by_id(TestData.load_shop_catalogue(), "reroll_plus")
	_manager.coins = 50

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


func test_advance_round_outside_run_goes_to_flea_market() -> void:
	_manager.current_run = null
	_manager.last_run_result = {}
	_manager.current_round = 1

	_manager.advance_round()

	assert_eq(_manager.current_phase, _manager.Phase.FLEA_MARKET)
	assert_eq(_manager.current_round, 2)


func test_end_combat_in_run_victory_routes_through_complete_current_node() -> void:
	await _manager.start_game(true)
	_manager.current_run.enter_node(1)
	var final_score: int = _manager.target_score

	_manager.end_combat(final_score, true)

	assert_eq(_manager.total_score, final_score)
	assert_eq(_manager.current_phase, _manager.Phase.MAP)


func test_end_combat_emits_score_changed_from_game_manager() -> void:
	_manager.current_phase = _manager.Phase.COMBAT
	_manager.current_run = null
	var final_score: int = _manager.target_score
	watch_signals(_manager)

	_manager.end_combat(final_score, true)

	assert_signal_emitted_with_parameters(_manager, "score_changed", [final_score])


func test_end_combat_completed_tutorial_run_start_goes_to_map() -> void:
	_manager.current_phase = _manager.Phase.COMBAT
	_manager.current_run = _build_test_run_state()
	_manager.current_run.current_node_id = -1
	TutorialManager.completed = true
	TutorialManager.clear_active_tutorial()

	_manager.end_combat(_manager.target_score, true)

	assert_eq(_manager.current_phase, _manager.Phase.MAP)
	assert_not_null(_manager.current_run)
	assert_eq(_manager.current_run.current_node_id, -1)
	assert_eq_deep(_manager.current_run.completed_node_ids, [] as Array[int])


func test_end_combat_first_run_intro_win_uses_tutorial_continuation() -> void:
	await _manager.start_game(false)
	var intro_target: int = _manager.target_score

	assert_not_null(_manager.current_run)
	assert_eq(_manager.current_phase, _manager.Phase.COMBAT)
	assert_eq(_manager.current_round, 0)
	assert_true(TutorialManager.report_action("advance_intro"))
	assert_true(TutorialManager.report_action("combat_roll", {"roll_number": 0}))
	assert_true(TutorialManager.report_action("hold_changed", {"held_indices": [0]}))
	assert_true(TutorialManager.report_action("combat_roll", {"roll_number": 1}))
	assert_true(TutorialManager.report_action("advance_intro"))
	assert_true(TutorialManager.report_action("combat_score"))
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_WIN)
	assert_true(TutorialManager.report_action("combat_next_round"))

	_manager.end_combat(intro_target, true)

	assert_eq(_manager.total_score, intro_target)
	assert_eq(_manager.current_phase, _manager.Phase.FLEA_MARKET)
	assert_ne(_manager.current_phase, _manager.Phase.MAP)
	assert_eq(_manager.current_round, 1)
	assert_eq(_manager.target_score, _manager.BASE_TARGET)
	assert_eq(_manager.coins, 35)
	assert_not_null(_manager.current_run)
	assert_eq_deep(_manager.last_run_result, {})


func test_end_combat_in_run_defeat_calls_end_run() -> void:
	await _manager.start_game(true)
	_manager.current_round = 2
	_manager.coins = 17

	_manager.end_combat(0, false)

	assert_eq(_manager.current_phase, _manager.Phase.MAIN_MENU)
	assert_null(_manager.current_run)
	assert_eq(_manager.total_score, 0)
	assert_eq_deep(
		_manager.last_run_result,
		{
			"victory": false,
			"round": 2,
			"total_score": 0,
			"coins": 17,
		}
	)


func test_end_combat_outside_run_uses_legacy_advance_or_main_menu() -> void:
	_manager.current_run = null
	_manager.last_run_result = {}
	_manager.current_round = 1

	_manager.end_combat(_manager.target_score, true)

	assert_eq(_manager.current_phase, _manager.Phase.FLEA_MARKET)
	assert_eq(_manager.current_round, 2)


func test_end_combat_outside_run_defeat_goes_to_main_menu() -> void:
	_manager.current_run = null
	_manager.last_run_result = {}
	_manager.current_phase = _manager.Phase.COMBAT

	_manager.end_combat(0, false)

	assert_eq(_manager.current_phase, _manager.Phase.MAIN_MENU)
	assert_null(_manager.current_run)
	assert_eq_deep(_manager.last_run_result, {})


func test_complete_current_node_without_current_node_warns_and_does_not_advance() -> void:
	await _manager.start_game(true)
	_manager.current_round = 1

	_manager.complete_current_node()

	assert_engine_error("Cannot complete a map node before one is selected")
	assert_eq(_manager.current_phase, _manager.Phase.MAP)
	assert_eq(_manager.current_round, 1)


func test_complete_current_node_outside_run_warns_and_returns() -> void:
	_manager.current_run = null
	_manager.current_phase = _manager.Phase.FLEA_MARKET
	_manager.current_round = 2

	_manager.complete_current_node()

	assert_engine_error("Cannot complete a map node without an active run")
	assert_eq(_manager.current_phase, _manager.Phase.FLEA_MARKET)
	assert_eq(_manager.current_round, 2)
	assert_eq_deep(_manager.phase_history, [])


func test_complete_current_node_combat_advances_round_and_goes_to_map() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.current_node_id = 1
	_manager.current_round = 2
	_manager.coins = 10
	_manager.target_score = 200
	var selected_dice: Array[Die] = [TestData.die_from_values([1, 2, 3, 4, 5, 6])]
	_manager.selected_dice = selected_dice

	_manager.complete_current_node()

	assert_eq(_manager.current_phase, _manager.Phase.MAP)
	assert_eq(_manager.current_round, 3)
	assert_eq(_manager.coins, 30)
	assert_eq(_manager.target_score, 337)
	assert_eq(_manager.selected_dice.size(), 0)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.MAP])


func test_complete_current_node_emits_state_change_signals_from_game_manager() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.current_node_id = 1
	_manager.current_round = 2
	_manager.coins = 10
	watch_signals(_manager)

	_manager.complete_current_node()

	assert_signal_emitted_with_parameters(_manager, "coins_changed", [30])


func test_complete_current_node_shop_goes_to_map_without_round_advance() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.current_node_id = 3
	_manager.current_round = 2
	_manager.coins = 10
	_manager.target_score = 200
	var selected_dice: Array[Die] = [TestData.die_from_values([1, 2, 3, 4, 5, 6])]
	_manager.selected_dice = selected_dice

	_manager.complete_current_node()

	assert_eq(_manager.current_phase, _manager.Phase.MAP)
	assert_eq(_manager.current_round, 2)
	assert_eq(_manager.coins, 10)
	assert_eq(_manager.target_score, 200)
	assert_eq(_manager.selected_dice.size(), 1)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.MAP])


func test_complete_current_node_boss_ends_run_with_victory_without_next_round() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.current_node_id = 4
	_manager.current_round = 3
	_manager.coins = 10
	_manager.target_score = 200
	_manager.total_score = 640

	_manager.complete_current_node()

	assert_eq(_manager.current_phase, _manager.Phase.MAIN_MENU)
	assert_null(_manager.current_run)
	assert_eq_deep(
		_manager.last_run_result,
		{
			"victory": true,
			"round": 3,
			"total_score": 640,
			"coins": 35,
		}
	)
	assert_eq(_manager.target_score, 200)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.MAIN_MENU])


func test_flea_market_continue_outside_run_goes_to_dice_select() -> void:
	_manager.current_run = null
	_manager.current_phase = _manager.Phase.FLEA_MARKET

	_manager.flea_market_continue()

	assert_eq(_manager.current_phase, _manager.Phase.DICE_SELECT)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.DICE_SELECT])


func test_flea_market_continue_onboarding_run_start_goes_to_dice_select() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.current_node_id = -1
	_manager.current_phase = _manager.Phase.FLEA_MARKET

	_manager.flea_market_continue()

	assert_engine_error("Unexpected Flea Market continue before selecting a map node")
	assert_eq(_manager.current_phase, _manager.Phase.MAP)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.MAP])


func test_flea_market_continue_shop_node_completes_to_map() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.current_node_id = 3
	_manager.current_phase = _manager.Phase.FLEA_MARKET
	_manager.current_round = 2
	_manager.coins = 10
	_manager.target_score = 200

	_manager.flea_market_continue()

	assert_eq(_manager.current_phase, _manager.Phase.MAP)
	assert_eq(_manager.current_round, 2)
	assert_eq(_manager.coins, 10)
	assert_eq(_manager.target_score, 200)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.MAP])


func test_flea_market_continue_combat_node_warns_and_goes_to_map() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.current_node_id = 1
	_manager.current_phase = _manager.Phase.FLEA_MARKET
	_manager.current_round = 2

	_manager.flea_market_continue()

	assert_engine_error("Unexpected Flea Market continue from non-shop map node")
	assert_eq(_manager.current_phase, _manager.Phase.MAP)
	assert_eq(_manager.current_round, 2)
	assert_not_null(_manager.current_run)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.MAP])


func test_flea_market_continue_boss_node_warns_and_goes_to_map() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.current_node_id = 4
	_manager.current_phase = _manager.Phase.FLEA_MARKET
	_manager.current_round = 3

	_manager.flea_market_continue()

	assert_engine_error("Unexpected Flea Market continue from non-shop map node")
	assert_eq(_manager.current_phase, _manager.Phase.MAP)
	assert_eq(_manager.current_round, 3)
	assert_not_null(_manager.current_run)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.MAP])


func test_end_run_victory_returns_to_main_menu_with_result() -> void:
	await _manager.start_game(true)
	_manager.current_round = 4
	_manager.total_score = 512
	_manager.coins = 37
	_manager.save_game()
	assert_true(_manager.has_save())

	_manager.end_run(true)

	assert_eq(_manager.current_phase, _manager.Phase.MAIN_MENU)
	assert_null(_manager.current_run)
	assert_false(_manager.has_save())
	assert_false(_manager.can_load_save())
	assert_eq_deep(
		_manager.last_run_result,
		{
			"victory": true,
			"round": 4,
			"total_score": 512,
			"coins": 37,
		}
	)


func test_end_run_defeat_returns_to_main_menu_with_result() -> void:
	await _manager.start_game(true)
	_manager.current_round = 4
	_manager.total_score = 512
	_manager.coins = 37
	_manager.save_game()
	assert_true(_manager.has_save())

	_manager.end_run(false)

	assert_eq(_manager.current_phase, _manager.Phase.MAIN_MENU)
	assert_null(_manager.current_run)
	assert_false(_manager.has_save())
	assert_false(_manager.can_load_save())
	assert_eq_deep(
		_manager.last_run_result,
		{
			"victory": false,
			"round": 4,
			"total_score": 512,
			"coins": 37,
		}
	)


func test_abandon_run_clears_run_without_result() -> void:
	await _manager.start_game(true)

	_manager.abandon_run()

	assert_null(_manager.current_run)
	assert_eq_deep(_manager.last_run_result, {})


func test_enter_map_node_rejects_unavailable_node() -> void:
	_manager.current_run = _build_test_run_state()

	_manager.enter_map_node(99)

	assert_engine_error("Cannot enter unavailable map node")
	assert_eq(_manager.current_run.current_node_id, -1)
	assert_eq_deep(_manager.phase_history, [])


func test_enter_map_node_outside_run_warns_and_returns() -> void:
	_manager.current_run = null
	_manager.current_phase = _manager.Phase.MAP

	_manager.enter_map_node(1)

	assert_engine_error("Cannot enter a map node without an active run")
	assert_eq(_manager.current_phase, _manager.Phase.MAP)
	assert_eq_deep(_manager.phase_history, [])


func test_enter_map_node_combat_sets_current_node_and_goes_to_dice_select() -> void:
	_manager.current_run = _build_test_run_state()

	_manager.enter_map_node(1)

	assert_eq(_manager.current_run.current_node_id, 1)
	assert_eq(_manager.current_run.visited_node_ids, [1] as Array[int])
	assert_eq(_manager.current_phase, _manager.Phase.DICE_SELECT)
	assert_eq_deep(_manager.phase_history, [_manager.Phase.DICE_SELECT])


func test_enter_map_node_shop_goes_to_flea_market() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(1)
	_manager.current_run.complete_current_node()

	_manager.enter_map_node(3)

	assert_eq(_manager.current_run.current_node_id, 3)
	assert_eq(_manager.current_phase, _manager.Phase.FLEA_MARKET)


func test_enter_map_node_boss_scales_target_and_goes_to_dice_select() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(1)
	_manager.current_run.complete_current_node()
	_manager.current_run.enter_node(2)
	_manager.current_run.complete_current_node()
	_manager.target_score = 200

	_manager.enter_map_node(4)

	assert_eq(_manager.current_run.current_node_id, 4)
	assert_eq(_manager.target_score, 300)
	assert_eq(_manager.current_phase, _manager.Phase.DICE_SELECT)


func test_build_save_data_normalizes_combat_phase() -> void:
	_manager.current_phase = _manager.Phase.COMBAT

	var data: Dictionary = _manager.build_save_data()

	assert_eq(data["phase"], "FLEA_MARKET")


func test_build_save_data_keeps_combat_phase_for_active_tutorial_checkpoint() -> void:
	_manager.current_phase = _manager.Phase.COMBAT
	TutorialManager.start_first_run()
	TutorialManager.enter_scene(TutorialManager.SCENE_COMBAT)

	var data: Dictionary = _manager.build_save_data()

	assert_eq(data["phase"], "COMBAT")
	assert_eq(data["tutorial_mode"], TutorialManager.MODE_FIRST_RUN)


func test_build_save_data_normalizes_map_run_combat_to_dice_select() -> void:
	_manager.current_phase = _manager.Phase.COMBAT
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(1)

	var data: Dictionary = _manager.build_save_data()

	assert_eq(data["phase"], "DICE_SELECT")
	assert_true(data.has("current_run"))


func test_build_save_data_includes_version_metadata() -> void:
	var data: Dictionary = _manager.build_save_data()

	assert_eq(data["save_version"], 2)
	assert_eq(data["app_version"], _manager.get_app_version())


func test_build_save_data_serializes_current_run_without_last_result() -> void:
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(1)
	_manager.current_run.complete_current_node()
	(
		_manager
		. current_run
		. set_shop_state(
			3,
			{
				"offerings": [{"id": "loaded_die"}],
				"sold": [true],
				"reroll_count": 1,
			}
		)
	)
	_manager.last_run_result = {"victory": true}

	var data: Dictionary = _manager.build_save_data()
	var run_data: Dictionary = data.get("current_run", {})

	assert_true(data.has("current_run"))
	assert_eq(run_data.get("seed"), 42)
	assert_eq(run_data.get("current_node_id"), 1)
	assert_eq(run_data.get("visited_node_ids"), [1])
	assert_eq(run_data.get("completed_node_ids"), [1])
	assert_eq(run_data.get("shop_states", {})["3"]["offerings"][0]["id"], "loaded_die")
	assert_eq(run_data.get("shop_states", {})["3"]["sold"], [true])
	assert_eq(run_data.get("shop_states", {})["3"]["reroll_count"], 1)
	assert_eq((run_data.get("nodes", []) as Array).size(), 4)
	assert_false(data.has("last_run_result"))


func test_build_and_apply_save_data_round_trip_preserves_state() -> void:
	_manager.current_phase = _manager.Phase.DICE_SELECT
	_manager.coins = 37
	_manager.total_score = 121
	_manager.target_score = 275
	_manager.hands_per_round = 5
	_manager.rerolls_per_hand = 4
	_manager.current_round = 3
	_manager.dice_bag = DiceBag.new()
	(
		_manager
		. dice_bag
		. add_die(
			(
				Die
				. new(
					[
						TestData.basic_face(1),
						TestData.face("pip_6", 6, DiceFace.Type.PIP, 10.0),
						TestData.face("mult_2", 2, DiceFace.Type.MULT, 3.0),
						TestData.face("xmult_1", 1, DiceFace.Type.XMULT, 2.0),
						TestData.face("wild", 0, DiceFace.Type.WILD),
						TestData.basic_face(4),
					],
					"red",
					"Chaos Die",
					"Stateful test die"
				)
			)
		)
	)
	_manager.dice_bag.get_die(0).set("rarity", "rare")
	_manager.modifiers = (
		[TestData.modifier("x_mult", 3.0, "yahtzee", "yahtzee_hunter", "Yahtzee Hunter")] as Array[Modifier]
	)
	_manager.modifiers[0].rarity = "rare"
	var selected: Array[Die] = [_manager.dice_bag.get_die(0)]
	_manager.selected_dice = selected
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(1)
	_manager.current_run.complete_current_node()
	_manager.current_run.enter_node(3)
	(
		_manager
		. current_run
		. set_shop_state(
			3,
			{
				"offerings": [{"id": "loaded_die"}],
				"sold": [false],
				"reroll_count": 0,
			}
		)
	)
	TutorialManager.start_replay()
	TutorialManager.enter_scene(TutorialManager.SCENE_DICE_SELECT)
	TutorialManager.report_action("advance_intro")
	TutorialManager.report_action("advance_intro")
	TutorialManager.report_action("advance_intro")
	TutorialManager.report_action("buy_item", {"item_id": "loaded_die", "die_index": 0})
	TutorialManager.report_action("open_face_item", {"item_id": "extra_6"})
	TutorialManager.improved_die_index = 0
	TutorialManager.report_action("go_to_dice_select")

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
	assert_eq(restored.selected_dice.size(), 1)
	assert_eq(restored.dice_bag.get_die(0).color, "red")
	assert_eq(restored.dice_bag.get_die(0).get("rarity"), "rare")
	assert_eq(restored.dice_bag.get_die(0).get_face(1).id, "pip_6")
	assert_eq(restored.dice_bag.get_die(0).get_face(2).face_type, DiceFace.Type.MULT)
	assert_eq(restored.modifiers[0].rarity, "rare")
	assert_not_null(restored.current_run)
	assert_eq(restored.current_run.seed, 42)
	assert_eq(restored.current_run.current_node_id, 3)
	assert_eq(restored.current_run.visited_node_ids, [1, 3] as Array[int])
	assert_eq(restored.current_run.completed_node_ids, [1] as Array[int])
	assert_eq(restored.current_run.nodes.size(), 4)
	assert_eq(restored.current_run.nodes[3].type, MapNode.NodeType.SHOP)
	assert_eq(restored.current_run.get_shop_state(3)["offerings"][0]["id"], "loaded_die")
	assert_eq(restored.current_run.available_node_ids().size(), 0)
	assert_eq(TutorialManager.mode, TutorialManager.MODE_REPLAY)
	assert_eq(TutorialManager.checkpoint_scene, TutorialManager.SCENE_DICE_SELECT)
	assert_eq_deep(restored.build_save_data(), data)


func test_loading_save_clears_run_state() -> void:
	var data: Dictionary = _manager.build_save_data()
	_manager.current_run = _build_test_run_state()
	_manager.last_run_result = {"victory": true}

	_manager.apply_save_data(data)

	assert_null(_manager.current_run)
	assert_eq_deep(_manager.last_run_result, {})


func test_start_tutorial_replay_resets_run_and_enters_intro_combat() -> void:
	_manager.coins = 7
	_manager.current_round = 4
	_manager.target_score = 999
	_manager.modifiers = (
		[TestData.modifier("x_mult", 3.0, "yahtzee", "yahtzee_hunter", "Yahtzee Hunter")] as Array[Modifier]
	)
	_manager.current_run = RunState.new()
	_manager.last_run_result = {"victory": true}

	await _manager.start_tutorial_replay()

	assert_eq(_manager.coins, 25)
	assert_eq(_manager.current_round, 0)
	assert_eq(_manager.target_score, 60)
	assert_eq(_manager.modifiers.size(), 0)
	assert_eq(_manager.selected_dice.size(), 5)
	assert_eq(TutorialManager.mode, TutorialManager.MODE_REPLAY)
	assert_eq(TutorialManager.step_id, TutorialManager.STEP_INTRO_WELCOME)
	assert_eq_deep(TutorialManager.required_combat_hold_indices, [0])
	assert_null(_manager.current_run)
	assert_eq_deep(_manager.last_run_result, {})
	assert_eq_deep(_manager.phase_history, [_manager.Phase.COMBAT])


func test_skip_active_tutorial_completes_and_keeps_map_run() -> void:
	_manager.current_phase = _manager.Phase.COMBAT
	_manager.coins = 25
	_manager.current_round = 0
	_manager.target_score = 60
	_manager.modifiers = ([TestData.modifier("x_mult", 3.0, "yahtzee")] as Array[Modifier])
	var selected_dice: Array[Die] = [TestData.die_from_values([6, 6, 6, 6, 6])]
	_manager.selected_dice = selected_dice
	_manager.current_run = RunState.new()
	_manager.last_run_result = {"victory": true}
	TutorialManager.start_first_run()

	_manager.skip_active_tutorial()

	assert_true(TutorialManager.completed)
	assert_false(TutorialManager.is_active())
	assert_eq(_manager.coins, 10)
	assert_eq(_manager.current_round, 1)
	assert_eq(_manager.target_score, _manager.BASE_TARGET)
	assert_eq(_manager.modifiers.size(), 0)
	assert_eq(_manager.dice_bag.size(), 5)
	assert_eq(_manager.selected_dice.size(), 0)
	assert_not_null(_manager.current_run)
	if _manager.current_run != null:
		assert_eq(_manager.current_run.current_node_id, -1)
		assert_true(_manager.current_run.nodes.size() >= 2)
	assert_eq_deep(_manager.last_run_result, {})
	assert_eq_deep(_manager.phase_history, [_manager.Phase.MAP])


func test_apply_save_data_migrates_legacy_save_without_version() -> void:
	var legacy_data := {
		"phase": "DICE_SELECT",
		"coins": 41,
		"total_score": 240,
		"target_score": 300,
		"hands_per_round": 5,
		"rerolls_per_hand": 2,
		"current_round": 4,
		"dice_bag":
		[{"faces": [1, 2, 3, 4, 5, 6], "color": "green", "name": "Legacy Die", "description": "Old-format die"}],
		"modifiers": [],
	}

	var restored_phase: int = _manager.apply_save_data(legacy_data)

	assert_eq(restored_phase, _manager.Phase.DICE_SELECT)
	assert_eq(_manager.coins, 41)
	assert_eq(_manager.current_round, 4)
	assert_eq(_manager.dice_bag.size(), 1)
	assert_eq(_manager.dice_bag.get_die(0).die_name, "Legacy Die")
	assert_eq(_manager.build_save_data()["save_version"], GameManager.SAVE_FORMAT_VERSION)


func test_apply_save_data_loads_map_save_at_flea_market_without_run_state() -> void:
	var map_save := {
		"save_version": GameManager.SAVE_FORMAT_VERSION,
		"app_version": _manager.get_app_version(),
		"phase": "MAP",
		"coins": 41,
		"total_score": 240,
		"target_score": 300,
		"hands_per_round": 5,
		"rerolls_per_hand": 2,
		"current_round": 4,
		"dice_bag": [],
		"selected_dice_indices": [],
		"modifiers": [],
	}
	_manager.current_run = RunState.new()
	_manager.last_run_result = {"won": true}

	var restored_phase: int = _manager.apply_save_data(map_save)

	assert_eq(restored_phase, _manager.Phase.FLEA_MARKET)
	assert_null(_manager.current_run)
	assert_eq_deep(_manager.last_run_result, {})


func test_apply_save_data_rejects_future_save_version_without_mutating_state() -> void:
	var future_data: Dictionary = _manager.build_save_data()
	future_data["save_version"] = 99
	_manager.coins = 123
	_manager.current_phase = _manager.Phase.MAIN_MENU

	var restored_phase: int = _manager.apply_save_data(future_data)

	assert_eq(restored_phase, _manager.Phase.MAIN_MENU)
	assert_eq(_manager.coins, 123)


func test_save_game_uses_override_path_instead_of_production_save() -> void:
	var default_path := "user://gut_default_save_%d.json" % Time.get_ticks_usec()
	var save_path := "user://gut_test_save_%d.json" % Time.get_ticks_usec()
	_temp_paths.append(default_path)
	_temp_paths.append(save_path)
	_manager.save_path = default_path
	_manager.current_phase = _manager.Phase.FLEA_MARKET
	_manager.coins = 99

	_manager.save_game(save_path)

	var file := FileAccess.open(save_path, FileAccess.READ)
	assert_not_null(file)
	var json := JSON.new()
	assert_eq(json.parse(file.get_as_text()), OK)
	file.close()
	var saved_data: Dictionary = json.data

	assert_true(_manager.has_save(save_path))
	assert_true(_manager.can_load_save(save_path))
	assert_false(_manager.has_save())
	assert_eq(int(saved_data["save_version"]), GameManager.SAVE_FORMAT_VERSION)
	assert_eq(saved_data["app_version"], _manager.get_app_version())


func test_can_load_save_accepts_legacy_save_without_version() -> void:
	var save_path := "user://gut_legacy_save_%d.json" % Time.get_ticks_usec()
	_temp_paths.append(save_path)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	assert_not_null(file)
	(
		file
		. store_string(
			(
				JSON
				. stringify(
					{
						"phase": "FLEA_MARKET",
						"coins": 55,
						"total_score": 10,
						"target_score": 200,
						"hands_per_round": 4,
						"rerolls_per_hand": 3,
						"current_round": 2,
						"dice_bag": [],
						"modifiers": [],
					}
				)
			)
		)
	)
	file.close()

	assert_true(_manager.can_load_save(save_path))


func test_can_load_save_returns_false_for_future_save_version() -> void:
	var save_path := "user://gut_future_save_%d.json" % Time.get_ticks_usec()
	_temp_paths.append(save_path)
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	assert_not_null(file)
	(
		file
		. store_string(
			(
				JSON
				. stringify(
					{
						"save_version": 99,
						"app_version": "v9.9.9",
						"phase": "FLEA_MARKET",
						"coins": 55,
						"total_score": 10,
						"target_score": 200,
						"hands_per_round": 4,
						"rerolls_per_hand": 3,
						"current_round": 2,
						"dice_bag": [],
						"modifiers": [],
					}
				)
			)
		)
	)
	file.close()

	assert_false(_manager.can_load_save(save_path))


func test_tutorial_completion_persists_save_without_phase_change() -> void:
	var save_path := "user://gut_tutorial_complete_%d.json" % Time.get_ticks_usec()
	_temp_paths.append(save_path)
	_manager.save_path = save_path
	_manager.current_phase = _manager.Phase.COMBAT
	TutorialManager.start_first_run()
	TutorialManager.enter_scene(TutorialManager.SCENE_COMBAT)

	TutorialManager.complete_tutorial()
	_manager._on_tutorial_state_changed()

	assert_true(_manager.has_save())
	var file := FileAccess.open(save_path, FileAccess.READ)
	assert_not_null(file)
	var json := JSON.new()
	assert_eq(json.parse(file.get_as_text()), OK)
	var data: Dictionary = json.data
	assert_true(bool(data.get("tutorial_completed", false)))
	assert_eq(str(data.get("tutorial_mode", "")), TutorialManager.MODE_INACTIVE)
	assert_eq(str(data.get("phase", "")), "FLEA_MARKET")


func test_can_load_save_accepts_v1_save_version() -> void:
	var tmp_path := "user://test_old_save.json"
	_temp_paths.append(tmp_path)
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	(
		file
		. store_string(
			(
				JSON
				. stringify(
					{
						"save_version": 1,
						"phase": "FLEA_MARKET",
						"coins": 99,
						"modifiers":
						[
							{
								"id": "pair_boost",
								"name": "Pair Boost",
								"effect": "add_mult",
								"value": 1.0,
								"condition": "pair",
								"rarity": "common",
							}
						],
					}
				)
			)
		)
	)
	file = null

	assert_true(_manager.can_load_save(tmp_path), "v1 saves must stay loadable after format bump to v2")


func test_tutorial_replay_completion_persists_cleared_checkpoint_for_completed_users() -> void:
	var save_path := "user://gut_tutorial_replay_complete_%d.json" % Time.get_ticks_usec()
	_temp_paths.append(save_path)
	_manager.save_path = save_path
	_manager.current_phase = _manager.Phase.COMBAT
	TutorialManager.completed = true
	TutorialManager.start_replay()
	TutorialManager.enter_scene(TutorialManager.SCENE_COMBAT)
	_manager._sync_tutorial_tracking()

	TutorialManager.complete_tutorial()
	_manager._on_tutorial_state_changed()

	assert_true(_manager.has_save())
	var file := FileAccess.open(save_path, FileAccess.READ)
	assert_not_null(file)
	var json := JSON.new()
	assert_eq(json.parse(file.get_as_text()), OK)
	var data: Dictionary = json.data
	var tutorial_state: Dictionary = data.get("tutorial_state", {})
	assert_true(bool(data.get("tutorial_completed", false)))
	assert_eq(str(data.get("tutorial_mode", "")), TutorialManager.MODE_INACTIVE)
	assert_eq(str(tutorial_state.get("step_id", "__missing__")), "")
	assert_eq(str(tutorial_state.get("checkpoint_scene", "__missing__")), "")
