extends GutTest

const TestableGameManagerScript = preload("res://tests/support/testable_game_manager.gd")
const RUN_OUTCOME_RESOLVER_PATH := "res://scripts/run/run_outcome_resolver.gd"

var _manager: Variant
var _resolver: Variant


func before_each() -> void:
	_manager = TestableGameManagerScript.new()
	autoqfree(_manager)
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()
	_resolver = _make_resolver()


func after_each() -> void:
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func test_overlay_run_combat_victory_completes_node_once_and_requests_save() -> void:
	if _resolver == null:
		return
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(1)
	_manager.current_round = 1
	_manager.coins = 50
	_manager.target_score = 150

	var result: Dictionary = _resolver.resolve_combat_result_for_overlay(_manager, TutorialManager, 180, true)
	var duplicate: Dictionary = _resolver.resolve_combat_result_for_overlay(_manager, TutorialManager, 999, true)

	assert_eq(result.get("phase"), _manager.Phase.MAP)
	assert_eq(result.get("save_action"), _resolver.SAVE_ACTION_SAVE)
	assert_false(bool(result.get("already_resolved", false)))
	assert_eq(duplicate.get("phase"), _manager.Phase.MAP)
	assert_eq(duplicate.get("save_action"), _resolver.SAVE_ACTION_NONE)
	assert_true(bool(duplicate.get("already_resolved", false)))
	assert_eq(_manager.total_score, 180)
	assert_eq(_manager.current_round, 2)
	assert_eq(_manager.coins, 65)
	assert_eq(_manager.current_run.completed_node_ids, [1] as Array[int])


func test_resolver_returns_state_events_without_emitting_manager_signals() -> void:
	if _resolver == null:
		return
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(1)
	_manager.current_round = 1
	_manager.coins = 50
	watch_signals(_manager)

	var result: Dictionary = _resolver.resolve_combat_result(_manager, TutorialManager, 180, true)

	assert_signal_not_emitted(_manager, "score_changed")
	assert_signal_not_emitted(_manager, "coins_changed")
	assert_eq_deep(result.get("events", {}), {"score_changed": 180, "coins_changed": 65})


func test_overlay_run_combat_defeat_records_result_and_requests_delete() -> void:
	if _resolver == null:
		return
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(1)
	_manager.current_round = 2
	_manager.coins = 17

	var result: Dictionary = _resolver.resolve_combat_result_for_overlay(_manager, TutorialManager, 12, false)

	assert_eq(result.get("phase"), _manager.Phase.MAIN_MENU)
	assert_eq(result.get("save_action"), _resolver.SAVE_ACTION_DELETE)
	assert_null(_manager.current_run)
	assert_eq_deep(
		_manager.last_run_result,
		{
			"victory": false,
			"round": 2,
			"total_score": 12,
			"coins": 17,
		}
	)


func test_boss_victory_records_terminal_result_and_requests_delete() -> void:
	if _resolver == null:
		return
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(4)
	_manager.current_round = 3
	_manager.coins = 10
	_manager.target_score = 200

	var result: Dictionary = _resolver.resolve_combat_result(_manager, TutorialManager, 640, true)

	assert_eq(result.get("phase"), _manager.Phase.MAIN_MENU)
	assert_eq(result.get("save_action"), _resolver.SAVE_ACTION_DELETE)
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


func test_tutorial_intro_win_advances_to_shop_without_ending_run() -> void:
	if _resolver == null:
		return
	_manager.current_run = _build_test_run_state()
	_manager.current_round = 0
	_manager.coins = 25
	_manager.target_score = 60
	TutorialManager.start_first_run()

	var result: Dictionary = _resolver.resolve_combat_result(_manager, TutorialManager, 60, true)

	assert_eq(result.get("phase"), _manager.Phase.SHOP)
	assert_eq(result.get("save_action"), _resolver.SAVE_ACTION_NONE)
	assert_not_null(_manager.current_run)
	assert_eq(_manager.current_round, 1)
	assert_eq(_manager.coins, 35)
	assert_eq(_manager.target_score, _manager.BASE_TARGET)
	assert_eq_deep(_manager.last_run_result, {})


func test_advance_round_uses_resolver_state_transition_and_returns_events() -> void:
	if _resolver == null:
		return
	var selected_dice: Array[Die] = [Die.new()]
	_manager.current_round = 2
	_manager.coins = 50
	_manager.target_score = 200
	_manager.selected_dice = selected_dice

	var result: Dictionary = _resolver.advance_round(_manager)

	assert_eq(result.get("phase"), _manager.Phase.SHOP)
	assert_eq_deep(result.get("events", {}), {"coins_changed": 70})
	assert_eq(_manager.coins, 70)
	assert_eq(_manager.current_round, 3)
	assert_eq(_manager.target_score, 337)
	assert_eq(_manager.selected_dice.size(), 0)


func _make_resolver() -> Variant:
	var script: Variant = load(RUN_OUTCOME_RESOLVER_PATH)
	assert_not_null(script, "RunOutcomeResolver should exist at %s" % RUN_OUTCOME_RESOLVER_PATH)
	if script == null:
		return null
	return script.new()


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
