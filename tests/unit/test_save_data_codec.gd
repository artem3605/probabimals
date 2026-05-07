extends GutTest

const SAVE_DATA_CODEC_PATH := "res://scripts/save/save_data_codec.gd"
const TestData = preload("res://tests/support/test_data.gd")
const TestableGameManagerScript = preload("res://tests/support/testable_game_manager.gd")

var _manager: Variant
var _codec: Variant


func before_each() -> void:
	_manager = TestableGameManagerScript.new()
	autoqfree(_manager)
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()
	_codec = _make_codec()


func after_each() -> void:
	TutorialManager.completed = false
	TutorialManager.clear_active_tutorial()


func test_codec_round_trips_player_run_and_tutorial_state_without_file_io() -> void:
	if _codec == null:
		return
	_manager.current_phase = _manager.Phase.DICE_SELECT
	_manager.coins = 37
	_manager.total_score = 121
	_manager.target_score = 275
	_manager.current_round = 3
	_manager.dice_bag = DiceBag.new()
	_manager.dice_bag.add_die(TestData.die_from_values([1, 6, 2, 1, 0, 4]))
	_manager.modifiers = (
		[TestData.modifier("x_mult", 3.0, "yahtzee", "yahtzee_hunter", "Yahtzee Hunter")] as Array[Modifier]
	)
	_manager.selected_dice = [_manager.dice_bag.get_die(0)] as Array[Die]
	_manager.current_run = _build_test_run_state()
	_manager.current_run.enter_node(1)
	_manager.current_run.complete_current_node()
	_manager.current_run.enter_node(3)
	_manager.current_run.set_shop_state(3, {"offerings": [{"id": "loaded_die"}], "sold": [false]})
	TutorialManager.start_replay()
	TutorialManager.enter_scene(TutorialManager.SCENE_DICE_SELECT)

	var data: Dictionary = _codec.build_save_data(_manager, TutorialManager, _manager.get_app_version(), -1)
	var restored: Variant = TestableGameManagerScript.new()
	autoqfree(restored)
	var restored_phase: int = _codec.apply_save_data(
		restored, TutorialManager, data, restored.Phase.MAIN_MENU, restored.get_app_version()
	)

	assert_eq(restored_phase, restored.Phase.DICE_SELECT)
	assert_eq(restored.coins, 37)
	assert_eq(restored.total_score, 121)
	assert_eq(restored.target_score, 275)
	assert_eq(restored.current_round, 3)
	assert_eq(restored.dice_bag.size(), 1)
	assert_eq(restored.selected_dice.size(), 1)
	assert_eq(restored.modifiers.size(), 1)
	assert_not_null(restored.current_run)
	assert_eq(restored.current_run.current_node_id, 3)
	assert_eq(restored.current_run.completed_node_ids, [1] as Array[int])
	assert_eq(restored.current_run.get_shop_state(3)["offerings"][0]["id"], "loaded_die")
	assert_eq(TutorialManager.mode, TutorialManager.MODE_REPLAY)


func _make_codec() -> Variant:
	var script: Variant = ResourceLoader.load(SAVE_DATA_CODEC_PATH)
	assert_not_null(script, "SaveDataCodec script should exist")
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
